"""Deterministic engine tests for the FSRS-style memory core.

Covers the Commit-1 acceptance surface: same inputs reproduce the same
decision, every transition stays inside the engine contract, snapshots
round-trip, and the grade/confidence boundaries follow the documented bands.
"""

from __future__ import annotations

import random
from datetime import UTC, datetime, timedelta

import pytest

from memora.modules.memory.constants import (
    EVENT_ATTEMPT,
    EVENT_EXPOSURE,
    EVENT_INVALIDATION,
    REASON_OUT_OF_ORDER_EVIDENCE,
    REASON_RECALL_LAPSE,
    REASON_RECALL_SUCCESS,
    REASON_REVIEW_SCHEDULED,
    REASON_STATE_INITIALIZED,
)
from memora.modules.memory.engine import fsrs
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.engine.decide import Decision, EventFacts, decide
from memora.modules.memory.engine.state import LearnerConceptState

UTC = UTC

NOW = datetime(2026, 10, 29, 12, 0, 0, tzinfo=UTC)
EXPOSED_AT = datetime(2026, 10, 28, 9, 0, 0, tzinfo=UTC)
REVIEWED_AT = datetime(2026, 10, 29, 8, 0, 0, tzinfo=UTC)

SNAPSHOT_KEYS = {
    "schema_version",
    "engine_version",
    "difficulty",
    "stability_days",
    "last_retrievability",
    "evidence_confidence",
    "first_exposed_at",
    "last_reviewed_at",
    "next_review_at",
    "exposure_count",
    "eligible_review_count",
    "lapse_count",
}


def exposure_event(
    observed_at: datetime = EXPOSED_AT,
    confidence: float = 0.9,
) -> EventFacts:
    return EventFacts(
        event_type=EVENT_EXPOSURE,
        observed_at=observed_at,
        confidence=confidence,
    )


def attempt_event(
    score: float,
    observed_at: datetime = REVIEWED_AT,
    confidence: float = 0.9,
) -> EventFacts:
    return EventFacts(
        event_type=EVENT_ATTEMPT,
        observed_at=observed_at,
        confidence=confidence,
        score=score,
    )


def bootstrapped_state() -> LearnerConceptState:
    return decide(None, exposure_event(), now=NOW).result_state


def assert_within_contract(state: LearnerConceptState) -> None:
    config = DEFAULT_ENGINE_CONFIG
    assert config.difficulty_min <= state.difficulty <= config.difficulty_max
    assert config.stability_min_days <= state.stability_days <= config.stability_max_days
    assert 0.0 <= state.last_retrievability <= 1.0
    assert 0.0 <= state.evidence_confidence <= 1.0
    assert state.exposure_count >= 0
    assert state.eligible_review_count >= 0
    assert state.lapse_count >= 0
    assert state.first_exposed_at.tzinfo is UTC
    assert state.next_review_at.tzinfo is UTC


# ---------------------------------------------------------------------------
# determinism
# ---------------------------------------------------------------------------


def test_same_inputs_reproduce_bit_identical_decision() -> None:
    state = bootstrapped_state()
    event = attempt_event(score=0.8)

    first = decide(state, event, now=NOW)
    second = decide(state, event, now=NOW)

    assert first == second
    assert first.result_state.difficulty == second.result_state.difficulty
    assert first.result_state.stability_days == second.result_state.stability_days
    assert first.next_review_at == second.next_review_at


def test_bootstrap_exposure_is_deterministic() -> None:
    assert decide(None, exposure_event(), now=NOW) == decide(None, exposure_event(), now=NOW)


def test_decision_stamps_engine_and_policy_versions() -> None:
    decision = decide(None, exposure_event(), now=NOW)
    assert decision.engine_version == DEFAULT_ENGINE_CONFIG.engine_version
    assert decision.policy_version == DEFAULT_ENGINE_CONFIG.policy_version
    assert decision.result_state.to_snapshot()["engine_version"] == decision.engine_version


def test_changing_now_changes_only_the_schedule() -> None:
    state = bootstrapped_state()
    event = attempt_event(score=0.8)

    early = decide(state, event, now=NOW)
    late = decide(state, event, now=NOW + timedelta(hours=6))

    assert early.result_state.difficulty == late.result_state.difficulty
    assert early.result_state.stability_days == late.result_state.stability_days
    assert late.next_review_at > early.next_review_at


# ---------------------------------------------------------------------------
# engine contract bounds across many transitions
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "scores",
    [
        [0.0],
        [0.3],
        [0.5],
        [0.8],
        [1.0],
        [1.0, 1.0, 1.0, 1.0],
        [0.0, 0.0, 0.0],
        [1.0, 0.0, 1.0, 0.0],
        [0.4, 0.9, 0.2, 0.7, 0.1, 1.0],
        [0.6] * 12,
    ],
)
def test_score_sequences_stay_inside_contract(scores: list[float]) -> None:
    state = bootstrapped_state()
    observed = REVIEWED_AT
    for score in scores:
        decision = decide(state, attempt_event(score, observed_at=observed), now=observed)
        assert_within_contract(decision.result_state)
        state = decision.result_state
        observed += timedelta(days=1)


def test_many_exposures_stay_inside_contract() -> None:
    state = bootstrapped_state()
    observed = EXPOSED_AT
    for _ in range(10):
        decision = decide(state, exposure_event(observed_at=observed), now=observed)
        assert_within_contract(decision.result_state)
        state = decision.result_state
        observed += timedelta(days=3)


def _fuzz_decisions(seed: int, steps: int = 200) -> list[Decision]:
    """Replay a seeded pseudo-random event sequence through the pure engine."""
    rng = random.Random(seed)
    state: LearnerConceptState | None = None
    decisions: list[Decision] = []
    observed = EXPOSED_AT
    for _ in range(steps):
        observed += timedelta(hours=rng.randint(1, 36))
        if rng.random() < 0.3:
            event = EventFacts(
                event_type=EVENT_EXPOSURE,
                observed_at=observed,
                confidence=rng.random(),
            )
        else:
            event = EventFacts(
                event_type=EVENT_ATTEMPT,
                observed_at=observed,
                confidence=rng.random(),
                score=rng.random(),
            )
        decision = decide(state, event, now=observed)
        assert_within_contract(decision.result_state)
        decisions.append(decision)
        state = decision.result_state
    return decisions


def test_seeded_event_fuzz_stays_inside_contract_and_repeats() -> None:
    """A long random sequence is bounded and bit-identical on replay."""
    first = _fuzz_decisions(20261029)
    second = _fuzz_decisions(20261029)

    assert first == second
    assert len(first) == 200
    assert any(decision.result_state.lapse_count for decision in first)


def test_recall_never_loses_stability() -> None:
    state = bootstrapped_state()
    observed = REVIEWED_AT
    for score in (0.6, 0.8, 1.0, 0.7):
        decision = decide(state, attempt_event(score, observed_at=observed), now=observed)
        assert decision.result_state.stability_days >= state.stability_days - 1e-9
        state = decision.result_state
        observed += timedelta(days=1)


def test_lapse_collapses_stability_toward_the_floor() -> None:
    state = bootstrapped_state()
    for observed in (REVIEWED_AT, REVIEWED_AT + timedelta(days=1)):
        state = decide(state, attempt_event(1.0, observed_at=observed), now=observed).result_state
    prior = state.stability_days
    decision = decide(state, attempt_event(0.0, observed_at=observed + timedelta(days=5)), now=NOW)
    assert decision.result_state.stability_days < prior
    assert decision.result_state.stability_days >= DEFAULT_ENGINE_CONFIG.stability_min_days


def test_easy_growth_exceeds_good_growth() -> None:
    state = bootstrapped_state()
    easy = decide(state, attempt_event(1.0), now=NOW).result_state
    good = decide(state, attempt_event(2 / 3), now=NOW).result_state
    assert easy.stability_days > good.stability_days


# ---------------------------------------------------------------------------
# grade mapping and boundary bands
# ---------------------------------------------------------------------------


def test_grade_mapping_bounds() -> None:
    assert fsrs.map_score_to_grade(0.0).value == 1.0
    assert fsrs.map_score_to_grade(1.0).value == 1.0 + DEFAULT_ENGINE_CONFIG.grade_span
    assert fsrs.map_score_to_grade(0.5).is_recall
    assert not fsrs.map_score_to_grade(0.49).is_recall


def test_score_outside_range_is_rejected() -> None:
    with pytest.raises(ValueError, match="score"):
        attempt_event(1.5)
    with pytest.raises(ValueError, match="score"):
        decide(bootstrapped_state(), attempt_event(-0.1), now=NOW)


def test_retrievability_hits_target_retention_one_stability_out() -> None:
    config = DEFAULT_ENGINE_CONFIG
    stability = 7.0
    last = datetime(2026, 10, 22, tzinfo=UTC)
    r = fsrs.retrievability(stability, last, last + timedelta(days=7), config=config)
    assert r == pytest.approx(config.desired_retention)


def test_interval_matches_stability_for_default_curve() -> None:
    config = DEFAULT_ENGINE_CONFIG
    assert fsrs.interval_for_retention(12.5, config=config) == pytest.approx(12.5)


# ---------------------------------------------------------------------------
# bootstrap decisions
# ---------------------------------------------------------------------------


def test_first_exposure_initializes_state_near_probe_schedule() -> None:
    decision = decide(None, exposure_event(), now=NOW)

    assert decision.previous_state is None
    assert REASON_STATE_INITIALIZED in decision.reason_codes
    assert REASON_REVIEW_SCHEDULED in decision.reason_codes
    state = decision.result_state
    assert_within_contract(state)
    assert state.exposure_count == 1
    assert state.eligible_review_count == 0
    assert state.last_reviewed_at is None
    assert state.evidence_confidence == pytest.approx(0.9)
    expected = NOW + timedelta(
        days=fsrs.interval_for_retention(
            DEFAULT_ENGINE_CONFIG.exposure_initial_stability_days, config=DEFAULT_ENGINE_CONFIG
        )
    )
    assert state.next_review_at == pytest.approx(expected, abs=timedelta(seconds=1))


def test_first_scored_event_without_exposure_bootstraps_counts() -> None:
    decision = decide(None, attempt_event(0.9), now=NOW)

    state = decision.result_state
    assert_within_contract(state)
    assert state.eligible_review_count == 1
    assert state.lapse_count == 0
    assert REASON_RECALL_SUCCESS in decision.reason_codes


def test_weak_first_scored_event_bootstraps_as_lapse() -> None:
    decision = decide(None, attempt_event(0.1), now=NOW)

    assert REASON_RECALL_LAPSE in decision.reason_codes
    assert decision.result_state.lapse_count == 1


# ---------------------------------------------------------------------------
# exposure and scored transitions on an existing state
# ---------------------------------------------------------------------------


def test_exposure_records_evidence_without_moving_the_schedule() -> None:
    state = bootstrapped_state()
    scheduled = state.next_review_at

    decision = decide(state, exposure_event(observed_at=EXPOSED_AT + timedelta(days=1)), now=NOW)

    assert REASON_REVIEW_SCHEDULED not in decision.reason_codes
    assert decision.result_state.next_review_at == scheduled
    assert decision.result_state.exposure_count == state.exposure_count + 1
    assert decision.result_state.eligible_review_count == state.eligible_review_count


def test_exposure_blends_confidence() -> None:
    state = bootstrapped_state()
    decision = decide(state, exposure_event(confidence=0.2), now=NOW)
    expected = 0.7 * state.evidence_confidence + 0.3 * 0.2
    assert decision.result_state.evidence_confidence == pytest.approx(expected)


def test_successful_review_schedules_farther_out() -> None:
    state = bootstrapped_state()
    decision = decide(state, attempt_event(0.9), now=NOW)

    assert REASON_RECALL_SUCCESS in decision.reason_codes
    assert REASON_REVIEW_SCHEDULED in decision.reason_codes
    assert decision.result_state.eligible_review_count == 1
    assert decision.result_state.stability_days > state.stability_days
    assert decision.result_state.next_review_at > state.next_review_at


def test_scheduled_interval_follows_new_stability() -> None:
    state = bootstrapped_state()
    decision = decide(state, attempt_event(0.9), now=NOW)
    expected = NOW + timedelta(
        days=fsrs.interval_for_retention(
            decision.result_state.stability_days, config=DEFAULT_ENGINE_CONFIG
        )
    )
    assert decision.next_review_at == pytest.approx(expected, abs=timedelta(seconds=1))


def test_out_of_order_event_is_flagged_and_clamped() -> None:
    state = bootstrapped_state()
    past_event = attempt_event(0.9, observed_at=state.first_exposed_at - timedelta(days=2))

    decision = decide(state, past_event, now=NOW)

    assert REASON_OUT_OF_ORDER_EVIDENCE in decision.reason_codes
    assert_within_contract(decision.result_state)


def test_out_of_order_exposure_is_flagged() -> None:
    state = bootstrapped_state()
    decision = decide(
        state,
        exposure_event(observed_at=state.first_exposed_at - timedelta(days=2)),
        now=NOW,
    )
    assert REASON_OUT_OF_ORDER_EVIDENCE in decision.reason_codes


def test_elapsed_time_reduces_retrievability_influence() -> None:
    state = bootstrapped_state()
    immediate = decide(state, attempt_event(0.9, observed_at=REVIEWED_AT), now=NOW).result_state
    delayed = decide(
        state,
        attempt_event(0.9, observed_at=REVIEWED_AT + timedelta(days=10)),
        now=NOW,
    ).result_state
    # A recall further down the forgetting curve is stronger evidence.
    assert delayed.stability_days > immediate.stability_days


# ---------------------------------------------------------------------------
# snapshots
# ---------------------------------------------------------------------------


def test_snapshot_round_trip_preserves_state() -> None:
    state = bootstrapped_state()
    restored = LearnerConceptState.from_snapshot(state.to_snapshot())
    assert restored == state


def test_snapshot_round_trip_preserves_scored_state() -> None:
    state = decide(bootstrapped_state(), attempt_event(0.7), now=NOW).result_state
    restored = LearnerConceptState.from_snapshot(state.to_snapshot())
    assert restored == state


def test_snapshot_excludes_identity_columns() -> None:
    snapshot = bootstrapped_state().to_snapshot()
    assert set(snapshot) == SNAPSHOT_KEYS
    # The engine never sees identity columns, so a decision cannot leak or
    # touch another learner's or concept's state.
    assert "user_id" not in snapshot
    assert "concept_id" not in snapshot


def test_snapshot_rejects_unknown_schema_version() -> None:
    snapshot = bootstrapped_state().to_snapshot()
    snapshot["schema_version"] = "memora.memory_state/999"
    with pytest.raises(ValueError, match="unsupported memory state snapshot"):
        LearnerConceptState.from_snapshot(snapshot)


def test_snapshot_rejects_out_of_contract_values() -> None:
    snapshot = bootstrapped_state().to_snapshot()
    snapshot["difficulty"] = 99.0
    with pytest.raises(ValueError, match="difficulty"):
        LearnerConceptState.from_snapshot(snapshot)

    snapshot = bootstrapped_state().to_snapshot()
    snapshot["exposure_count"] = -1
    with pytest.raises(ValueError, match="non-negative"):
        LearnerConceptState.from_snapshot(snapshot)


# ---------------------------------------------------------------------------
# input validation
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("kwargs", "message"),
    [
        ({"event_type": "teleport"}, "unknown memory event type"),
        ({"event_type": EVENT_ATTEMPT, "score": None}, "requires a score"),
        ({"event_type": EVENT_EXPOSURE, "score": 0.5}, "exposure events carry no score"),
        ({"confidence": 1.5}, "confidence"),
    ],
)
def test_event_facts_validation(kwargs: dict, message: str) -> None:
    base = {"event_type": EVENT_EXPOSURE, "observed_at": EXPOSED_AT, "confidence": 0.9}
    base.update(kwargs)
    with pytest.raises(ValueError, match=message):
        EventFacts(**base)


def test_invalidation_is_metadata_not_a_decision() -> None:
    event = EventFacts(
        event_type=EVENT_INVALIDATION,
        observed_at=REVIEWED_AT,
        confidence=0.9,
    )

    with pytest.raises(ValueError, match="recorded without a decision"):
        decide(bootstrapped_state(), event, now=NOW)

    with pytest.raises(ValueError, match="invalidation events carry no score"):
        EventFacts(
            event_type=EVENT_INVALIDATION,
            observed_at=REVIEWED_AT,
            confidence=0.9,
            score=0.5,
        )


def test_snapshot_engine_version_is_explicit() -> None:
    state = bootstrapped_state()

    assert state.to_snapshot()["engine_version"] == DEFAULT_ENGINE_CONFIG.engine_version
    assert state.to_snapshot(engine_version="fsrs-mvp-9.9.9")["engine_version"] == "fsrs-mvp-9.9.9"


def test_naive_datetimes_are_rejected() -> None:
    with pytest.raises(ValueError, match="timezone-aware"):
        EventFacts(
            event_type=EVENT_EXPOSURE,
            observed_at=datetime(2026, 10, 28, 9, 0, 0),
            confidence=0.9,
        )
    with pytest.raises(ValueError, match="timezone-aware"):
        decide(None, exposure_event(), now=datetime(2026, 10, 29, 12, 0, 0))


def test_state_requires_aware_next_review() -> None:
    with pytest.raises(ValueError, match="timezone-aware"):
        LearnerConceptState(
            difficulty=5.0,
            stability_days=1.0,
            last_retrievability=1.0,
            evidence_confidence=0.9,
            first_exposed_at=EXPOSED_AT,
            next_review_at=datetime(2026, 10, 30, 12, 0, 0),
        )


# ---------------------------------------------------------------------------
# configuration
# ---------------------------------------------------------------------------


def test_default_configuration_is_valid() -> None:
    DEFAULT_ENGINE_CONFIG.validate()


def test_invalid_configuration_fails_fast() -> None:
    bad = EngineConfig(recall_gain=-1.0)
    with pytest.raises(ValueError, match="invalid memory engine configuration"):
        bad.validate()


def test_alternative_configuration_changes_decisions_consistently() -> None:
    config = EngineConfig(recall_gain=1.0)
    config.validate()
    state = bootstrapped_state()
    baseline = decide(state, attempt_event(0.9), now=NOW, config=DEFAULT_ENGINE_CONFIG)
    alternative = decide(state, attempt_event(0.9), now=NOW, config=config)
    assert alternative.result_state.stability_days != baseline.result_state.stability_days
    assert alternative.engine_version == config.engine_version
    assert isinstance(alternative, Decision)
