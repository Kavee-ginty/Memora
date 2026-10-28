"""Durable ingestion worker.

External storage/model calls happen outside database transactions. Each handler
re-checks its lease before persisting so a crashed worker cannot commit stale work.
"""

from __future__ import annotations

import base64
import hashlib
import json
import logging
import time
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.core.config import Settings
from memora.modules.ingestion.constants import (
    CANDIDATE_SCHEMA_VERSION,
    FAILURE_CODES,
    JOB_BACKOFF_SECONDS,
    JOB_DELETE_UPLOAD,
    JOB_EXTRACT,
    JOB_RECONCILE,
    confidence_band,
    requires_verification,
)
from memora.modules.ingestion.extraction import (
    ExtractionProvider,
    ExtractionUnavailable,
    NoExtractableContent,
    build_extraction_provider,
)
from memora.modules.ingestion.service import ManualTextProtector
from memora.modules.ingestion.storage import ObjectStorage, StorageUnavailable, build_object_storage
from memora.modules.ingestion.validation import validate_upload_bytes

logger = logging.getLogger(__name__)
LEASE_SECONDS = 120
RECONCILE_INTERVAL_SECONDS = 60
DELETER_VERSION = "ingestion-deleter-v1"


class IngestionWorker:
    def __init__(
        self,
        engine: Engine,
        settings: Settings,
        *,
        extractor: ExtractionProvider | None = None,
        storage: ObjectStorage | None = None,
        protector: ManualTextProtector | None = None,
        worker_id: str | None = None,
    ) -> None:
        self.engine = engine
        self.settings = settings
        self.extractor = extractor or build_extraction_provider(settings)
        self.storage = storage or build_object_storage(settings)
        self.protector = protector
        self.worker_id = worker_id or f"ingestion-{uuid4()}"
        self._last_reconcile = 0.0

    def run_once(self) -> bool:
        job = self._claim_job()
        if job is None:
            return False
        try:
            if job["job_type"] == JOB_EXTRACT:
                self._handle_extract(job)
                return True
            if job["job_type"] == JOB_DELETE_UPLOAD:
                self._handle_delete(job)
                return True
            if job["job_type"] == JOB_RECONCILE:
                self._handle_reconcile(job)
                return True
            self._retry_or_fail(job, "unsupported_job_type")
        except Exception:
            logger.exception("ingestion job failed safely", extra={"job_id": str(job["id"])})
            self._retry_or_fail(job, "internal_error")
        return True

    def run_forever(self, *, poll_seconds: float = 2.0) -> None:
        logger.info("ingestion worker started", extra={"worker_id": self.worker_id})
        while True:
            worked = self.run_once()
            now = time.monotonic()
            if now - self._last_reconcile >= RECONCILE_INTERVAL_SECONDS:
                self._last_reconcile = now
                self.reconcile()
            if not worked:
                time.sleep(poll_seconds)

    def _claim_job(self) -> dict[str, Any] | None:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_worker"))
            row = (
                connection.execute(
                    text("""
                        WITH next_job AS (
                            SELECT id FROM background_jobs
                            WHERE (
                                (status IN ('queued','retry_wait') AND available_at <= now())
                                OR (status = 'leased' AND lease_expires_at <= now())
                            )
                            ORDER BY available_at
                            FOR UPDATE SKIP LOCKED
                            LIMIT 1
                        )
                        UPDATE background_jobs
                        SET status = 'leased', lease_owner = :owner,
                            lease_expires_at = now() + (:lease_seconds * interval '1 second'),
                            attempt_count = attempt_count + 1,
                            updated_at = now(), row_version = row_version + 1
                        FROM next_job
                        WHERE background_jobs.id = next_job.id
                        RETURNING background_jobs.id, job_type, owner_user_id,
                                  resource_type, resource_id, attempt_count,
                                  max_attempts, payload
                        """),
                    {"owner": self.worker_id, "lease_seconds": LEASE_SECONDS},
                )
                .mappings()
                .first()
            )
            if row is None:
                return
            return dict(row)

    def _scope(self, connection: Connection, user_id: UUID | None) -> None:
        connection.execute(text("SET LOCAL ROLE memora_worker"))
        if user_id is not None:
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(user_id)},
            )

    def _lease_still_held(self, connection: Connection, job: dict[str, Any]) -> bool:
        return bool(
            connection.scalar(
                text(
                    "SELECT 1 FROM background_jobs "
                    "WHERE id = :id AND status = 'leased' AND lease_owner = :owner "
                    "FOR UPDATE"
                ),
                {"id": job["id"], "owner": self.worker_id},
            )
        )

    def _handle_extract(self, job: dict[str, Any]) -> None:
        context = self._load_extraction_context(job)
        if context is None:
            return
        candidates, failure = self._extract_candidates(context)
        if failure is not None:
            self._fail_extraction(job, context, failure)
            return
        self._persist_candidates(job, context, candidates)

    def _load_extraction_context(self, job: dict[str, Any]) -> dict[str, Any] | None:
        owner = job["owner_user_id"]
        with self.engine.begin() as connection:
            self._scope(connection, owner)
            payload = connection.scalar(
                text("SELECT memora_ingestion_context(:update_id, :user_id)"),
                {"update_id": job["resource_id"], "user_id": owner},
            )
            if payload is None:
                self._finish_job(connection, job, "succeeded", None)
                return
            update = dict(payload["update"])
            if update["status"] != "processing":
                self._finish_job(connection, job, "succeeded", None)
                return
            ciphertext = update["manual_text_ciphertext"]
            update["manual_text_ciphertext"] = (
                base64.b64decode(ciphertext) if ciphertext is not None else None
            )
            upload = dict(payload["upload"]) if payload["upload"] is not None else None
            aliases = [
                dict(row)
                for row in connection.execute(
                    text("""
                        SELECT ca.alias_text, ca.is_preferred,
                               c.id AS concept_id, cv.id AS concept_version_id,
                               cv.title, cv.definition
                        FROM concept_aliases ca
                        JOIN concept_versions cv ON cv.id = ca.concept_version_id
                        JOIN concepts c ON c.id = cv.concept_id
                        WHERE c.subject_id = :subject_id
                          AND c.status = 'approved'
                          AND cv.content_status = 'approved'
                        ORDER BY ca.is_preferred DESC
                        LIMIT 500
                        """),
                    {"subject_id": update["subject_id"]},
                ).mappings()
            ]
        return {"update": update, "upload": dict(upload) if upload else None, "aliases": aliases}

    def _extract_candidates(self, context: dict[str, Any]) -> tuple[list[Any], str | None]:
        update = context["update"]
        manual_text = None
        if update["manual_text_ciphertext"] is not None:
            if self.protector is None:
                return [], "extraction_unavailable"
            try:
                manual_text = self.protector.decrypt(
                    bytes(update["manual_text_ciphertext"]), update_id=update["id"]
                )
            except Exception:
                logger.exception("manual text could not be decrypted")
                return [], "extraction_failed"
        file_bytes = None
        media_type = None
        declared_name = None
        upload = context["upload"]
        if upload is not None:
            media_type = upload["declared_media_type"]
            declared_name = upload["declared_name"]
            try:
                observed = self.storage.head_object(upload["object_key"])
                if observed is None:
                    return [], "source_unavailable"
                if observed.byte_size > self.settings.upload_max_bytes:
                    return [], "payload_too_large"
                file_bytes = self.storage.get_object(upload["object_key"])
                validate_upload_bytes(
                    payload=file_bytes,
                    declared_name=upload["declared_name"],
                    declared_media_type=upload["declared_media_type"],
                    maximum=self.settings.upload_max_bytes,
                    expected_sha256=upload["content_sha256"] or "",
                )
            except StorageUnavailable:
                return [], "source_unavailable"
            except ApiError as exc:
                return [], exc.code
        try:
            candidates = self.extractor.extract(
                manual_text=manual_text,
                file_bytes=file_bytes,
                media_type=media_type,
                declared_name=declared_name,
                aliases=context["aliases"],
            )
        except NoExtractableContent:
            return [], "no_extractable_content"
        except ExtractionUnavailable:
            return [], "extraction_unavailable"
        except Exception:
            logger.exception("extraction provider failed")
            return [], "extraction_failed"
        return candidates, None

    def _persist_candidates(
        self, job: dict[str, Any], context: dict[str, Any], candidates: list[Any]
    ) -> None:
        update = context["update"]
        with self.engine.begin() as connection:
            self._scope(connection, update["user_id"])
            if not self._lease_still_held(connection, job):
                return
            connection.execute(
                text("""
                    DELETE FROM verification_requests
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status IN ('pending','expired')
                    """),
                {"update_id": update["id"], "user_id": update["user_id"]},
            )
            connection.execute(
                text("""
                    DELETE FROM extraction_candidates
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status IN ('candidate','needs_verification')
                    """),
                {"update_id": update["id"], "user_id": update["user_id"]},
            )
            expires_at = datetime.now(UTC) + timedelta(
                hours=self.settings.verification_expiry_hours
            )
            seen_keys: set[tuple[str, str]] = set()
            for candidate in candidates:
                payload_identity = json.dumps(candidate.payload, sort_keys=True, default=str)
                candidate_key = (candidate.candidate_type, payload_identity)
                if candidate_key in seen_keys:
                    continue
                seen_keys.add(candidate_key)
                candidate_id = uuid4()
                needs_verification = requires_verification(candidate.confidence)
                connection.execute(
                    text("""
                        INSERT INTO extraction_candidates(
                            id, learning_update_id, user_id, candidate_type,
                            candidate_payload, source_locator, confidence,
                            model_key, prompt_version, schema_version, status, expires_at
                        ) VALUES (
                            :id, :update_id, :user_id, :candidate_type,
                            CAST(:payload AS jsonb), CAST(:locator AS jsonb), :confidence,
                            :model_key, :prompt_version, :schema_version, :status, :expires_at
                        )
                        """),
                    {
                        "id": candidate_id,
                        "update_id": update["id"],
                        "user_id": update["user_id"],
                        "candidate_type": candidate.candidate_type,
                        "payload": json.dumps(candidate.payload, default=str),
                        "locator": json.dumps(candidate.source_locator, default=str),
                        "confidence": candidate.confidence,
                        "model_key": self.extractor.model_key,
                        "prompt_version": self.extractor.prompt_version,
                        "schema_version": CANDIDATE_SCHEMA_VERSION,
                        "status": "needs_verification" if needs_verification else "accepted",
                        "expires_at": expires_at,
                    },
                )
                if not needs_verification:
                    continue
                connection.execute(
                    text("""
                            INSERT INTO verification_requests(
                                learning_update_id, candidate_id, user_id,
                                reason_code, question_text, options,
                                status, expires_at
                            ) VALUES (
                                :update_id, :candidate_id, :user_id,
                                'low_confidence_extraction', :question,
                                CAST(:options AS jsonb), 'pending', :expires_at
                            )
                            """),
                    {
                        "update_id": update["id"],
                        "candidate_id": candidate_id,
                        "user_id": update["user_id"],
                        "question": f"Check this extracted {candidate.candidate_type}.",
                        "options": json.dumps(
                            {
                                "schema_version": CANDIDATE_SCHEMA_VERSION,
                                "confidence_band": confidence_band(candidate.confidence),
                                "decisions": ["accept", "edit", "reject", "merge"],
                            }
                        ),
                        "expires_at": expires_at,
                    },
                )
                continue
            if context["upload"] is not None:
                connection.execute(
                    text("""
                        UPDATE source_uploads
                        SET status = 'validated', updated_at = now(),
                            row_version = row_version + 1
                        WHERE id = :upload_id AND status = 'processing'
                        """),
                    {"upload_id": context["upload"]["id"]},
                )
            connection.execute(
                text(
                    "SELECT memora_ingestion_mark_update("
                    ":update_id, :user_id, 'verification_required', NULL)"
                ),
                {"update_id": update["id"], "user_id": update["user_id"]},
            )
            self._finish_job(connection, job, "succeeded", None)

    def _fail_extraction(
        self, job: dict[str, Any], context: dict[str, Any], failure_code: str
    ) -> None:
        safe_code = failure_code if failure_code in FAILURE_CODES else "extraction_failed"
        logger.warning("ingestion extraction failed", extra={"failure_code": safe_code})
        update = context["update"]
        retryable = safe_code in {
            "extraction_failed",
            "source_unavailable",
            "extraction_unavailable",
        }
        if retryable and job["attempt_count"] < job["max_attempts"]:
            self._retry_or_fail(job, safe_code)
            return
        with self.engine.begin() as connection:
            self._scope(connection, update["user_id"])
            if not self._lease_still_held(connection, job):
                return
            connection.execute(
                text(
                    "SELECT memora_ingestion_mark_update("
                    ":update_id, :user_id, 'failed', :failure_code)"
                ),
                {
                    "failure_code": safe_code,
                    "update_id": update["id"],
                    "user_id": update["user_id"],
                },
            )
            if retryable:
                connection.execute(
                    text("""
                        UPDATE background_jobs
                        SET status = 'dead_lettered', last_error_code = :code,
                            lease_owner = NULL, lease_expires_at = NULL,
                            updated_at = now(), row_version = row_version + 1
                        WHERE id = :id AND status = 'leased' AND lease_owner = :owner
                        """),
                    {"code": safe_code, "id": job["id"], "owner": self.worker_id},
                )
            else:
                self._finish_job(connection, job, "failed", safe_code)

    def _handle_delete(self, job: dict[str, Any]) -> None:
        with self.engine.begin() as connection:
            self._scope(connection, job["owner_user_id"])
            upload = (
                connection.execute(
                    text("""
                        SELECT id, user_id, object_key, status
                        FROM source_uploads WHERE id = :upload_id
                        """),
                    {"upload_id": job["resource_id"]},
                )
                .mappings()
                .first()
            )
            if upload is None:
                self._finish_job(connection, job, "succeeded", None)
                return
            upload = dict(upload)
            if upload["status"] == "deleted":
                self._finish_job(connection, job, "succeeded", None)
                return
        try:
            self.storage.delete_object(upload["object_key"])
            observed = self.storage.head_object(upload["object_key"])
        except StorageUnavailable:
            self._retry_or_fail(job, "deletion_failed")
            return
        if observed is not None:
            self._retry_or_fail(job, "deletion_failed")
            return
        fingerprint = hashlib.sha256(upload["object_key"].encode()).hexdigest()
        with self.engine.begin() as connection:
            self._scope(connection, upload["user_id"])
            if not self._lease_still_held(connection, job):
                return
            connection.execute(
                text("""
                    INSERT INTO deletion_proofs(
                        source_upload_id, scope, provider, target_fingerprint,
                        result, verified_at, reconciler_version
                    ) VALUES (
                        :upload_id, 'source_upload', :provider, :fingerprint,
                        'deleted', now(), :deleter_version
                    )
                    ON CONFLICT (source_upload_id, scope, provider)
                    WHERE source_upload_id IS NOT NULL DO NOTHING
                    """),
                {
                    "upload_id": upload["id"],
                    "provider": self.storage.provider_name,
                    "fingerprint": fingerprint,
                    "deleter_version": DELETER_VERSION,
                },
            )
            connection.execute(
                text("""
                    UPDATE source_uploads
                    SET status = 'deleted', deleted_at = COALESCE(deleted_at, now()),
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :upload_id
                    """),
                {"upload_id": upload["id"]},
            )
            self._finish_job(connection, job, "succeeded", None)

    def reconcile(self) -> int:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_worker"))
            row = connection.execute(text("SELECT memora_expire_ingestion(now())")).scalar()
        return int(row or 0)

    def _handle_reconcile(self, job: dict[str, Any]) -> None:
        self.reconcile()
        with self.engine.begin() as connection:
            self._scope(connection, job["owner_user_id"])
            if self._lease_still_held(connection, job):
                self._finish_job(connection, job, "succeeded", None)

    def _retry_or_fail(self, job: dict[str, Any], failure_code: str) -> None:
        safe_code = failure_code if failure_code in FAILURE_CODES else "extraction_failed"
        attempt = int(job["attempt_count"])
        if attempt < int(job["max_attempts"]):
            delay = JOB_BACKOFF_SECONDS[min(attempt - 1, len(JOB_BACKOFF_SECONDS) - 1)]
            with self.engine.begin() as connection:
                self._scope(connection, job["owner_user_id"])
                connection.execute(
                    text("""
                        UPDATE background_jobs
                        SET status = 'retry_wait', last_error_code = :code,
                            available_at = now() + (:delay * interval '1 second'),
                            lease_owner = NULL, lease_expires_at = NULL,
                            updated_at = now(), row_version = row_version + 1
                        WHERE id = :id AND status = 'leased' AND lease_owner = :owner
                        """),
                    {"code": safe_code, "delay": delay, "id": job["id"], "owner": self.worker_id},
                )
            return
        with self.engine.begin() as connection:
            self._scope(connection, job["owner_user_id"])
            connection.execute(
                text("""
                    UPDATE background_jobs
                    SET status = 'dead_lettered', last_error_code = :code,
                        lease_owner = NULL, lease_expires_at = NULL,
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :id AND status = 'leased' AND lease_owner = :owner
                    """),
                {"code": safe_code, "id": job["id"], "owner": self.worker_id},
            )

    def _finish_job(
        self,
        connection: Connection,
        job: dict[str, Any],
        status_value: str,
        failure_code: str | None,
    ) -> None:
        connection.execute(
            text("""
                UPDATE background_jobs
                SET status = :status, last_error_code = :code,
                    lease_owner = NULL, lease_expires_at = NULL,
                    updated_at = now(), row_version = row_version + 1
                WHERE id = :id AND status = 'leased' AND lease_owner = :owner
                """),
            {
                "status": status_value,
                "code": failure_code,
                "id": job["id"],
                "owner": self.worker_id,
            },
        )


def build_worker(settings: Settings) -> IngestionWorker:
    from memora.db.runtime import database_engine

    if settings.database_url is None:
        raise RuntimeError("MEMORA_DATABASE_URL is required for the ingestion worker")
    protector = None
    if settings.ingestion_encryption_key is not None:
        key = base64.b64decode(settings.ingestion_encryption_key.get_secret_value(), validate=True)
        protector = ManualTextProtector(key)
    return IngestionWorker(
        database_engine(settings.database_url),
        settings,
        protector=protector,
        worker_id=f"ingestion-{uuid4()}",
    )


__all__ = ["IngestionWorker", "build_worker"]
