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
    assert "FROM subjects" in query_str
    assert "status = 'approved'" in query_str


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
    assert "status = 'approved'" in query_str


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
    query_str = str(connection.execute.call_args[0][0])
    assert "status = 'approved'" in query_str


def test_service_get_concept_by_code() -> None:
    connection = MagicMock()
    subject_id = uuid4()
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
    result = service.get_concept_by_code("PHYS-MEC-NEWTON2", subject_id=subject_id)

    assert result == mock_row
    assert result["kind"] == "law"
    query_str = str(connection.execute.call_args[0][0])
    assert "c.status = 'approved'" in query_str
    assert "cv.content_status = 'approved'" in query_str
    assert "c.subject_id = :subject_id" in query_str


def test_service_find_concepts_by_alias() -> None:
    connection = MagicMock()
    subject_id = uuid4()
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
    result = service.find_concepts_by_alias("f = ma", subject_id=subject_id)

    assert len(result) == 1
    assert result[0]["stable_code"] == "PHYS-MEC-NEWTON2"
    query_params = connection.execute.call_args[0][1]
    assert query_params["normalized"] == "f = ma"
    assert query_params["subject_id"] == str(subject_id)
    assert query_params["limit"] == 20


def test_service_find_concepts_by_alias_bounds() -> None:
    connection = MagicMock()
    service = CurriculumService(connection)
    subject_id = uuid4()

    with pytest.raises(ValueError, match="limit must be between 1 and 50"):
        service.find_concepts_by_alias("test", subject_id=subject_id, limit=0)

    with pytest.raises(ValueError, match="limit must be between 1 and 50"):
        service.find_concepts_by_alias("test", subject_id=subject_id, limit=51)


def test_service_get_prerequisites_bounded_depth() -> None:
    connection = MagicMock()
    version_id = uuid4()
    mock_rows = [
        {"concept_version_id": uuid4(), "stable_code": "PHYS-MEC-VELOCITY", "depth": 1},
        {"concept_version_id": uuid4(), "stable_code": "PHYS-MEC-DISPLACEMENT", "depth": 2},
    ]
    connection.execute.return_value.mappings.return_value.all.return_value = mock_rows

    service = CurriculumService(connection)
    result = service.get_prerequisites(version_id, max_depth=3, result_limit=25)

    assert len(result) == 2
    assert result[0]["stable_code"] == "PHYS-MEC-VELOCITY"
    query_str = str(connection.execute.call_args[0][0])
    assert "WITH RECURSIVE prereqs AS" in query_str
    assert "p.depth < :max_depth" in query_str
    assert "LIMIT :result_limit" in query_str
    assert "c.status = 'approved'" in query_str
    assert "cv.content_status = 'approved'" in query_str


def test_service_get_prerequisites_invalid_depth() -> None:
    connection = MagicMock()
    service = CurriculumService(connection)
    with pytest.raises(ValueError, match="max_depth must be between 1 and 5"):
        service.get_prerequisites(uuid4(), max_depth=0)

    with pytest.raises(ValueError, match="max_depth must be between 1 and 5"):
        service.get_prerequisites(uuid4(), max_depth=6)


def test_service_get_prerequisites_invalid_result_limit() -> None:
    connection = MagicMock()
    service = CurriculumService(connection)
    with pytest.raises(ValueError, match="result_limit must be between 1 and 50"):
        service.get_prerequisites(uuid4(), result_limit=0)

    with pytest.raises(ValueError, match="result_limit must be between 1 and 50"):
        service.get_prerequisites(uuid4(), result_limit=51)


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
    query_str = str(connection.execute.call_args[0][0])
    assert "kc.status = 'approved'" in query_str
    assert "cv.content_status = 'approved'" in query_str


def test_validate_graph_integrity_passes_when_clean() -> None:
    connection = MagicMock()
    # Mocking all 6 validation queries returning no errors
    connection.execute.return_value.fetchall.side_effect = [
        [],  # 1. no obj cycles
        [],  # 2. no edge cycles
        [("prerequisite_of",), ("related_to",)],  # 3. valid edge types
        [],  # 4. no unmapped concepts
        [],  # 5. no missing edge provenance
        [],  # 6. no missing claim provenance
    ]

    service = CurriculumService(connection)
    result = service.validate_graph_integrity()

    assert result["valid"] is True
    assert len(result["errors"]) == 0


def test_validate_graph_integrity_fails_when_cycles_or_invalid_edges() -> None:
    connection = MagicMock()
    connection.execute.return_value.fetchall.side_effect = [
        [(uuid4(),)],  # 1. objective cycle detected!
        [(uuid4(),)],  # 2. edge cycle detected!
        [("prerequisite_of",), ("invalid_custom_edge",)],  # 3. unallowlisted edge type!
        [(uuid4(), "PHYS-UNMAPPED")],  # 4. unmapped concept!
        [(uuid4(),)],  # 5. missing edge provenance!
        [(uuid4(),)],  # 6. missing claim provenance!
    ]

    service = CurriculumService(connection)
    result = service.validate_graph_integrity()

    assert result["valid"] is False
    assert len(result["errors"]) == 6
    assert any("Cycle detected in learning_objectives" in e for e in result["errors"])
    assert any("Cycle detected in concept_edges" in e for e in result["errors"])
    assert any("Unallowlisted edge types found" in e for e in result["errors"])
    assert any("Concepts missing learning objective mapping" in e for e in result["errors"])
    assert any("Concept edges missing provenance" in e for e in result["errors"])
    assert any("Knowledge claims missing provenance" in e for e in result["errors"])
