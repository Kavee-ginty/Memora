"""FSRS-style quantitative transitions.

Pure math only: every function takes explicit inputs and configuration and
returns clamped values inside the engine contract. No function reads a clock
or holds state, so identical inputs reproduce identical outputs bit for bit.

Model summary (version ``fsrs-mvp-1.0.0``, see ``engine/config.py``):

- Forgetting curve: ``R(t) = (1 + FACTOR * t / S) ** DECAY`` with
  ``DECAY = -0.5`` and ``FACTOR = 19/81``. By construction ``R(t = S)`` equals
  the desired retention (0.9), so a review scheduled one stability away is
  predicted to land at the desired retention.
- Grade: a normalised score in ``[0, 1]`` maps onto the FSRS-style ``[1, 4]``
  grade axis as ``G = 1 + grade_span * score``.
- Difficulty: updated against the grade, then pulled back toward the initial
  difficulty (mean reversion), clamped to ``[1, 10]``.
- Stability after successful recall: multiplicative growth that shrinks as
  stability grows and grows with how much time had already elapsed (the
  recall happened further down the forgetting curve).
- Stability after a lapse: power-law collapse scaled by difficulty and elapsed
  retrievability.
"""

from __future__ import annotations

import math
from dataclasses import dataclass
from datetime import datetime

from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig

_EPSILON = 1e-12


@dataclass(frozen=True)
class Grade:
    """A score mapped onto the continuous FSRS-style grade axis."""

    score: float
    value: float
    is_recall: bool


def map_score_to_grade(
    score: float,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> Grade:
    """Map a normalised score onto the grade axis and the recall/lapse split."""
    if not 0.0 <= score <= 1.0:
        raise ValueError("score must be within [0, 1]")
    grade_value = 1.0 + config.grade_span * score
    return Grade(
        score=score,
        value=grade_value,
        is_recall=score >= config.recall_score_threshold,
    )


def clamp(value: float, lower: float, upper: float) -> float:
    return min(max(value, lower), upper)


def retrievability(
    stability_days: float,
    last_reviewed_at: datetime,
    observed_at: datetime,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """Estimated recall probability ``elapsed`` days after the last review."""
    elapsed_days = max((observed_at - last_reviewed_at).total_seconds() / 86400.0, 0.0)
    stability = max(stability_days, _EPSILON)
    raw = (1.0 + config.factor * elapsed_days / stability) ** config.decay
    return clamp(raw, 0.0, 1.0)


def interval_for_retention(
    stability_days: float,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """Interval in days at which the forgetting curve hits the target retention.

    With the default curve parameters the answer is exactly ``stability_days``;
    the function exists so a future curve change keeps scheduling consistent.
    """
    exponent = 1.0 / config.decay
    interval = stability_days * ((config.desired_retention**exponent - 1.0) / config.factor)
    return max(interval, config.stability_min_days)


def initial_difficulty(
    grade: Grade,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """First difficulty estimate from a grade, clamped to the engine contract."""
    raw = config.difficulty_initial - (grade.value - 3.0) * config.difficulty_initial_slope
    return clamp(raw, config.difficulty_min, config.difficulty_max)


def initial_stability(
    grade: Grade,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """Stability after the first scored review of a concept (FSRS S0).

    Follows the FSRS family convention that the first rating seeds stability
    directly from the grade instead of transitioning from a probe value.
    """
    raw = config.initial_stability_base * math.exp(
        config.initial_stability_grade_weight * (grade.value - 3.0)
    )
    return clamp(raw, config.stability_min_days, config.stability_max_days)


def next_difficulty(
    difficulty: float,
    grade: Grade,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """Grade-driven difficulty update with mean reversion toward the initial."""
    updated = difficulty - config.difficulty_update * (grade.value - 3.0)
    reverted = (
        config.difficulty_reversion * config.difficulty_default
        + (1.0 - config.difficulty_reversion) * updated
    )
    return clamp(reverted, config.difficulty_min, config.difficulty_max)


def stability_after_recall(
    stability_days: float,
    grade: Grade,
    retrievability_at_review: float,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """Bounded multiplicative growth after a successful recall."""
    stability = max(stability_days, _EPSILON)
    growth = (
        config.recall_gain
        * math.exp(config.recall_grade_weight * (grade.value - 3.0))
        * stability ** (-config.recall_stability_damping)
        * math.expm1(config.recall_elapsed_weight * (1.0 - retrievability_at_review))
    )
    return clamp(
        stability * (1.0 + max(growth, 0.0)),
        config.stability_min_days,
        config.stability_max_days,
    )


def stability_after_lapse(
    stability_days: float,
    difficulty: float,
    retrievability_at_review: float,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """Bounded power-law collapse after a lapse."""
    stability = max(stability_days, _EPSILON)
    collapsed = (
        config.lapse_base
        * difficulty ** (-config.lapse_difficulty_damping)
        * math.expm1(config.lapse_power * math.log1p(stability))
        * math.exp(config.lapse_elapsed_weight * (1.0 - retrievability_at_review))
    )
    return clamp(
        max(collapsed, 0.0),
        config.stability_min_days,
        config.stability_max_days,
    )


def blend_confidence(
    current_confidence: float,
    event_confidence: float,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> float:
    """Fold one event's confidence into the running evidence confidence."""
    if not 0.0 <= current_confidence <= 1.0:
        raise ValueError("current confidence must be within [0, 1]")
    if not 0.0 <= event_confidence <= 1.0:
        raise ValueError("event confidence must be within [0, 1]")
    blended = (1.0 - config.confidence_blend) * current_confidence + (
        config.confidence_blend * event_confidence
    )
    return clamp(blended, 0.0, 1.0)
