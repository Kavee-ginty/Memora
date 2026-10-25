import re
from pathlib import Path
from typing import Annotated

import pytest
from fastapi import Depends, FastAPI, Header
from pydantic import BaseModel

from memora.api.openapi import COMMON_ERROR_RESPONSES, ContractError, custom_openapi
from memora.api.operation_ids import OPERATION_IDS, OperationId
from memora.api.security import bearer_auth
from memora.api.v1.schemas.headers import IdempotencyHeaders
from memora.main import create_app

INVENTORY_PATH = (
    Path(__file__).resolve().parents[2] / "contracts" / "openapi" / "operation-inventory.md"
)
OPERATION_ID_PATTERN = re.compile(r"^[a-z][A-Za-z0-9]*$")
VERBS = frozenset(
    {
        "accept",
        "bootstrap",
        "cancel",
        "commit",
        "complete",
        "create",
        "delete",
        "finalize",
        "get",
        "list",
        "pause",
        "preview",
        "register",
        "retry",
        "revoke",
        "skip",
        "start",
        "submit",
        "update",
    }
)


def _inventory_rows() -> list[tuple[str, str, str]]:
    rows: list[tuple[str, str, str]] = []
    for line in INVENTORY_PATH.read_text(encoding="utf-8").splitlines():
        if not line.startswith("|"):
            continue
        cells = [cell.strip() for cell in line.strip("|").split("|")]
        if len(cells) != 7 or cells[0] in {"Domain", "---"}:
            continue
        method = cells[1]
        path = cells[2].strip("`")
        operation_id = cells[3].strip("`")
        rows.append((method, path, operation_id))
    return rows


def test_operation_ids_are_unique() -> None:
    assert len(OperationId.__members__) == len(OperationId)
    assert len(OperationId) == len(OPERATION_IDS)


def test_operation_ids_are_lower_camel_case() -> None:
    assert all(OPERATION_ID_PATTERN.fullmatch(operation_id) for operation_id in OPERATION_IDS)


def test_inventory_matches_registry() -> None:
    rows = _inventory_rows()
    inventory_ids = [operation_id for _, _, operation_id in rows]

    assert len(rows) == 52
    assert len(inventory_ids) == len(set(inventory_ids))
    assert set(inventory_ids) == set(OPERATION_IDS)


def test_inventory_paths_are_versioned() -> None:
    for _, path, _ in _inventory_rows():
        assert path.startswith(("/v1/", "/health/"))


def test_v1_operation_ids_start_with_verb() -> None:
    for _, path, operation_id in _inventory_rows():
        if not path.startswith("/v1/"):
            continue
        match = re.match(r"^[a-z]+", operation_id)
        assert match is not None
        assert match.group(0) in VERBS


def test_health_operation_ids_are_grandfathered() -> None:
    assert {"healthLive", "healthReady"} <= OPERATION_IDS


def test_shared_components_and_error_example() -> None:
    schema = custom_openapi(create_app())
    components = schema["components"]

    assert schema["openapi"] == "3.1.0"
    assert components["securitySchemes"]["bearerAuth"]["scheme"] == "bearer"
    assert components["parameters"]["IdempotencyKey"]["name"] == "Idempotency-Key"
    assert {"X-Correlation-ID", "X-Request-ID"} <= set(components["headers"])
    assert {
        "ErrorEnvelope",
        "ErrorDetail",
        "FieldError",
        "PageMeta",
        "PageParams",
        "AsyncOperation",
        "RequestHeaders",
        "IdempotencyHeaders",
    } <= set(components["schemas"])
    assert components["schemas"]["ErrorEnvelope"]["examples"][0]["error"]["code"] == (
        "validation_failed"
    )
    assert set(COMMON_ERROR_RESPONSES) == {400, 401, 403, 404, 409, 413, 415, 422, 429, 503}
    assert (
        "X-Correlation-ID" in schema["paths"]["/health/live"]["get"]["responses"]["200"]["headers"]
    )
    assert {
        "health",
        "session",
        "profile",
        "curriculum",
        "learning-updates",
        "verification",
        "missions",
        "progress",
        "rewards",
        "reports",
        "privacy",
    } == {tag["name"] for tag in schema["tags"]}


def test_health_operation_ids() -> None:
    schema = custom_openapi(create_app())

    assert schema["paths"]["/health/live"]["get"]["operationId"] == "healthLive"
    assert schema["paths"]["/health/ready"]["get"]["operationId"] == "healthReady"


def test_custom_openapi_is_cached() -> None:
    app = create_app()

    assert custom_openapi(app) is custom_openapi(app)


def test_contract_guard_rejects_unregistered_operation_id() -> None:
    app = FastAPI()

    @app.get(
        "/v1/example",
        operation_id="unknownOperation",
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="not registered"):
        custom_openapi(app)


def test_contract_guard_rejects_duplicate_operation_ids() -> None:
    app = FastAPI()

    @app.get(
        "/v1/first",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def first() -> dict[str, str]:
        return {"status": "ok"}

    @app.get(
        "/v1/second",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def second() -> dict[str, str]:
        return {"status": "ok"}

    with (
        pytest.warns(UserWarning, match="Duplicate Operation ID"),
        pytest.raises(ContractError, match="Duplicate operationId"),
    ):
        custom_openapi(app)


def test_contract_guard_rejects_undocumented_path() -> None:
    app = FastAPI()

    @app.get(
        "/admin/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="Undocumented path"):
        custom_openapi(app)


def test_contract_guard_rejects_missing_bearer() -> None:
    app = FastAPI()

    @app.get(
        "/v1/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="bearerAuth"):
        custom_openapi(app)


def test_contract_guard_rejects_non_envelope_error() -> None:
    app = FastAPI()
    responses = {
        **COMMON_ERROR_RESPONSES,
        409: {
            "description": "Conflict",
            "content": {"application/json": {"schema": {"type": "object"}}},
        },
    }

    @app.get(
        "/v1/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=responses,
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="409 must use ErrorEnvelope"):
        custom_openapi(app)


def test_contract_guard_rejects_missing_idempotency() -> None:
    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.CREATE_QUESTION_REPORT,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="Idempotency-Key"):
        custom_openapi(app)


def test_contract_guard_accepts_idempotency_header_model() -> None:
    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.CREATE_QUESTION_REPORT,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(headers: Annotated[IdempotencyHeaders, Header()]) -> dict[str, str]:
        return {"status": "ok"}

    operation = custom_openapi(app)["paths"]["/v1/example"]["post"]
    parameter_names = {parameter.get("name") for parameter in operation["parameters"]}

    assert "Idempotency-Key" in parameter_names
    assert operation["responses"]["422"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/ErrorEnvelope"
    }


def test_contract_guard_accepts_client_operation_id() -> None:
    class AttemptRequest(BaseModel):
        client_operation_id: str

    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.SUBMIT_ATTEMPT,
        tags=["missions"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(body: AttemptRequest) -> dict[str, str]:
        return {"status": "ok"}

    custom_openapi(app)


def test_contract_guard_rejects_missing_error_responses() -> None:
    app = FastAPI()

    @app.get(
        "/v1/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="error responses"):
        custom_openapi(app)


def test_contract_guard_rejects_optional_client_operation_id() -> None:
    class OptionalAttemptRequest(BaseModel):
        client_operation_id: str | None = None

    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.SUBMIT_ATTEMPT,
        tags=["missions"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(body: OptionalAttemptRequest) -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="client_operation_id in the request body"):
        custom_openapi(app)


def test_contract_guard_rejects_header_only_for_client_operation_id() -> None:
    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.SUBMIT_ATTEMPT,
        tags=["missions"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(
        idempotency_key: Annotated[str, Header(alias="Idempotency-Key")],
    ) -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="client_operation_id in the request body"):
        custom_openapi(app)


def test_contract_guard_rejects_query_only_for_client_operation_id() -> None:
    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.SUBMIT_ATTEMPT,
        tags=["missions"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(client_operation_id: str) -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="client_operation_id in the request body"):
        custom_openapi(app)


def test_contract_guard_rejects_optional_body_for_client_operation_id() -> None:
    class AttemptRequest(BaseModel):
        client_operation_id: str

    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.SUBMIT_ATTEMPT,
        tags=["missions"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(body: AttemptRequest | None = None) -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="client_operation_id in the request body"):
        custom_openapi(app)


def test_contract_guard_rejects_catchall_only_error_response() -> None:
    app = FastAPI()

    @app.get(
        "/v1/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses={
            "default": {
                "description": "Default error",
                "content": {
                    "application/json": {"schema": {"$ref": "#/components/schemas/ErrorEnvelope"}}
                },
            }
        },
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="error responses"):
        custom_openapi(app)


def test_contract_guard_rejects_non_envelope_numeric_error() -> None:
    app = FastAPI()

    @app.get(
        "/v1/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses={
            400: {
                "description": "Bad Request",
                "content": {"application/json": {"schema": {"type": "object"}}},
            }
        },
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="400 must use ErrorEnvelope"):
        custom_openapi(app)


def test_contract_guard_rejects_non_envelope_default_error() -> None:
    app = FastAPI()

    responses = dict(COMMON_ERROR_RESPONSES)
    responses["default"] = {
        "description": "Default error",
        "content": {"application/json": {"schema": {"type": "object"}}},
    }

    @app.get(
        "/v1/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=responses,
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="default must use ErrorEnvelope"):
        custom_openapi(app)


def test_contract_guard_rejects_non_envelope_wildcard_errors() -> None:
    for wildcard in ("4XX", "5XX"):
        app = FastAPI()
        responses = dict(COMMON_ERROR_RESPONSES)
        responses[wildcard] = {
            "description": f"{wildcard} error",
            "content": {"application/json": {"schema": {"type": "object"}}},
        }

        @app.get(
            "/v1/example",
            operation_id=OperationId.GET_HOME,
            tags=["reports"],
            dependencies=[Depends(bearer_auth)],
            responses=responses,
        )
        def example() -> dict[str, str]:
            return {"status": "ok"}

        with pytest.raises(ContractError, match=f"{wildcard} must use ErrorEnvelope"):
            custom_openapi(app)


def test_contract_guard_accepts_envelope_catchall_error() -> None:
    app = FastAPI()
    responses = dict(COMMON_ERROR_RESPONSES)
    responses["default"] = {
        "description": "Default catch-all error",
        "content": {"application/json": {"schema": {"$ref": "#/components/schemas/ErrorEnvelope"}}},
    }

    @app.get(
        "/v1/example",
        operation_id=OperationId.GET_HOME,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=responses,
    )
    def example() -> dict[str, str]:
        return {"status": "ok"}

    schema = custom_openapi(app)
    assert schema["paths"]["/v1/example"]["get"]["responses"]["default"] is not None


def test_contract_guard_rejects_optional_idempotency_header() -> None:
    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.CREATE_QUESTION_REPORT,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(
        idempotency_key: Annotated[str | None, Header(alias="Idempotency-Key")] = None,
    ) -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="Idempotency-Key"):
        custom_openapi(app)


def test_contract_guard_rejects_client_operation_id_on_unauthorized_operation() -> None:
    class AttemptRequest(BaseModel):
        client_operation_id: str

    app = FastAPI()

    @app.post(
        "/v1/example",
        operation_id=OperationId.CREATE_QUESTION_REPORT,
        tags=["reports"],
        dependencies=[Depends(bearer_auth)],
        responses=COMMON_ERROR_RESPONSES,
    )
    def example(body: AttemptRequest) -> dict[str, str]:
        return {"status": "ok"}

    with pytest.raises(ContractError, match="Idempotency-Key"):
        custom_openapi(app)
