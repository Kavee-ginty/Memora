from __future__ import annotations

import hashlib
import io
import urllib.error
import urllib.request
from datetime import UTC, datetime, timedelta

import pytest
from pydantic import SecretStr

from memora.core.config import Settings
from memora.modules.ingestion.storage import (
    MemoryObjectStorage,
    S3ObjectStorage,
    StorageUnavailable,
    build_object_storage,
)

PNG = b"\x89PNG\r\n\x1a\nsynthetic-image-bytes"


def test_memory_grant_is_single_key_and_short_lived() -> None:
    storage = MemoryObjectStorage()
    before = datetime.now(UTC)
    grant = storage.create_upload_grant(
        object_key="user/update/upload.png",
        expires_in=60,
        content_type="image/png",
    )

    assert grant.url == "memory://uploads/user/update/upload.png"
    assert grant.required_headers == {"Content-Type": "image/png"}
    assert before + timedelta(seconds=50) <= grant.expires_at <= before + timedelta(seconds=70)
    assert grant.url.count("user") == 1


def test_memory_storage_lifecycle_and_proof_ready_head() -> None:
    storage = MemoryObjectStorage()
    key = "user/update/upload.png"

    assert storage.head_object(key) is None
    storage.put_object(key, PNG, "image/png")
    metadata = storage.head_object(key)

    assert metadata is not None
    assert metadata.byte_size == len(PNG)
    assert metadata.content_type == "image/png"
    assert storage.get_object(key) == PNG

    storage.delete_object(key)
    assert storage.head_object(key) is None
    with pytest.raises(StorageUnavailable):
        storage.get_object(key)


def test_memory_etag_is_content_hash() -> None:
    storage = MemoryObjectStorage()
    key = "user/update/upload.png"
    storage.put_object(key, PNG, "image/png")

    metadata = storage.head_object(key)

    assert metadata is not None
    assert metadata.etag == hashlib.sha256(PNG).hexdigest()


def test_s3_requires_https_endpoint() -> None:
    with pytest.raises(ValueError, match="HTTPS"):
        S3ObjectStorage(
            endpoint="http://localhost:9000",
            region="us-east-1",
            bucket="memora",
            access_key="synthetic",
            secret_key="synthetic",
        )


def test_s3_grant_contains_scoped_sigv4_parameters() -> None:
    storage = S3ObjectStorage(
        endpoint="https://s3.example.com",
        region="eu-west-1",
        bucket="memora",
        access_key="synthetic-access",
        secret_key="synthetic-secret",
        timeout_seconds=5,
    )

    grant = storage.create_upload_grant(
        object_key="user/update/upload.pdf",
        expires_in=300,
        content_type="application/pdf",
    )

    assert grant.url.startswith("https://s3.example.com/memora/")
    assert "X-Amz-Algorithm=AWS4-HMAC-SHA256" in grant.url
    assert "X-Amz-Credential=synthetic-access%2F" in grant.url
    assert "X-Amz-Expires=300" in grant.url
    assert "X-Amz-SignedHeaders=content-type%3Bhost" in grant.url
    assert "X-Amz-Signature=" in grant.url
    assert grant.required_headers == {"Content-Type": "application/pdf"}


def test_s3_object_key_is_path_encoded_and_not_a_prefix_match() -> None:
    storage = S3ObjectStorage(
        endpoint="https://s3.example.com",
        region="us-east-1",
        bucket="memora",
        access_key="synthetic-access",
        secret_key="synthetic-secret",
    )

    path = storage._object_path("notes/a b.pdf")

    assert path == "/memora/notes/a%20b.pdf"
    assert storage._object_path("notes/a b.pdf.bak") != path


def test_build_object_storage_memory_provider() -> None:
    settings = Settings(
        _env_file=None,
        environment="local",
        database_url="postgresql+psycopg://memora:memora@127.0.0.1:5432/memora",
        object_storage_provider="memory",
    )
    storage = build_object_storage(settings)
    assert storage.provider_name == "memory"
    assert isinstance(storage, MemoryObjectStorage)


def test_build_object_storage_s3_provider_requires_configuration() -> None:
    # Missing endpoint and bucket
    settings = Settings(
        _env_file=None,
        environment="local",
        database_url="postgresql+psycopg://memora:memora@127.0.0.1:5432/memora",
        object_storage_provider="s3",
    )
    with pytest.raises(RuntimeError, match="ENDPOINT and MEMORA_OBJECT_STORAGE_BUCKET"):
        build_object_storage(settings)

    # Missing keys
    settings_with_endpoint = Settings(
        _env_file=None,
        environment="local",
        database_url="postgresql+psycopg://memora:memora@127.0.0.1:5432/memora",
        object_storage_provider="s3",
        object_storage_endpoint="https://s3.example.com",
        object_storage_bucket="bucket",
    )
    with pytest.raises(RuntimeError, match="ACCESS_KEY and MEMORA_OBJECT_STORAGE_SECRET_KEY"):
        build_object_storage(settings_with_endpoint)

    # Valid S3 configuration
    valid_s3_settings = Settings(
        _env_file=None,
        environment="local",
        database_url="postgresql+psycopg://memora:memora@127.0.0.1:5432/memora",
        object_storage_provider="s3",
        object_storage_endpoint="https://s3.example.com",
        object_storage_bucket="bucket",
        object_storage_access_key=SecretStr("access-key"),
        object_storage_secret_key=SecretStr("secret-key"),
    )
    storage = build_object_storage(valid_s3_settings)
    assert storage.provider_name == "s3"
    assert isinstance(storage, S3ObjectStorage)


def test_s3_secrets_not_leaked_in_exceptions_or_repr() -> None:
    secret = "SUPER_SECRET_S3_KEY"
    storage = S3ObjectStorage(
        endpoint="https://s3.example.com",
        region="us-east-1",
        bucket="memora",
        access_key="access-id",
        secret_key=secret,
    )
    grant = storage.create_upload_grant(
        object_key="test/file.pdf",
        expires_in=60,
        content_type="application/pdf",
    )
    assert secret not in grant.url
    assert secret not in repr(storage)


class _FakeS3Response:
    def __init__(self, headers: dict[str, str] | None = None) -> None:
        self.headers = headers or {}

    def __enter__(self) -> _FakeS3Response:
        return self

    def __exit__(self, *args: object) -> bool:
        return False


def _http_error(code: int) -> urllib.error.HTTPError:
    return urllib.error.HTTPError(
        "https://s3.example.com/memora/user/update/file.pdf",
        code,
        "synthetic error",
        None,
        io.BytesIO(b""),
    )


def _s3_storage() -> S3ObjectStorage:
    return S3ObjectStorage(
        endpoint="https://s3.example.com",
        region="eu-west-1",
        bucket="memora",
        access_key="synthetic-access",
        secret_key="synthetic-secret",
    )


def test_s3_head_404_is_absent_but_any_other_error_fails_closed(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    storage = _s3_storage()

    def absent(request: urllib.request.Request, timeout: int) -> _FakeS3Response:
        raise _http_error(404)

    monkeypatch.setattr(urllib.request, "urlopen", absent)
    assert storage.head_object("user/update/file.pdf") is None

    def denied(request: urllib.request.Request, timeout: int) -> _FakeS3Response:
        raise _http_error(403)

    monkeypatch.setattr(urllib.request, "urlopen", denied)
    with pytest.raises(StorageUnavailable):
        storage.head_object("user/update/file.pdf")

    def server_error(request: urllib.request.Request, timeout: int) -> _FakeS3Response:
        raise _http_error(500)

    monkeypatch.setattr(urllib.request, "urlopen", server_error)
    with pytest.raises(StorageUnavailable):
        storage.head_object("user/update/file.pdf")


def test_s3_head_returns_metadata_from_response_headers(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    storage = _s3_storage()
    response = _FakeS3Response(
        {"Content-Length": "24", "Content-Type": "image/png", "ETag": "etag-1"}
    )
    monkeypatch.setattr(urllib.request, "urlopen", lambda request, timeout: response)

    metadata = storage.head_object("user/update/file.png")

    assert metadata is not None
    assert metadata.byte_size == 24
    assert metadata.content_type == "image/png"
    assert metadata.etag == "etag-1"


def test_s3_delete_treats_only_404_as_proven_absence(monkeypatch: pytest.MonkeyPatch) -> None:
    storage = _s3_storage()

    def gone(request: urllib.request.Request, timeout: int) -> _FakeS3Response:
        raise _http_error(404)

    monkeypatch.setattr(urllib.request, "urlopen", gone)
    assert storage.delete_object("user/update/file.pdf") is None

    def denied(request: urllib.request.Request, timeout: int) -> _FakeS3Response:
        raise _http_error(403)

    monkeypatch.setattr(urllib.request, "urlopen", denied)
    with pytest.raises(StorageUnavailable):
        storage.delete_object("user/update/file.pdf")
