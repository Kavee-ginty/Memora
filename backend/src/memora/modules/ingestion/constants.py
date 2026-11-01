"""Reviewed constants for the learning-ingestion boundary.

Product values that belong to later tasks (mission caps, XP thresholds, memory
policy versions) are intentionally absent.
"""

from __future__ import annotations

from enum import StrEnum

ALLOWED_MEDIA_TYPES: dict[str, str] = {
    "application/pdf": "pdf",
    "image/png": "image",
    "image/jpeg": "image",
}
ALLOWED_EXTENSIONS: dict[str, str] = {
    "pdf": "application/pdf",
    "png": "image/png",
    "jpg": "image/jpeg",
    "jpeg": "image/jpeg",
}
MAGIC_PREFIXES: tuple[tuple[bytes, str], ...] = (
    (b"%PDF-", "application/pdf"),
    (b"\x89PNG\r\n\x1a\n", "image/png"),
    (b"\xff\xd8\xff", "image/jpeg"),
)
AUTO_ACCEPT_CONFIDENCE = 0.85
CONFIDENCE_BANDS: tuple[tuple[float, str], ...] = ((0.85, "high"), (0.6, "medium"), (0.0, "low"))
CANDIDATE_TYPES = frozenset(
    {"edge", "unit", "claim", "concept", "diagram", "example", "formula", "variable"}
)
CANDIDATE_SCHEMA_VERSION = "1"
EXTRACTION_PROMPT_VERSION = "ingestion-extract-v1"
DETERMINISTIC_MODEL_KEY = "deterministic-alias-v1"
TERMINAL_UPDATE_STATUSES = frozenset({"deleted", "expired", "committed"})
ACTIVE_UPDATE_STATUSES = frozenset(
    {"draft", "failed", "uploading", "processing", "verification_required"}
)
TERMINAL_UPLOAD_STATUSES = frozenset({"deleted", "expired", "rejected"})
DELETABLE_UPLOAD_STATUSES = frozenset({"uploaded", "validated", "authorized", "processing"})
MAX_MANUAL_TEXT_CHARS = 20000
MAX_CANDIDATE_TITLE_CHARS = 240
MAX_SOURCE_LOCATOR_BYTES = 2000
MAX_FILENAME_CHARS = 180
MAX_PROCESSING_DERIVATIVES = 20
JOB_EXTRACT = "ingestion.extract"
JOB_DELETE_UPLOAD = "ingestion.delete_upload"
JOB_RECONCILE = "ingestion.reconcile"
JOB_STATUSES = frozenset(
    {"failed", "leased", "queued", "cancelled", "succeeded", "retry_wait", "dead_lettered"}
)
MAX_JOB_ATTEMPTS = 5
JOB_BACKOFF_SECONDS: tuple[int, ...] = (15, 60, 180, 600, 1800)
FAILURE_CODES = frozenset(
    {
        "cancelled",
        "internal_error",
        "deletion_failed",
        "extraction_failed",
        "payload_too_large",
        "validation_failed",
        "source_unavailable",
        "extraction_unavailable",
        "no_extractable_content",
        "unsupported_media_type",
    }
)


class InputType(StrEnum):
    MANUAL_TEXT = "manual_text"
    PDF = "pdf"
    IMAGE = "image"
    MIXED = "mixed"


class LearningUpdateStatus(StrEnum):
    DRAFT = "draft"
    UPLOADING = "uploading"
    PROCESSING = "processing"
    VERIFICATION_REQUIRED = "verification_required"
    COMMITTED = "committed"
    FAILED = "failed"
    EXPIRED = "expired"
    DELETED = "deleted"


class UploadStatus(StrEnum):
    AUTHORIZED = "authorized"
    UPLOADED = "uploaded"
    VALIDATED = "validated"
    PROCESSING = "processing"
    DELETING = "deleting"
    DELETED = "deleted"
    REJECTED = "rejected"
    EXPIRED = "expired"


class CandidateStatus(StrEnum):
    CANDIDATE = "candidate"
    NEEDS_VERIFICATION = "needs_verification"
    ACCEPTED = "accepted"
    REJECTED = "rejected"
    COMMITTED = "committed"
    EXPIRED = "expired"


class VerificationDecisionValue(StrEnum):
    ACCEPT = "accept"
    EDIT = "edit"
    REJECT = "reject"
    MERGE = "merge"


class DeletionStatus(StrEnum):
    NOT_REQUIRED = "not_required"
    PENDING = "pending"
    DELETED = "deleted"
    FAILED = "failed"


def confidence_band(confidence: float) -> str:
    for threshold, band in CONFIDENCE_BANDS:
        if not confidence >= threshold:
            continue
        return band
    return "low"


def requires_verification(confidence: float) -> bool:
    return confidence < AUTO_ACCEPT_CONFIDENCE
