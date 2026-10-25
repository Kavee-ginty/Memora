"""Bounded authorized knowledge access methods for curriculum and knowledge graph.

Implements TRD §7.2, §8.1-8.2:
- Concept and claim lookup by stable code and normalized alias.
- Bounded recursive Common Table Expression (CTE) for prerequisite traversal.
- Curriculum-scoped objective tree resolution.
- Graph integrity and cycle validation.
"""

from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from memora.modules.curriculum.constants import EDGE_TYPES


class CurriculumService:
    """Service providing bounded, authorized access to curriculum and knowledge graph."""

    def __init__(self, connection: Connection) -> None:
        self.connection = connection

    def get_subject_by_code(self, code: str = "physics") -> dict[str, Any] | None:
        """Retrieve subject record by its unique code."""
        query = text("SELECT id, code, name, status, created_at FROM subjects WHERE code = :code")
        row = self.connection.execute(query, {"code": code}).mappings().first()
        return dict(row) if row else None

    def get_curriculum_version(
        self,
        subject_id: UUID | str,
        edition_code: str = "GCE-AL-PHYSICS-2017",
        language_medium: str = "en",
    ) -> dict[str, Any] | None:
        """Retrieve curriculum version record."""
        query = text(
            """
            SELECT id, subject_id, authority, edition_code, language_medium,
                   valid_from, valid_to, status
            FROM curriculum_versions
            WHERE subject_id = :subject_id
              AND edition_code = :edition_code
              AND language_medium = :language_medium
            """
        )
        row = (
            self.connection.execute(
                query,
                {
                    "subject_id": str(subject_id),
                    "edition_code": edition_code,
                    "language_medium": language_medium,
                },
            )
            .mappings()
            .first()
        )
        return dict(row) if row else None

    def get_learning_objectives(self, curriculum_version_id: UUID | str) -> list[dict[str, Any]]:
        """Retrieve ordered hierarchical learning objectives for a curriculum version."""
        query = text(
            """
            SELECT id, curriculum_version_id, objective_code, parent_objective_id,
                   title, description, sequence_no, status
            FROM learning_objectives
            WHERE curriculum_version_id = :curriculum_version_id
            ORDER BY sequence_no, objective_code
            """
        )
        rows = (
            self.connection.execute(query, {"curriculum_version_id": str(curriculum_version_id)})
            .mappings()
            .all()
        )
        return [dict(r) for r in rows]

    def get_concept_by_code(
        self, stable_code: str, subject_id: UUID | str | None = None
    ) -> dict[str, Any] | None:
        """Retrieve a concept and its latest approved version by stable code."""
        query = text(
            """
            SELECT c.id AS concept_id, c.subject_id, c.stable_code, c.status AS concept_status,
                   cv.id AS concept_version_id, cv.version_no, cv.kind, cv.title, cv.definition,
                   cv.symbol_context, cv.unit_context, cv.content_status
            FROM concepts c
            JOIN concept_versions cv ON cv.concept_id = c.id
            WHERE c.stable_code = :stable_code
              AND (:subject_id IS NULL OR c.subject_id = :subject_id)
              AND cv.content_status = 'approved'
            ORDER BY cv.version_no DESC
            LIMIT 1
            """
        )
        row = (
            self.connection.execute(
                query,
                {"stable_code": stable_code, "subject_id": str(subject_id) if subject_id else None},
            )
            .mappings()
            .first()
        )
        return dict(row) if row else None

    def find_concepts_by_alias(
        self, alias_query: str, subject_id: UUID | str | None = None, limit: int = 20
    ) -> list[dict[str, Any]]:
        """Find concepts matching a normalized alias term or symbol (used for note ingestion)."""
        normalized = alias_query.strip().lower()
        query = text(
            """
            SELECT DISTINCT c.id AS concept_id, c.stable_code, cv.id AS concept_version_id,
                            cv.title, cv.kind, ca.alias_text, ca.alias_type, ca.is_preferred
            FROM concept_aliases ca
            JOIN concept_versions cv ON cv.id = ca.concept_version_id
            JOIN concepts c ON c.id = cv.concept_id
            WHERE ca.normalized_alias = :normalized
              AND (:subject_id IS NULL OR c.subject_id = :subject_id)
              AND cv.content_status = 'approved'
            ORDER BY ca.is_preferred DESC, cv.title
            LIMIT :limit
            """
        )
        rows = (
            self.connection.execute(
                query,
                {
                    "normalized": normalized,
                    "subject_id": str(subject_id) if subject_id else None,
                    "limit": limit,
                },
            )
            .mappings()
            .all()
        )
        return [dict(r) for r in rows]

    def get_prerequisites(
        self, concept_version_id: UUID | str, max_depth: int = 5
    ) -> list[dict[str, Any]]:
        """Bounded recursive CTE traversal to find all prerequisites of a concept version."""
        if max_depth < 1:
            raise ValueError("max_depth must be at least 1")

        query = text(
            """
            WITH RECURSIVE prereqs AS (
                SELECT
                    e.from_concept_version_id,
                    e.to_concept_version_id,
                    e.edge_type,
                    e.confidence,
                    1 AS depth
                FROM concept_edges e
                WHERE e.to_concept_version_id = :concept_version_id
                  AND e.edge_type = 'prerequisite_of'
                  AND e.status = 'approved'
                  AND (e.valid_to IS NULL OR e.valid_to > now())
                UNION ALL
                SELECT
                    e.from_concept_version_id,
                    e.to_concept_version_id,
                    e.edge_type,
                    e.confidence,
                    p.depth + 1 AS depth
                FROM concept_edges e
                JOIN prereqs p ON e.to_concept_version_id = p.from_concept_version_id
                WHERE e.edge_type = 'prerequisite_of'
                  AND e.status = 'approved'
                  AND (e.valid_to IS NULL OR e.valid_to > now())
                  AND p.depth < :max_depth
            )
            SELECT DISTINCT
                cv.id AS concept_version_id,
                c.id AS concept_id,
                c.stable_code,
                cv.title,
                cv.kind,
                cv.version_no,
                p.depth
            FROM prereqs p
            JOIN concept_versions cv ON cv.id = p.from_concept_version_id
            JOIN concepts c ON c.id = cv.concept_id
            ORDER BY p.depth, c.stable_code
            """
        )
        rows = (
            self.connection.execute(
                query, {"concept_version_id": str(concept_version_id), "max_depth": max_depth}
            )
            .mappings()
            .all()
        )
        return [dict(r) for r in rows]

    def get_concept_claims(self, concept_version_id: UUID | str) -> list[dict[str, Any]]:
        """Retrieve approved knowledge claims for a concept version."""
        query = text(
            """
            SELECT id, claim_group_id, concept_version_id, version_no, claim_type,
                   statement, structured_value, status, provenance_type, provenance_ref
            FROM knowledge_claims
            WHERE concept_version_id = :concept_version_id
              AND status = 'approved'
            ORDER BY claim_type, version_no
            """
        )
        rows = (
            self.connection.execute(query, {"concept_version_id": str(concept_version_id)})
            .mappings()
            .all()
        )
        return [dict(r) for r in rows]

    def validate_graph_integrity(
        self, curriculum_version_id: UUID | str | None = None
    ) -> dict[str, Any]:
        """Perform cycle detection, edge type validation, mapping and provenance checks."""
        results: dict[str, Any] = {"valid": True, "errors": []}

        # 1. Cycle detection in learning_objectives hierarchy
        obj_cycle_query = text(
            """
            WITH RECURSIVE obj_path AS (
                SELECT id, parent_objective_id, ARRAY[id] AS path, false AS is_cycle
                FROM learning_objectives
                WHERE parent_objective_id IS NOT NULL
                UNION ALL
                SELECT lo.id, lo.parent_objective_id, p.path || lo.id, lo.id = ANY(p.path)
                FROM learning_objectives lo
                JOIN obj_path p ON lo.id = p.parent_objective_id
                WHERE NOT p.is_cycle AND array_length(p.path, 1) < 20
            )
            SELECT id FROM obj_path WHERE is_cycle
            """
        )
        obj_cycles = self.connection.execute(obj_cycle_query).fetchall()
        if obj_cycles:
            results["valid"] = False
            results["errors"].append(
                f"Cycle detected in learning_objectives: {len(obj_cycles)} looping nodes"
            )

        # 2. Cycle detection in concept_edges (prerequisite_of)
        edge_cycle_query = text(
            """
            WITH RECURSIVE edge_path AS (
                SELECT from_concept_version_id, to_concept_version_id,
                       ARRAY[from_concept_version_id, to_concept_version_id] AS path,
                       false AS is_cycle
                FROM concept_edges
                WHERE edge_type = 'prerequisite_of' AND status = 'approved'
                UNION ALL
                SELECT e.from_concept_version_id, e.to_concept_version_id,
                       p.path || e.to_concept_version_id,
                       e.to_concept_version_id = ANY(p.path)
                FROM concept_edges e
                JOIN edge_path p ON e.from_concept_version_id = p.to_concept_version_id
                WHERE e.edge_type = 'prerequisite_of' AND e.status = 'approved'
                  AND NOT p.is_cycle AND array_length(p.path, 1) < 30
            )
            SELECT DISTINCT unnest(path) FROM edge_path WHERE is_cycle
            """
        )
        edge_cycles = self.connection.execute(edge_cycle_query).fetchall()
        if edge_cycles:
            results["valid"] = False
            results["errors"].append(
                f"Cycle detected in concept_edges: {len(edge_cycles)} nodes in cycle"
            )

        # 3. Check for invalid edge types in concept_edges
        edge_type_query = text(
            """
            SELECT DISTINCT edge_type FROM concept_edges
            """
        )
        existing_types = [r[0] for r in self.connection.execute(edge_type_query).fetchall()]
        invalid_types = set(existing_types) - EDGE_TYPES
        if invalid_types:
            results["valid"] = False
            results["errors"].append(f"Unallowlisted edge types found: {invalid_types}")

        # 4. Check that all approved concept versions map to at least one learning objective
        unmapped_query = text(
            """
            SELECT cv.id, c.stable_code
            FROM concept_versions cv
            JOIN concepts c ON c.id = cv.concept_id
            LEFT JOIN concept_objective_maps com ON com.concept_version_id = cv.id
            WHERE cv.content_status = 'approved'
              AND com.learning_objective_id IS NULL
            """
        )
        unmapped = self.connection.execute(unmapped_query).fetchall()
        if unmapped:
            results["valid"] = False
            results["errors"].append(
                f"Concepts missing learning objective mapping: {[r[1] for r in unmapped]}"
            )

        # 5. Check that all concept_edges have provenance
        missing_edge_prov_query = text(
            """
            SELECT id FROM concept_edges
            WHERE provenance_type IS NULL OR provenance_ref IS NULL
               OR trim(provenance_type) = '' OR trim(provenance_ref) = ''
            """
        )
        missing_prov = self.connection.execute(missing_edge_prov_query).fetchall()
        if missing_prov:
            results["valid"] = False
            results["errors"].append(f"Concept edges missing provenance: {len(missing_prov)} rows")

        return results
