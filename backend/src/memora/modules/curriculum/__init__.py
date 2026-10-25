"""Curriculum and knowledge graph domain module."""

from memora.modules.curriculum.constants import (
    ALIAS_TYPES,
    CLAIM_TYPES,
    CONCEPT_KINDS,
    EDGE_TYPES,
    MISSION_TYPES,
    REASON_CODES,
)
from memora.modules.curriculum.service import CurriculumService

__all__ = [
    "ALIAS_TYPES",
    "CLAIM_TYPES",
    "CONCEPT_KINDS",
    "CurriculumService",
    "EDGE_TYPES",
    "MISSION_TYPES",
    "REASON_CODES",
]
