from datetime import UTC, date, datetime, timedelta

import pytest

from memora.modules.engagement.policy import (
    ReefInputs,
    calculate_xp,
    project_reef,
    streak_qualification,
)


def test_xp_v1_rewards_protected_and_repaired_equally() -> None:
    assert calculate_xp(4, 2, comeback=False) == 46
    assert calculate_xp(4, 2, comeback=True) == 52
    assert calculate_xp(0, 0, comeback=False) == 0


def test_xp_v1_rejects_negative_counts() -> None:
    with pytest.raises(ValueError):
        calculate_xp(-1, 0, comeback=False)


def test_streak_v1_uses_one_immediately_preceding_grace_day() -> None:
    today = date(2026, 11, 14)
    assert streak_qualification(today, [date(2026, 11, 13)]) == (
        "mission_completed",
        None,
    )
    assert streak_qualification(today, [date(2026, 11, 12)]) == (
        "mission_completed",
        date(2026, 11, 13),
    )
    assert streak_qualification(
        today,
        [date(2026, 11, 12)],
        [date(2026, 11, 10)],
    ) == ("comeback_completed", None)
    assert streak_qualification(today, [date(2026, 11, 11)]) == (
        "comeback_completed",
        None,
    )


def test_reef_v1_covers_all_five_states_deterministically() -> None:
    now = datetime(2026, 11, 14, tzinfo=UTC)
    cases = (
        (ReefInputs(0, 0, 0, 0, 0, None, now), "new"),
        (ReefInputs(5, 0.9, 0.05, 0.1, 0.9, now, now), "thriving"),
        (ReefInputs(5, 0.7, 0.2, 0.2, 0.7, now, now), "healthy"),
        (ReefInputs(5, 0.4, 0.6, 0.7, 0.3, now, now), "needs_care"),
        (
            ReefInputs(5, 0.8, 0.1, 0.1, 0.8, now - timedelta(days=30), now),
            "dormant",
        ),
    )
    for inputs, expected in cases:
        first = project_reef(inputs)
        assert first.condition == expected
        assert project_reef(inputs) == first
