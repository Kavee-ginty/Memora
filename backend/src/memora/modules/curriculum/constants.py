"""Ontology constants and allowlists for the curriculum and knowledge graph."""

# TRD §8.2, Schema §7.6: concept_edges.edge_type
EDGE_TYPES: frozenset[str] = frozenset(
    {
        "prerequisite_of",
        "applies_under",
        "contradicts",
        "example_of",
        "misconception_about",
        "related_to",
    }
)

# Schema §7.3: concept_versions.kind
CONCEPT_KINDS: frozenset[str] = frozenset(
    {
        "concept",
        "principle",
        "law",
        "formula",
        "variable",
        "unit",
        "method",
        "diagram_skill",
        "misconception",
    }
)

# Schema §7.4: concept_aliases.alias_type
ALIAS_TYPES: frozenset[str] = frozenset(
    {
        "term",
        "symbol",
        "abbreviation",
        "spelling",
    }
)

# Schema §7.5: knowledge_claims.claim_type
CLAIM_TYPES: frozenset[str] = frozenset(
    {
        "definition",
        "condition",
        "formula",
        "example",
        "misconception",
        "solution_step",
    }
)

# Schema §18.2, §11: mission_items.mission_type
MISSION_TYPES: frozenset[str] = frozenset(
    {
        "protect",
        "repair",
        "recover",
        "discover",
        "challenge",
    }
)

# TRD §9.5: Reason codes for scheduling and missions
REASON_CODES: frozenset[str] = frozenset(
    {
        "forgetting_curve_overdue",
        "weak_prerequisite_failure",
        "misconception_detected",
        "daily_retention_protect",
        "new_concept_introduction",
        "streak_preservation",
        "high_error_rate_repair",
    }
)
