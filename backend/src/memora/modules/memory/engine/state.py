"""Learner-concept memory state: the quantitative model of Schema §10.1.

The state is an immutable value object. The engine never mutates a state; a
decision produces a new one. The persistence layer owns the identity columns
(``user_id``, ``concept_id``, ``active_concept_version_id``) — the engine
state carries only the quantitative and temporal fields, so no decision can
ever touch another concept's state (Task Table T11 isolation gate).
"""

from __future__ import annotations

from dataclasses import dataclass, replace
from datetime import UTC, datetime
from typing import Any

from memora.modules.memory.engine.config import (
    DEFAULT_ENGINE_CONFIG,
    STATE_SNAPSHOT_SCHEMA_VERSION,
    EngineConfig,
)

_UTC: Any = UTC


def require_utc(value: datetime, name: str) -> datetime:
    """Return ``value`` normalized to UTC or raise if it is naive."""
    if value.tzinfo is None:
        raise ValueError(f"{name} must be timezone-aware")
    return value.astimezone(_UTC)


@dataclass(frozen=True)
class LearnerConceptState:
    """Current FSRS-style snapshot for one learner-concept pair.

    ``last_retrievability`` is the retrievability computed at the most recent
    decision, not a live value; live retrievability is always derived from
    ``stability_days`` and elapsed time at decision time.
    """

    difficulty: float
    stability_days: float
    last_retrievability: float
    evidence_confidence: float
    first_exposed_at: datetime
    next_review_at: datetime
    last_reviewed_at: datetime | None = None
    exposure_count: int = 0
    eligible_review_count: int = 0
    lapse_count: int = 0

    def __post_init__(self) -> None:
        object.__setattr__(
            self, "first_exposed_at", require_utc(self.first_exposed_at, "first_exposed_at")
        )
        if self.last_reviewed_at is not None:
            object.__setattr__(
                self,
                "last_reviewed_at",
                require_utc(self.last_reviewed_at, "last_reviewed_at"),
            )
        object.__setattr__(
            self, "next_review_at", require_utc(self.next_review_at, "next_review_at")
        )

    def with_counts(
        self,
        *,
        exposure_delta: int = 0,
        review_delta: int = 0,
        lapse_delta: int = 0,
    ) -> LearnerConceptState:
        return replace(
            self,
            exposure_count=self.exposure_count + exposure_delta,
            eligible_review_count=self.eligible_review_count + review_delta,
            lapse_count=self.lapse_count + lapse_delta,
        )

    def to_snapshot(self) -> dict[str, Any]:
        """Serialise to the schema-versioned jsonb shape stored in decisions."""
        return {
            "schema_version": STATE_SNAPSHOT_SCHEMA_VERSION,
            "engine_version": DEFAULT_ENGINE_CONFIG.engine_version,
            "difficulty": self.difficulty,
            "stability_days": self.stability_days,
            "last_retrievability": self.last_retrievability,
            "evidence_confidence": self.evidence_confidence,
            "first_exposed_at": self.first_exposed_at.isoformat(),
            "last_reviewed_at": (
                None if self.last_reviewed_at is None else self.last_reviewed_at.isoformat()
            ),
            "next_review_at": self.next_review_at.isoformat(),
            "exposure_count": self.exposure_count,
            "eligible_review_count": self.eligible_review_count,
            "lapse_count": self.lapse_count,
        }

    @classmethod
    def from_snapshot(
        cls,
        snapshot: dict[str, Any],
        *,
        config: EngineConfig = DEFAULT_ENGINE_CONFIG,
    ) -> LearnerConceptState:
        """Rebuild a state from its stored snapshot.

        Raises ``ValueError`` for an unknown schema version or any value
        outside the engine contract: persisted states are written by the
        engine itself, so out-of-bounds data means corruption, not input to
        repair.
        """
        schema_version = snapshot.get("schema_version")
        if schema_version != STATE_SNAPSHOT_SCHEMA_VERSION:
            raise ValueError(f"unsupported memory state snapshot: {schema_version!r}")

        difficulty = _as_float(snapshot, "difficulty")
        stability = _as_float(snapshot, "stability_days")
        retrievability = _as_float(snapshot, "last_retrievability")
        confidence = _as_float(snapshot, "evidence_confidence")

        if not config.difficulty_min <= difficulty <= config.difficulty_max:
            raise ValueError("difficulty outside engine contract")
        if not config.stability_min_days <= stability <= config.stability_max_days:
            raise ValueError("stability outside engine contract")
        if not 0.0 <= retrievability <= 1.0:
            raise ValueError("retrievability outside engine contract")
        if not 0.0 <= confidence <= 1.0:
            raise ValueError("evidence confidence outside engine contract")

        last_reviewed_raw = snapshot.get("last_reviewed_at")
        return cls(
            difficulty=difficulty,
            stability_days=stability,
            last_retrievability=retrievability,
            evidence_confidence=confidence,
            first_exposed_at=_as_datetime(snapshot, "first_exposed_at"),
            last_reviewed_at=(
                None if last_reviewed_raw is None else _as_datetime(snapshot, "last_reviewed_at")
            ),
            next_review_at=_as_datetime(snapshot, "next_review_at"),
            exposure_count=_as_non_negative_int(snapshot, "exposure_count"),
            eligible_review_count=_as_non_negative_int(snapshot, "eligible_review_count"),
            lapse_count=_as_non_negative_int(snapshot, "lapse_count"),
        )


def _as_float(snapshot: dict[str, Any], key: str) -> float:
    value = snapshot.get(key)
    if not isinstance(value, (int, float)) or isinstance(value, bool):
        raise ValueError(f"memory state snapshot field {key!r} must be numeric")
    return float(value)


def _as_non_negative_int(snapshot: dict[str, Any], key: str) -> int:
    value = snapshot.get(key)
    if not isinstance(value, int) or isinstance(value, bool) or value < 0:
        raise ValueError(f"memory state snapshot field {key!r} must be a non-negative integer")
    return value


def _as_datetime(snapshot: dict[str, Any], key: str) -> datetime:
    value = snapshot.get(key)
    if not isinstance(value, str):
        raise ValueError(f"memory state snapshot field {key!r} must be an ISO timestamp")
    parsed = datetime.fromisoformat(value)
    return require_utc(parsed, key)
