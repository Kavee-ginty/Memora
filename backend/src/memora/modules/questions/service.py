"""Question report application service and reviewed-content import boundary."""

from __future__ import annotations

import base64
import binascii
import hashlib
import json
import os
from datetime import UTC, datetime
from typing import Annotated
from uuid import UUID, uuid4

from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
from cryptography.hazmat.primitives.kdf.hkdf import HKDF
from fastapi import Depends

from memora.api.errors import ApiError
from memora.api.security import AuthenticatedRequest
from memora.api.v1.schemas.common import Page
from memora.api.v1.schemas.question_reports import (
    QuestionReportCreateRequest,
    QuestionReportResponse,
    QuestionReportSummary,
)
from memora.core.config import Settings, get_settings
from memora.db.runtime import database_engine
from memora.modules.questions.constants import (
    OPEN_REPORT_STATUSES,
    REPORT_CURSOR_VERSION,
    REPORT_ENCRYPTION_CONTEXT,
)
from memora.modules.questions.models import QuestionImportBundle
from memora.modules.questions.repository import (
    QuestionImportRepository,
    QuestionReportRepository,
)
from memora.modules.questions.validation import validate_question_import


class ReportDescriptionProtector:
    """Encrypt optional free text without storing searchable plaintext."""

    def __init__(self, base_key: bytes) -> None:
        if len(base_key) != 32:
            raise ValueError("Report encryption key must decode to exactly 32 bytes")
        derived = HKDF(
            algorithm=hashes.SHA256(),
            length=32,
            salt=None,
            info=REPORT_ENCRYPTION_CONTEXT,
        ).derive(base_key)
        self._cipher = AESGCM(derived)

    def protect(self, description: str, *, owner: bytes) -> bytes:
        nonce = os.urandom(12)
        ciphertext = self._cipher.encrypt(nonce, description.encode("utf-8"), owner)
        return b"\x01" + nonce + ciphertext

    def reveal(self, ciphertext: bytes, *, owner: bytes) -> str:
        if len(ciphertext) < 13 or ciphertext[0] != 1:
            raise ValueError("Unsupported report ciphertext")
        return self._cipher.decrypt(ciphertext[1:13], ciphertext[13:], owner).decode("utf-8")


class QuestionService:
    def __init__(self, repository: QuestionReportRepository, settings: Settings) -> None:
        self.repository = repository
        self.settings = settings

    def create_report(
        self,
        request: AuthenticatedRequest,
        question_version_id: UUID,
        body: QuestionReportCreateRequest,
        *,
        idempotency_key: str,
    ) -> tuple[QuestionReportResponse, bool]:
        if body.report_type == "grading_dispute" and body.attempt_id is None:
            raise ApiError(
                422,
                "validation_failed",
                "Include the attempt you are disputing.",
                "correct_input",
            )

        report_id = uuid4()
        submitted_at = datetime.now(UTC)
        ciphertext = None
        if body.description is not None:
            owner = _report_owner(
                request,
                question_version_id=question_version_id,
                report_id=report_id,
            )
            ciphertext = self._protector().protect(body.description, owner=owner)

        row, created = self.repository.create_report(
            request.context,
            idempotency_key=idempotency_key,
            request_hash=_request_hash(body, question_version_id),
            report_id=report_id,
            question_version_id=question_version_id,
            attempt_id=body.attempt_id,
            report_type=body.report_type,
            description_ciphertext=ciphertext,
            submitted_at=submitted_at,
        )
        return _report_response(row), created

    def list_reports(
        self,
        request: AuthenticatedRequest,
        *,
        cursor: str | None,
        limit: int,
    ) -> Page[QuestionReportSummary]:
        before = _decode_report_cursor(cursor) if cursor is not None else None
        rows, has_more = self.repository.list_reports(
            request.context,
            limit=limit,
            before=before,
        )
        items = [_report_summary(row) for row in rows]
        next_cursor = None
        if has_more and rows:
            last = rows[-1]
            next_cursor = _encode_report_cursor(
                last["submitted_at"],
                UUID(str(last["id"])),
            )
        return Page[QuestionReportSummary](
            items=items,
            next_cursor=next_cursor,
            has_more=has_more,
        )

    def get_report(self, request: AuthenticatedRequest, report_id: UUID) -> QuestionReportResponse:
        row = self.repository.get_report(request.context, report_id=report_id)
        if row is None:
            raise ApiError(404, "resource_not_found", "Question report was not found.")
        return _report_response(row)

    def _protector(self) -> ReportDescriptionProtector:
        configured = self.settings.device_encryption_key
        if configured is None:
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Report submission is temporarily unavailable.",
                "retry",
                retryable=True,
            )
        try:
            base_key = base64.b64decode(configured.get_secret_value(), validate=True)
            return ReportDescriptionProtector(base_key)
        except (ValueError, TypeError, binascii.Error) as exc:
            raise ApiError(
                503,
                "temporarily_unavailable",
                "Report submission is temporarily unavailable.",
                "retry",
                retryable=True,
            ) from exc


class QuestionImportService:
    """Reviewed content import used by offline/admin tooling only."""

    def __init__(self, repository: QuestionImportRepository) -> None:
        self.repository = repository

    def import_question(self, bundle: QuestionImportBundle) -> dict[str, object]:
        imported = validate_question_import(bundle)
        return self.repository.import_question(imported)


def _report_owner(
    request: AuthenticatedRequest,
    *,
    question_version_id: UUID,
    report_id: UUID,
) -> bytes:
    return b"\0".join(
        (
            REPORT_ENCRYPTION_CONTEXT,
            request.context.issuer.encode("utf-8"),
            request.context.subject.encode("utf-8"),
            question_version_id.bytes,
            report_id.bytes,
        )
    )


def _request_hash(body: QuestionReportCreateRequest, question_version_id: UUID) -> str:
    payload = json.dumps(
        {
            "question_version_id": str(question_version_id),
            "attempt_id": str(body.attempt_id) if body.attempt_id is not None else None,
            "report_type": body.report_type,
            "description": body.description,
        },
        sort_keys=True,
        separators=(",", ":"),
    )
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def _evidence_state(report_type: str, status: str) -> str:
    if status in OPEN_REPORT_STATUSES and report_type in {"grading_dispute", "answer_error"}:
        return "limited_pending_review"
    return "recorded"


def _report_summary(row: dict[str, object]) -> QuestionReportSummary:
    return QuestionReportSummary(
        id=UUID(str(row["id"])),
        question_version_id=UUID(str(row["question_version_id"])),
        attempt_id=(UUID(str(row["attempt_id"])) if row["attempt_id"] is not None else None),
        report_type=str(row["report_type"]),
        status=str(row["status"]),
        submitted_at=row["submitted_at"],
        resolved_at=row["resolved_at"],
        description_present=bool(row["description_present"]),
        evidence_state=_evidence_state(str(row["report_type"]), str(row["status"])),
    )


def _report_response(row: dict[str, object]) -> QuestionReportResponse:
    summary = _report_summary(row)
    return QuestionReportResponse(
        **summary.model_dump(),
        resolution_code=(
            str(row["resolution_code"]) if row["resolution_code"] is not None else None
        ),
        review_required=str(row["status"]) in OPEN_REPORT_STATUSES,
    )


def _encode_report_cursor(submitted_at: datetime, report_id: UUID) -> str:
    payload = json.dumps(
        {
            "v": REPORT_CURSOR_VERSION,
            "t": submitted_at.astimezone(UTC).isoformat(),
            "id": str(report_id),
        },
        separators=(",", ":"),
    )
    return base64.urlsafe_b64encode(payload.encode("utf-8")).decode("ascii").rstrip("=")


def _decode_report_cursor(cursor: str) -> tuple[datetime, UUID]:
    try:
        padded = cursor + "=" * (-len(cursor) % 4)
        payload = json.loads(base64.urlsafe_b64decode(padded.encode("ascii")))
        if not isinstance(payload, dict):
            raise ValueError("cursor payload must be an object")
        if payload.get("v") != REPORT_CURSOR_VERSION:
            raise ValueError("unsupported cursor version")
        submitted_at = datetime.fromisoformat(str(payload["t"]))
        if submitted_at.tzinfo is None:
            raise ValueError("cursor timestamp must include a timezone")
        report_id = UUID(str(payload["id"]))
        return submitted_at.astimezone(UTC), report_id
    except (
        ValueError,
        TypeError,
        KeyError,
        OverflowError,
        RecursionError,
        json.JSONDecodeError,
        binascii.Error,
    ) as exc:
        raise ApiError(
            400,
            "invalid_cursor",
            "Use a valid report cursor.",
            "refresh_state",
        ) from exc


def get_question_service(
    settings: Annotated[Settings, Depends(get_settings)],
) -> QuestionService:
    return QuestionService(
        QuestionReportRepository(database_engine(settings.database_url)),
        settings,
    )
