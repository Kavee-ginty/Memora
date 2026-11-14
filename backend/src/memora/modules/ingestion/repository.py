"""Owner-scoped persistence for learning updates, uploads and candidates."""

from __future__ import annotations

import base64
import binascii
import hashlib
import json
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.api.security import AuthContext
from memora.modules.ingestion.constants import (
    CandidateStatus,
    DeletionStatus,
    LearningUpdateStatus,
    UploadStatus,
)

IDEMPOTENCY_TTL_HOURS = 24


class IngestionRepository:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    @contextmanager
    def _connection(self, auth: AuthContext) -> Iterator[tuple[Connection, UUID]]:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_api"))
            user_id = connection.scalar(
                text("SELECT memora_resolve_user_id(:issuer, :subject)"),
                {"issuer": auth.issuer, "subject": auth.subject},
            )
            if user_id is None:
                raise ApiError(403, "operation_not_allowed", "Account setup is required.")
            user_id = UUID(str(user_id))
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(user_id)},
            )
            yield (connection, user_id)

    def get_update(self, auth: AuthContext, update_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            return self._load_update(connection, user_id, update_id)

    def get_upload(self, auth: AuthContext, update_id: UUID, upload_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            row = (
                connection.execute(
                    text("""
                        SELECT id, learning_update_id, object_key, declared_name,
                               declared_media_type, byte_size, content_sha256,
                               status, expires_at
                        FROM source_uploads
                        WHERE id = :upload_id AND learning_update_id = :update_id
                          AND user_id = :user_id
                        """),
                    {"upload_id": upload_id, "update_id": update_id, "user_id": user_id},
                )
                .mappings()
                .first()
            )
            if row is None:
                raise ApiError(404, "resource_not_found", "This upload was not found.")
            return dict(row)

    def has_ingestion_consent(self, auth: AuthContext) -> bool:
        with self._connection(auth) as (connection, user_id):
            rows = connection.execute(
                text("""
                    SELECT DISTINCT ON (consent_type) consent_type, decision
                    FROM consent_records
                    WHERE user_id = :user_id
                    ORDER BY consent_type, decided_at DESC, created_at DESC
                    """),
                {"user_id": user_id},
            ).mappings()
            decisions = {row["consent_type"]: row["decision"] for row in rows}
        return all(
            decisions.get(name) == "granted"
            for name in ("terms", "privacy", "material_processing", "model_processing")
        )

    def list_updates(
        self, auth: AuthContext, *, cursor: str | None, limit: int
    ) -> tuple[list[dict[str, Any]], str | None, bool]:
        with self._connection(auth) as (connection, user_id):
            parameters = {"user_id": user_id, "limit": limit + 1}
            cursor_clause = ""
            if cursor is not None:
                cursor_time, cursor_id = _decode_cursor(cursor)
                cursor_clause = "AND (updated_at, id) < (:cursor_time, :cursor_id)"
                parameters.update({"cursor_time": cursor_time, "cursor_id": cursor_id})
            rows = (
                connection.execute(
                    text(
                        f"""
                        SELECT id FROM learning_updates
                        WHERE user_id = :user_id {cursor_clause}
                        ORDER BY updated_at DESC, id DESC
                        LIMIT :limit
                        """
                    ),
                    parameters,
                )
                .scalars()
                .all()
            )
            has_more = len(rows) > limit
            selected = rows[:limit]
            updates = [self._load_update(connection, user_id, update_id) for update_id in selected]
            next_cursor = (
                _encode_cursor(updates[-1]["updated_at"], updates[-1]["id"])
                if has_more and updates
                else None
            )
        return updates, next_cursor, has_more

    def list_candidates(
        self, auth: AuthContext, update_id: UUID, *, cursor: str | None, limit: int
    ) -> tuple[list[dict[str, Any]], str | None, bool]:
        with self._connection(auth) as (connection, user_id):
            self._load_update(connection, user_id, update_id)
            parameters = {"update_id": update_id, "user_id": user_id, "limit": limit + 1}
            cursor_clause = ""
            if cursor is not None:
                cursor_time, cursor_id = _decode_cursor(cursor)
                cursor_clause = "AND (created_at, id) > (:cursor_time, :cursor_id)"
                parameters.update({"cursor_time": cursor_time, "cursor_id": cursor_id})
            rows = (
                connection.execute(
                    text(
                        f"""
                        SELECT c.id, c.candidate_type, c.candidate_payload,
                               c.source_locator, c.confidence, c.status,
                               c.row_version, c.created_at
                        FROM extraction_candidates c
                        WHERE c.learning_update_id = :update_id AND c.user_id = :user_id
                          AND c.status <> 'expired' {cursor_clause}
                        ORDER BY c.created_at, c.id
                        LIMIT :limit
                        """
                    ),
                    parameters,
                )
                .mappings()
                .all()
            )
            has_more = len(rows) > limit
            items = [dict(row) for row in rows[:limit]]
            next_cursor = (
                _encode_cursor(items[-1]["created_at"], items[-1]["id"])
                if has_more and items
                else None
            )
        return items, next_cursor, has_more

    def preview(self, auth: AuthContext, update_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            update = self._load_update(connection, user_id, update_id)
            candidates = (
                connection.execute(
                    text("""
                        SELECT id, candidate_type, candidate_payload, status
                        FROM extraction_candidates
                        WHERE learning_update_id = :update_id AND user_id = :user_id
                          AND status IN ('accepted','committed','needs_verification')
                        ORDER BY created_at, id
                        """),
                    {"update_id": update_id, "user_id": user_id},
                )
                .mappings()
                .all()
            )
            pending = connection.scalar(
                text("""
                    SELECT count(*) FROM verification_requests
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status = 'pending'
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
        return {
            "update": update,
            "candidates": [dict(row) for row in candidates],
            "pending": pending,
        }

    def create_update(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        request_hash: str,
        update_id: UUID,
        subject_id: UUID,
        input_type: str,
        learned_at: datetime,
        client_operation_id: UUID,
        manual_text_ciphertext: bytes | None,
        files: list[dict[str, Any]],
        expires_at: datetime,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "createLearningUpdate", idempotency_key, request_hash
            )
            if replay is not None:
                return self._load_update(connection, user_id, UUID(replay))
            existing = connection.scalar(
                text("""
                    SELECT id FROM learning_updates
                    WHERE user_id = :user_id AND client_operation_id = :client_operation_id
                    """),
                {"user_id": user_id, "client_operation_id": client_operation_id},
            )
            if existing is not None:
                raise ApiError(
                    409,
                    "idempotency_key_reused",
                    "Use a new idempotency key for a new learning update.",
                    "correct_input",
                )
            curriculum_version_id = connection.scalar(
                text("""
                    SELECT cv.id FROM curriculum_versions cv
                    WHERE cv.subject_id = :subject_id AND cv.status = 'approved'
                    ORDER BY cv.valid_from DESC NULLS LAST, cv.created_at DESC
                    LIMIT 1
                    """),
                {"subject_id": subject_id},
            )
            if curriculum_version_id is None:
                raise ApiError(
                    422, "validation_failed", "Choose an available subject.", "correct_input"
                )
            if files:
                status = LearningUpdateStatus.UPLOADING.value
            else:
                status = LearningUpdateStatus.PROCESSING.value
            connection.execute(
                text("""
                    INSERT INTO learning_updates(
                        id, user_id, subject_id, curriculum_version_id, input_type,
                        manual_text_ciphertext, status, learned_at, client_operation_id,
                        expires_at
                    ) VALUES (
                        :id, :user_id, :subject_id, :curriculum_version_id, :input_type,
                        :manual_text_ciphertext, :status, :learned_at, :client_operation_id,
                        :expires_at
                    )
                    """),
                {
                    "id": update_id,
                    "user_id": user_id,
                    "subject_id": subject_id,
                    "curriculum_version_id": curriculum_version_id,
                    "input_type": input_type,
                    "manual_text_ciphertext": manual_text_ciphertext,
                    "status": status,
                    "learned_at": learned_at,
                    "client_operation_id": client_operation_id,
                    "expires_at": expires_at,
                },
            )
            if not files:
                self._enqueue_job(
                    connection,
                    job_type="ingestion.extract",
                    owner_user_id=user_id,
                    resource_type="learning_update",
                    resource_id=update_id,
                    dedupe_key=f"extract:{update_id}",
                )
            self._complete_idempotency(
                connection, user_id, "createLearningUpdate", idempotency_key, str(update_id)
            )
            return self._load_update(connection, user_id, update_id)

    def update_draft(
        self,
        auth: AuthContext,
        update_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        version: int,
        learned_at: datetime | None,
        manual_text_ciphertext: bytes | None,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "updateLearningUpdate", idempotency_key, request_hash
            )
            if replay is not None:
                return self._load_update(connection, user_id, UUID(replay))
            updated = connection.scalar(
                text("""
                    UPDATE learning_updates
                    SET learned_at = COALESCE(:learned_at, learned_at),
                        manual_text_ciphertext = COALESCE(
                            :manual_text_ciphertext, manual_text_ciphertext
                        ),
                        updated_at = now(),
                        row_version = row_version + 1
                    WHERE id = :update_id AND user_id = :user_id
                      AND status = 'draft' AND row_version = :version
                    RETURNING id
                    """),
                {
                    "update_id": update_id,
                    "user_id": user_id,
                    "version": version,
                    "learned_at": learned_at,
                    "manual_text_ciphertext": manual_text_ciphertext,
                },
            )
            if updated is None:
                return self._raise_version_or_state(connection, user_id, update_id, version)
            self._complete_idempotency(
                connection, user_id, "updateLearningUpdate", idempotency_key, str(update_id)
            )
            return self._load_update(connection, user_id, update_id)

    def discard_update(
        self, auth: AuthContext, update_id: UUID, *, idempotency_key: str, request_hash: str
    ) -> tuple[dict[str, Any], bool]:
        """Return the update and whether a cleanup job was required."""

        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "deleteLearningUpdate", idempotency_key, request_hash
            )
            if replay is not None:
                return self._load_update(connection, user_id, UUID(replay)), False
            update = self._lock_update(connection, user_id, update_id)
            if update["status"] == "deleted":
                return self._load_update(connection, user_id, update_id), False
            if update["status"] == "committed":
                raise ApiError(
                    409, "invalid_state", "Committed learning cannot be discarded.", "refresh_state"
                )
            if update["status"] == "expired":
                return self._load_update(connection, user_id, update_id), False
            upload_ids = connection.execute(
                text("""
                    UPDATE source_uploads
                    SET status = 'deleting', updated_at = now(), row_version = row_version + 1
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status IN ('authorized','uploaded','validated','processing')
                    RETURNING id
                    """),
                {"update_id": update_id, "user_id": user_id},
            ).scalars()
            uploads = list(upload_ids)
            connection.execute(
                text("""
                    UPDATE learning_updates
                    SET status = 'deleted', updated_at = now(), row_version = row_version + 1
                    WHERE id = :update_id AND user_id = :user_id
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            connection.execute(
                text("""
                    UPDATE background_jobs
                    SET status = 'cancelled', updated_at = now(), row_version = row_version + 1
                    WHERE resource_type = 'learning_update' AND resource_id = :update_id
                      AND status IN ('queued','retry_wait','leased')
                    """),
                {"update_id": update_id},
            )
            for upload_id in uploads:
                self._enqueue_deletion_job(connection, owner_user_id=user_id, resource_id=upload_id)
            self._complete_idempotency(
                connection, user_id, "deleteLearningUpdate", idempotency_key, str(update_id)
            )
            return self._load_update(connection, user_id, update_id), bool(uploads)

    def create_upload(
        self,
        auth: AuthContext,
        update_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        declared_name: str,
        declared_media_type: str,
        byte_size: int,
        content_sha256: str,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "createUploadGrant", idempotency_key, request_hash
            )
            if replay is not None:
                row = (
                    connection.execute(
                        text("""
                            SELECT id, declared_name, declared_media_type,
                                   detected_media_type, byte_size, status, expires_at,
                                   deleted_at, object_key
                            FROM source_uploads
                            WHERE id = :upload_id AND learning_update_id = :update_id
                              AND user_id = :user_id
                            """),
                        {"upload_id": UUID(replay), "update_id": update_id, "user_id": user_id},
                    )
                    .mappings()
                    .first()
                )
                if row is None:
                    raise ApiError(404, "resource_not_found", "This upload was not found.")
                result = dict(row)
                result["_object_key"] = result.pop("object_key")
                return result
            update = self._lock_update(connection, user_id, update_id)
            if update["status"] not in {"draft", "uploading"}:
                raise ApiError(
                    409,
                    "invalid_state",
                    "Uploads can only be added to a draft update.",
                    "refresh_state",
                )
            count = connection.scalar(
                text("""
                    SELECT count(*) FROM source_uploads
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status <> 'deleted'
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            if count >= 5:
                raise ApiError(
                    422,
                    "validation_failed",
                    "This update already has the maximum number of files.",
                    "correct_input",
                )
            upload = self._insert_upload(
                connection,
                update_id,
                user_id,
                {
                    "declared_name": declared_name,
                    "declared_media_type": declared_media_type,
                    "byte_size": byte_size,
                    "content_sha256": content_sha256,
                },
                update["expires_at"],
            )
            connection.execute(
                text("""
                    UPDATE learning_updates
                    SET status = 'uploading', updated_at = now(), row_version = row_version + 1
                    WHERE id = :update_id AND user_id = :user_id AND status = 'draft'
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            self._complete_idempotency(
                connection, user_id, "createUploadGrant", idempotency_key, str(upload["id"])
            )
            return upload

    def finalize_upload(
        self,
        auth: AuthContext,
        update_id: UUID,
        upload_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        evidence: dict[str, Any],
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "finalizeUpload", idempotency_key, request_hash
            )
            if replay is not None:
                return self._load_update(connection, user_id, UUID(replay))
            self._lock_update(connection, user_id, update_id)
            upload = (
                connection.execute(
                    text("""
                    SELECT id, status, expires_at FROM source_uploads
                    WHERE id = :upload_id AND learning_update_id = :update_id
                      AND user_id = :user_id
                    FOR UPDATE
                    """),
                    {"upload_id": upload_id, "update_id": update_id, "user_id": user_id},
                )
                .mappings()
                .first()
            )
            if upload is None:
                raise ApiError(404, "resource_not_found", "This upload was not found.")
            if upload["expires_at"] <= datetime.now(UTC):
                connection.execute(
                    text("UPDATE source_uploads SET status='expired' WHERE id=:upload_id"),
                    {"upload_id": upload_id},
                )
                raise ApiError(
                    409,
                    "invalid_state",
                    "This upload grant has expired. Request a new upload.",
                    "refresh_state",
                )
            if upload["status"] == "deleted":
                raise ApiError(409, "invalid_state", "This upload was already deleted.")
            if upload["status"] in {"uploaded", "validated", "processing"}:
                self._complete_idempotency(
                    connection, user_id, "finalizeUpload", idempotency_key, str(update_id)
                )
                return self._load_update(connection, user_id, update_id)
            connection.execute(
                text("""
                    UPDATE source_uploads
                    SET status = 'processing', detected_media_type = :detected_media_type,
                        content_sha256 = :content_sha256, byte_size = :byte_size,
                        validation_result = CAST(:validation AS jsonb),
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :upload_id
                    """),
                {
                    "upload_id": upload_id,
                    "detected_media_type": evidence["detected_media_type"],
                    "content_sha256": evidence["content_sha256"],
                    "byte_size": evidence["byte_size"],
                    "validation": json.dumps(
                        {
                            "schema_version": "1",
                            "checksum_verified": True,
                            "magic_bytes_verified": True,
                        }
                    ),
                },
            )
            connection.execute(
                text("""
                    UPDATE learning_updates
                    SET status = 'processing', updated_at = now(),
                        row_version = row_version + 1
                    WHERE id = :update_id AND user_id = :user_id
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            self._enqueue_job(
                connection,
                job_type="ingestion.extract",
                owner_user_id=user_id,
                resource_type="learning_update",
                resource_id=update_id,
                dedupe_key=f"extract:{update_id}",
            )
            self._complete_idempotency(
                connection, user_id, "finalizeUpload", idempotency_key, str(update_id)
            )
            return self._load_update(connection, user_id, update_id)

    def retry_update(
        self,
        auth: AuthContext,
        update_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        stage: str,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "retryLearningUpdate", idempotency_key, request_hash
            )
            if replay is not None:
                return self._load_update(connection, user_id, UUID(replay))
            update = self._lock_update(connection, user_id, update_id)
            if stage == "deletion":
                # Source deletion status is separate from the retained update's
                # state, so recovery must also work for a committed update whose
                # deletion job died in a provider outage.
                uploads = list(
                    connection.execute(
                        text("""
                            SELECT id FROM source_uploads
                            WHERE learning_update_id = :update_id AND user_id = :user_id
                              AND status IN ('deleting','expired','rejected')
                              AND deleted_at IS NULL
                            """),
                        {"update_id": update_id, "user_id": user_id},
                    ).scalars()
                )
                if not uploads:
                    raise ApiError(
                        409,
                        "invalid_state",
                        "No source deletion is waiting to be retried.",
                        "refresh_state",
                    )
                for upload_id in uploads:
                    self._enqueue_deletion_job(
                        connection, owner_user_id=user_id, resource_id=upload_id
                    )
            else:
                if update["status"] != "failed":
                    raise ApiError(
                        409,
                        "invalid_state",
                        "Only a failed update can be retried.",
                        "refresh_state",
                    )
                connection.execute(
                    text("""
                        UPDATE learning_updates
                        SET status = 'processing', failure_code = NULL,
                            updated_at = now(), row_version = row_version + 1
                        WHERE id = :update_id AND user_id = :user_id
                        """),
                    {"update_id": update_id, "user_id": user_id},
                )
                self._enqueue_job(
                    connection,
                    job_type="ingestion.extract",
                    owner_user_id=user_id,
                    resource_type="learning_update",
                    resource_id=update_id,
                    dedupe_key=f"extract:{update_id}:retry:{update['row_version']}",
                )
            self._complete_idempotency(
                connection, user_id, "retryLearningUpdate", idempotency_key, str(update_id)
            )
            return self._load_update(connection, user_id, update_id)

    def submit_decisions(
        self,
        auth: AuthContext,
        update_id: UUID,
        *,
        idempotency_key: str,
        request_hash: str,
        decisions: list[dict[str, Any]],
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "submitVerificationDecisions", idempotency_key, request_hash
            )
            if replay is not None:
                return self._load_update(connection, user_id, UUID(replay))
            update = self._lock_update(connection, user_id, update_id)
            if update["status"] in {"deleted", "expired", "committed"}:
                raise ApiError(
                    409, "invalid_state", "This update can no longer be verified.", "refresh_state"
                )
            candidate_ids = [decision["candidate_id"] for decision in decisions]
            rows = (
                connection.execute(
                    text("""
                        SELECT id, status, row_version FROM extraction_candidates
                        WHERE learning_update_id = :update_id AND user_id = :user_id
                          AND id = ANY(:candidate_ids)
                        FOR UPDATE
                        """),
                    {"update_id": update_id, "user_id": user_id, "candidate_ids": candidate_ids},
                )
                .mappings()
                .all()
            )
            by_id = {row["id"]: row for row in rows}
            if len(by_id) != len(candidate_ids):
                raise ApiError(404, "resource_not_found", "A candidate was not found.")
            for decision in decisions:
                row = by_id[decision["candidate_id"]]
                if row["row_version"] != decision["candidate_version"]:
                    raise ApiError(
                        409,
                        "version_conflict",
                        "Refresh the candidates and try again.",
                        "refresh_state",
                    )
                if row["status"] in {"expired", "rejected", "committed"}:
                    raise ApiError(
                        409,
                        "invalid_state",
                        "A candidate is no longer open for verification.",
                        "refresh_state",
                    )
                self._apply_decision(connection, user_id, update_id, decision)
            new_status = "verification_required"
            connection.execute(
                text("""
                    UPDATE learning_updates
                    SET status = :status, updated_at = now(), row_version = row_version + 1
                    WHERE id = :update_id AND user_id = :user_id
                    """),
                {"status": new_status, "update_id": update_id, "user_id": user_id},
            )
            self._complete_idempotency(
                connection, user_id, "submitVerificationDecisions", idempotency_key, str(update_id)
            )
            return self._load_update(connection, user_id, update_id)

    def commit(
        self, auth: AuthContext, update_id: UUID, *, idempotency_key: str, request_hash: str
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "commitLearningUpdate", idempotency_key, request_hash
            )
            if replay is not None:
                return self._load_commit(connection, user_id, update_id)
            update = self._lock_update(connection, user_id, update_id)
            if update["status"] == "committed":
                self._complete_idempotency(
                    connection, user_id, "commitLearningUpdate", idempotency_key, str(update_id)
                )
                return self._load_commit(connection, user_id, update_id)
            if update["status"] != "verification_required":
                raise ApiError(
                    409, "invalid_state", "This update is not ready to commit.", "refresh_state"
                )
            pending = connection.scalar(
                text("""
                    SELECT count(*) FROM verification_requests
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status = 'pending'
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            if pending:
                raise ApiError(
                    409,
                    "invalid_state",
                    "Verify the remaining concepts before committing.",
                    "refresh_state",
                )
            candidates = (
                connection.execute(
                    text("""
                        SELECT id, candidate_type, candidate_payload, confidence,
                               source_locator, status
                        FROM extraction_candidates
                        WHERE learning_update_id = :update_id AND user_id = :user_id
                          AND status IN ('accepted','committed')
                        ORDER BY created_at, id
                        FOR UPDATE
                        """),
                    {"update_id": update_id, "user_id": user_id},
                )
                .mappings()
                .all()
            )
            if not candidates:
                raise ApiError(
                    409, "invalid_state", "No accepted concepts remain to commit.", "refresh_state"
                )
            rejected = connection.scalar(
                text("""
                    SELECT count(*) FROM extraction_candidates
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status IN ('needs_verification','candidate')
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            if rejected:
                raise ApiError(
                    409,
                    "invalid_state",
                    "Every candidate must be accepted or rejected before commit.",
                    "refresh_state",
                )
            snapshot = [
                {
                    "id": str(candidate["id"]),
                    "type": candidate["candidate_type"],
                    "payload": candidate["candidate_payload"],
                }
                for candidate in candidates
            ]
            snapshot_hash = hashlib.sha256(
                json.dumps(snapshot, sort_keys=True, separators=(",", ":"), default=str).encode()
            ).hexdigest()
            commit_version = connection.scalar(
                text("""
                    SELECT COALESCE(max(commit_version), 0) + 1 FROM knowledge_commits
                    WHERE learning_update_id = :update_id
                    """),
                {"update_id": update_id},
            )
            committed_concepts = [
                {
                    "concept_id": str(candidate["candidate_payload"]["concept_id"]),
                    "concept_version_id": str(candidate["candidate_payload"]["concept_version_id"]),
                    "confidence": float(candidate["confidence"]),
                }
                for candidate in candidates
                if candidate["candidate_type"] == "concept"
                and candidate["candidate_payload"].get("concept_id")
                and candidate["candidate_payload"].get("concept_version_id")
            ]
            event_id = uuid4()
            connection.execute(
                text("""
                    INSERT INTO outbox_events(
                        id, domain_event_key, aggregate_type, aggregate_id, event_type,
                        event_version, payload, correlation_id, publication_status
                    ) VALUES (
                        :id, :event_key, 'learning_update', :update_id,
                        'learning_update.committed', 1, CAST(:payload AS jsonb),
                        :correlation_id, 'pending'
                    )
                    """),
                {
                    "id": event_id,
                    "event_key": f"learning_update.committed:{update_id}:{commit_version}",
                    "update_id": update_id,
                    "payload": json.dumps(
                        {
                            "schema_version": "1",
                            "user_id": str(user_id),
                            "learning_update_id": str(update_id),
                            "committed_concepts": committed_concepts,
                        }
                    ),
                    "correlation_id": uuid4(),
                },
            )
            # T19 trigger: learning-path-ready push signal, written in the
            # same transaction as the commit itself. Identifiers and the safe
            # committed-concept count only — never learning text.
            connection.execute(
                text("""
                    INSERT INTO outbox_events(
                        domain_event_key, aggregate_type, aggregate_id, event_type,
                        event_version, payload, correlation_id, publication_status
                    ) VALUES (
                        :event_key, 'learning_update', :update_id,
                        'ingestion.learning_path_committed', 1,
                        CAST(:payload AS jsonb), :correlation_id, 'pending'
                    )
                    """),
                {
                    "event_key": f"ingestion.learning_path_committed:{update_id}:{commit_version}",
                    "update_id": update_id,
                    "payload": json.dumps(
                        {
                            "schema_version": "1",
                            "user_id": str(user_id),
                            "update_id": str(update_id),
                            "count": len(committed_concepts),
                        }
                    ),
                    "correlation_id": uuid4(),
                },
            )
            committed_counts = {"concept": 0, "claim": 0, "edge": 0, "private": 0}
            concept_mappings = []
            for candidate in candidates:
                payload = candidate["candidate_payload"]
                concept_version_id = payload.get("concept_version_id")
                concept_id = payload.get("concept_id")
                if candidate["candidate_type"] == "concept" and concept_version_id:
                    committed_counts["concept"] += 1
                    concept_mappings.append(
                        {
                            "candidate_id": candidate["id"],
                            "title": payload.get("title", "Concept"),
                            "candidate_type": candidate["candidate_type"],
                            "concept_id": concept_id,
                            "concept_version_id": concept_version_id,
                        }
                    )
                    continue
                private_id = uuid4()
                connection.execute(
                    text("""
                            INSERT INTO private_knowledge_items(
                                id, user_id, learning_update_id, item_type,
                                structured_content, schema_version, confidence,
                                provenance, status, concept_version_id
                            ) VALUES (
                                :id, :user_id, :update_id, :item_type,
                                CAST(:content AS jsonb), '1', :confidence,
                                CAST(:provenance AS jsonb), 'active', :concept_version_id
                            )
                            """),
                    {
                        "id": private_id,
                        "user_id": user_id,
                        "update_id": update_id,
                        "item_type": candidate["candidate_type"],
                        "content": json.dumps(payload, default=str),
                        "confidence": float(candidate["confidence"]),
                        "provenance": json.dumps(
                            {
                                "schema_version": "1",
                                "source": "extraction_candidate",
                                "candidate_id": str(candidate["id"]),
                                "locator": candidate["source_locator"],
                            },
                            default=str,
                        ),
                        "concept_version_id": concept_version_id,
                    },
                )
                committed_counts["private"] += 1
                if candidate["candidate_type"] == "claim":
                    committed_counts["claim"] += 1
                if candidate["candidate_type"] != "edge":
                    continue
                committed_counts["edge"] += 1
                continue
            connection.execute(
                text("""
                    UPDATE extraction_candidates
                    SET status = 'committed', updated_at = now(),
                        row_version = row_version + 1
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status = 'accepted'
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            commit_id = uuid4()
            connection.execute(
                text("""
                    INSERT INTO knowledge_commits(
                        id, learning_update_id, user_id, commit_version,
                        candidate_snapshot_hash, committed_counts, transaction_id,
                        committed_at, outbox_event_id
                    ) VALUES (
                        :id, :update_id, :user_id, :commit_version,
                        :snapshot_hash, CAST(:counts AS jsonb), :transaction_id,
                        now(), :outbox_event_id
                    )
                    """),
                {
                    "id": commit_id,
                    "update_id": update_id,
                    "user_id": user_id,
                    "commit_version": commit_version,
                    "snapshot_hash": snapshot_hash,
                    "counts": json.dumps(committed_counts),
                    "transaction_id": str(uuid4()),
                    "outbox_event_id": event_id,
                },
            )
            connection.execute(
                text("""
                    UPDATE learning_updates
                    SET status = 'committed', failure_code = NULL,
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :update_id AND user_id = :user_id
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            deleting_uploads = connection.execute(
                text("""
                    UPDATE source_uploads
                    SET status = 'deleting', updated_at = now(),
                        row_version = row_version + 1
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                      AND status IN ('authorized','uploaded','validated','processing')
                    RETURNING id
                    """),
                {"update_id": update_id, "user_id": user_id},
            ).scalars()
            for upload_id in deleting_uploads:
                self._enqueue_deletion_job(connection, owner_user_id=user_id, resource_id=upload_id)
            self._complete_idempotency(
                connection, user_id, "commitLearningUpdate", idempotency_key, str(update_id)
            )
            result = self._load_commit(connection, user_id, update_id)
            result["concept_mappings"] = concept_mappings
        return result

    def _apply_decision(
        self,
        connection: Connection,
        user_id: UUID,
        update_id: UUID,
        decision: dict[str, Any],
    ) -> None:
        request_id = connection.scalar(
            text("""
                SELECT id FROM verification_requests
                WHERE candidate_id = :candidate_id AND user_id = :user_id
                  AND status = 'pending'
                FOR UPDATE
                """),
            {"candidate_id": decision["candidate_id"], "user_id": user_id},
        )
        if request_id is None:
            raise ApiError(
                409, "invalid_state", "This candidate does not need verification.", "refresh_state"
            )
        api_decision = decision["decision"]
        if api_decision in {"merge", "accept"}:
            stored_decision = "correct" if api_decision == "merge" else "accept"
            corrected = (
                {
                    "schema_version": "1",
                    "merge_into_candidate_id": str(
                        decision["corrected_payload"].get("merge_into_candidate_id")
                    )
                    if decision.get("corrected_payload", {}).get("merge_into_candidate_id")
                    else None,
                }
                if api_decision == "merge"
                else None
            )
        elif api_decision == "edit":
            stored_decision = "correct"
            corrected = {"schema_version": "1", "payload": decision["corrected_payload"]}
        else:
            stored_decision = "reject"
            corrected = None
        connection.execute(
            text("""
                INSERT INTO verification_decisions(
                    verification_request_id, user_id, decision,
                    corrected_payload, decided_at
                ) VALUES (
                    :request_id, :user_id, :decision, CAST(:corrected AS jsonb), now()
                )
                """),
            {
                "request_id": request_id,
                "user_id": user_id,
                "decision": stored_decision,
                "corrected": json.dumps(corrected) if corrected is not None else None,
            },
        )
        connection.execute(
            text(
                "UPDATE verification_requests "
                "SET status='answered', updated_at=now() WHERE id = :request_id"
            ),
            {"request_id": request_id},
        )
        candidate_status = CandidateStatus.REJECTED.value
        if stored_decision == "accept":
            candidate_status = CandidateStatus.ACCEPTED.value
        elif stored_decision == "correct":
            candidate_status = CandidateStatus.ACCEPTED.value
            if corrected and corrected.get("payload"):
                connection.execute(
                    text("""
                        UPDATE extraction_candidates
                        SET candidate_payload = CAST(:payload AS jsonb),
                            updated_at = now(), row_version = row_version + 1
                        WHERE id = :candidate_id AND user_id = :user_id
                        """),
                    {
                        "payload": json.dumps(corrected["payload"], default=str),
                        "candidate_id": decision["candidate_id"],
                        "user_id": user_id,
                    },
                )
        connection.execute(
            text("""
                UPDATE extraction_candidates
                SET status = :status, updated_at = now(), row_version = row_version + 1
                WHERE id = :candidate_id AND user_id = :user_id
                """),
            {
                "status": candidate_status,
                "candidate_id": decision["candidate_id"],
                "user_id": user_id,
            },
        )

    def _insert_upload(
        self,
        connection: Connection,
        update_id: UUID,
        user_id: UUID,
        file: dict[str, Any],
        expires_at: datetime | None,
    ) -> dict[str, Any]:
        upload_id = uuid4()
        object_key = f"{user_id}/{update_id}/{upload_id}"
        row = (
            connection.execute(
                text("""
                    INSERT INTO source_uploads(
                        id, learning_update_id, user_id, object_key,
                        declared_name, declared_media_type, byte_size,
                        content_sha256, status, expires_at
                    ) VALUES (
                        :id, :update_id, :user_id, :object_key,
                        :declared_name, :declared_media_type, :byte_size,
                        :content_sha256, 'authorized',
                        COALESCE(:expires_at, now() + interval '72 hours')
                    )
                    RETURNING id, declared_name, declared_media_type, detected_media_type,
                              byte_size, status, expires_at, deleted_at, object_key
                    """),
                {
                    "id": upload_id,
                    "update_id": update_id,
                    "user_id": user_id,
                    "object_key": object_key,
                    "declared_name": file["declared_name"],
                    "declared_media_type": file["declared_media_type"],
                    "byte_size": file["byte_size"],
                    "content_sha256": file["content_sha256"],
                    "expires_at": expires_at,
                },
            )
            .mappings()
            .one()
        )
        result = dict(row)
        result["_object_key"] = result.pop("object_key")
        return result

    def reject_upload(
        self, auth: AuthContext, update_id: UUID, upload_id: UUID, *, failure_code: str
    ) -> None:
        with self._connection(auth) as (connection, user_id):
            connection.execute(
                text("""
                    UPDATE source_uploads
                    SET status = 'rejected', validation_result = CAST(:evidence AS jsonb),
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :upload_id AND learning_update_id = :update_id
                      AND user_id = :user_id
                    """),
                {
                    "upload_id": upload_id,
                    "update_id": update_id,
                    "user_id": user_id,
                    "evidence": json.dumps({"schema_version": "1", "failure_code": failure_code}),
                },
            )
            connection.execute(
                text("""
                    UPDATE learning_updates
                    SET status = 'failed', failure_code = :failure_code,
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :update_id AND user_id = :user_id
                    """),
                {"failure_code": failure_code, "update_id": update_id, "user_id": user_id},
            )
            self._enqueue_deletion_job(connection, owner_user_id=user_id, resource_id=upload_id)

    def _load_update(
        self, connection: Connection, user_id: UUID, update_id: UUID
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text("""
                    SELECT id, subject_id, curriculum_version_id, input_type, status,
                           learned_at, failure_code, expires_at,
                           manual_text_ciphertext IS NOT NULL AS has_manual_text,
                           created_at, updated_at, row_version
                    FROM learning_updates
                    WHERE id = :update_id AND user_id = :user_id
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(404, "resource_not_found", "This learning update was not found.")
        result = dict(row)
        uploads = (
            connection.execute(
                text("""
                    SELECT id, declared_name, declared_media_type, detected_media_type,
                           byte_size, status, expires_at, deleted_at
                    FROM source_uploads
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                    ORDER BY created_at, id
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            .mappings()
            .all()
        )
        result["uploads"] = [dict(upload) for upload in uploads]
        result["source_deletion_status"] = _deletion_status(result["uploads"])
        return result

    def _load_commit(
        self, connection: Connection, user_id: UUID, update_id: UUID
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text("""
                    SELECT id, commit_version, committed_counts
                    FROM knowledge_commits
                    WHERE learning_update_id = :update_id AND user_id = :user_id
                    ORDER BY commit_version DESC LIMIT 1
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(409, "invalid_state", "This update has not been committed.")
        update = self._load_update(connection, user_id, update_id)
        private_count = connection.scalar(
            text("""
                SELECT count(*) FROM private_knowledge_items
                WHERE learning_update_id = :update_id AND user_id = :user_id
                """),
            {"update_id": update_id, "user_id": user_id},
        )
        return {
            "update": update,
            "knowledge_commit_id": row["id"],
            "commit_version": row["commit_version"],
            "committed_counts": row["committed_counts"],
            "private_knowledge_count": private_count,
            "concept_mappings": [],
        }

    def _lock_update(
        self, connection: Connection, user_id: UUID, update_id: UUID
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text("""
                    SELECT id, status, expires_at, row_version
                    FROM learning_updates
                    WHERE id = :update_id AND user_id = :user_id
                    FOR UPDATE
                    """),
                {"update_id": update_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(404, "resource_not_found", "This learning update was not found.")
        return dict(row)

    def _raise_version_or_state(
        self, connection: Connection, user_id: UUID, update_id: UUID, version: int
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    "SELECT status, row_version FROM learning_updates "
                    "WHERE id = :update_id AND user_id = :user_id"
                ),
                {"update_id": update_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            raise ApiError(404, "resource_not_found", "This learning update was not found.")
        if row["status"] != "draft":
            raise ApiError(
                409, "invalid_state", "Only a draft update can be edited.", "refresh_state"
            )
        raise ApiError(
            409, "version_conflict", "Refresh this update and try again.", "refresh_state"
        )

    def _enqueue_deletion_job(
        self, connection: Connection, *, owner_user_id: UUID, resource_id: UUID
    ) -> None:
        """Queue a raw-object deletion, reviving a dead deletion job.

        A provider outage can dead-letter the original job while the raw file is
        still stored. Reusing the dedupe key must requeue that job with fresh
        attempts instead of being swallowed by the conflict guard; active and
        already-succeeded jobs are left untouched.
        """
        connection.execute(
            text("""
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, max_attempts, available_at, payload
                ) VALUES (
                    :job_type, :owner_user_id, 'source_upload', :resource_id,
                    :dedupe_key, 'queued', 5, now(), CAST(:payload AS jsonb)
                )
                ON CONFLICT (dedupe_key) DO UPDATE
                SET status = 'queued', attempt_count = 0, available_at = now(),
                    lease_owner = NULL, lease_expires_at = NULL, last_error_code = NULL,
                    updated_at = now(), row_version = background_jobs.row_version + 1
                WHERE background_jobs.status IN ('dead_lettered', 'failed')
                """),
            {
                "job_type": "ingestion.delete_upload",
                "owner_user_id": owner_user_id,
                "resource_id": resource_id,
                "dedupe_key": f"delete_upload:{resource_id}",
                "payload": json.dumps({"schema_version": "1"}),
            },
        )

    def _enqueue_job(
        self,
        connection: Connection,
        *,
        job_type: str,
        owner_user_id: UUID,
        resource_type: str,
        resource_id: UUID,
        dedupe_key: str,
        payload: dict[str, Any] | None = None,
    ) -> None:
        connection.execute(
            text("""
                INSERT INTO background_jobs(
                    job_type, owner_user_id, resource_type, resource_id,
                    dedupe_key, status, max_attempts, available_at, payload
                ) VALUES (
                    :job_type, :owner_user_id, :resource_type, :resource_id,
                    :dedupe_key, 'queued', 5, now(), CAST(:payload AS jsonb)
                )
                ON CONFLICT (dedupe_key) DO NOTHING
                """),
            {
                "job_type": job_type,
                "owner_user_id": owner_user_id,
                "resource_type": resource_type,
                "resource_id": resource_id,
                "dedupe_key": dedupe_key,
                "payload": json.dumps(payload or {"schema_version": "1"}),
            },
        )

    @staticmethod
    def _claim_idempotency(
        connection: Connection, user_id: UUID, operation: str, key: str, request_hash: str
    ) -> str | None:
        inserted = connection.scalar(
            text("""
                INSERT INTO idempotency_records(
                    user_id, scope, operation, idempotency_key,
                    request_hash, status, expires_at
                ) VALUES (
                    :user_id, :scope, :operation, :key,
                    :request_hash, 'processing', now() + interval '24 hours'
                )
                ON CONFLICT (scope, operation, idempotency_key) DO NOTHING
                RETURNING id
                """),
            {
                "user_id": user_id,
                "scope": str(user_id),
                "operation": operation,
                "key": key,
                "request_hash": request_hash,
            },
        )
        if inserted is not None:
            return
        record = (
            connection.execute(
                text("""
                    SELECT request_hash, status, response_reference
                    FROM idempotency_records
                    WHERE scope = :scope AND operation = :operation
                      AND idempotency_key = :key
                    """),
                {"scope": str(user_id), "operation": operation, "key": key},
            )
            .mappings()
            .one()
        )
        if record["request_hash"] != request_hash:
            raise ApiError(
                409,
                "idempotency_key_reused",
                "Use a new idempotency key for this request.",
                "correct_input",
            )
        if record["status"] != "completed" or not record["response_reference"]:
            raise ApiError(
                409,
                "operation_in_progress",
                "This operation is still in progress.",
                "retry",
                retryable=True,
                retry_after_seconds=1,
            )
        return str(record["response_reference"])

    @staticmethod
    def _complete_idempotency(
        connection: Connection, user_id: UUID, operation: str, key: str, reference: str
    ) -> None:
        connection.execute(
            text("""
                UPDATE idempotency_records
                SET status = 'completed', response_reference = :reference,
                    updated_at = now(), row_version = row_version + 1
                WHERE user_id = :user_id AND operation = :operation
                  AND idempotency_key = :key AND status = 'processing'
                """),
            {"user_id": user_id, "operation": operation, "key": key, "reference": reference},
        )


def request_hash(value: dict[str, Any]) -> str:
    canonical = json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(canonical.encode()).hexdigest()


def _deletion_status(uploads: list[dict[str, Any]]) -> str:
    if not uploads:
        return DeletionStatus.NOT_REQUIRED.value
    statuses = {upload["status"] for upload in uploads}
    if statuses <= {UploadStatus.DELETED.value}:
        return DeletionStatus.DELETED.value
    if statuses & {"deleting", "expired", "rejected"}:
        return DeletionStatus.PENDING.value
    return DeletionStatus.NOT_REQUIRED.value


def _encode_cursor(created_at: datetime, identifier: UUID) -> str:
    value = json.dumps({"t": created_at.astimezone(UTC).isoformat(), "id": str(identifier)})
    return base64.urlsafe_b64encode(value.encode()).decode().rstrip("=")


def _decode_cursor(cursor: str) -> tuple[datetime, UUID]:
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        value = json.loads(base64.urlsafe_b64decode(padded).decode())
        parsed = datetime.fromisoformat(value["t"])
        if parsed.tzinfo is None:
            raise ValueError("cursor must be UTC")
        return parsed, UUID(value["id"])
    except (ValueError, KeyError, TypeError, binascii.Error, json.JSONDecodeError) as exc:
        raise ApiError(400, "invalid_cursor", "Refresh the list and try again.") from exc


def update_expiry(now: datetime, hours: int) -> datetime:
    return now + timedelta(hours=hours)
