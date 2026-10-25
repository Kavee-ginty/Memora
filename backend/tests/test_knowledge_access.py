"""Tests for CurriculumService and Knowledge Access methods."""

from unittest.mock import MagicMock
from uuid import uuid4

import pytest

from memora.modules.curriculum.service import CurriculumService


def test_service_get_subject_by_code() -> None:
    connection = MagicMock()
    mock_row = {"id": uuid4(), "code": "physics", "name": "Physics", "status": "approved"}
    connection.execute.return_value.mappings.return_value.first.return_value = mock_row

    service = CurriculumService(connection)
    result = service.get_subject_by_code("physics")

    assert result == mock_row
    query_str = str(connection.execute.call_args[0][0])
    assert "FROM subjects WHERE code = :code" in query_str


def test_service_get_curriculum_version() -> None:
    connection = MagicMock()
    subject_id = uuid4()
    mock_row = {
        "id": uuid4(),
        "subject_id": subject_id,
        "edition_code": "GCE-AL-PHYSICS-2017",
        "language_medium": "en",
        "status": "approved",
    }
    connection.execute.return_value.mappings.return_value.first.return_value = mock_row

    service = CurriculumService(connection)
    result = service.get_curriculum_version(subject_id)

    assert result == mock_row
    query_str = str(connection.execute.call_args[0][0])
    assert "FROM curriculum_versions" in query_str


def test_service_get_learning_objectives() -> None:
    connection = MagicMock()
    curriculum_id = uuid4()
    mock_rows = [
        {"id": uuid4(), "objective_code": "LO-PHYS-01-MEAS", "sequence_no": 1},
        {"id": uuid4(), "objective_code": "LO-PHYS-02-MECH", "sequence_no": 2},
    ]
    connection.execute.return_value.mappings.return_value.all.return_value = mock_rows

    service = CurriculumService(connection)
    result = service.get_learning_objectives(curriculum_id)

    assert len(result) == 2
    assert result[0]["objective_code"] == "LO-PHYS-01-MEAS"


def test_service_get_concept_by_code() -> None:
    connection = MagicMock()
    mock_row = {
        "concept_id": uuid4(),
        "stable_code": "PHYS-MEC-NEWTON2",
        "concept_version_id": uuid4(),
        "title": "Newton's Second Law of Motion",
        "kind": "law",
        "version_no": 1,
    }
    connection.execute.return_value.mappings.return_value.first.return_value = mock_row

    service = CurriculumService(connection)
    result = service.get_concept_by_code("PHYS-MEC-NEWTON2")

    assert result == mock_row
    assert result["kind"] == "law"


def test_service_find_concepts_by_alias() -> None:
    connection = MagicMock()
    mock_rows = [
        {
            "concept_id": uuid4(),
            "stable_code": "PHYS-MEC-NEWTON2",
            "concept_version_id": uuid4(),
            "title": "Newton's Second Law of Motion",
            "alias_text": "F = ma",
            "is_preferred": False,
        }
    ]
    connection.execute.return_value.mappings.return_value.all.return_value = mock_rows

    service = CurriculumService(connection)
    result = service.find_concepts_by_alias("f = ma")

    assert len(result) == 1
    assert result[0]["stable_code"] == "PHYS-MEC-NEWTON2"
    query_params = connection.execute.call_args[0][1]
    assert query_params["normalized"] == "f = ma"


def test_service_get_prerequisites_bounded_depth() -> None:
    connection = MagicMock()
    version_id = uuid4()
    mock_rows = [
        {"concept_version_id": uuid4(), "stable_code": "PHYS-MEC-VELOCITY", "depth": 1},
        {"concept_version_id": uuid4(), "stable_code": "PHYS-MEC-DISPLACEMENT", "depth": 2},
    ]
    connection.execute.return_value.mappings.return_value.all.return_value = mock_rows

    service = CurriculumService(connection)
    result = service.get_prerequisites(version_id, max_depth=3)

    assert len(result) == 2
    assert result[0]["stable_code"] == "PHYS-MEC-VELOCITY"
    query_str = str(connection.execute.call_args[0][0])
    assert "WITH RECURSIVE prereqs AS" in query_str
    assert "p.depth < :max_depth" in query_str


def test_service_get_prerequisites_invalid_depth() -> None:
    connection = MagicMock()
    service = CurriculumService(connection)
    with pytest.raises(ValueError, match="max_depth must be at least 1"):
        service.get_prerequisites(uuid4(), max_depth=0)


def test_service_get_concept_claims() -> None:
    connection = MagicMock()
    version_id = uuid4()
    mock_rows = [
        {"id": uuid4(), "claim_type": "formula", "statement": "F = ma"},
        {"id": uuid4(), "claim_type": "definition", "statement": "Force definition"},
    ]
    connection.execute.return_value.mappings.return_value.all.return_value = mock_rows

    service = CurriculumService(connection)
    result = service.get_concept_claims(version_id)

    assert len(result) == 2
    assert result[0]["claim_type"] == "formula"


def test_validate_graph_integrity_passes_when_clean() -> None:
    connection = MagicMock()
    # Mocking all 5 validation queries returning no errors
    connection.execute.return_value.fetchall.side_effect = [
        [],  # no obj cycles
        [],  # no edge cycles
        [("prerequisite_of",), ("related_to",)],  # valid edge types
        [],  # no unmapped concepts
        [],  # no missing provenance
    ]

    service = CurriculumService(connection)
    result = service.validate_graph_integrity()

    assert result["valid"] is True
    assert len(result["errors"]) == 0


def test_validate_graph_integrity_fails_when_cycles_or_invalid_edges() -> None:
    connection = MagicMock()
    connection.execute.return_value.fetchall.side_effect = [
        [(uuid4(),)],  # objective cycle detected!
        [(uuid4(),)],  # edge cycle detected!
        [("prerequisite_of",), ("invalid_custom_edge",)],  # unallowlisted edge type!
        [(uuid4(), "PHYS-UNMAPPED")],  # unmapped concept!
        [(uuid4(),)],  # missing edge provenance!
    ]

    service = CurriculumService(connection)
    result = service.validate_graph_integrity()

    assert result["valid"] is False
    assert len(result["errors"]) == 5
    assert any("Cycle detected in learning_objectives" in e for e in result["errors"])
    assert any("Cycle detected in concept_edges" in e for e in result["errors"])
    assert any("Unallowlisted edge types found" in e for e in result["errors"])
    assert any("Concepts missing learning objective mapping" in e for e in result["errors"])
    assert any("Concept edges missing provenance" in e for e in result["errors"])
