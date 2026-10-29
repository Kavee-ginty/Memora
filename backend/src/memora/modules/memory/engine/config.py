"""Versioned configuration for the FSRS-style memory engine.

Every number the engine uses lives here in one frozen value object. Weights
are configuration, not code (TRD §9.4); changing any value requires bumping
``ENGINE_VERSION`` (quantitative model) or ``POLICY_VERSION`` (expert rules)
so that every persisted decision stays reproducible against the exact
configuration that produced it.

The model follows the FSRS family structure: a power-law forgetting curve, a
mean-reverted difficulty in a bounded range, multiplicative stability growth
after successful recall, and power-law stability collapse after a lapse.
It is deliberately not a verbatim port of any published FSRS release: the
weights are named, bounded, and calibrated by the fixtures in
``backend/tests/fixtures/memory`` instead of learned parameters.
"""

from __future__ import annotations

from dataclasses import dataclass

ENGINE_VERSION: str = "fsrs-mvp-1.0.0"
POLICY_VERSION: str = "policy-mvp-1.0.0"

# Snapshot payload schema version for state serialised into the
# ``memory_decisions.previous_state`` / ``result_state`` jsonb columns.
STATE_SNAPSHOT_SCHEMA_VERSION: str = "memora.memory_state/1"


@dataclass(frozen=True)
class EngineConfig:
    """Immutable engine and policy configuration.

    Attributes mirror the formulas in :mod:`memora.modules.memory.engine.fsrs`.
    All multipliers are non-negative; ranges are inclusive.
    """

    # --- model identity -------------------------------------------------
    engine_version: str = ENGINE_VERSION
    policy_version: str = POLICY_VERSION

    # --- forgetting curve -----------------------------------------------
    # R(t) = (1 + FACTOR * t / S) ** DECAY, clamped to [0, 1].
    # With DECAY=-0.5 and FACTOR=19/81, R(t = S) equals
    # ``desired_retention`` exactly, so the scheduled interval in days is
    # the post-review stability.
    decay: float = -0.5
    factor: float = 19.0 / 81.0
    desired_retention: float = 0.9

    # --- state bounds (the "engine contract" of Schema §10.1) ------------
    difficulty_min: float = 1.0
    difficulty_max: float = 10.0
    difficulty_default: float = 5.0
    stability_min_days: float = 0.1
    stability_max_days: float = 3650.0
    # Stability attributed to a concept before the first scored review;
    # used only to compute elapsed retrievability for the first attempt.
    stability_probe_days: float = 0.5

    # --- grade mapping ---------------------------------------------------
    # Continuous grade G = 1 + grade_span * score maps a normalised score
    # in [0, 1] onto the FSRS-style [1, 4] grade axis.
    grade_span: float = 3.0
    # Scores at or above the threshold count as successful recall; below
    # as a lapse. ``partial`` grading outcomes (0.5) sit exactly at the
    # boundary and count as recall with a reduced growth factor.
    recall_score_threshold: float = 0.5

    # --- difficulty updates ----------------------------------------------
    difficulty_initial: float = 5.0
    difficulty_initial_slope: float = 1.0
    difficulty_update: float = 1.0
    difficulty_reversion: float = 0.2

    # --- stability growth on successful recall ----------------------------
    recall_gain: float = 3.0
    recall_grade_weight: float = 0.8
    recall_stability_damping: float = 0.2
    recall_elapsed_weight: float = 0.5

    # --- stability collapse on lapse --------------------------------------
    lapse_base: float = 1.0
    lapse_difficulty_damping: float = 0.2
    lapse_power: float = 0.3
    lapse_elapsed_weight: float = 0.3

    # --- evidence confidence ----------------------------------------------
    # Blend factor for folding an event's confidence into the running
    # per-concept evidence confidence.
    confidence_blend: float = 0.3

    # --- exposure bootstrap ------------------------------------------------
    # Stability assigned when a concept is first exposed (no scored review
    # yet); the first scheduled review follows the first-review policy.
    exposure_initial_stability_days: float = 0.5

    # --- initial stability after a first scored review (FSRS S0) ----------
    # S0(G) = initial_stability_base * exp(initial_stability_grade_weight
    # * (G - 3)); a strong first attempt starts far out, a weak one near in.
    initial_stability_base: float = 1.0
    initial_stability_grade_weight: float = 1.0

    # --- expert policy layer (TRD §9.3, versioned with POLICY_VERSION) ----
    # First retrieval lands inside this window unless first-attempt evidence
    # is strong enough to justify a later start (PRD 012).
    first_review_min_hours: float = 16.0
    first_review_max_hours: float = 48.0
    strong_evidence_score: float = 0.8
    # Events below the confidence floor have proportionally damped influence
    # on stability and difficulty; at the floor the influence is full (D4).
    confidence_floor: float = 0.35
    # An absence longer than this is a comeback: actual elapsed time is used,
    # but the next review is capped to a welcoming, manageable interval
    # (PRD 015).
    comeback_threshold_days: float = 7.0
    comeback_interval_max_days: float = 3.0
    # A failure explained by weak prerequisites pulls the next review earlier
    # so Recover work can follow (TRD §9.3).
    recover_interval_max_days: float = 7.0
    # A failure on a concept whose prerequisite is currently below this
    # retrievability counts as weak-prerequisite evidence.
    weak_prerequisite_retrievability_floor: float = 0.5
    # No scheduled interval may exceed this cap, so overdue work never
    # compounds into an unmanageable backlog (TRD §9.5).
    interval_max_days: float = 180.0

    def validate(self) -> None:
        """Fail fast on configuration that would break the engine contract."""
        checks = (
            0.0 < self.desired_retention < 1.0,
            0.0 < self.difficulty_min < self.difficulty_default < self.difficulty_max,
            0.0 < self.stability_min_days < self.stability_max_days,
            0.0 < self.stability_probe_days < self.stability_max_days,
            0.0 <= self.recall_score_threshold <= 1.0,
            self.grade_span > 0.0,
            self.decay < 0.0,
            self.factor > 0.0,
            0.0 <= self.confidence_blend <= 1.0,
            0.0 < self.exposure_initial_stability_days < self.stability_max_days,
            self.initial_stability_base > 0.0,
            self.initial_stability_grade_weight >= 0.0,
            0.0 < self.confidence_floor <= 1.0,
            0.0 <= self.strong_evidence_score <= 1.0,
            0.0 < self.first_review_min_hours < self.first_review_max_hours,
            self.comeback_threshold_days > 0.0,
            0.0 < self.comeback_interval_max_days <= self.interval_max_days,
            0.0 < self.recover_interval_max_days <= self.interval_max_days,
            self.interval_max_days > 0.0,
            0.0 < self.weak_prerequisite_retrievability_floor <= 1.0,
            all(
                weight >= 0.0
                for weight in (
                    self.difficulty_initial_slope,
                    self.difficulty_update,
                    self.recall_gain,
                    self.recall_grade_weight,
                    self.recall_stability_damping,
                    self.recall_elapsed_weight,
                    self.lapse_base,
                    self.lapse_difficulty_damping,
                    self.lapse_power,
                    self.lapse_elapsed_weight,
                )
            ),
            0.0 <= self.difficulty_reversion <= 1.0,
        )
        if not all(checks):
            raise ValueError("invalid memory engine configuration")


DEFAULT_ENGINE_CONFIG = EngineConfig()
DEFAULT_ENGINE_CONFIG.validate()
