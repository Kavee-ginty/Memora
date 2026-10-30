"""Calibration fixtures and 30-day scheduling simulations (T11 DoD).

Proves the four gate scenarios - new concept, overdue, weak prerequisite and
comeback - replay deterministically through the versioned engine and policy,
stay inside the expert bounds, and record the fixture/engine/policy versions
that produced them.
"""

from __future__ import annotations

import json
import os
from datetime import UTC, datetime, timedelta

import pytest

from memora.modules.memory.constants import (
    MEMORY_EXPLANATION_TEMPLATE_KEYS,
    MEMORY_REASON_CODES,
    REASON_COMEBACK_ELAPSED,
    REASON_WEAK_PREREQUISITE_RECOVER,
)
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG
from memora.modules.memory.simulation import (
    DEFAULT_CALENDAR_DAYS,
    REQUIRED_SCENARIOS,
    FixtureError,
    load_fixture,
    run_calendar_simulation,
    run_fixture,
)

FIXTURE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "fixtures", "memory", "calibration_v1.json"
)
START = datetime(2026, 10, 1, 6, 30, 0, tzinfo=UTC)


def load_document() -> dict:
    with open(FIXTURE_PATH, encoding="utf-8") as handle:
        return json.load(handle)


@pytest.fixture(scope="module")
def fixture_document() -> dict:
    return load_fixture(load_document())


@pytest.fixture(scope="module")
def results(fixture_document: dict):
    return {result.scenario: result for result in run_fixture(fixture_document, start=START)}


# ---------------------------------------------------------------------------
# fixture contract
# ---------------------------------------------------------------------------


def test_fixture_is_versioned_and_covers_every_gate_scenario(fixture_document: dict) -> None:
    assert fixture_document["fixture_version"] == "memory-calibration/1"
    assert fixture_document["calendar_days"] == DEFAULT_CALENDAR_DAYS
    names = [scenario["name"] for scenario in fixture_document["scenarios"]]
    assert names == list(REQUIRED_SCENARIOS)


@pytest.mark.parametrize(
    "mutate, message",
    [
        (lambda doc: doc.pop("fixture_version"), "fixture_version"),
        (lambda doc: doc.update({"fixture_version": "v1"}), "fixture_version"),
        (lambda doc: doc.update({"calendar_days": 0}), "calendar_days"),
        (lambda doc: doc.update({"scenarios": []}), "scenarios"),
        (lambda doc: doc["scenarios"].pop(), "missing required scenarios"),
        (
            lambda doc: doc["scenarios"][0]["events"].append(
                {"day": 99, "event_type": "attempt", "score": 0.5, "confidence": 0.5}
            ),
            "outside the calendar",
        ),
        (
            lambda doc: doc["scenarios"][0]["events"].append(
                {"day": 29, "event_type": "attempt", "confidence": 0.5}
            ),
            "need a score",
        ),
        (
            lambda doc: doc["scenarios"][0]["events"].append(
                {"day": 29, "event_type": "exposure", "score": 0.5, "confidence": 0.5}
            ),
            "carry no score",
        ),
    ],
)
def test_broken_fixtures_fail_loudly(mutate, message: str) -> None:
    document = load_document()
    mutate(document)
    with pytest.raises(FixtureError) as raised:
        load_fixture(document)
    assert message in str(raised.value)


# ---------------------------------------------------------------------------
# simulation determinism and provenance
# ---------------------------------------------------------------------------


def test_replay_is_deterministic(fixture_document: dict, results: dict) -> None:
    first = {name: result.to_dict() for name, result in results.items()}
    second = {
        result.scenario: result.to_dict() for result in run_fixture(load_document(), start=START)
    }
    assert first == second


def test_replay_records_fixture_engine_and_policy_versions(results: dict) -> None:
    for result in results.values():
        output = result.to_dict()
        assert output["fixture_version"] == "memory-calibration/1"
        assert output["engine_version"] == DEFAULT_ENGINE_CONFIG.engine_version
        assert output["policy_version"] == DEFAULT_ENGINE_CONFIG.policy_version
        assert output["calendar_days"] == DEFAULT_CALENDAR_DAYS
        assert output["steps"], "every scenario applies at least one event"


def test_every_step_stays_inside_the_allowlists_and_bounds(results: dict) -> None:
    for result in results.values():
        for step in result.steps:
            assert set(step.reason_codes) <= set(MEMORY_REASON_CODES)
            assert step.explanation_template_key in MEMORY_EXPLANATION_TEMPLATE_KEYS
            # A decision never schedules a review in the past and never
            # exceeds the policy interval cap.
            assert step.next_review_at > step.observed_at
            assert 0.0 < step.interval_days <= DEFAULT_ENGINE_CONFIG.interval_max_days


def test_events_land_on_the_simulated_calendar(results: dict) -> None:
    for result in results.values():
        assert result.start == START
        for step in result.steps:
            expected = START.replace(hour=9, minute=0, second=0, microsecond=0) + timedelta(
                days=step.day
            )
            assert step.observed_at == expected


# ---------------------------------------------------------------------------
# the four gate scenarios
# ---------------------------------------------------------------------------


def test_new_concept_first_review_lands_inside_the_window(results: dict) -> None:
    result = results["new_concept"]
    first, second = result.steps[0], result.steps[1]
    assert first.event_type == "exposure"
    assert first.next_review_at - first.observed_at >= timedelta(
        hours=DEFAULT_ENGINE_CONFIG.first_review_min_hours
    )
    assert first.next_review_at - first.observed_at <= timedelta(
        hours=DEFAULT_ENGINE_CONFIG.first_review_max_hours
    )
    # A strong first attempt may justify a later start, never a wilder one.
    assert second.next_review_at - second.observed_at <= timedelta(
        days=DEFAULT_ENGINE_CONFIG.interval_max_days
    )


def test_overdue_review_uses_elapsed_time_within_the_cap(results: dict) -> None:
    result = results["overdue"]
    overdue_step = result.steps[2]
    # 15 days elapsed against a short stability: retrievability has fallen
    # below the desired retention, so elapsed time - not the due date - drove
    # the transition.
    assert overdue_step.retrievability_at_decision < DEFAULT_ENGINE_CONFIG.desired_retention
    assert overdue_step.interval_days <= DEFAULT_ENGINE_CONFIG.interval_max_days
    assert overdue_step.next_review_at > overdue_step.observed_at
    assert overdue_step.stability_days <= DEFAULT_ENGINE_CONFIG.stability_max_days


def test_weak_prerequisite_lapse_flags_recover_and_pulls_review_earlier(
    results: dict,
) -> None:
    result = results["weak_prerequisite"]
    lapse = next(
        step for step in result.steps if step.event_type == "attempt" and step.score == 0.2
    )
    assert REASON_WEAK_PREREQUISITE_RECOVER in lapse.reason_codes
    assert lapse.interval_days <= DEFAULT_ENGINE_CONFIG.recover_interval_max_days
    assert lapse.explanation_template_key == "memory.explanation.weak_prerequisite"


def test_comeback_preserves_progress_and_caps_the_interval(results: dict) -> None:
    result = results["comeback"]
    comeback_step = result.steps[2]
    assert REASON_COMEBACK_ELAPSED in comeback_step.reason_codes
    assert comeback_step.interval_days <= DEFAULT_ENGINE_CONFIG.comeback_interval_max_days
    assert comeback_step.explanation_template_key == "memory.explanation.comeback"
    # Progress is preserved: the comeback review still grows stability rather
    # than resetting it toward the floor.
    before_absence = result.steps[1]
    assert comeback_step.stability_days > before_absence.stability_days
    final = result.final_state
    assert final is not None
    assert final.eligible_review_count == 3
    assert final.lapse_count == 0


def test_weak_prerequisite_scenario_only_flags_the_weak_event(results: dict) -> None:
    result = results["weak_prerequisite"]
    flagged = [
        step.day for step in result.steps if REASON_WEAK_PREREQUISITE_RECOVER in step.reason_codes
    ]
    assert flagged == [6]


def test_simulation_requires_an_aware_start(fixture_document: dict) -> None:
    with pytest.raises(ValueError):
        run_calendar_simulation(
            fixture_document["scenarios"][0],
            start=datetime(2026, 10, 1, 9, 0, 0),
            fixture_version="memory-calibration/1",
        )
