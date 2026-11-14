"""Closed push payload contract tests (T19 Commit 1).

Covers the API §16.2 allowlist: the builder accepts only registered
categories, opaque identifiers, safe parameters and timezone-aware expiries;
lock-screen detail bands filter parameters (PRD 031); the flattened wire form
round-trips; and malformed data raises :class:`PayloadError` so callers fall
back safely instead of crashing.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta

import pytest

from memora.modules.notifications.constants import (
    CATEGORY_DUE_MEMORIES,
    CATEGORY_MISSION_READY,
    CATEGORY_PRIVACY_EXPORT_READY,
    LOC_MISSION_READY,
    PARAM_COUNT,
    PARAM_SUBJECT_NAME,
    REMINDER_INTENT_TTL,
    category_spec,
)
from memora.modules.notifications.payload import (
    PayloadError,
    build_payload,
    is_expired,
    payload_from_data,
    payload_to_data,
    tray_body,
)

NOW = datetime.now(UTC)


def build(**overrides):  # noqa: ANN001, ANN202 - test helper with defaults
    defaults = dict(
        category=CATEGORY_MISSION_READY,
        resource_id="018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80",
        expires_at=NOW + REMINDER_INTENT_TTL,
        notification_id="a1b2c3d4e5f60718293a4b5c6d7e8f90",
        detail="minimal",
    )
    defaults.update(overrides)
    return build_payload(**defaults)


def test_minimal_band_strips_all_parameters() -> None:
    payload = build(
        detail="minimal",
        params={PARAM_SUBJECT_NAME: "Physics", PARAM_COUNT: 3},
    )
    assert payload.params == {}


def test_subject_band_keeps_only_subject_name() -> None:
    payload = build(
        category=CATEGORY_DUE_MEMORIES,
        detail="subject",
        params={PARAM_SUBJECT_NAME: "Physics", PARAM_COUNT: 3},
    )
    assert payload.params == {PARAM_SUBJECT_NAME: "Physics"}


def test_detailed_band_keeps_all_safe_parameters() -> None:
    payload = build(detail="detailed", params={PARAM_SUBJECT_NAME: "Physics", PARAM_COUNT: 3})
    assert payload.params == {PARAM_SUBJECT_NAME: "Physics", PARAM_COUNT: 3}


def test_unknown_category_is_rejected() -> None:
    with pytest.raises(KeyError):
        build(category="streak_nag")


def test_unknown_parameter_name_is_rejected() -> None:
    with pytest.raises(PayloadError, match="outside the safe allowlist"):
        build(params={"answer_key": "C"})


def test_subject_name_bounds_are_enforced() -> None:
    with pytest.raises(PayloadError, match="1-64 characters"):
        build(params={PARAM_SUBJECT_NAME: "x" * 65})
    with pytest.raises(PayloadError, match="control characters"):
        build(params={PARAM_SUBJECT_NAME: "Physics\noverride"})


def test_count_bounds_are_enforced() -> None:
    with pytest.raises(PayloadError, match="between 0 and"):
        build(params={PARAM_COUNT: 1000})
    with pytest.raises(PayloadError, match="must be an integer"):
        build(params={PARAM_COUNT: "3"})


def test_naive_expiry_is_rejected() -> None:
    with pytest.raises(PayloadError, match="timezone-aware"):
        build(expires_at=datetime(2026, 1, 1))


def test_unknown_lock_screen_detail_is_rejected() -> None:
    with pytest.raises(PayloadError, match="lock_screen_detail"):
        build(detail="everything")


def test_identifier_shape_is_opaque_only() -> None:
    with pytest.raises(PayloadError, match="resource_id"):
        build(resource_id="read all my notes please")
    with pytest.raises(PayloadError, match="notification_id"):
        build(notification_id="short")


def test_resource_type_must_match_category() -> None:
    with pytest.raises(PayloadError, match="not valid for category"):
        build(resource_type="learning_update")


def test_route_intent_and_loc_key_come_from_registry() -> None:
    payload = build()
    spec = category_spec(payload.category)
    assert payload.route_intent == spec.route_intent
    assert payload.loc_key == LOC_MISSION_READY


def test_expired_detection_respects_boundary() -> None:
    payload = build(expires_at=NOW + timedelta(minutes=5))
    assert is_expired(payload, NOW + timedelta(minutes=4, seconds=59)) is False
    assert is_expired(payload, NOW + timedelta(minutes=5)) is True
    with pytest.raises(PayloadError, match="timezone-aware"):
        is_expired(payload, NOW.replace(tzinfo=None))


def test_wire_form_round_trip_preserves_contract_fields() -> None:
    payload = build(
        category=CATEGORY_PRIVACY_EXPORT_READY,
        detail="detailed",
        params={PARAM_SUBJECT_NAME: "Physics", PARAM_COUNT: 2},
    )
    restored = payload_from_data(payload_to_data(payload))
    assert restored == payload


def test_wire_form_rejects_unknown_versions_and_missing_keys() -> None:
    data = payload_to_data(build())
    with pytest.raises(PayloadError, match="schema_version"):
        payload_from_data({**data, "schema_version": "999"})
    incomplete = {key: value for key, value in data.items() if key != "loc_key"}
    with pytest.raises(PayloadError, match="missing keys"):
        payload_from_data(incomplete)


def test_wire_form_rejects_registry_mismatch() -> None:
    data = payload_to_data(build())
    with pytest.raises(PayloadError, match="route_intent"):
        payload_from_data({**data, "route_intent": "open_reward_center"})


def test_wire_form_rejects_out_of_band_parameters() -> None:
    data = payload_to_data(build(detail="minimal"))
    with pytest.raises(PayloadError, match="outside the safe allowlist"):
        payload_from_data({**data, "param.misconception": "why you failed"})


def test_every_category_has_a_complete_registry_entry() -> None:
    from memora.modules.notifications.constants import NOTIFICATION_CATEGORIES

    for category in NOTIFICATION_CATEGORIES:
        spec = category_spec(category)
        assert spec.destination_route != spec.category  # registry holds route names
        assert spec.fallback_route
        assert spec.loc_key.startswith("notification.")
        assert spec.intent_ttl > timedelta(0)


def test_tray_body_adapts_to_lock_screen_detail_bands() -> None:
    # The MVP's fixed Physics subject is safe in every detail band;
    # detailed alone adds the duration clause.
    subject_only = build_payload(
        category=CATEGORY_MISSION_READY,
        resource_id="018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80",
        expires_at=NOW + REMINDER_INTENT_TTL,
        notification_id="a1b2c3d4e5f60718293a4b5c6d7e8f90",
        detail="subject",
        params={PARAM_SUBJECT_NAME: "Physics"},
    )
    assert tray_body(subject_only) == "Your Physics daily mission is ready."

    minimal = build_payload(
        category=CATEGORY_MISSION_READY,
        resource_id="018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80",
        expires_at=NOW + REMINDER_INTENT_TTL,
        notification_id="a1b2c3d4e5f60718293a4b5c6d7e8f90",
        detail="minimal",
        params={PARAM_SUBJECT_NAME: "Physics", PARAM_COUNT: 5},
    )
    # Parameters outside the minimal band are dropped before rendering, so
    # no dangling "About minutes." fragment can appear.
    assert tray_body(minimal) == "Your Physics daily mission is ready."

    detailed = build_payload(
        category=CATEGORY_MISSION_READY,
        resource_id="018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80",
        expires_at=NOW + REMINDER_INTENT_TTL,
        notification_id="a1b2c3d4e5f60718293a4b5c6d7e8f90",
        detail="detailed",
        params={PARAM_SUBJECT_NAME: "Physics", PARAM_COUNT: 5},
    )
    assert tray_body(detailed) == "Your Physics daily mission is ready. About 5 minutes."


def test_tray_body_handles_other_categories_and_fallback() -> None:
    due = build_payload(
        category=CATEGORY_DUE_MEMORIES,
        resource_id="018f3c2a-7b9c-4d1e-9f2a-3b4c5d6e7f80",
        expires_at=NOW + REMINDER_INTENT_TTL,
        notification_id="a1b2c3d4e5f60718293a4b5c6d7e8f90",
    )
    assert tray_body(due) == (
        "A few Physics memories are ready for care. Review when it suits you."
    )


def test_registry_entries_stay_complete() -> None:
    from memora.modules.notifications.constants import NOTIFICATION_CATEGORIES

    for category in NOTIFICATION_CATEGORIES:
        spec = category_spec(category)
        assert spec.destination_route != spec.category
        assert spec.fallback_route
        assert spec.loc_key.startswith("notification.")
        assert spec.intent_ttl > timedelta(0)
        assert spec.route_intent
