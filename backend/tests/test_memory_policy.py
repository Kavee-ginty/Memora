"""Policy-layer tests: the four T11 acceptance scenarios plus bounds.

Covers new-concept first review (PRD 012), bounded overdue scheduling
(TRD §9.5), comeback handling (PRD 015), weak-prerequisite recovery signals
(TRD §9.3) and the low-confidence influence band (D4), including the exact
behaviour at the confidence floor.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from unittest.mock import MagicMock
from uuid import uuid4

import pytest

from memora.modules.memory.constants import (
    EVENT_ATTEMPT,
    EVENT_EXPOSURE,
    MEMORY_EXPLANATION_TEMPLATE_KEYS,
    MEMORY_REASON_CODES,
    REASON_COMEBACK_ELAPSED,
    REASON_EVIDENCE_JUSTIFIED_SCHEDULE,
    REASON_FIRST_REVIEW_BOUNDED,
    REASON_INTERVAL_BOUNDED,
    REASON_LOW_CONFIDENCE_DAMPED,
    REASON_OUT_OF_ORDER_EVIDENCE,
    REASON_WEAK_PREREQUISITE_RECOVER,
    TEMPLATE_COMEBACK,
    TEMPLATE_EVIDENCE_RECORDED,
    TEMPLATE_FIRST_REVIEW,
    TEMPLATE_LOW_CONFIDENCE,
    TEMPLATE_WEAK_PREREQUISITE,
)
from memora.modules.memory.engine import fsrs
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.engine.decide import EventFacts
from memora.modules.memory.engine.policy import PrerequisiteSignal, decide_with_policy
from memora.modules.memory.prerequisites import (
    collect_prerequisite_signal,
    prerequisite_concept_ids,
)

UTC = UTC

NOW = datetime(2026, 10, 29, 12, 0, 0, tzinfo=UTC)
EXPOSED_AT = datetime(2026, 10, 28, 9, 0, 0, tzinfo=UTC)
REVIEWED_AT = datetime(2026, 10, 29, 8, 0, 0, tzinfo=UTC)


def exposure_event(observed_at: datetime = EXPOSED_AT, confidence: float = 0.9) -> EventFacts:
    return EventFacts(event_type=EVENT_EXPOSURE, observed_at=observed_at, confidence=confidence)


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


def bootstrapped_state() -> object:
    return decide_with_policy(None, exposure_event(), now=NOW).result_state


# ---------------------------------------------------------------------------
# scenario: new concept — first review lands near the next day (PRD 012)
# ---------------------------------------------------------------------------


def test_first_exposure_schedules_inside_the_policy_window() -> None:
    decision = decide_with_policy(None, exposure_event(), now=NOW)

    window_floor = NOW + timedelta(hours=DEFAULT_ENGINE_CONFIG.first_review_min_hours)
    window_ceiling = NOW + timedelta(hours=DEFAULT_ENGINE_CONFIG.first_review_max_hours)
    assert window_floor <= decision.next_review_at <= window_ceiling
    assert REASON_FIRST_REVIEW_BOUNDED in decision.reason_codes
    assert decision.explanation_template_key == TEMPLATE_FIRST_REVIEW
    assert decision.result_state.next_review_at == decision.next_review_at


def test_weak_first_attempt_is_bounded_into_the_window() -> None:
    decision = decide_with_policy(None, attempt_event(0.1), now=NOW)

    window_floor = NOW + timedelta(hours=DEFAULT_ENGINE_CONFIG.first_review_min_hours)
    assert decision.next_review_at == window_floor
    assert REASON_FIRST_REVIEW_BOUNDED in decision.reason_codes


def test_strong_first_attempt_justifies_a_later_first_review() -> None:
    decision = decide_with_policy(None, attempt_event(1.0), now=NOW)

    window_ceiling = NOW + timedelta(hours=DEFAULT_ENGINE_CONFIG.first_review_max_hours)
    assert decision.next_review_at > window_ceiling
    assert REASON_EVIDENCE_JUSTIFIED_SCHEDULE in decision.reason_codes


def test_moderate_first_attempt_sits_inside_the_window_untouched() -> None:
    decision = decide_with_policy(None, attempt_event(0.8), now=NOW)

    window_floor = NOW + timedelta(hours=DEFAULT_ENGINE_CONFIG.first_review_min_hours)
    window_ceiling = NOW + timedelta(hours=DEFAULT_ENGINE_CONFIG.first_review_max_hours)
    assert window_floor <= decision.next_review_at <= window_ceiling
    assert REASON_FIRST_REVIEW_BOUNDED not in decision.reason_codes
    assert REASON_EVIDENCE_JUSTIFIED_SCHEDULE not in decision.reason_codes


# ---------------------------------------------------------------------------
# scenario: overdue — actual elapsed time, bounded schedule (TRD §9.5)
# ---------------------------------------------------------------------------


def test_overdue_recall_uses_actual_elapsed_time_but_caps_the_interval() -> None:
    config = EngineConfig(
        comeback_interval_max_days=0.5,
        recover_interval_max_days=0.9,
        interval_max_days=1.0,
    )
    config.validate()
    decision = decide_with_policy(None, attempt_event(1.0), now=NOW, config=config)

    cap = NOW + timedelta(days=config.interval_max_days)
    assert decision.next_review_at <= cap
    assert REASON_INTERVAL_BOUNDED in decision.reason_codes
    # The strong-evidence reason is still recorded even though the cap won.
    assert REASON_EVIDENCE_JUSTIFIED_SCHEDULE in decision.reason_codes


def test_default_policy_caps_long_stability_horizons() -> None:
    state = bootstrapped_state()
    # Drive stability far above the interval cap through strong recalls.
    observed = REVIEWED_AT
    for _ in range(40):
        state = decide_with_policy(
            state,
            attempt_event(1.0, observed_at=observed),
            now=observed,
            config=DEFAULT_ENGINE_CONFIG,
        ).result_state
        observed += timedelta(days=1)

    decision = decide_with_policy(state, attempt_event(1.0, observed_at=observed), now=NOW)
    cap = NOW + timedelta(days=DEFAULT_ENGINE_CONFIG.interval_max_days)
    assert decision.next_review_at <= cap
    assert decision.result_state.stability_days <= DEFAULT_ENGINE_CONFIG.stability_max_days


def test_overdue_lapse_after_long_absence_stays_bounded() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(
        state,
        attempt_event(0.0, observed_at=EXPOSED_AT + timedelta(days=90)),
        now=NOW,
    )

    cap = NOW + timedelta(days=DEFAULT_ENGINE_CONFIG.comeback_interval_max_days)
    assert decision.next_review_at <= cap
    assert REASON_COMEBACK_ELAPSED in decision.reason_codes


# ---------------------------------------------------------------------------
# scenario: comeback — welcoming plan, nothing erased (PRD 015)
# ---------------------------------------------------------------------------


def test_comeback_lapse_flags_and_caps_without_erasing_state() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(
        state,
        attempt_event(0.2, observed_at=EXPOSED_AT + timedelta(days=30)),
        now=NOW,
    )

    cap = NOW + timedelta(days=DEFAULT_ENGINE_CONFIG.comeback_interval_max_days)
    assert decision.next_review_at <= cap
    assert REASON_COMEBACK_ELAPSED in decision.reason_codes
    assert decision.explanation_template_key == TEMPLATE_COMEBACK
    assert decision.result_state.first_exposed_at == state.first_exposed_at
    assert decision.result_state.stability_days >= DEFAULT_ENGINE_CONFIG.stability_min_days
    assert decision.result_state.eligible_review_count == state.eligible_review_count + 1


def test_comeback_exposure_caps_the_stale_schedule() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(
        state,
        exposure_event(observed_at=EXPOSED_AT + timedelta(days=30)),
        now=NOW,
    )

    cap = NOW + timedelta(days=DEFAULT_ENGINE_CONFIG.comeback_interval_max_days)
    assert decision.next_review_at <= cap
    assert REASON_COMEBACK_ELAPSED in decision.reason_codes
    assert decision.explanation_template_key == TEMPLATE_COMEBACK


def test_absence_below_threshold_is_not_a_comeback() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(
        state,
        attempt_event(0.9, observed_at=EXPOSED_AT + timedelta(days=2)),
        now=NOW,
    )
    assert REASON_COMEBACK_ELAPSED not in decision.reason_codes


# ---------------------------------------------------------------------------
# scenario: weak prerequisite — Recover evidence, no cross-concept writes
# ---------------------------------------------------------------------------


def test_lapse_with_weak_prerequisite_flags_recover() -> None:
    state = bootstrapped_state()
    signal = PrerequisiteSignal(weak_prerequisite_concept_ids=(str(uuid4()),))
    decision = decide_with_policy(
        state,
        attempt_event(0.1, observed_at=REVIEWED_AT),
        now=NOW,
        prerequisite_signal=signal,
    )

    cap = NOW + timedelta(days=DEFAULT_ENGINE_CONFIG.recover_interval_max_days)
    assert REASON_WEAK_PREREQUISITE_RECOVER in decision.reason_codes
    assert decision.next_review_at <= cap
    assert decision.explanation_template_key == TEMPLATE_WEAK_PREREQUISITE


def test_strong_prerequisite_signal_does_not_flag_recover() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(
        state,
        attempt_event(0.9, observed_at=REVIEWED_AT),
        now=NOW,
        prerequisite_signal=PrerequisiteSignal(weak_prerequisite_concept_ids=(str(uuid4()),)),
    )
    assert REASON_WEAK_PREREQUISITE_RECOVER not in decision.reason_codes


def test_weak_signal_without_failure_does_not_flag_recover() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(
        state,
        exposure_event(observed_at=EXPOSED_AT + timedelta(days=1)),
        now=NOW,
        prerequisite_signal=PrerequisiteSignal(weak_prerequisite_concept_ids=(str(uuid4()),)),
    )
    assert REASON_WEAK_PREREQUISITE_RECOVER not in decision.reason_codes


# ---------------------------------------------------------------------------
# low-confidence influence band (D4)
# ---------------------------------------------------------------------------


def test_below_floor_confidence_damps_proportionally() -> None:
    state = bootstrapped_state()
    full = decide_with_policy(
        state, attempt_event(0.9, confidence=DEFAULT_ENGINE_CONFIG.confidence_floor), now=NOW
    )
    damped = decide_with_policy(state, attempt_event(0.9, confidence=0.2), now=NOW)

    scale = 0.2 / DEFAULT_ENGINE_CONFIG.confidence_floor
    expected = (
        state.stability_days + (full.result_state.stability_days - state.stability_days) * scale
    )
    assert damped.result_state.stability_days == pytest.approx(expected, rel=1e-9)
    assert (
        state.stability_days < damped.result_state.stability_days < full.result_state.stability_days
    )
    assert damped.next_review_at < full.next_review_at
    assert REASON_LOW_CONFIDENCE_DAMPED in damped.reason_codes
    assert damped.explanation_template_key == TEMPLATE_LOW_CONFIDENCE


def test_confidence_exactly_at_floor_has_full_influence() -> None:
    state = bootstrapped_state()
    at_floor = decide_with_policy(
        state, attempt_event(0.9, confidence=DEFAULT_ENGINE_CONFIG.confidence_floor), now=NOW
    )
    certain = decide_with_policy(state, attempt_event(0.9, confidence=1.0), now=NOW)
    assert at_floor.result_state.stability_days == certain.result_state.stability_days
    assert REASON_LOW_CONFIDENCE_DAMPED not in at_floor.reason_codes


def test_zero_confidence_freezes_the_quantitative_state() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(state, attempt_event(0.9, confidence=0.0), now=NOW)
    assert decision.result_state.stability_days == pytest.approx(state.stability_days)
    assert decision.result_state.difficulty == pytest.approx(state.difficulty)
    # The review still happened: counters and confidence blend move.
    assert decision.result_state.eligible_review_count == state.eligible_review_count + 1


def test_low_confidence_first_attempt_is_damped_and_bounded() -> None:
    decision = decide_with_policy(None, attempt_event(0.9, confidence=0.1), now=NOW)
    assert REASON_LOW_CONFIDENCE_DAMPED in decision.reason_codes
    window_ceiling = NOW + timedelta(hours=DEFAULT_ENGINE_CONFIG.first_review_max_hours)
    assert decision.next_review_at <= window_ceiling


# ---------------------------------------------------------------------------
# explanation precedence and closed allowlists
# ---------------------------------------------------------------------------


def test_template_precedence_weak_over_comeback_over_confidence() -> None:
    state = bootstrapped_state()
    decision = decide_with_policy(
        state,
        attempt_event(0.1, observed_at=EXPOSED_AT + timedelta(days=30), confidence=0.1),
        now=NOW,
        prerequisite_signal=PrerequisiteSignal(weak_prerequisite_concept_ids=(str(uuid4()),)),
    )
    assert REASON_WEAK_PREREQUISITE_RECOVER in decision.reason_codes
    assert REASON_COMEBACK_ELAPSED in decision.reason_codes
    assert REASON_LOW_CONFIDENCE_DAMPED in decision.reason_codes
    assert decision.explanation_template_key == TEMPLATE_WEAK_PREREQUISITE


def test_all_policy_outputs_stay_inside_the_allowlists() -> None:
    state = bootstrapped_state()
    decisions = [
        decide_with_policy(None, exposure_event(), now=NOW),
        decide_with_policy(None, attempt_event(1.0), now=NOW),
        decide_with_policy(None, attempt_event(0.1), now=NOW),
        decide_with_policy(
            state, attempt_event(0.1, observed_at=EXPOSED_AT + timedelta(days=30)), now=NOW
        ),
        decide_with_policy(
            state,
            attempt_event(0.2, observed_at=EXPOSED_AT + timedelta(days=30), confidence=0.1),
            now=NOW,
            prerequisite_signal=PrerequisiteSignal(weak_prerequisite_concept_ids=("x",)),
        ),
    ]
    for decision in decisions:
        assert set(decision.reason_codes) <= set(MEMORY_REASON_CODES)
        assert decision.explanation_template_key in MEMORY_EXPLANATION_TEMPLATE_KEYS
        assert decision.reason_codes  # never empty: every decision explains itself


def test_policy_is_deterministic() -> None:
    state = bootstrapped_state()
    event = attempt_event(0.7, observed_at=EXPOSED_AT + timedelta(days=30), confidence=0.2)
    signal = PrerequisiteSignal(weak_prerequisite_concept_ids=(str(uuid4()),))
    assert decide_with_policy(state, event, now=NOW, prerequisite_signal=signal) == (
        decide_with_policy(state, event, now=NOW, prerequisite_signal=signal)
    )


# ---------------------------------------------------------------------------
# initial stability (engine refinement used by the first-review policy)
# ---------------------------------------------------------------------------


def test_initial_stability_grows_with_the_grade() -> None:
    weak = fsrs.initial_stability(fsrs.map_score_to_grade(0.1))
    strong = fsrs.initial_stability(fsrs.map_score_to_grade(1.0))
    assert DEFAULT_ENGINE_CONFIG.stability_min_days <= weak < strong
    assert strong <= DEFAULT_ENGINE_CONFIG.stability_max_days


# ---------------------------------------------------------------------------
# prerequisite signal lookup (read-only, reuses the T08 traversal)
# ---------------------------------------------------------------------------


def _graph_response(rows: list[dict]) -> MagicMock:
    response = MagicMock()
    response.mappings.return_value.all.return_value = rows
    return response


def _state_response(row: dict | None) -> MagicMock:
    response = MagicMock()
    response.mappings.return_value.first.return_value = row
    return response


def test_prerequisite_concept_ids_reuses_the_bounded_traversal() -> None:
    concept_id = uuid4()
    connection = MagicMock()
    connection.execute.return_value = _graph_response([{"concept_id": concept_id}])

    ids = prerequisite_concept_ids(connection, concept_version_id=uuid4())

    assert ids == (str(concept_id),)
    executed = str(connection.execute.call_args[0][0])
    assert "prerequisite_of" in executed
    assert "status = 'approved'" in executed


def test_collect_signal_flags_weak_prerequisite_state() -> None:
    user_id = uuid4()
    connection = MagicMock()
    connection.execute.side_effect = [
        _graph_response([{"concept_id": uuid4()}]),
        _state_response(
            {
                "stability_days": 0.2,
                "last_reviewed_at": NOW - timedelta(days=30),
                "first_exposed_at": NOW - timedelta(days=60),
            }
        ),
    ]

    signal = collect_prerequisite_signal(
        connection, user_id=user_id, concept_version_id=uuid4(), now=NOW
    )

    assert signal.has_weak_prerequisites
    assert len(signal.weak_prerequisite_concept_ids) == 1
    state_query = str(connection.execute.call_args_list[1][0][0])
    assert "learner_concept_states" in state_query
    assert connection.execute.call_args_list[1][0][1]["user_id"] == str(user_id)


def test_collect_signal_ignores_healthy_and_unlearned_prerequisites() -> None:
    healthy_id, unlearned_id = uuid4(), uuid4()
    connection = MagicMock()
    connection.execute.side_effect = [
        _graph_response([{"concept_id": healthy_id}, {"concept_id": unlearned_id}]),
        _state_response(
            {
                "stability_days": 12.0,
                "last_reviewed_at": NOW - timedelta(days=1),
                "first_exposed_at": NOW - timedelta(days=40),
            }
        ),
        _state_response(None),
    ]

    signal = collect_prerequisite_signal(
        connection, user_id=uuid4(), concept_version_id=uuid4(), now=NOW
    )

    assert not signal.has_weak_prerequisites


def test_collect_signal_requires_timezone_aware_now() -> None:
    with pytest.raises(ValueError, match="timezone-aware"):
        collect_prerequisite_signal(
            MagicMock(),
            user_id=uuid4(),
            concept_version_id=uuid4(),
            now=datetime(2026, 10, 29, 12, 0, 0),
        )


# ---------------------------------------------------------------------------
# stale evidence: late delivery never rewinds the review anchor (review fix 2)
# ---------------------------------------------------------------------------


def reviewed_state() -> object:
    """Exposure followed by one successful review at REVIEWED_AT."""
    state = bootstrapped_state()
    return decide_with_policy(
        state, attempt_event(0.9, observed_at=REVIEWED_AT), now=NOW
    ).result_state


def test_stale_event_is_a_strict_no_op() -> None:
    state = reviewed_state()
    stale = attempt_event(1.0, observed_at=EXPOSED_AT + timedelta(hours=1))

    decision = decide_with_policy(state, stale, now=NOW)

    assert decision.reason_codes == (REASON_OUT_OF_ORDER_EVIDENCE,)
    assert decision.explanation_template_key == TEMPLATE_EVIDENCE_RECORDED
    assert decision.result_state == state
    assert decision.next_review_at == state.next_review_at
    assert decision.result_state.last_reviewed_at == state.last_reviewed_at
    assert decision.result_state.eligible_review_count == state.eligible_review_count


def test_delivery_order_never_rewinds_the_anchor() -> None:
    """The Codex review comparison: newer attempt first, older attempt late.

    Chronological delivery applies both attempts; delayed delivery applies
    only the newer one and records the older as stale. Either way the
    stored anchor is the newer attempt's time and the schedule is the one
    the newer evidence produced.
    """
    earlier = attempt_event(0.7, observed_at=REVIEWED_AT)
    later = attempt_event(0.9, observed_at=REVIEWED_AT + timedelta(days=2))
    base = bootstrapped_state()

    chronological = base
    for event in (earlier, later):
        chronological = decide_with_policy(chronological, event, now=NOW).result_state

    delayed_first = decide_with_policy(base, later, now=NOW).result_state
    delayed_final = decide_with_policy(delayed_first, earlier, now=NOW)

    assert delayed_final.reason_codes == (REASON_OUT_OF_ORDER_EVIDENCE,)
    # The late older attempt rewinds nothing: the anchor stays at the newer
    # review, the schedule keeps the newer evidence's decision.
    assert delayed_final.result_state == delayed_first
    assert delayed_final.result_state.last_reviewed_at == later.observed_at
    assert delayed_final.result_state.last_reviewed_at > earlier.observed_at
    assert delayed_final.next_review_at == delayed_first.next_review_at
    # Chronological processing remains the richer path: both attempts
    # applied, anchored on the newest.
    assert chronological.last_reviewed_at == later.observed_at


def test_stale_events_are_order_independent() -> None:
    state = reviewed_state()
    stale_a = attempt_event(0.6, observed_at=EXPOSED_AT + timedelta(hours=2))
    stale_b = attempt_event(0.3, observed_at=EXPOSED_AT + timedelta(hours=4))

    first_order = decide_with_policy(state, stale_a, now=NOW)
    after_a = first_order.result_state
    second = decide_with_policy(after_a, stale_b, now=NOW).result_state

    reverse_first = decide_with_policy(state, stale_b, now=NOW)
    reverse_second = decide_with_policy(reverse_first.result_state, stale_a, now=NOW).result_state

    assert first_order.result_state == state
    assert reverse_first.result_state == state
    assert second == state == reverse_second


def test_stale_event_with_low_confidence_keeps_the_schedule() -> None:
    state = reviewed_state()
    stale = attempt_event(0.2, observed_at=EXPOSED_AT + timedelta(hours=1), confidence=0.1)

    decision = decide_with_policy(state, stale, now=NOW)

    # Damping and interval bounds guard new schedules only; a no-op must
    # not be pushed forward or flagged.
    assert decision.next_review_at == state.next_review_at
    assert REASON_LOW_CONFIDENCE_DAMPED not in decision.reason_codes
    assert REASON_INTERVAL_BOUNDED not in decision.reason_codes


def test_stale_exposure_is_a_strict_no_op() -> None:
    state = reviewed_state()
    stale = exposure_event(observed_at=EXPOSED_AT, confidence=0.8)

    decision = decide_with_policy(state, stale, now=NOW)

    assert decision.result_state == state
    assert decision.reason_codes == (REASON_OUT_OF_ORDER_EVIDENCE,)
    assert decision.explanation_template_key == TEMPLATE_EVIDENCE_RECORDED
