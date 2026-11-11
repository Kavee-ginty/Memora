"""Closed contracts for the notification domain.

Every category, route intent, localization key and payload parameter that can
appear in a push payload is defined here. The payload builder in
:mod:`memora.modules.notifications.payload` rejects anything outside these
sets, so a payload cannot carry free-form content (API §16.2: no note text,
answers, misconception details or tokens).

The category set and the destination/fallback pairs mirror the supported
deep links in Flow §13.1. Route names match the canonical route inventory in
Flow §3.3 and the mobile ``app_router.dart`` route names.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import timedelta
from typing import Final

# Notification categories. One per supported deep-link intent (Flow §13.1).
CATEGORY_MISSION_READY: Final = "mission_ready"
CATEGORY_DUE_MEMORIES: Final = "due_memories"
CATEGORY_VERIFICATION_REQUIRED: Final = "verification_required"
CATEGORY_LEARNING_PATH_READY: Final = "learning_path_ready"
CATEGORY_REWARD_READY: Final = "reward_ready"
CATEGORY_PRIVACY_EXPORT_READY: Final = "privacy_export_ready"

NOTIFICATION_CATEGORIES: Final[tuple[str, ...]] = (
    CATEGORY_MISSION_READY,
    CATEGORY_DUE_MEMORIES,
    CATEGORY_VERIFICATION_REQUIRED,
    CATEGORY_LEARNING_PATH_READY,
    CATEGORY_REWARD_READY,
    CATEGORY_PRIVACY_EXPORT_READY,
)

# Reminder categories are scheduled, repeated prompts (daily mission, due
# memories). PRD 032 frequency caps and reminder preferences apply to these.
# The remaining categories are one-per-workflow status signals.
REMINDER_CATEGORIES: Final[tuple[str, ...]] = (
    CATEGORY_MISSION_READY,
    CATEGORY_DUE_MEMORIES,
)

# Routes a deep link may never open directly: timed or submitted question
# surfaces (Flow §13.1; UI/UX §9.21). The deepest mission target is the
# mission preview.
BLOCKED_DEEP_LINK_ROUTES: Final[frozenset[str]] = frozenset(
    {"mission", "missionFeedback", "explanation"}
)

# Route intents. Kept distinct from categories so the wire contract names the
# *intent* while the registry owns routing decisions.
INTENT_OPEN_MISSION_PREVIEW: Final = "open_mission_preview"
INTENT_OPEN_VERIFY_CONCEPTS: Final = "open_verify_concepts"
INTENT_OPEN_PATH_PREVIEW: Final = "open_path_preview"
INTENT_OPEN_PROGRESS: Final = "open_progress"
INTENT_OPEN_EXPORT_STATUS: Final = "open_export_status"

# Localization keys rendered by the mobile client (UI/UX §9.21 contextual
# copy). Keys are stable identifiers; clients ship the copy.
LOC_MISSION_READY: Final = "notification.mission_ready"
LOC_DUE_MEMORIES: Final = "notification.due_memories"
LOC_VERIFICATION_REQUIRED: Final = "notification.verification_required"
LOC_LEARNING_PATH_READY: Final = "notification.learning_path_ready"
LOC_REWARD_READY: Final = "notification.reward_ready"
LOC_PRIVACY_EXPORT_READY: Final = "notification.privacy_export_ready"

# Safe payload parameters. The only free-ish value is the curriculum subject
# display name; everything else is a bounded count. ``subject_name`` may be
# included only for ``subject``/``detailed`` lock-screen detail bands, and
# ``count`` only for ``detailed`` (PRD 031: minimal preview must not expose
# learning detail).
PARAM_SUBJECT_NAME: Final = "subject_name"
PARAM_COUNT: Final = "count"
SAFE_PARAM_NAMES: Final[tuple[str, ...]] = (PARAM_SUBJECT_NAME, PARAM_COUNT)

SUBJECT_NAME_MAX_LENGTH: Final = 64
COUNT_MAX: Final = 999

# Version of the on-wire data payload shape. Bump on any incompatible change
# so clients can ignore unknown future shapes safely.
PAYLOAD_SCHEMA_VERSION: Final = "1"

# Intent lifetime. Reminders expire after a day; workflow status signals stay
# actionable for the same window the underlying workflow remains open (the
# client revalidates through the API regardless, per API §16.3).
REMINDER_INTENT_TTL: Final = timedelta(hours=24)
WORKFLOW_INTENT_TTL: Final = timedelta(hours=72)


@dataclass(frozen=True)
class NotificationCategorySpec:
    """Routing and copy contract for one notification category."""

    category: str
    route_intent: str
    destination_route: str
    fallback_route: str
    loc_key: str
    reminder: bool
    intent_ttl: timedelta


CATEGORY_REGISTRY: Final[dict[str, NotificationCategorySpec]] = {
    spec.category: spec
    for spec in (
        NotificationCategorySpec(
            category=CATEGORY_MISSION_READY,
            route_intent=INTENT_OPEN_MISSION_PREVIEW,
            destination_route="missionPreview",
            fallback_route="home",
            loc_key=LOC_MISSION_READY,
            reminder=True,
            intent_ttl=REMINDER_INTENT_TTL,
        ),
        NotificationCategorySpec(
            category=CATEGORY_DUE_MEMORIES,
            route_intent=INTENT_OPEN_MISSION_PREVIEW,
            destination_route="missionPreview",
            fallback_route="home",
            loc_key=LOC_DUE_MEMORIES,
            reminder=True,
            intent_ttl=REMINDER_INTENT_TTL,
        ),
        NotificationCategorySpec(
            category=CATEGORY_VERIFICATION_REQUIRED,
            route_intent=INTENT_OPEN_VERIFY_CONCEPTS,
            destination_route="verifyConcepts",
            fallback_route="materialStatus",
            loc_key=LOC_VERIFICATION_REQUIRED,
            reminder=False,
            intent_ttl=WORKFLOW_INTENT_TTL,
        ),
        NotificationCategorySpec(
            category=CATEGORY_LEARNING_PATH_READY,
            route_intent=INTENT_OPEN_PATH_PREVIEW,
            destination_route="pathPreview",
            fallback_route="learning",
            loc_key=LOC_LEARNING_PATH_READY,
            reminder=False,
            intent_ttl=WORKFLOW_INTENT_TTL,
        ),
        NotificationCategorySpec(
            category=CATEGORY_REWARD_READY,
            route_intent=INTENT_OPEN_PROGRESS,
            destination_route="progress",
            fallback_route="progress",
            loc_key=LOC_REWARD_READY,
            reminder=False,
            intent_ttl=WORKFLOW_INTENT_TTL,
        ),
        NotificationCategorySpec(
            category=CATEGORY_PRIVACY_EXPORT_READY,
            route_intent=INTENT_OPEN_EXPORT_STATUS,
            destination_route="privacyExportStatus",
            fallback_route="privacy",
            loc_key=LOC_PRIVACY_EXPORT_READY,
            reminder=False,
            intent_ttl=WORKFLOW_INTENT_TTL,
        ),
    )
}


def category_spec(category: str) -> NotificationCategorySpec:
    """Return the registry spec for ``category`` or raise ``KeyError``."""

    return CATEGORY_REGISTRY[category]
