from __future__ import annotations

import contextlib
import hashlib
import hmac
import io
import logging
import zipfile
from datetime import UTC, datetime
from uuid import UUID

from memora.core.config import get_settings
from memora.modules.ingestion.storage import (
    ObjectStorage,
    StorageUnavailable,
    build_object_storage,
)

logger = logging.getLogger(__name__)

_override_storage: ObjectStorage | None = None


def get_privacy_object_storage() -> ObjectStorage:
    if _override_storage is not None:
        return _override_storage
    return build_object_storage(get_settings())


def set_privacy_object_storage(storage: ObjectStorage | None) -> None:
    global _override_storage
    _override_storage = storage


def export_object_key(request_id: UUID) -> str:
    return f"exports/{request_id}.zip"


def export_archive_exists(request_id: UUID) -> bool:
    storage = get_privacy_object_storage()
    try:
        return storage.head_object(export_object_key(request_id)) is not None
    except StorageUnavailable:
        return False


def get_export_archive_bytes(request_id: UUID) -> bytes:
    storage = get_privacy_object_storage()
    return storage.get_object(export_object_key(request_id))


def write_export_archive(
    request_id: UUID,
    user_id: UUID,
    export_json_bytes: bytes,
    summary_text: str,
) -> str:
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("export.json", export_json_bytes)
        zf.writestr("summary.txt", summary_text.encode("utf-8"))

    zip_bytes = buf.getvalue()
    key = export_object_key(request_id)
    storage = get_privacy_object_storage()
    storage.put_object(key, zip_bytes, content_type="application/zip")
    logger.info("Export archive stored in object storage: key=%s size=%d", key, len(zip_bytes))
    return key


def delete_export_archive(request_id: UUID) -> None:
    key = export_object_key(request_id)
    storage = get_privacy_object_storage()
    with contextlib.suppress(StorageUnavailable):
        storage.delete_object(key)


def purge_upload_object(object_key: str) -> bool:
    """Purges a temporary upload object from authoritative storage and verifies absence."""
    storage = get_privacy_object_storage()
    storage.delete_object(object_key)
    observed = storage.head_object(object_key)
    if observed is not None:
        raise StorageUnavailable(
            f"Object storage deletion verification failed for object: {object_key}"
        )
    logger.info("Purged and verified absence of temporary upload object %s", object_key)
    return True


def _signing_secret() -> bytes:
    settings = get_settings()
    if settings.device_encryption_key:
        return settings.device_encryption_key.get_secret_value().encode()
    if settings.device_fingerprint_key:
        return settings.device_fingerprint_key.get_secret_value().encode()
    return b"memora-default-export-token-secret-32b"


def generate_export_download_token(
    request_id: UUID,
    user_id: UUID,
    expires_at: datetime,
) -> str:
    """Generates a cryptographic purpose-bound, expiring download token for the export archive."""
    exp = int(expires_at.timestamp())
    msg = f"{request_id}:{user_id}:export_download:{exp}".encode()
    sig = hmac.new(_signing_secret(), msg, hashlib.sha256).hexdigest()
    return f"{exp}.{sig}"


def verify_export_download_token(
    request_id: UUID,
    user_id: UUID,
    token: str,
) -> bool:
    """Verifies that the provided token is signed, unexpired, and purpose-bound to this export."""
    parts = token.split(".", 1)
    if len(parts) != 2:
        return False
    exp_str, sig = parts
    try:
        exp = int(exp_str)
    except ValueError:
        return False

    now = int(datetime.now(UTC).timestamp())
    if now > exp:
        return False

    expected_msg = f"{request_id}:{user_id}:export_download:{exp}".encode()
    expected_sig = hmac.new(_signing_secret(), expected_msg, hashlib.sha256).hexdigest()
    return hmac.compare_digest(sig, expected_sig)
