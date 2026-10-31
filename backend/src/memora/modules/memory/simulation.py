"""Deterministic 30-day scheduling simulation over calibration fixtures.

The simulator replays a versioned fixture calendar through
:func:`memora.modules.memory.engine.policy.decide_with_policy` exactly as the
worker would, but without a database: the state is carried forward in memory.
That makes the four gate scenarios (new, overdue, weak-prerequisite, comeback)
reproducible in CI and lets the acceptance evidence name the fixture, engine
and policy versions that produced it (Task Table T11 DoD).

The simulator is deliberately pure and clock-free: the caller supplies the
start instant and the fixture supplies day offsets, so identical fixtures and
versions always produce identical output.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import UTC, datetime, timedelta
from typing import Any

from memora.modules.memory.constants import (
    EVENT_EXPOSURE,
    MEMORY_EVENT_TYPES,
    SCORED_MEMORY_EVENT_TYPES,
)
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.engine.decide import EventFacts
from memora.modules.memory.engine.policy import (
    PrerequisiteSignal,
    decide_with_policy,
)
from memora.modules.memory.engine.state import LearnerConceptState

FIXTURE_VERSION_PREFIX = "memory-calibration/"
REQUIRED_SCENARIOS: tuple[str, ...] = (
    "new_concept",
    "overdue",
    "weak_prerequisite",
    "comeback",
)
SIMULATION_HOUR_UTC = 9
DEFAULT_CALENDAR_DAYS = 30
MAX_CALENDAR_DAYS = 90


class FixtureError(ValueError):
    """A calibration fixture that does not match the documented shape."""


@dataclass(frozen=True)
class SimulationStep:
    """One applied evidence event and the decision it produced."""

    day: int
    event_type: str
    score: float | None
    confidence: float
    observed_at: datetime
    next_review_at: datetime
    interval_days: float
    retrievability_at_decision: float
    stability_days: float
    reason_codes: tuple[str, ...]
    explanation_template_key: str


@dataclass(frozen=True)
class SimulationResult:
    """A completed calendar replay with its provenance."""

    scenario: str
    fixture_version: str
    engine_version: str
    policy_version: str
    calendar_days: int
    start: datetime
    steps: tuple[SimulationStep, ...] = field(default_factory=tuple)
    final_state: LearnerConceptState | None = None

    @property
    def max_interval_days(self) -> float:
        return max((step.interval_days for step in self.steps), default=0.0)

    @property
    def reason_codes(self) -> tuple[str, ...]:
        seen: list[str] = []
        for step in self.steps:
            for code in step.reason_codes:
                if code not in seen:
                    seen.append(code)
        return tuple(seen)

    def to_dict(self) -> dict[str, Any]:
        """Serialise the replay, recording the versions that produced it."""
        return {
            "scenario": self.scenario,
            "fixture_version": self.fixture_version,
            "engine_version": self.engine_version,
            "policy_version": self.policy_version,
            "calendar_days": self.calendar_days,
            "start": self.start.isoformat(),
            "max_interval_days": round(self.max_interval_days, 6),
            "reason_codes": list(self.reason_codes),
            "steps": [
                {
                    "day": step.day,
                    "event_type": step.event_type,
                    "score": step.score,
                    "confidence": step.confidence,
                    "observed_at": step.observed_at.isoformat(),
                    "next_review_at": step.next_review_at.isoformat(),
                    "interval_days": round(step.interval_days, 6),
                    "retrievability_at_decision": round(step.retrievability_at_decision, 6),
                    "stability_days": round(step.stability_days, 6),
                    "reason_codes": list(step.reason_codes),
                    "explanation_template_key": step.explanation_template_key,
                }
                for step in self.steps
            ],
        }


def load_fixture(document: Any) -> dict[str, Any]:
    """Validate a calibration fixture document and return it unchanged.

    Raises :class:`FixtureError` for a missing version, a non-positive
    calendar, a duplicate scenario or a malformed event list, so a broken
    fixture fails loudly instead of silently weakening the simulation.
    """
    if not isinstance(document, dict):
        raise FixtureError("calibration fixture must be a JSON object")

    fixture_version = document.get("fixture_version")
    if not isinstance(fixture_version, str) or not fixture_version.startswith(
        FIXTURE_VERSION_PREFIX
    ):
        raise FixtureError(f"fixture_version must start with {FIXTURE_VERSION_PREFIX!r}")

    calendar_days = document.get("calendar_days", DEFAULT_CALENDAR_DAYS)
    if (
        not isinstance(calendar_days, int)
        or isinstance(calendar_days, bool)
        or not 1 <= calendar_days <= MAX_CALENDAR_DAYS
    ):
        raise FixtureError(f"calendar_days must be within [1, {MAX_CALENDAR_DAYS}]")

    scenarios = document.get("scenarios")
    if not isinstance(scenarios, list) or not scenarios:
        raise FixtureError("scenarios must be a non-empty list")

    names: list[str] = []
    for scenario in scenarios:
        if not isinstance(scenario, dict):
            raise FixtureError("each scenario must be a JSON object")
        name = scenario.get("name")
        if not isinstance(name, str) or not name:
            raise FixtureError("each scenario needs a name")
        if name in names:
            raise FixtureError(f"duplicate scenario: {name!r}")
        names.append(name)
        _validate_events(scenario.get("events"), calendar_days=calendar_days, name=name)

    missing = [name for name in REQUIRED_SCENARIOS if name not in names]
    if missing:
        raise FixtureError(f"fixture is missing required scenarios: {missing}")
    return document


def run_calendar_simulation(
    scenario: dict[str, Any],
    *,
    start: datetime,
    fixture_version: str,
    calendar_days: int = DEFAULT_CALENDAR_DAYS,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> SimulationResult:
    """Replay one scenario's evidence across the calendar through the engine."""
    if start.tzinfo is None:
        raise ValueError("start must be timezone-aware")
    events = _validate_events(scenario.get("events"), calendar_days=calendar_days, name=None)

    state: LearnerConceptState | None = None
    steps: list[SimulationStep] = []
    for event_spec in events:
        observed_at = _instant(start, event_spec["day"])
        facts = EventFacts(
            event_type=event_spec["event_type"],
            observed_at=observed_at,
            confidence=event_spec["confidence"],
            score=event_spec.get("score"),
        )
        signal = (
            PrerequisiteSignal(weak_prerequisite_concept_ids=("synthetic-prerequisite",))
            if event_spec.get("weak_prerequisite")
            else None
        )
        decision = decide_with_policy(
            state,
            facts,
            now=observed_at,
            prerequisite_signal=signal,
            config=config,
        )
        state = decision.result_state
        steps.append(
            SimulationStep(
                day=event_spec["day"],
                event_type=facts.event_type,
                score=facts.score,
                confidence=facts.confidence,
                observed_at=observed_at,
                next_review_at=decision.next_review_at,
                interval_days=(decision.next_review_at - observed_at).total_seconds() / 86400.0,
                retrievability_at_decision=decision.retrievability_at_decision,
                stability_days=decision.result_state.stability_days,
                reason_codes=decision.reason_codes,
                explanation_template_key=decision.explanation_template_key,
            )
        )

    return SimulationResult(
        scenario=str(scenario["name"]),
        fixture_version=fixture_version,
        engine_version=config.engine_version,
        policy_version=config.policy_version,
        calendar_days=calendar_days,
        start=start,
        steps=tuple(steps),
        final_state=state,
    )


def run_fixture(
    document: dict[str, Any],
    *,
    start: datetime,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> tuple[SimulationResult, ...]:
    """Replay every scenario of a validated fixture in fixture order."""
    fixture = load_fixture(document)
    calendar_days = int(fixture.get("calendar_days", DEFAULT_CALENDAR_DAYS))
    return tuple(
        run_calendar_simulation(
            scenario,
            start=start,
            fixture_version=fixture["fixture_version"],
            calendar_days=calendar_days,
            config=config,
        )
        for scenario in fixture["scenarios"]
    )


# ----------------------------------------------------------------------
# validation helpers
# ----------------------------------------------------------------------


def _validate_events(
    events: Any,
    *,
    calendar_days: int,
    name: str | None,
) -> list[dict[str, Any]]:
    label = "scenario" if name is None else f"scenario {name!r}"
    if not isinstance(events, list) or not events:
        raise FixtureError(f"{label} needs a non-empty events list")

    validated: list[dict[str, Any]] = []
    previous_day = -1
    for event in events:
        if not isinstance(event, dict):
            raise FixtureError(f"{label} events must be JSON objects")
        day = event.get("day")
        if not isinstance(day, int) or isinstance(day, bool):
            raise FixtureError(f"{label} event day must be an integer")
        if day < previous_day:
            raise FixtureError(f"{label} event days must be non-decreasing")
        if day >= calendar_days:
            raise FixtureError(f"{label} event day {day} is outside the calendar")
        previous_day = day

        event_type = event.get("event_type")
        if event_type not in MEMORY_EVENT_TYPES:
            raise FixtureError(f"{label} has an unknown event_type: {event_type!r}")
        confidence = event.get("confidence")
        if (
            not isinstance(confidence, (int, float))
            or isinstance(confidence, bool)
            or not 0.0 <= float(confidence) <= 1.0
        ):
            raise FixtureError(f"{label} event confidence must be within [0, 1]")

        score = event.get("score")
        if event_type == EVENT_EXPOSURE:
            if score is not None:
                raise FixtureError(f"{label} exposure events carry no score")
        elif event_type in SCORED_MEMORY_EVENT_TYPES:
            if (
                not isinstance(score, (int, float))
                or isinstance(score, bool)
                or not 0.0 <= float(score) <= 1.0
            ):
                raise FixtureError(f"{label} scored events need a score within [0, 1]")
        elif score is not None:
            raise FixtureError(f"{label} {event_type} events carry no score")

        if not isinstance(event.get("weak_prerequisite", False), bool):
            raise FixtureError(f"{label} weak_prerequisite must be a boolean")

        validated.append(dict(event))
    return validated


def _instant(start: datetime, day: int) -> datetime:
    day_start = start.astimezone(UTC).replace(
        hour=SIMULATION_HOUR_UTC, minute=0, second=0, microsecond=0
    )
    return day_start + timedelta(days=day)
