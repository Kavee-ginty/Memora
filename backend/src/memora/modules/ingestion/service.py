"""Learning-ingestion application service."""

from __future__ import annotations

import base64
import binascii
import os
from datetime import UTC, datetime, timedelta
from typing import Annotated, Any
from uuid import UUID, uuid4

from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from fastapi import Depends

from memora.api.errors import ApiError
from memora.api.security import AuthenticatedRequest
from memora.api.v1.schemas.ingestion import (
    CandidateListResponse,
    CandidateResponse,
    CreateLearningUpdateRequest,
    FinalizeUploadRequest,
    KnowledgeCommitResponse,
    LearningPathPreviewConcept,
    LearningPathPreviewResponse,
    LearningUpdateListResponse,
    LearningUpdateResponse,
    SourceUploadSummary,
    SubmitVerificationDecisionsRequest,
    SubmitVerificationDecisionsResponse,
    UpdateLearningUpdateRequest,
    UploadGrantRequest,
    UploadGrantResponse,
    VerificationDecisionResult,
)
from memora.core.config import Settings, get_settings
from memora.db.runtime import database_engine
from memora.modules.ingestion.constants import (
    MAX_MANUAL_TEXT_CHARS,
    DeletionStatus,
    confidence_band,
    requires_verification,
)
from memora.modules.ingestion.repository import IngestionRepository, request_hash, update_expiry
from memora.modules.ingestion.storage import ObjectStorage, StorageUnavailable, build_object_storage
from memora.modules.ingestion.validation import (
    validate_byte_size,
    validate_declared_media_type,
    validate_upload_bytes,
)

MANUAL_TEXT_AAD_PREFIX = "learning_update:"


class ManualTextProtector:
    """AES-256-GCM protection for bounded manual learning text."""

    def __init__(self, key: bytes) -> None:
        if len(key) != 32:
            raise ValueError("Ingestion key must decode to exactly 32 bytes")
        self._cipher = AESGCM(key)

    def encrypt(self, text: str, *, update_id: UUID) -> bytes:
        nonce = os.urandom(12)
        aad = f"{MANUAL_TEXT_AAD_PREFIX}{update_id}".encode()
        return b"\x01" + nonce + self._cipher.encrypt(nonce, text.encode("utf-8"), aad)

    def decrypt(self, payload: bytes, *, update_id: UUID) -> str:
        if not payload or payload[0] != 1:
            raise ValueError("Unsupported protected text version")
        nonce, ciphertext = payload[1:13], payload[13:]
        aad = f"{MANUAL_TEXT_AAD_PREFIX}{update_id}".encode()
        return self._cipher.decrypt(nonce, ciphertext, aad).decode("utf-8")


class IngestionService:
    def __init__(
        self,
        repository: IngestionRepository,
        storage: ObjectStorage,
        settings: Settings,
        protector: ManualTextProtector | None,
    ) -> None:
        self.repository = repository
        self.storage = storage
        self.settings = settings
        self.protector = protector

    def create(
        self,
        auth: AuthenticatedRequest,
        body: CreateLearningUpdateRequest,
        *,
        idempotency_key: str,
    ) -> LearningUpdateResponse:
        if not self.repository.has_ingestion_consent(auth.context):
            raise ApiError(
                403,
                "consent_required",
                "Accept the material processing terms before adding learning material.",
                "correct_input",
            )
        now = datetime.now(UTC)
        if body.learned_at > now + timedelta(minutes=5):
            raise ApiError(
                422,
                "validation_failed",
                "The learning time cannot be in the future.",
                "correct_input",
            )
        if len(body.files) > self.settings.upload_max_files:
            raise ApiError(
                422, "validation_failed", "This update has too many files.", "correct_input"
            )
        for file in body.files:
            validate_declared_media_type(
                declared_name=file.declared_name, declared_media_type=file.declared_media_type
            )
            validate_byte_size(file.byte_size, self.settings.upload_max_bytes)
        update_id = uuid4()
        ciphertext = None
        if body.manual_text is not None:
            text = body.manual_text.strip()
            if not text:
                raise ApiError(
                    422,
                    "validation_failed",
                    "Add some text or remove the text source.",
                    "correct_input",
                )
            if len(text) > MAX_MANUAL_TEXT_CHARS:
                raise ApiError(413, "payload_too_large", "The text is too long.")
            ciphertext = self._protector().encrypt(text, update_id=update_id)
        files = [
            {
                "declared_name": file.declared_name,
                "declared_media_type": file.declared_media_type.split(";", 1)[0].strip().lower(),
                "byte_size": file.byte_size,
                "content_sha256": file.content_sha256,
            }
            for file in body.files
        ]
        record = self.repository.create_update(
            auth.context,
            idempotency_key=idempotency_key,
            request_hash=request_hash(
                {
                    "subject_id": body.subject_id,
                    "input_type": body.input_type,
                    "learned_at": body.learned_at,
                    "client_operation_id": body.client_operation_id,
                    "manual_text": body.manual_text,
                    "files": files,
                }
            ),
            update_id=update_id,
            subject_id=body.subject_id,
            input_type=body.input_type.value,
            learned_at=body.learned_at,
            client_operation_id=body.client_operation_id,
            manual_text_ciphertext=ciphertext,
            files=files,
            expires_at=update_expiry(now, self.settings.ingestion_expiry_hours),
        )
        return self._update(record)

    def list(
        self, auth: AuthenticatedRequest, *, cursor: str | None, limit: int
    ) -> LearningUpdateListResponse:
        records, next_cursor, has_more = self.repository.list_updates(
            auth.context, cursor=cursor, limit=limit
        )
        return LearningUpdateListResponse(
            items=[self._update(record) for record in records],
            next_cursor=next_cursor,
            has_more=has_more,
        )

    def get(self, auth: AuthenticatedRequest, update_id: UUID) -> LearningUpdateResponse:
        return self._update(self.repository.get_update(auth.context, update_id))

    def update(
        self,
        auth: AuthenticatedRequest,
        update_id: UUID,
        body: UpdateLearningUpdateRequest,
        *,
        idempotency_key: str,
    ) -> LearningUpdateResponse:
        ciphertext = None
        if body.manual_text is not None:
            if len(body.manual_text) > MAX_MANUAL_TEXT_CHARS:
                raise ApiError(413, "payload_too_large", "The text is too long.")
            ciphertext = self._protector().encrypt(body.manual_text, update_id=update_id)
        record = self.repository.update_draft(
            auth.context,
            update_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash(
                {
                    "update_id": update_id,
                    "version": body.version,
                    "learned_at": body.learned_at,
                    "manual_text": body.manual_text,
                }
            ),
            version=body.version,
            learned_at=body.learned_at,
            manual_text_ciphertext=ciphertext,
        )
        return self._update(record)

    def discard(
        self, auth: AuthenticatedRequest, update_id: UUID, *, idempotency_key: str
    ) -> tuple[LearningUpdateResponse, bool]:
        record, cleanup = self.repository.discard_update(
            auth.context,
            update_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash({"update_id": update_id}),
        )
        return self._update(record), cleanup

    def grant(
        self,
        auth: AuthenticatedRequest,
        update_id: UUID,
        body: UploadGrantRequest,
        *,
        idempotency_key: str,
    ) -> UploadGrantResponse:
        validate_declared_media_type(
            declared_name=body.declared_name, declared_media_type=body.declared_media_type
        )
        validate_byte_size(body.byte_size, self.settings.upload_max_bytes)
        upload = self.repository.create_upload(
            auth.context,
            update_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash(
                {
                    "update_id": update_id,
                    "declared_name": body.declared_name,
                    "declared_media_type": body.declared_media_type,
                    "byte_size": body.byte_size,
                    "content_sha256": body.content_sha256,
                }
            ),
            declared_name=body.declared_name,
            declared_media_type=body.declared_media_type.split(";", 1)[0].strip().lower(),
            byte_size=body.byte_size,
            content_sha256=body.content_sha256,
        )
        object_key = upload.pop("_object_key")
        grant = self.storage.create_upload_grant(
            object_key=object_key,
            expires_in=self.settings.upload_grant_ttl_seconds,
            content_type=upload["declared_media_type"],
        )
        return UploadGrantResponse(
            upload_id=upload["id"],
            url=grant.url,
            method="PUT",
            required_headers=grant.required_headers,
            max_bytes=self.settings.upload_max_bytes,
            expires_at=grant.expires_at,
            checksum_rule="SHA-256 hex digest of the exact uploaded bytes",
        )

    def finalize(
        self,
        auth: AuthenticatedRequest,
        update_id: UUID,
        upload_id: UUID,
        body: FinalizeUploadRequest,
        *,
        idempotency_key: str,
    ) -> LearningUpdateResponse:
        upload = self.repository.get_upload(auth.context, update_id, upload_id)
        validate_byte_size(body.observed_size, self.settings.upload_max_bytes)
        if body.observed_size != upload["byte_size"]:
            raise ApiError(
                422,
                "validation_failed",
                "The uploaded file size does not match the declared size.",
                "correct_input",
            )
        if body.content_sha256.lower() != (upload["content_sha256"] or "").lower():
            raise ApiError(
                422,
                "validation_failed",
                "The uploaded file does not match the declared checksum.",
                "correct_input",
            )
        try:
            observed = self.storage.head_object(upload["object_key"])
            if observed is None:
                raise ApiError(
                    409,
                    "invalid_state",
                    "The upload is not present in temporary storage.",
                    "retry",
                    retryable=True,
                    retry_after_seconds=5,
                )
            if observed.byte_size != body.observed_size:
                raise ApiError(
                    422,
                    "validation_failed",
                    "The stored file size does not match the declared size.",
                    "correct_input",
                )
            payload = self.storage.get_object(upload["object_key"])
        except StorageUnavailable as exc:
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Temporary upload verification is unavailable.",
                "retry",
                retryable=True,
                retry_after_seconds=5,
            ) from exc
        try:
            evidence = validate_upload_bytes(
                payload=payload,
                declared_name=upload["declared_name"],
                declared_media_type=upload["declared_media_type"],
                maximum=self.settings.upload_max_bytes,
                expected_sha256=body.content_sha256,
            )
        except ApiError as exc:
            self.repository.reject_upload(auth.context, update_id, upload_id, failure_code=exc.code)
            raise
        record = self.repository.finalize_upload(
            auth.context,
            update_id,
            upload_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash(
                {
                    "upload_id": upload_id,
                    "observed_size": body.observed_size,
                    "content_sha256": body.content_sha256.lower(),
                    "client_operation_id": body.client_operation_id,
                }
            ),
            evidence={
                "detected_media_type": evidence.detected_media_type,
                "byte_size": evidence.byte_size,
                "content_sha256": evidence.content_sha256,
            },
        )
        return self._update(record)

    def retry(
        self,
        auth: AuthenticatedRequest,
        update_id: UUID,
        *,
        stage: str,
        idempotency_key: str,
    ) -> LearningUpdateResponse:
        record = self.repository.retry_update(
            auth.context,
            update_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash({"update_id": update_id, "stage": stage}),
            stage=stage,
        )
        return self._update(record)

    def candidates(
        self, auth: AuthenticatedRequest, update_id: UUID, *, cursor: str | None, limit: int
    ) -> CandidateListResponse:
        rows, next_cursor, has_more = self.repository.list_candidates(
            auth.context, update_id, cursor=cursor, limit=limit
        )
        return CandidateListResponse(
            items=[self._candidate(row) for row in rows], next_cursor=next_cursor, has_more=has_more
        )

    def decide(
        self,
        auth: AuthenticatedRequest,
        update_id: UUID,
        body: SubmitVerificationDecisionsRequest,
        *,
        idempotency_key: str,
    ) -> SubmitVerificationDecisionsResponse:
        decisions = [
            {
                "candidate_id": decision.candidate_id,
                "candidate_version": decision.candidate_version,
                "decision": decision.decision.value,
                "corrected_payload": decision.corrected_payload,
            }
            for decision in body.decisions
        ]
        record = self.repository.submit_decisions(
            auth.context,
            update_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash(
                {
                    "update_id": update_id,
                    "decisions": [
                        {
                            "candidate_id": item.candidate_id,
                            "candidate_version": item.candidate_version,
                            "decision": item.decision,
                            "corrected_payload": item.corrected_payload,
                        }
                        for item in body.decisions
                    ],
                }
            ),
            decisions=decisions,
        )
        results = [
            VerificationDecisionResult(
                candidate_id=decision.candidate_id,
                candidate_status="accepted"
                if decision.decision.value in {"edit", "merge", "accept"}
                else "rejected",
                requires_verification=False,
            )
            for decision in body.decisions
        ]
        return SubmitVerificationDecisionsResponse(update=self._update(record), results=results)

    def preview(self, auth: AuthenticatedRequest, update_id: UUID) -> LearningPathPreviewResponse:
        data = self.repository.preview(auth.context, update_id)
        accepted = [
            candidate
            for candidate in data["candidates"]
            if candidate["status"] in {"accepted", "committed"}
        ]
        unique_concepts = {}
        for candidate in accepted:
            payload = candidate["candidate_payload"]
            key = str(payload.get("concept_version_id") or candidate["id"])
            unique_concepts.setdefault(key, candidate)
        concepts = [
            LearningPathPreviewConcept(
                candidate_id=candidate["id"],
                title=str(candidate["candidate_payload"].get("title", "Concept")),
                candidate_type=candidate["candidate_type"],
                concept_id=candidate["candidate_payload"].get("concept_id"),
                concept_version_id=candidate["candidate_payload"].get("concept_version_id"),
            )
            for candidate in list(unique_concepts.values())[:5]
        ]
        can_commit = (
            data["update"]["status"] == "verification_required"
            and bool(accepted)
            and not data["pending"]
        )
        blocked_reason = None
        if data["pending"]:
            blocked_reason = "verification_pending"
        elif not accepted:
            blocked_reason = "no_valid_concept"
        elif data["update"]["status"] not in {"committed", "verification_required"}:
            blocked_reason = "invalid_state"
        return LearningPathPreviewResponse(
            update_id=update_id,
            status=data["update"]["status"],
            concept_count=len(accepted),
            first_concepts=concepts,
            estimated_first_mission_minutes=max(5, min(20, len(accepted) * 2))
            if accepted
            else None,
            can_commit=can_commit,
            blocked_reason=blocked_reason,
        )

    def commit(
        self, auth: AuthenticatedRequest, update_id: UUID, *, idempotency_key: str
    ) -> KnowledgeCommitResponse:
        result = self.repository.commit(
            auth.context,
            update_id,
            idempotency_key=idempotency_key,
            request_hash=request_hash({"update_id": update_id}),
        )
        update = self._update(result["update"])
        mappings = [
            LearningPathPreviewConcept(
                candidate_id=item["candidate_id"],
                title=item["title"],
                candidate_type=item["candidate_type"],
                concept_id=item["concept_id"],
                concept_version_id=item["concept_version_id"],
            )
            for item in result["concept_mappings"]
        ]
        return KnowledgeCommitResponse(
            learning_update=update,
            knowledge_commit_id=result["knowledge_commit_id"],
            commit_version=result["commit_version"],
            committed_counts=result["committed_counts"],
            concept_mappings=mappings,
            private_knowledge_count=result["private_knowledge_count"],
            first_mission=None,
            source_deletion_status=update.source_deletion_status,
        )

    def _protector(self) -> ManualTextProtector:
        if self.protector is None:
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Text protection is not configured.",
                "retry",
                retryable=True,
            )
        return self.protector

    @staticmethod
    def _update(record: dict[str, Any]) -> LearningUpdateResponse:
        uploads = [
            SourceUploadSummary(
                id=upload["id"],
                declared_name=upload["declared_name"],
                declared_media_type=upload["declared_media_type"],
                detected_media_type=upload["detected_media_type"],
                byte_size=upload["byte_size"],
                status=upload["status"],
                expires_at=upload["expires_at"],
                deleted_at=upload["deleted_at"],
                deletion_status=DeletionStatus.DELETED
                if upload["status"] == "deleted"
                else DeletionStatus.PENDING,
            )
            for upload in record["uploads"]
        ]
        return LearningUpdateResponse(
            id=record["id"],
            subject_id=record["subject_id"],
            curriculum_version_id=record["curriculum_version_id"],
            input_type=record["input_type"],
            status=record["status"],
            learned_at=record["learned_at"],
            failure_code=record["failure_code"],
            expires_at=record["expires_at"],
            has_manual_text=record["has_manual_text"],
            created_at=record["created_at"],
            updated_at=record["updated_at"],
            row_version=record["row_version"],
            source_deletion_status=record["source_deletion_status"],
            uploads=uploads,
        )

    @staticmethod
    def _candidate(row: dict[str, Any]) -> CandidateResponse:
        payload = row["candidate_payload"]
        title = str(
            payload.get("title")
            or payload.get("statement")
            or payload.get("text")
            or row["candidate_type"].replace("_", " ").title()
        )
        summary = str(
            payload.get("definition")
            or payload.get("summary")
            or payload.get("statement")
            or "Extracted from this learning update."
        )
        confidence = float(row["confidence"])
        return CandidateResponse(
            id=row["id"],
            candidate_type=row["candidate_type"],
            display_title=title[:240],
            display_summary=summary[:1000],
            confidence=confidence,
            confidence_band=confidence_band(confidence),
            requires_verification=requires_verification(confidence),
            status=row["status"],
            source_locator=row["source_locator"],
            candidate_version=row["row_version"],
        )


def _load_protector(settings: Settings) -> ManualTextProtector | None:
    if settings.ingestion_encryption_key is None:
        return
    try:
        key = base64.b64decode(settings.ingestion_encryption_key.get_secret_value(), validate=True)
    except (binascii.Error, ValueError) as exc:
        raise ValueError("MEMORA_INGESTION_ENCRYPTION_KEY must be valid base64") from exc
    return ManualTextProtector(key)


_STORAGE: dict[str, ObjectStorage] = {}


def _shared_storage(settings: Settings) -> ObjectStorage:
    key = settings.object_storage_provider
    if key not in _STORAGE:
        _STORAGE[key] = build_object_storage(settings)
    return _STORAGE[key]


def get_ingestion_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> IngestionService:
    if settings.database_url is None:
        raise RuntimeError("MEMORA_DATABASE_URL is required")
    return IngestionService(
        repository=IngestionRepository(database_engine(settings.database_url)),
        storage=_shared_storage(settings),
        settings=settings,
        protector=_load_protector(settings),
    )
