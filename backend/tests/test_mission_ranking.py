from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

from memora.modules.memory.constants import (
    SELECTION_REASON_ERROR_REPAIR,
    SELECTION_REASON_NEW_CONCEPT,
    SELECTION_REASON_RETENTION,
    SELECTION_REASON_WEAK_PREREQUISITE,
)
from memora.modules.memory.selection import DueConceptCandidate
from memora.modules.missions.constants import MAX_ESTIMATED_SECONDS, MAX_PLANNED_ITEMS
from memora.modules.missions.ranking import (
    PlannedQuestion,
    apply_workload_cap,
    mission_type,
    rank_candidates,
)


def candidate(
    *,
    urgency: str = "due",
    forgetting_risk: float = 0.6,
    evidence_confidence: float = 0.9,
    recent_error_severity: float = 0.0,
    weak_prerequisites: tuple[UUID, ...] = (),
    is_new: bool = False,
    is_comeback: bool = False,
    reason: str = SELECTION_REASON_RETENTION,
    next_review_at: datetime | None = None,
) -> DueConceptCandidate:
    now = datetime(2026, 11, 1, tzinfo=UTC)
    return DueConceptCandidate(
        concept_id=uuid4(),
        concept_version_id=uuid4(),
        stable_code=f"concept-{uuid4().hex[:8]}",
        title="Synthetic concept",
        next_review_at=next_review_at or now,
        last_reviewed_at=now - timedelta(days=2),
        urgency=urgency,
        overdue_days=2.0 if urgency == "overdue" else 0.0,
        retrievability=1.0 - forgetting_risk,
        retrievability_band="settling",
        forgetting_risk=forgetting_risk,
        evidence_confidence=evidence_confidence,
        recent_error_severity=recent_error_severity,
        recent_error_count=1 if recent_error_severity else 0,
        lapse_count=1 if recent_error_severity else 0,
        exposure_count=2,
        eligible_review_count=1,
        is_new_concept=is_new,
        is_comeback=is_comeback,
        prerequisite_impact=2 if weak_prerequisites else 0,
        weak_prerequisite_concept_ids=weak_prerequisites,
        coverage_objective_ids=(uuid4(),),
        selection_reason=reason,
    )


def planned(due: DueConceptCandidate, *, seconds: int = 60) -> PlannedQuestion:
    ranked = rank_candidates([due])[0]
    return PlannedQuestion(
        ranked=ranked,
        target_concept_id=due.concept_id,
        target_concept_version_id=due.concept_version_id,
        question_version_id=uuid4(),
        question_type="mcq",
        estimated_seconds=seconds,
        source_class="expert_verified",
    )


def test_ranking_prioritizes_overdue_and_error_evidence_deterministically() -> None:
    near = candidate(urgency="near_due", forgetting_risk=0.2)
    overdue = candidate(
        urgency="overdue",
        forgetting_risk=0.9,
        recent_error_severity=0.8,
        reason=SELECTION_REASON_ERROR_REPAIR,
    )

    first = rank_candidates([near, overdue])
    replay = rank_candidates([overdue, near])

    assert [item.concept_id for item in first] == [overdue.concept_id, near.concept_id]
    assert first == replay


def test_mission_types_reflect_learning_purpose() -> None:
    prerequisite_id = uuid4()

    assert mission_type(candidate(is_new=True, reason=SELECTION_REASON_NEW_CONCEPT)) == "discover"
    assert (
        mission_type(
            candidate(
                weak_prerequisites=(prerequisite_id,),
                reason=SELECTION_REASON_WEAK_PREREQUISITE,
            )
        )
        == "recover"
    )
    assert (
        mission_type(
            candidate(
                recent_error_severity=0.7,
                reason=SELECTION_REASON_ERROR_REPAIR,
            )
        )
        == "repair"
    )
    assert (
        mission_type(
            candidate(
                urgency="near_due",
                forgetting_risk=0.1,
                evidence_confidence=0.95,
            )
        )
        == "challenge"
    )
    assert mission_type(candidate()) == "protect"


def test_workload_stops_at_item_and_duration_bounds_without_padding() -> None:
    work = [planned(candidate(), seconds=90) for _ in range(10)]

    selected = apply_workload_cap(work)
    sparse = apply_workload_cap(work[:2])

    assert len(selected) == min(MAX_PLANNED_ITEMS, MAX_ESTIMATED_SECONDS // 90)
    assert sum(item.estimated_seconds for item in selected) <= MAX_ESTIMATED_SECONDS
    assert len(sparse) == 2


def test_low_confidence_lowers_priority_and_comeback_stays_bounded() -> None:
    trusted = candidate(evidence_confidence=0.95)
    uncertain = candidate(evidence_confidence=0.1)
    comeback = candidate(is_comeback=True)

    ranked = rank_candidates([uncertain, trusted, comeback])

    assert ranked[0].concept_id == comeback.concept_id
    assert ranked[-1].concept_id == uncertain.concept_id
