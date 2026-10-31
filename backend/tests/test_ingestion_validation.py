from __future__ import annotations

import hashlib

import pytest

from memora.api.errors import ApiError
from memora.modules.ingestion.validation import (
    detect_media_type,
    sanitize_filename,
    validate_byte_size,
    validate_upload_bytes,
)

PDF = b"%PDF-1.7\nsynthetic notes"
PNG = b"\x89PNG\r\n\x1a\nsynthetic-image"
JPEG = b"\xff\xd8\xff\xe0synthetic-photo"


def test_filename_sanitisation_removes_paths_and_controls() -> None:
    name = sanitize_filename("../../etc/pass\x00word?.pdf")

    assert name == "password_.pdf"
    assert "/" not in name
    assert "\\" not in name
    assert "\x00" not in name


def test_filename_sanitisation_rejects_empty_names() -> None:
    with pytest.raises(ApiError) as captured:
        sanitize_filename("...")

    assert captured.value.status_code == 422
    assert captured.value.code == "validation_failed"


def test_magic_bytes_detect_only_supported_types() -> None:
    assert detect_media_type(PDF) == "application/pdf"
    assert detect_media_type(PNG) == "image/png"
    assert detect_media_type(JPEG) == "image/jpeg"
    assert detect_media_type(b"MZ\x90\x00") is None


def test_size_bounds_reject_empty_and_oversize() -> None:
    with pytest.raises(ApiError) as empty:
        validate_byte_size(0, maximum=1024)

    assert empty.value.status_code == 422

    with pytest.raises(ApiError) as oversize:
        validate_byte_size(2048, maximum=1024)

    assert oversize.value.status_code == 413
    assert oversize.value.code == "payload_too_large"


def test_spoofed_content_is_rejected_even_when_declared_type_is_allowed() -> None:
    with pytest.raises(ApiError) as captured:
        validate_upload_bytes(
            payload=PNG,
            declared_name="notes.pdf",
            declared_media_type="application/pdf",
            maximum=1024,
            expected_sha256=hashlib.sha256(PNG).hexdigest(),
        )

    assert captured.value.status_code == 422
    assert captured.value.code == "validation_failed"


def test_unknown_content_is_rejected_as_unsupported() -> None:
    with pytest.raises(ApiError) as captured:
        validate_upload_bytes(
            payload=b"plain text pretending to be a document",
            declared_name="notes.pdf",
            declared_media_type="application/pdf",
            maximum=1024,
            expected_sha256=hashlib.sha256(b"plain text pretending to be a document").hexdigest(),
        )

    assert captured.value.status_code == 415
    assert captured.value.code == "unsupported_media_type"


def test_checksum_mismatch_fails_without_echoing_content() -> None:
    with pytest.raises(ApiError) as captured:
        validate_upload_bytes(
            payload=PDF,
            declared_name="notes.pdf",
            declared_media_type="application/pdf",
            maximum=1024,
            expected_sha256="0" * 64,
        )

    assert captured.value.status_code == 422
    assert captured.value.code == "validation_failed"
    assert PDF.decode() not in captured.value.message


def test_upload_validation_accepts_matching_types_and_checksum() -> None:
    evidence = validate_upload_bytes(
        payload=PDF,
        declared_name="notes.pdf",
        declared_media_type="application/pdf; charset=binary",
        maximum=1024,
        expected_sha256=hashlib.sha256(PDF).hexdigest(),
    )

    assert evidence.detected_media_type == "application/pdf"
    assert evidence.declared_media_type == "application/pdf"
    assert evidence.byte_size == len(PDF)
    assert evidence.content_sha256 == hashlib.sha256(PDF).hexdigest()
