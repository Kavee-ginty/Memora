"""Idempotent foundational database seeds for local and deployed environments."""

import json
from uuid import NAMESPACE_DNS, uuid5

from sqlalchemy import create_engine, text

from memora.core.config import get_settings
from memora.modules.curriculum.seed_data import (
    CONCEPT_EDGES,
    CONCEPTS_DATA,
    LEARNING_OBJECTIVES,
    PROVENANCE_NIE_2017,
    REWARD_DEFINITIONS,
)

PHYSICS_SUBJECT_ID = "10000000-0000-0000-0000-000000000001"
PHYSICS_CURRICULUM_ID = "20000000-0000-0000-0000-000000000001"

SUBJECT_SEED_SQL = text(
    """
    INSERT INTO subjects(id, code, name, status)
    VALUES (:subject_id, 'physics', 'Physics', 'approved')
    ON CONFLICT (code) DO NOTHING
    """
)
SUBJECT_ID_SQL = text("SELECT id FROM subjects WHERE code = 'physics'")
CURRICULUM_SEED_SQL = text(
    """
    INSERT INTO curriculum_versions(
        id, subject_id, authority, edition_code, language_medium, valid_from, status
    ) VALUES (
        :curriculum_id, :subject_id, 'National Institute of Education, Sri Lanka',
        'GCE-AL-PHYSICS-2017', 'en', DATE '2017-01-01', 'approved'
    ) ON CONFLICT (subject_id, edition_code, language_medium) DO NOTHING
    """
)
CURRICULUM_ID_SQL = text(
    """
    SELECT id FROM curriculum_versions
    WHERE subject_id = :subject_id
      AND edition_code = 'GCE-AL-PHYSICS-2017'
      AND language_medium = 'en'
    """
)

OBJECTIVE_SEED_SQL = text(
    """
    INSERT INTO learning_objectives(
        id, curriculum_version_id, objective_code, parent_objective_id,
        title, description, sequence_no, status
    ) VALUES (
        :id, :curriculum_version_id, :objective_code, :parent_objective_id,
        :title, :description, :sequence_no, :status
    ) ON CONFLICT (curriculum_version_id, objective_code) DO NOTHING
    """
)

CONCEPT_SEED_SQL = text(
    """
    INSERT INTO concepts(id, subject_id, stable_code, status)
    VALUES (:id, :subject_id, :stable_code, 'approved')
    ON CONFLICT (subject_id, stable_code) DO NOTHING
    """
)

CONCEPT_VERSION_SEED_SQL = text(
    """
    INSERT INTO concept_versions(
        id, concept_id, version_no, kind, title, definition,
        symbol_context, unit_context, content_status, reviewed_at
    ) VALUES (
        :id, :concept_id, 1, :kind, :title, :definition,
        CAST(:symbol_context AS jsonb), CAST(:unit_context AS jsonb), 'approved', now()
    ) ON CONFLICT (concept_id, version_no) DO NOTHING
    """
)

CONCEPT_ALIAS_SEED_SQL = text(
    """
    INSERT INTO concept_aliases(
        id, concept_version_id, alias_text, normalized_alias,
        language_code, alias_type, is_preferred
    ) VALUES (
        :id, :concept_version_id, :alias_text, :normalized_alias,
        'en', :alias_type, :is_preferred
    ) ON CONFLICT (id) DO NOTHING
    """
)

KNOWLEDGE_CLAIM_SEED_SQL = text(
    """
    INSERT INTO knowledge_claims(
        id, claim_group_id, concept_version_id, version_no, claim_type,
        statement, structured_value, status, provenance_type, provenance_ref, reviewed_at
    ) VALUES (
        :id, :claim_group_id, :concept_version_id, 1, :claim_type,
        :statement, CAST(:structured_value AS jsonb), 'approved',
        'syllabus_specification', :provenance_ref, now()
    ) ON CONFLICT (claim_group_id, version_no) DO NOTHING
    """
)

CONCEPT_EDGE_SEED_SQL = text(
    """
    INSERT INTO concept_edges(
        id, from_concept_version_id, to_concept_version_id, edge_type, confidence,
        status, provenance_type, provenance_ref, valid_from
    ) VALUES (
        :id, :from_concept_version_id, :to_concept_version_id, :edge_type, :confidence,
        'approved', 'syllabus_specification', :provenance_ref, now()
    ) ON CONFLICT (id) DO NOTHING
    """
)

CONCEPT_OBJECTIVE_MAP_SEED_SQL = text(
    """
    INSERT INTO concept_objective_maps(
        concept_version_id, learning_objective_id, mapping_type, coverage_weight,
        provenance_type, provenance_ref
    ) VALUES (
        :concept_version_id, :learning_objective_id, 'primary', 1.0,
        'curriculum_framework', :provenance_ref
    ) ON CONFLICT (concept_version_id, learning_objective_id, mapping_type) DO NOTHING
    """
)

REWARD_DEFINITION_SEED_SQL = text(
    """
    INSERT INTO reward_definitions(
        id, reward_code, reward_type, title, asset_key, xp_threshold, status
    ) VALUES (
        :id, :reward_code, :reward_type, :title, :asset_key, :xp_threshold, :status
    ) ON CONFLICT (reward_code) DO NOTHING
    """
)


def seed_database(database_url: str | None = None) -> None:
    """Seed foundational curriculum, knowledge graph, and progression data."""
    engine = create_engine(database_url or get_settings().database_url)
    with engine.begin() as connection:
        values = {"subject_id": PHYSICS_SUBJECT_ID, "curriculum_id": PHYSICS_CURRICULUM_ID}
        # Call 0: Subject seed
        connection.execute(SUBJECT_SEED_SQL, values)
        resolved_subject_id = connection.scalar(SUBJECT_ID_SQL)
        if resolved_subject_id is None:
            resolved_subject_id = PHYSICS_SUBJECT_ID
        values["subject_id"] = resolved_subject_id

        # Call 1: Curriculum version seed
        connection.execute(CURRICULUM_SEED_SQL, values)
        resolved_curriculum_id = connection.scalar(
            CURRICULUM_ID_SQL, {"subject_id": values["subject_id"]}
        )
        if resolved_curriculum_id is None:
            resolved_curriculum_id = PHYSICS_CURRICULUM_ID
        curriculum_id = str(resolved_curriculum_id)
        subject_id = str(resolved_subject_id)

        # 1. Learning Objectives
        obj_code_to_id: dict[str, str] = {}
        for obj in LEARNING_OBJECTIVES:
            obj_code_to_id[obj["objective_code"]] = obj["id"]
            connection.execute(
                OBJECTIVE_SEED_SQL,
                {
                    "id": obj["id"],
                    "curriculum_version_id": curriculum_id,
                    "objective_code": obj["objective_code"],
                    "parent_objective_id": obj["parent_objective_id"],
                    "title": obj["title"],
                    "description": obj["description"],
                    "sequence_no": obj["sequence_no"],
                    "status": obj["status"],
                },
            )

        # 2. Concepts, Versions, Aliases, Claims, and Objective Maps
        for cdata in CONCEPTS_DATA:
            concept_id = cdata["concept_id"]
            version_id = cdata["version_id"]

            connection.execute(
                CONCEPT_SEED_SQL,
                {"id": concept_id, "subject_id": subject_id, "stable_code": cdata["stable_code"]},
            )

            connection.execute(
                CONCEPT_VERSION_SEED_SQL,
                {
                    "id": version_id,
                    "concept_id": concept_id,
                    "kind": cdata["kind"],
                    "title": cdata["title"],
                    "definition": cdata["definition"],
                    "symbol_context": json.dumps(cdata["symbol_context"])
                    if cdata["symbol_context"]
                    else None,
                    "unit_context": json.dumps(cdata["unit_context"])
                    if cdata["unit_context"]
                    else None,
                },
            )

            for alias in cdata["aliases"]:
                alias_id = str(uuid5(NAMESPACE_DNS, f"memora:alias:{version_id}:{alias['text']}"))
                connection.execute(
                    CONCEPT_ALIAS_SEED_SQL,
                    {
                        "id": alias_id,
                        "concept_version_id": version_id,
                        "alias_text": alias["text"],
                        "normalized_alias": alias["text"].strip().lower(),
                        "alias_type": alias["type"],
                        "is_preferred": alias["is_preferred"],
                    },
                )

            for claim in cdata["claims"]:
                connection.execute(
                    KNOWLEDGE_CLAIM_SEED_SQL,
                    {
                        "id": claim["claim_id"],
                        "claim_group_id": claim["group_id"],
                        "concept_version_id": version_id,
                        "claim_type": claim["claim_type"],
                        "statement": claim["statement"],
                        "structured_value": json.dumps(claim.get("structured_value"))
                        if claim.get("structured_value")
                        else None,
                        "provenance_ref": PROVENANCE_NIE_2017,
                    },
                )

            objective_id = obj_code_to_id.get(cdata["objective_code"])
            if objective_id:
                connection.execute(
                    CONCEPT_OBJECTIVE_MAP_SEED_SQL,
                    {
                        "concept_version_id": version_id,
                        "learning_objective_id": objective_id,
                        "provenance_ref": PROVENANCE_NIE_2017,
                    },
                )

        # 3. Concept Edges
        for edge in CONCEPT_EDGES:
            connection.execute(
                CONCEPT_EDGE_SEED_SQL,
                {
                    "id": edge["id"],
                    "from_concept_version_id": edge["from_version_id"],
                    "to_concept_version_id": edge["to_version_id"],
                    "edge_type": edge["edge_type"],
                    "confidence": edge["confidence"],
                    "provenance_ref": PROVENANCE_NIE_2017,
                },
            )

        # 4. Reward Definitions
        for reward in REWARD_DEFINITIONS:
            connection.execute(
                REWARD_DEFINITION_SEED_SQL,
                {
                    "id": reward["id"],
                    "reward_code": reward["reward_code"],
                    "reward_type": reward["reward_type"],
                    "title": reward["title"],
                    "asset_key": reward["asset_key"],
                    "xp_threshold": reward["xp_threshold"],
                    "status": reward["status"],
                },
            )

    engine.dispose()


if __name__ == "__main__":
    seed_database()
