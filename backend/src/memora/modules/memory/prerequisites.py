"""Read-only prerequisite signals from the knowledge graph (T08) and the
learner's own memory state.

The lookup never writes: prerequisite weakness only influences reason codes,
explanations and due-selection inputs. Recover mission selection stays with
T13. Graph traversal reuses :class:`memora.modules.curriculum.service.CurriculumService`
so the edge semantics (``prerequisite_of``, approved, valid window, bounded
depth and result count) have exactly one implementation.
"""

from __future__ import annotations

from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, text

from memora.modules.curriculum.constants import DEFAULT_PREREQ_DEPTH, MAX_PREREQ_RESULTS
from memora.modules.curriculum.service import CurriculumService
from memora.modules.memory.engine import fsrs
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG, EngineConfig
from memora.modules.memory.engine.policy import PrerequisiteSignal

# Upper bound on prerequisite states inspected per signal; the traversal
# result limit already bounds this, the constant documents the intent.
MAX_SIGNAL_RESULTS = MAX_PREREQ_RESULTS

_STATE_QUERY = text(
    """
    SELECT stability_days, last_reviewed_at, first_exposed_at
    FROM learner_concept_states
    WHERE user_id = :user_id AND concept_id = :concept_id
    """
)


def prerequisite_concept_ids(
    connection: Connection,
    *,
    concept_version_id: UUID | str,
    max_depth: int = DEFAULT_PREREQ_DEPTH,
) -> tuple[str, ...]:
    """Approved prerequisite concept IDs from the bounded graph traversal."""
    rows = CurriculumService(connection).get_prerequisites(
        concept_version_id, max_depth=max_depth, result_limit=MAX_SIGNAL_RESULTS
    )
    return tuple(str(row["concept_id"]) for row in rows)


def collect_prerequisite_signal(
    connection: Connection,
    *,
    user_id: UUID | str,
    concept_version_id: UUID | str,
    now: datetime,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> PrerequisiteSignal:
    """Flag prerequisites whose current retrievability is below the floor.

    A prerequisite the learner has never touched is a curriculum-coverage
    matter, not weak memory, and is not flagged here. The ``user_id``
    predicate documents intent; RLS remains defence in depth and scopes the
    query to the transaction's principal when run through the API/worker
    context.
    """
    if now.tzinfo is None:
        raise ValueError("now must be timezone-aware")

    weak: list[str] = []
    for concept_id in prerequisite_concept_ids(connection, concept_version_id=concept_version_id):
        row: dict[str, Any] | None = (
            connection.execute(
                _STATE_QUERY,
                {"user_id": str(user_id), "concept_id": concept_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            continue
        anchor = row["last_reviewed_at"] or row["first_exposed_at"]
        if is_weak_prerequisite_state(float(row["stability_days"]), anchor, now, config=config):
            weak.append(concept_id)
    return PrerequisiteSignal(weak_prerequisite_concept_ids=tuple(weak))


def is_weak_prerequisite_state(
    stability_days: float,
    anchor: datetime,
    now: datetime,
    *,
    config: EngineConfig = DEFAULT_ENGINE_CONFIG,
) -> bool:
    """Whether a prerequisite's current state counts as weak.

    Shared by the decision-time signal and the due-selection inputs so the
    Recover flag and the planner's weak-prerequisite flag use one rule.
    """
    retrievability = fsrs.retrievability(stability_days, anchor, now, config=config)
    return retrievability < config.weak_prerequisite_retrievability_floor
