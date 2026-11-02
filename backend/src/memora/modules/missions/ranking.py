"""Deterministic Daily Mission ranking and workload selection."""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass
from uuid import UUID

from memora.modules.memory.selection import DueConceptCandidate
from memora.modules.missions.constants import MAX_ESTIMATED_SECONDS, MAX_PLANNED_ITEMS

_URGENCY_POINTS = {"overdue": 100.0, "due": 75.0, "near_due": 40.0}


@dataclass(frozen=True, slots=True)
class RankedCandidate:
    candidate: DueConceptCandidate
    mission_type: str
    score: float

    @property
    def concept_id(self) -> UUID:
        return self.candidate.concept_id


@dataclass(frozen=True, slots=True)
class PlannedQuestion:
    ranked: RankedCandidate
    target_concept_id: UUID
    target_concept_version_id: UUID
    question_version_id: UUID
    question_type: str
    estimated_seconds: int
    source_class: str


def mission_type(candidate: DueConceptCandidate) -> str:
    """Map educational evidence to the documented mission purpose."""

    if candidate.weak_prerequisite_concept_ids:
        return "recover"
    if candidate.recent_error_severity >= 0.4:
        return "repair"
    if candidate.is_new_concept:
        return "discover"
    if (
        candidate.urgency == "near_due"
        and candidate.retrievability >= 0.8
        and candidate.evidence_confidence >= 0.8
    ):
        return "challenge"
    return "protect"


def priority_score(candidate: DueConceptCandidate) -> float:
    """Return a reproducible score from T11's bounded selection inputs."""

    return round(
        _URGENCY_POINTS.get(candidate.urgency, 0.0)
        + candidate.forgetting_risk * 40.0
        + candidate.recent_error_severity * 30.0
        + min(candidate.prerequisite_impact, 5) * 5.0
        + candidate.evidence_confidence * 10.0
        + (10.0 if candidate.is_comeback else 0.0),
        6,
    )


def rank_candidates(candidates: Iterable[DueConceptCandidate]) -> list[RankedCandidate]:
    ranked = [
        RankedCandidate(
            candidate=candidate,
            mission_type=mission_type(candidate),
            score=priority_score(candidate),
        )
        for candidate in candidates
    ]
    return sorted(
        ranked,
        key=lambda item: (
            -item.score,
            item.candidate.next_review_at,
            str(item.candidate.concept_id),
        ),
    )


def apply_workload_cap(
    questions: Iterable[PlannedQuestion],
    *,
    max_items: int = MAX_PLANNED_ITEMS,
    max_seconds: int = MAX_ESTIMATED_SECONDS,
) -> list[PlannedQuestion]:
    """Select ranked work until either approved bound is reached."""

    selected: list[PlannedQuestion] = []
    elapsed = 0
    covered_objectives: set[UUID] = set()
    remaining = list(questions)

    # Prefer candidates that add curriculum coverage when scores are otherwise close.
    while remaining and len(selected) < max_items:
        remaining.sort(
            key=lambda item: (
                -item.ranked.score,
                -int(bool(set(item.ranked.candidate.coverage_objective_ids) - covered_objectives)),
                item.ranked.candidate.next_review_at,
                str(item.ranked.concept_id),
            )
        )
        question = remaining.pop(0)
        if elapsed + question.estimated_seconds > max_seconds:
            continue
        selected.append(question)
        elapsed += question.estimated_seconds
        covered_objectives.update(question.ranked.candidate.coverage_objective_ids)
    return selected
