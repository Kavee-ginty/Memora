"""Validation for declared and observed temporary uploads."""

from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from pathlib import PurePath

from memora.api.errors import ApiError
from memora.modules.ingestion.constants import (
    ALLOWED_EXTENSIONS,
    ALLOWED_MEDIA_TYPES,
    MAGIC_PREFIXES,
    MAX_FILENAME_CHARS,
)

_CONTROL_CHARACTERS = re.compile(r"[\x00-\x1f\x7f]")
_SAFE_NAME = re.compile(r"[^A-Za-z0-9._ ()\[\]-]+")


@dataclass(frozen=True, slots=True)
class FileEvidence:
    declared_name: str
    declared_media_type: str
    detected_media_type: str
    byte_size: int
    content_sha256: str


def sanitize_filename(value: str) -> str:
    """Return a display-safe basename without path components or controls."""

    name = PurePath(value.replace("\\", "/")).name
    name = _CONTROL_CHARACTERS.sub("", name).strip().strip(".")
    name = _SAFE_NAME.sub("_", name)[:MAX_FILENAME_CHARS].strip()
    if not name:
        raise ApiError(
            422, "validation_failed", "Choose a file with a readable name.", "correct_input"
        )
    return name


def media_type_for_filename(name: str) -> str | None:
    suffix = PurePath(name).suffix.lower().lstrip(".")
    return ALLOWED_EXTENSIONS.get(suffix)


def detect_media_type(payload: bytes) -> str | None:
    for prefix, media_type in MAGIC_PREFIXES:
        if not payload.startswith(prefix):
            continue
        return media_type


def validate_declared_media_type(*, declared_name: str, declared_media_type: str) -> str:
    normalized = declared_media_type.split(";", 1)[0].strip().lower()
    if normalized not in ALLOWED_MEDIA_TYPES:
        raise ApiError(
            415, "unsupported_media_type", "Use a PDF, PNG or JPEG file.", "correct_input"
        )
    extension_type = media_type_for_filename(declared_name)
    if extension_type is not None and extension_type != normalized:
        raise ApiError(
            422,
            "validation_failed",
            "The file name does not match the declared file type.",
            "correct_input",
        )
    return normalized


def validate_byte_size(byte_size: int, maximum: int) -> None:
    if byte_size <= 0:
        raise ApiError(422, "validation_failed", "The selected file is empty.", "correct_input")
    if byte_size > maximum:
        raise ApiError(
            413,
            "payload_too_large",
            "The selected file is larger than the allowed limit.",
            "correct_input",
        )


def validate_upload_bytes(
    *,
    payload: bytes,
    declared_name: str,
    declared_media_type: str,
    maximum: int,
    expected_sha256: str,
) -> FileEvidence:
    validate_byte_size(len(payload), maximum)
    normalized_declared = validate_declared_media_type(
        declared_name=declared_name, declared_media_type=declared_media_type
    )
    detected = detect_media_type(payload)
    if detected is None:
        raise ApiError(
            415,
            "unsupported_media_type",
            "The file content is not a supported PDF, PNG or JPEG.",
            "correct_input",
        )
    if detected != normalized_declared:
        raise ApiError(
            422,
            "validation_failed",
            "The file content does not match the declared file type.",
            "correct_input",
        )
    digest = hashlib.sha256(payload).hexdigest()
    if digest != expected_sha256.lower():
        raise ApiError(
            422,
            "validation_failed",
            "The uploaded file does not match its checksum.",
            "correct_input",
        )
    return FileEvidence(
        declared_name=sanitize_filename(declared_name),
        declared_media_type=normalized_declared,
        detected_media_type=detected,
        byte_size=len(payload),
        content_sha256=digest,
    )


def sha256_hex(payload: bytes) -> str:
    return hashlib.sha256(payload).hexdigest()
