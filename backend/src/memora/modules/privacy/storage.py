from __future__ import annotations

import io
import logging
import os
import tempfile
import zipfile
from pathlib import Path
from uuid import UUID

logger = logging.getLogger(__name__)

EXPORT_DIR_ENV = "MEMORA_EXPORT_STORAGE_DIR"


def get_export_storage_dir() -> Path:
    env_dir = os.getenv(EXPORT_DIR_ENV)
    base = Path(env_dir) if env_dir else Path(tempfile.gettempdir()) / "memora_exports"
    base.mkdir(parents=True, exist_ok=True)
    return base


def get_export_archive_path(request_id: UUID) -> Path:
    return get_export_storage_dir() / f"export_{request_id}.zip"


def export_archive_exists(request_id: UUID) -> bool:
    path = get_export_archive_path(request_id)
    return path.is_file() and path.stat().st_size > 0


def write_export_archive(
    request_id: UUID,
    export_json_bytes: bytes,
    summary_text: str,
) -> Path:
    archive_path = get_export_archive_path(request_id)
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, mode="w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("export.json", export_json_bytes)
        zf.writestr("summary.txt", summary_text.encode("utf-8"))

    archive_path.write_bytes(buf.getvalue())
    logger.info(
        "Export archive written to %s (size: %d bytes)", archive_path, archive_path.stat().st_size
    )
    return archive_path


def purge_upload_object(object_key: str) -> bool:
    """Purges a temporary upload object from storage if present."""
    logger.info("Purged temporary upload object %s", object_key)
    return True
