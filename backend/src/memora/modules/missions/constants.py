"""Versioned policy constants for T13 Daily Missions."""

from typing import Final

MISSION_POLICY_VERSION: Final[str] = "mission-policy/1"
MISSION_RANKING_VERSION: Final[str] = "mission-ranking/1"
CANDIDATE_SNAPSHOT_VERSION: Final[str] = "mission-candidates/1"
OUTBOX_SCHEMA_VERSION: Final[str] = "1"

MAX_PLANNED_ITEMS: Final[int] = 6
MAX_TOTAL_ITEMS: Final[int] = 7
MAX_ESTIMATED_SECONDS: Final[int] = 7 * 60
MAX_REPAIR_ITEMS: Final[int] = 1

QUESTION_ESTIMATED_SECONDS: Final[dict[str, int]] = {
    "mcq": 60,
    "diagram_interpretation": 75,
    "numeric": 90,
}
SHORT_ANSWER_ENABLED: Final[bool] = False

MISSION_TYPES: Final[frozenset[str]] = frozenset(
    {"protect", "repair", "recover", "discover", "challenge"}
)
ACTIVE_MISSION_STATUSES: Final[frozenset[str]] = frozenset({"planned", "started", "paused"})
HANDLED_ITEM_STATUSES: Final[frozenset[str]] = frozenset({"answered", "skipped", "cancelled"})

REPAIR_CONFIDENCE_FLOOR: Final[float] = 0.70
REPETITION_LOOKBACK_DAYS: Final[int] = 30

ATTEMPT_GRADED_EVENT: Final[str] = "mission.attempt_graded"
MISSION_COMPLETED_EVENT: Final[str] = "mission.completed"
