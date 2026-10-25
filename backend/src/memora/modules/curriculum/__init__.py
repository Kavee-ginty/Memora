"""Curriculum and knowledge graph domain module."""

from memora.modules.curriculum.constants import (
    ALIAS_TYPES,
    CLAIM_TYPES,
    CONCEPT_KINDS,
    DEFAULT_ALIAS_LIMIT,
    DEFAULT_PREREQ_DEPTH,
    EDGE_TYPES,
    MAX_ALIAS_LIMIT,
    MAX_PREREQ_DEPTH,
    MAX_PREREQ_RESULTS,
    MISSION_TYPES,
    REASON_CODES,
)
from memora.modules.curriculum.service import CurriculumService

__all__ = [
    "ALIAS_TYPES",
    "CLAIM_TYPES",
    "CONCEPT_KINDS",
    "CurriculumService",
    "DEFAULT_ALIAS_LIMIT",
    "DEFAULT_PREREQ_DEPTH",
    "EDGE_TYPES",
    "MAX_ALIAS_LIMIT",
    "MAX_PREREQ_DEPTH",
    "MAX_PREREQ_RESULTS",
    "MISSION_TYPES",
    "REASON_CODES",
]
