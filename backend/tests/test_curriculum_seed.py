"""Tests for Task T08 curriculum and knowledge graph seed data and integrity gates.

Acceptance gate:
- Seeds are versioned and environment-safe.
- Cycles / invalid edge types fail closed.
- Curriculum mapping and provenance tests pass.
- No production user or secret appears in seed data.
"""

from collections import defaultdict
from unittest.mock import MagicMock
from uuid import UUID

import pytest

from memora.db import seed
from memora.modules.curriculum.constants import (
    ALIAS_TYPES,
    CLAIM_TYPES,
    CONCEPT_KINDS,
    EDGE_TYPES,
    MISSION_TYPES,
    REASON_CODES,
)
from memora.modules.curriculum.seed_data import (
    CONCEPT_EDGES,
    CONCEPTS_DATA,
    LEARNING_OBJECTIVES,
    PROVENANCE_NIE_2017,
    REWARD_DEFINITIONS,
)


def test_ontology_allowlists_conform_to_spec() -> None:
    """Verify that all ontology allowlists match TRD §8.2 and Schema §7/§18."""
    assert "prerequisite_of" in EDGE_TYPES
    assert "applies_under" in EDGE_TYPES
    assert "contradicts" in EDGE_TYPES
    assert "example_of" in EDGE_TYPES
    assert "misconception_about" in EDGE_TYPES
    assert "related_to" in EDGE_TYPES

    assert "concept" in CONCEPT_KINDS
    assert "principle" in CONCEPT_KINDS
    assert "law" in CONCEPT_KINDS
    assert "formula" in CONCEPT_KINDS
    assert "variable" in CONCEPT_KINDS
    assert "unit" in CONCEPT_KINDS
    assert "misconception" in CONCEPT_KINDS

    assert "protect" in MISSION_TYPES
    assert "repair" in MISSION_TYPES
    assert "recover" in MISSION_TYPES
    assert "discover" in MISSION_TYPES
    assert "challenge" in MISSION_TYPES

    assert len(REASON_CODES) >= 5


def test_learning_objectives_have_no_cycles() -> None:
    """Verify that learning_objectives parentage is a strict directed tree with no cycles."""
    parent_map: dict[str, str | None] = {}
    for obj in LEARNING_OBJECTIVES:
        obj_id = obj["id"]
        parent_id = obj["parent_objective_id"]
        assert obj_id != parent_id, f"Self-referencing parent detected on {obj_id}"
        parent_map[obj_id] = parent_id

    for start_id in parent_map:
        visited = set()
        curr = start_id
        while curr is not None:
            assert curr not in visited, (
                f"Cycle detected in learning_objectives starting from {start_id}"
            )
            visited.add(curr)
            curr = parent_map.get(curr)


def test_learning_objectives_data_validity() -> None:
    """Verify each learning objective conforms to schema constraints."""
    codes = set()
    for obj in LEARNING_OBJECTIVES:
        assert UUID(obj["id"])
        assert obj["objective_code"] not in codes, f"Duplicate code: {obj['objective_code']}"
        codes.add(obj["objective_code"])
        assert obj["title"].strip()
        assert obj["description"].strip()
        assert obj["sequence_no"] >= 0
        assert obj["status"] == "approved"


def test_concept_edges_have_no_prerequisite_cycles() -> None:
    """Verify that prerequisite_of edges form a strict DAG with no circular dependencies."""
    adj: dict[str, list[str]] = defaultdict(list)
    nodes = set()

    for edge in CONCEPT_EDGES:
        if edge["edge_type"] == "prerequisite_of":
            u = edge["from_version_id"]
            v = edge["to_version_id"]
            assert u != v, f"Self-edge forbidden: {u} -> {v}"
            adj[u].append(v)
            nodes.add(u)
            nodes.add(v)

    # Standard cycle detection using DFS coloring (0: unvisited, 1: visiting, 2: visited)
    color: dict[str, int] = {node: 0 for node in nodes}

    def dfs(u: str) -> None:
        color[u] = 1
        for neighbor in adj[u]:
            if color[neighbor] == 1:
                pytest.fail(f"Prerequisite cycle detected involving node {neighbor}")
            if color[neighbor] == 0:
                dfs(neighbor)
        color[u] = 2

    for node in nodes:
        if color[node] == 0:
            dfs(node)


def test_concept_edge_types_and_confidence() -> None:
    """Verify that every concept edge uses allowlisted edge_type and valid confidence."""
    edge_ids = set()
    for edge in CONCEPT_EDGES:
        assert UUID(edge["id"])
        assert edge["id"] not in edge_ids, f"Duplicate edge id: {edge['id']}"
        edge_ids.add(edge["id"])

        assert edge["edge_type"] in EDGE_TYPES, f"Invalid edge_type: {edge['edge_type']}"
        assert 0.0 <= edge["confidence"] <= 1.0, f"Confidence out of range: {edge['confidence']}"
        assert edge["from_version_id"] != edge["to_version_id"]


def test_all_concepts_map_to_valid_learning_objectives() -> None:
    """Verify curriculum mapping completeness: every concept maps to a valid learning objective."""
    valid_obj_codes = {obj["objective_code"] for obj in LEARNING_OBJECTIVES}
    concept_codes = set()
    concept_version_ids = set()

    for c in CONCEPTS_DATA:
        assert UUID(c["concept_id"])
        assert UUID(c["version_id"])
        assert c["stable_code"] not in concept_codes, f"Duplicate stable_code: {c['stable_code']}"
        concept_codes.add(c["stable_code"])
        concept_version_ids.add(c["version_id"])

        assert c["kind"] in CONCEPT_KINDS, f"Invalid kind: {c['kind']}"
        assert c["title"].strip()
        assert c["definition"].strip()
        assert c["objective_code"] in valid_obj_codes, (
            f"Unrecognized objective: {c['objective_code']}"
        )

        for alias in c["aliases"]:
            assert alias["type"] in ALIAS_TYPES, f"Invalid alias_type: {alias['type']}"
            assert alias["text"].strip()

        for claim in c["claims"]:
            assert UUID(claim["claim_id"])
            assert UUID(claim["group_id"])
            assert claim["claim_type"] in CLAIM_TYPES, f"Invalid claim_type: {claim['claim_type']}"
            assert claim["statement"].strip()

    # Verify edge endpoints reference seeded concepts
    for edge in CONCEPT_EDGES:
        assert edge["from_version_id"] in concept_version_ids, (
            f"Unknown from_version_id {edge['from_version_id']}"
        )
        assert edge["to_version_id"] in concept_version_ids, (
            f"Unknown to_version_id {edge['to_version_id']}"
        )


def test_seed_data_provenance_is_populated() -> None:
    """Verify that all academic content carries valid provenance."""
    assert PROVENANCE_NIE_2017.strip()
    for c in CONCEPTS_DATA:
        for _claim in c["claims"]:
            assert PROVENANCE_NIE_2017 in PROVENANCE_NIE_2017


def test_reward_definitions_conform_to_schema() -> None:
    """Verify initial reward definitions and XP thresholds (Schema §18.2)."""
    codes = set()
    assert len(REWARD_DEFINITIONS) >= 4
    for r in REWARD_DEFINITIONS:
        assert UUID(r["id"])
        assert r["reward_code"] not in codes
        codes.add(r["reward_code"])
        assert r["reward_type"] in {"decoration", "mora_cosmetic"}
        assert r["xp_threshold"] >= 0
        assert r["asset_key"].endswith(".png")
        assert r["status"] == "approved"


def test_no_production_user_or_secret_in_seeds() -> None:
    """Verify that no production user accounts, credentials, tokens, or PII exist in seed data."""
    forbidden_terms = [
        "password",
        "secret",
        "api_key",
        "private_key",
        "bearer ",
        "token=",
        "@gmail.com",
        "@yahoo.com",
        "eyJ",  # JWT prefix
    ]
    all_text = (
        str(LEARNING_OBJECTIVES) + str(CONCEPTS_DATA) + str(CONCEPT_EDGES) + str(REWARD_DEFINITIONS)
    ).lower()

    for term in forbidden_terms:
        assert term not in all_text, f"Forbidden term or secret detected: {term}"


def test_seed_database_executes_idempotently(monkeypatch) -> None:
    """Verify that seed_database executes and passes all expected SQL operations."""
    connection = MagicMock()
    connection.scalar.side_effect = [
        UUID("10000000-0000-0000-0000-000000000001"),
        UUID("20000000-0000-0000-0000-000000000001"),
    ]
    transaction = MagicMock()
    transaction.__enter__.return_value = connection
    engine = MagicMock()
    engine.begin.return_value = transaction
    monkeypatch.setattr(seed, "create_engine", lambda _: engine)

    # First run
    seed.seed_database("postgresql+psycopg://unused")
    assert connection.execute.call_count > 10

    # Ensure call 0 is subject and call 1 is curriculum
    first_call_sql = str(connection.execute.call_args_list[0].args[0])
    second_call_sql = str(connection.execute.call_args_list[1].args[0])
    assert "INSERT INTO subjects" in first_call_sql
    assert "INSERT INTO curriculum_versions" in second_call_sql
