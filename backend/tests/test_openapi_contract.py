import re
from pathlib import Path

from memora.api.operation_ids import OPERATION_IDS, OperationId

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
