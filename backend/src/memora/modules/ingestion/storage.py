"""Temporary object storage with short-lived signed grants.

The API never reads or writes upload bytes. It only signs a single-purpose URL.
The worker downloads, validates and deletes through the same adapter.
"""

from __future__ import annotations

import hashlib
import hmac
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from typing import Protocol
from urllib.parse import quote, urlparse

from memora.core.config import Settings


class StorageUnavailable(RuntimeError):
    """Raised when the configured object store cannot answer safely."""


@dataclass(frozen=True, slots=True)
class ObjectMetadata:
    byte_size: int
    content_type: str | None
    etag: str | None = None


@dataclass(frozen=True, slots=True)
class SignedGrant:
    url: str = field(repr=False)
    expires_at: datetime
    required_headers: dict[str, str] = field(default_factory=dict)


class ObjectStorage(Protocol):
    provider_name: str

    def create_upload_grant(
        self, *, object_key: str, expires_in: int, content_type: str
    ) -> SignedGrant:
        pass

    def create_download_url(self, object_key: str, *, expires_in: int = 300) -> str:
        pass

    def head_object(self, object_key: str) -> ObjectMetadata | None:
        pass

    def get_object(self, object_key: str) -> bytes:
        pass

    def delete_object(self, object_key: str) -> None:
        pass


class MemoryObjectStorage:
    """Deterministic in-memory adapter for unit tests and local smoke runs."""

    provider_name = "memory"

    def __init__(self) -> None:
        self._objects = {}

    def create_upload_grant(
        self, *, object_key: str, expires_in: int, content_type: str
    ) -> SignedGrant:
        return SignedGrant(
            url=f"memory://uploads/{quote(object_key)}",
            expires_at=datetime.now(UTC) + timedelta(seconds=expires_in),
            required_headers={"Content-Type": content_type},
        )

    def create_download_url(self, object_key: str, *, expires_in: int = 300) -> str:
        return f"memory://uploads/{quote(object_key)}"

    def put_object(self, object_key: str, payload: bytes, content_type: str) -> None:
        self._objects[object_key] = payload, content_type

    def head_object(self, object_key: str) -> ObjectMetadata | None:
        stored = self._objects.get(object_key)
        if stored is None:
            return
        payload, content_type = stored
        return ObjectMetadata(
            byte_size=len(payload),
            content_type=content_type,
            etag=hashlib.sha256(payload).hexdigest(),
        )

    def get_object(self, object_key: str) -> bytes:
        stored = self._objects.get(object_key)
        if stored is None:
            raise StorageUnavailable("The temporary source is no longer available.")
        return stored[0]

    def delete_object(self, object_key: str) -> None:
        self._objects.pop(object_key, None)


class S3ObjectStorage:
    """S3-compatible storage using SigV4 query authentication.

    Works with AWS S3, MinIO and Supabase Storage's S3 endpoint. No SDK is
    required; the worker and API use bounded standard-library HTTP requests.
    """

    provider_name = "s3"
    service = "s3"

    def __init__(
        self,
        *,
        endpoint: str,
        region: str,
        bucket: str,
        access_key: str,
        secret_key: str,
        timeout_seconds: int = 10,
    ) -> None:
        parsed = urlparse(endpoint)
        if parsed.scheme != "https" or not parsed.netloc:
            raise ValueError("Object storage endpoint must be an HTTPS URL")
        self.endpoint = endpoint.rstrip("/")
        self._origin = f"{parsed.scheme}://{parsed.netloc}"
        self.region = region
        self.bucket = bucket
        self.access_key = access_key
        self.secret_key = secret_key
        self.timeout_seconds = timeout_seconds

    def _object_path(self, object_key: str) -> str:
        base_path = urlparse(self.endpoint).path.rstrip("/")
        safe_key = "/".join(part for part in object_key.split("/") if part not in {"..", "", "."})
        return f"{base_path}/{quote(self.bucket, safe='')}/{quote(safe_key, safe='/-_.~')}"

    def _presign(
        self,
        method: str,
        object_key: str,
        *,
        expires_in: int,
        extra_headers: dict[str, str] | None = None,
    ) -> str:
        now = datetime.now(UTC)
        amz_date = now.strftime("%Y%m%dT%H%M%SZ")
        date_stamp = now.strftime("%Y%m%d")
        host = urlparse(self.endpoint).netloc.lower()
        path = self._object_path(object_key)
        credential_scope = f"{date_stamp}/{self.region}/{self.service}/aws4_request"
        headers = {"host": host}
        for name, value in (extra_headers or {}).items():
            headers[name.lower()] = value.strip()
        signed_headers = ";".join(sorted(headers))
        canonical_headers = "".join(f"{name}:{headers[name]}\n" for name in sorted(headers))
        query = {
            "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
            "X-Amz-Credential": f"{self.access_key}/{credential_scope}",
            "X-Amz-Date": amz_date,
            "X-Amz-Expires": str(max(1, min(expires_in, 604800))),
            "X-Amz-SignedHeaders": signed_headers,
        }
        canonical_query = "&".join(
            (
                f"{quote(name, safe='-_.~')}={quote(value, safe='-_.~')}"
                for name, value in sorted(query.items())
            )
        )
        canonical_request = "\n".join(
            [method, path, canonical_query, canonical_headers, signed_headers, "UNSIGNED-PAYLOAD"]
        )
        string_to_sign = "\n".join(
            [
                "AWS4-HMAC-SHA256",
                amz_date,
                credential_scope,
                hashlib.sha256(canonical_request.encode()).hexdigest(),
            ]
        )
        signing_key = _signing_key(self.secret_key, date_stamp, self.region, self.service)
        signature = hmac.new(signing_key, string_to_sign.encode(), hashlib.sha256).hexdigest()
        return f"{self._origin}{path}?{canonical_query}&X-Amz-Signature={signature}"

    def create_upload_grant(
        self, *, object_key: str, expires_in: int, content_type: str
    ) -> SignedGrant:
        url = self._presign(
            "PUT", object_key, expires_in=expires_in, extra_headers={"Content-Type": content_type}
        )
        return SignedGrant(
            url=url,
            expires_at=datetime.now(UTC) + timedelta(seconds=expires_in),
            required_headers={"Content-Type": content_type},
        )

    def create_download_url(self, object_key: str, *, expires_in: int = 300) -> str:
        return self._presign("GET", object_key, expires_in=expires_in)

    def head_object(self, object_key: str) -> ObjectMetadata | None:
        request = urllib.request.Request(
            self._presign("HEAD", object_key, expires_in=60), method="HEAD"
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout_seconds) as response:
                return ObjectMetadata(
                    byte_size=int(response.headers.get("Content-Length", "0")),
                    content_type=response.headers.get("Content-Type"),
                    etag=response.headers.get("ETag"),
                )
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                pass
        except (urllib.error.URLError, TimeoutError) as exc:
            raise StorageUnavailable("The temporary source is temporarily unavailable.") from exc

    def get_object(self, object_key: str) -> bytes:
        request = urllib.request.Request(
            self._presign("GET", object_key, expires_in=60), method="GET"
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout_seconds) as response:
                return response.read()
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                raise StorageUnavailable("The temporary source is no longer available.") from exc
            raise StorageUnavailable("The temporary source could not be read.") from exc
        except (urllib.error.URLError, TimeoutError) as exc:
            raise StorageUnavailable("The temporary source is temporarily unavailable.") from exc

    def delete_object(self, object_key: str) -> None:
        request = urllib.request.Request(
            self._presign("DELETE", object_key, expires_in=60), method="DELETE"
        )
        try:
            with urllib.request.urlopen(request, timeout=self.timeout_seconds):
                pass
        except urllib.error.HTTPError as exc:
            if exc.code == 404:
                pass
        except (urllib.error.URLError, TimeoutError) as exc:
            raise StorageUnavailable("The temporary source is temporarily unavailable.") from exc


def _signing_key(secret_key: str, date_stamp: str, region: str, service: str) -> bytes:
    key = f"AWS4{secret_key}".encode()
    for value in date_stamp, region, service, "aws4_request":
        key = hmac.new(key, value.encode(), hashlib.sha256).digest()
    return key


def build_object_storage(settings: Settings) -> ObjectStorage:
    if settings.object_storage_provider == "s3":
        if not settings.object_storage_endpoint or not settings.object_storage_bucket:
            raise RuntimeError(
                "MEMORA_OBJECT_STORAGE_ENDPOINT and MEMORA_OBJECT_STORAGE_BUCKET are required "
                "when MEMORA_OBJECT_STORAGE_PROVIDER is s3"
            )
        if not settings.object_storage_access_key or not settings.object_storage_secret_key:
            raise RuntimeError(
                "MEMORA_OBJECT_STORAGE_ACCESS_KEY and MEMORA_OBJECT_STORAGE_SECRET_KEY are "
                "required when MEMORA_OBJECT_STORAGE_PROVIDER is s3"
            )
        return S3ObjectStorage(
            endpoint=settings.object_storage_endpoint,
            region=settings.object_storage_region,
            bucket=settings.object_storage_bucket,
            access_key=settings.object_storage_access_key.get_secret_value(),
            secret_key=settings.object_storage_secret_key.get_secret_value(),
        )
    return MemoryObjectStorage()
