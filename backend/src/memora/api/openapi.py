from __future__ import annotations

from typing import Any

from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi
from pydantic import BaseModel

from memora.api.operation_ids import OPERATION_IDS, OperationId
from memora.api.v1.schemas.common import AsyncOperation, PageMeta, PageParams
from memora.api.v1.schemas.errors import ErrorEnvelope
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders

HTTP_METHODS = frozenset({"get", "put", "post", "delete", "options", "head", "patch", "trace"})
MUTATION_METHODS = frozenset({"post", "put", "patch", "delete"})
NATURALLY_IDEMPOTENT_OPERATION_IDS = frozenset({OperationId.DELETE_DEVICE.value})
CLIENT_OPERATION_ID_OPERATION_IDS = frozenset({OperationId.SUBMIT_ATTEMPT.value})
ALLOWED_PATHS = ("/v1", "/health")

TAGS = [
    {"name": "health", "description": "Liveness and readiness checks."},
    {"name": "session", "description": "Authentication session and device lifecycle."},
    {"name": "profile", "description": "Student profile, preferences and consent status."},
    {"name": "curriculum", "description": "Subjects, learning paths and concept progress."},
    {"name": "learning-updates", "description": "Learning material ingestion and status."},
    {"name": "verification", "description": "Extraction verification and learning-path commit."},
    {"name": "missions", "description": "Daily missions, items, attempts and results."},
    {"name": "progress", "description": "Seabed, reef and learning statistics."},
    {"name": "rewards", "description": "Reward inventory and placement."},
    {"name": "reports", "description": "Question reports and dispute status."},
    {"name": "privacy", "description": "Export and account-deletion workflows."},
]

ERROR_RESPONSE_DESCRIPTIONS = {
    400: "Malformed request, invalid cursor or invalid state.",
    401: "Missing, invalid or expired access token.",
    403: "Consent, recent authentication or operation not allowed.",
    404: "Resource not found in the authenticated scope.",
    409: "Version, idempotency or workflow conflict.",
    413: "Payload too large.",
    415: "Unsupported media type.",
    422: "Validation failed.",
    429: "Rate limited.",
    503: "Temporarily unavailable.",
}

COMMON_ERROR_RESPONSES: dict[int, dict[str, Any]] = {
    status: {
        "description": description,
        "content": {
            "application/json": {
                "schema": {"$ref": "#/components/schemas/ErrorEnvelope"},
            }
        },
    }
    for status, description in ERROR_RESPONSE_DESCRIPTIONS.items()
}

COMMON_PARAMETERS = {
    "IdempotencyKey": {
        "name": "Idempotency-Key",
        "in": "header",
        "required": True,
        "description": "Client-generated key scoped to the principal and operation.",
        "schema": {"type": "string", "minLength": 16, "maxLength": 255},
    },
    "IfNoneMatch": {
        "name": "If-None-Match",
        "in": "header",
        "required": False,
        "description": "ETag cache validation for optional reads.",
        "schema": {"type": "string"},
    },
}

COMMON_RESPONSE_HEADERS = {
    "X-Correlation-ID": {
        "description": "Effective correlation identifier echoed by the server.",
        "schema": {"type": "string"},
    },
    "X-Request-ID": {
        "description": "Support and tracing identifier.",
        "schema": {"type": "string"},
    },
}

BEARER_AUTH_SCHEME = {
    "type": "http",
    "scheme": "bearer",
    "bearerFormat": "JWT",
    "description": "Short-lived OIDC-issued access token.",
}

SHARED_MODELS: tuple[type[BaseModel], ...] = (
    ErrorEnvelope,
    PageMeta,
    PageParams,
    AsyncOperation,
    RequestHeaders,
    IdempotencyHeaders,
)


class ContractError(ValueError):
    pass


def _require(condition: bool, message: str) -> None:
    if not condition:
        raise ContractError(message)


def _resolve_ref(schema: dict[str, Any], reference: str) -> dict[str, Any]:
    if not reference.startswith("#/"):
        return {}
    current: Any = schema
    for part in reference[2:].split("/"):
        part = part.replace("~1", "/").replace("~0", "~")
        if not isinstance(current, dict) or part not in current:
            return {}
        current = current[part]
    return current if isinstance(current, dict) else {}


def _has_required_body_client_operation_id(
    schema: dict[str, Any], operation: dict[str, Any]
) -> bool:
    request_body = operation.get("requestBody")
    if not isinstance(request_body, dict) or request_body.get("required") is not True:
        return False

    content = request_body.get("content", {})
    for media_type in ("application/json", "application/*+json"):
        request_schema = content.get(media_type, {}).get("schema")
        if not isinstance(request_schema, dict):
            continue
        reference = request_schema.get("$ref")
        resolved = _resolve_ref(schema, reference) if reference else request_schema
        if (
            isinstance(resolved, dict)
            and "client_operation_id" in resolved.get("properties", {})
            and "client_operation_id" in resolved.get("required", [])
        ):
            return True
    return False


def _has_idempotency_key(schema: dict[str, Any], operation: dict[str, Any]) -> bool:
    parameters = schema.get("components", {}).get("parameters", {})
    for parameter in operation.get("parameters", []):
        reference = parameter.get("$ref")
        if reference:
            name = reference.rsplit("/", 1)[-1]
            if name in {"IdempotencyKey", "Idempotency-Key"} and name in parameters:
                resolved = parameters[name]
                if resolved.get("required", False):
                    return True
            continue
        if (
            parameter.get("name") == "Idempotency-Key"
            and parameter.get("in") == "header"
            and parameter.get("required", False)
        ):
            return True
    return False


def _is_error_status(status: str) -> bool:
    if status.isdigit():
        return 400 <= int(status) < 600
    return status.upper() in {"DEFAULT", "4XX", "5XX"}


def _validate_error_response(operation_id: str, status: str, response: dict[str, Any]) -> None:
    if not _is_error_status(status):
        return
    _require(isinstance(response, dict), f"{operation_id} {status} must be a response object")
    response_schema = response.get("content", {}).get("application/json", {}).get("schema")
    _require(
        response_schema == {"$ref": "#/components/schemas/ErrorEnvelope"},
        f"{operation_id} {status} must use ErrorEnvelope",
    )


def _validate_operation(
    schema: dict[str, Any],
    path: str,
    method: str,
    operation: dict[str, Any],
    seen: set[str],
) -> None:
    _require(isinstance(operation, dict), f"{method.upper()} {path} must be an operation object")
    operation_id = operation.get("operationId")
    _require(
        isinstance(operation_id, str) and bool(operation_id),
        f"{method.upper()} {path} must define operationId",
    )
    _require(operation_id in OPERATION_IDS, f"{operation_id} is not registered")
    _require(operation_id not in seen, f"Duplicate operationId {operation_id}")
    seen.add(operation_id)

    tags = operation.get("tags")
    _require(isinstance(tags, list) and bool(tags), f"{operation_id} must define tags")

    responses = operation.get("responses")
    _require(
        isinstance(responses, dict) and bool(responses),
        f"{operation_id} must define responses",
    )

    if path == "/v1" or path.startswith("/v1/"):
        _require(
            operation.get("security") == [{"bearerAuth": []}],
            f"{operation_id} must use bearerAuth",
        )
        # API §20: /v1 operations must document error responses using ErrorEnvelope
        _require(
            any(
                (isinstance(status, int) and 400 <= status < 600)
                or (isinstance(status, str) and status.isdigit() and 400 <= int(status) < 600)
                for status in responses
            ),
            f"{operation_id} must define error responses (4xx/5xx) for /v1 operations",
        )

    if method in MUTATION_METHODS:
        if operation_id in CLIENT_OPERATION_ID_OPERATION_IDS:
            _require(
                _has_required_body_client_operation_id(schema, operation),
                f"{operation_id} must require client_operation_id in the request body",
            )
        else:
            _require(
                operation_id in NATURALLY_IDEMPOTENT_OPERATION_IDS
                or _has_idempotency_key(schema, operation),
                f"{operation_id} must reference the Idempotency-Key parameter",
            )

    for status, response in responses.items():
        _validate_error_response(operation_id, str(status), response)


def validate_contract(schema: dict[str, Any]) -> None:
    components = schema.get("components", {})
    _require("bearerAuth" in components.get("securitySchemes", {}), "Missing bearerAuth scheme")
    _require(
        "IdempotencyKey" in components.get("parameters", {}), "Missing Idempotency-Key parameter"
    )
    _require("ErrorEnvelope" in components.get("schemas", {}), "Missing ErrorEnvelope schema")

    paths = schema.get("paths")
    _require(isinstance(paths, dict) and bool(paths), "OpenAPI must contain at least one path")

    seen: set[str] = set()
    for path, path_item in paths.items():
        _require(
            path == ALLOWED_PATHS[0]
            or path.startswith(f"{ALLOWED_PATHS[0]}/")
            or path == ALLOWED_PATHS[1]
            or path.startswith(f"{ALLOWED_PATHS[1]}/"),
            f"Undocumented path {path}",
        )
        _require(isinstance(path_item, dict), f"Invalid path item {path}")
        for method, operation in path_item.items():
            if method not in HTTP_METHODS:
                continue
            _validate_operation(schema, path, method, operation, seen)


def _inject_shared_schemas(components: dict[str, Any]) -> None:
    schemas = components.setdefault("schemas", {})
    for model in SHARED_MODELS:
        model_schema = model.model_json_schema(ref_template="#/components/schemas/{model}")
        definitions = model_schema.pop("$defs", {})
        schemas[model.__name__] = model_schema
        for name, definition in definitions.items():
            schemas[name] = definition


def _inject_common_response_headers(schema: dict[str, Any]) -> None:
    for path_item in schema.get("paths", {}).values():
        for method, operation in path_item.items():
            if method not in HTTP_METHODS:
                continue
            for response in operation.get("responses", {}).values():
                if not isinstance(response, dict):
                    continue
                headers = response.setdefault("headers", {})
                for name, header in COMMON_RESPONSE_HEADERS.items():
                    headers.setdefault(name, header)


def custom_openapi(app: FastAPI) -> dict[str, Any]:
    if app.openapi_schema:
        return app.openapi_schema

    schema = get_openapi(
        title=app.title,
        version=app.version,
        openapi_version="3.1.0",
        description=app.description,
        routes=app.routes,
        tags=TAGS,
    )
    components = schema.setdefault("components", {})
    components.setdefault("securitySchemes", {})["bearerAuth"] = BEARER_AUTH_SCHEME
    components.setdefault("parameters", {}).update(COMMON_PARAMETERS)
    components.setdefault("headers", {}).update(COMMON_RESPONSE_HEADERS)
    _inject_shared_schemas(components)
    _inject_common_response_headers(schema)
    validate_contract(schema)
    app.openapi_schema = schema
    return schema
