"""Due-selection inputs for the mission planner (T11 Commit 5).

Proves the boundary T13 consumes: bounded pages of typed inputs (urgency,
forgetting risk, recent error severity, prerequisite impact, weak-prerequisite
evidence, comeback and coverage flags), deterministic keyset pagination, and
no cross-learner leakage. Selection itself stays with T13, so no ranking is
asserted here. Database tests skip unless MEMORA_TEST_DATABASE_URL targets a
disposable database.

Timing note: the seeded graph's approved edges become valid at seed time, so
every test anchors ``as_of`` on the real clock *after* the fixture seeded the
database. The engine itself never reads the clock.
"""

from __future__ import annotations

from datetime import UTC, datetime, timedelta
from uuid import UUID, uuid4

import pytest
from sqlalchemy import Engine, text

from memora.modules.memory.constants import (
    RETRIEVABILITY_BAND_CRITICAL,
    RETRIEVABILITY_BAND_FADING,
    RETRIEVABILITY_BAND_FRESH,
    RETRIEVABILITY_BAND_SETTLING,
    SELECTION_INPUT_VERSION,
    SELECTION_REASON_CODES,
    SELECTION_REASON_ERROR_REPAIR,
    SELECTION_REASON_NEW_CONCEPT,
    SELECTION_REASON_OVERDUE,
    SELECTION_REASON_RETENTION,
    SELECTION_REASON_WEAK_PREREQUISITE,
    URGENCY_BANDS,
    URGENCY_DUE,
    URGENCY_OVERDUE,
)
from memora.modules.memory.engine.config import DEFAULT_ENGINE_CONFIG
from memora.modules.memory.selection import (
    MAX_HORIZON_DAYS,
    MAX_SELECTION_LIMIT,
    decode_cursor,
    encode_cursor,
    list_due_candidates,
    retrievability_band,
)
from test_memory_persistence import (
    alembic_config,
    apply,
    attempt,
    create_user,
    exposure,
)

DAY = timedelta(days=1)
HOUR = timedelta(hours=1)
DISPOSABLE_DATABASE_SUFFIXES = ("_test", "_ci")


@pytest.fixture
def database(monkeypatch: pytest.MonkeyPatch):
    """Same disposable-database contract as the persistence suite."""
    import os

    from alembic import command
    from sqlalchemy import create_engine
    from sqlalchemy.engine import make_url

    database_url = os.getenv("MEMORA_TEST_DATABASE_URL")
    if not database_url:
        pytest.skip("MEMORA_TEST_DATABASE_URL is not configured")
    database_name = make_url(database_url).database or ""
    if not database_name.endswith(DISPOSABLE_DATABASE_SUFFIXES):
        pytest.fail(
            "MEMORA_TEST_DATABASE_URL must target a disposable database ending in "
            f"{' or '.join(DISPOSABLE_DATABASE_SUFFIXES)}",
            pytrace=False,
        )

    monkeypatch.setenv("MEMORA_DATABASE_URL", database_url)
    from memora.db.seed import seed_database

    command.upgrade(alembic_config(database_url), "head")
    seed_database(database_url)
    engine = create_engine(database_url, connect_args={"connect_timeout": 10})
    try:
        yield engine
    finally:
        engine.dispose()


@pytest.fixture
def now(database: Engine) -> datetime:
    """Real-clock anchor taken after the seeded graph is valid."""
    return datetime.now(UTC).replace(microsecond=0)


def physics_subject_id(engine: Engine) -> UUID:
    with engine.begin() as connection:
        return UUID(str(connection.scalar(text("SELECT id FROM subjects WHERE code = 'physics'"))))


def concept_by_code(engine: Engine, stable_code: str) -> tuple[UUID, UUID]:
    with engine.begin() as connection:
        row = (
            connection.execute(
                text(
                    """
                    SELECT c.id AS concept_id, cv.id AS version_id
                    FROM concepts c
                    JOIN concept_versions cv ON cv.concept_id = c.id
                    WHERE c.stable_code = :code AND cv.version_no = 1
                    """
                ),
                {"code": stable_code},
            )
            .mappings()
            .one()
        )
    return UUID(str(row["concept_id"])), UUID(str(row["version_id"]))


def expose(
    engine: Engine,
    *,
    user_id: UUID,
    concept_id: UUID,
    version_id: UUID,
    at: datetime,
) -> None:
    event, source_id = exposure(observed_at=at)
    apply(
        engine,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
        now=at,
    )


def score(
    engine: Engine,
    *,
    user_id: UUID,
    concept_id: UUID,
    version_id: UUID,
    at: datetime,
    value: float,
    confidence: float = 0.9,
) -> None:
    event, source_id = attempt(score=value, observed_at=at, confidence=confidence)
    apply(
        engine,
        user_id=user_id,
        concept_id=concept_id,
        concept_version_id=version_id,
        event=event,
        source_id=source_id,
        now=at,
    )


def page(engine: Engine, *, user_id: UUID, subject_id: UUID, as_of: datetime, **kwargs):
    with engine.begin() as connection:
        return list_due_candidates(
            connection, user_id=user_id, subject_id=subject_id, as_of=as_of, **kwargs
        )


def by_code(candidates, stable_code: str):
    return next(candidate for candidate in candidates if candidate.stable_code == stable_code)


# ---------------------------------------------------------------------------
# empty and bounded pages
# ---------------------------------------------------------------------------


def test_empty_state_returns_an_empty_versioned_page(database: Engine, now: datetime) -> None:
    user_id = create_user(database)
    result = page(database, user_id=user_id, subject_id=physics_subject_id(database), as_of=now)

    assert result.candidates == ()
    assert result.next_cursor is None
    assert result.selection_input_version == SELECTION_INPUT_VERSION
    assert result.engine_version == DEFAULT_ENGINE_CONFIG.engine_version
    assert result.policy_version == DEFAULT_ENGINE_CONFIG.policy_version


def test_limits_and_horizons_outside_bounds_are_rejected(database: Engine, now: datetime) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)

    for kwargs in (
        {"limit": 0},
        {"limit": MAX_SELECTION_LIMIT + 1},
        {"horizon_days": 0.0},
        {"horizon_days": MAX_HORIZON_DAYS + 1},
    ):
        with pytest.raises(ValueError):
            page(database, user_id=user_id, subject_id=subject_id, as_of=now, **kwargs)

    with pytest.raises(ValueError):
        page(
            database,
            user_id=user_id,
            subject_id=subject_id,
            as_of=datetime(2026, 10, 29, 12, 0, 0),
        )


# ---------------------------------------------------------------------------
# the inputs TRD 9.4 ranks on
# ---------------------------------------------------------------------------


def test_exposure_only_concept_is_new_due_and_coverage_mapped(
    database: Engine, now: datetime
) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    concept_id, version_id = concept_by_code(database, "PHYS-MEA-SI-UNITS")
    expose(database, user_id=user_id, concept_id=concept_id, version_id=version_id, at=now)

    candidate = by_code(
        page(database, user_id=user_id, subject_id=subject_id, as_of=now).candidates,
        "PHYS-MEA-SI-UNITS",
    )

    assert candidate.urgency == URGENCY_DUE
    assert candidate.selection_reason == SELECTION_REASON_NEW_CONCEPT
    assert candidate.is_new_concept
    assert candidate.eligible_review_count == 0
    assert candidate.exposure_count == 1
    assert 0.0 <= candidate.forgetting_risk <= 1.0
    assert candidate.retrievability_band in {
        RETRIEVABILITY_BAND_FRESH,
        RETRIEVABILITY_BAND_SETTLING,
        RETRIEVABILITY_BAND_FADING,
        RETRIEVABILITY_BAND_CRITICAL,
    }
    assert candidate.coverage_objective_ids, "seeded concepts map to an objective"
    assert candidate.prerequisite_impact >= 1, "SI units gates two concepts"


def test_overdue_concept_is_flagged_and_pages_are_time_ordered(
    database: Engine, now: datetime
) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    old_id, old_version = concept_by_code(database, "PHYS-MEA-SI-UNITS")
    new_id, new_version = concept_by_code(database, "PHYS-MEC-DISPLACEMENT")
    expose(database, user_id=user_id, concept_id=old_id, version_id=old_version, at=now - 10 * DAY)
    expose(database, user_id=user_id, concept_id=new_id, version_id=new_version, at=now)

    candidates = page(database, user_id=user_id, subject_id=subject_id, as_of=now).candidates

    overdue = by_code(candidates, "PHYS-MEA-SI-UNITS")
    assert overdue.urgency == URGENCY_OVERDUE
    assert overdue.overdue_days > 8.0
    assert overdue.selection_reason == SELECTION_REASON_OVERDUE
    assert [c.next_review_at for c in candidates] == sorted(c.next_review_at for c in candidates)
    assert candidates[0].stable_code == "PHYS-MEA-SI-UNITS"


def test_horizon_bounds_the_candidate_pool(database: Engine, now: datetime) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    concept_id, version_id = concept_by_code(database, "PHYS-MEC-VELOCITY")
    expose(database, user_id=user_id, concept_id=concept_id, version_id=version_id, at=now)
    score(
        database,
        user_id=user_id,
        concept_id=concept_id,
        version_id=version_id,
        at=now,
        value=1.0,
    )

    # The next review is roughly half a day out: outside a 6-hour horizon,
    # inside the maximum horizon.
    narrow = page(database, user_id=user_id, subject_id=subject_id, as_of=now, horizon_days=0.25)
    wide = page(
        database,
        user_id=user_id,
        subject_id=subject_id,
        as_of=now,
        horizon_days=MAX_HORIZON_DAYS,
    )

    assert narrow.candidates == ()
    assert [c.stable_code for c in wide.candidates] == ["PHYS-MEC-VELOCITY"]


def test_recent_low_scores_raise_error_severity_and_repair_reason(
    database: Engine, now: datetime
) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    concept_id, version_id = concept_by_code(database, "PHYS-MEC-NEWTON2")
    expose(
        database, user_id=user_id, concept_id=concept_id, version_id=version_id, at=now - 2 * DAY
    )
    score(
        database,
        user_id=user_id,
        concept_id=concept_id,
        version_id=version_id,
        at=now - 2 * DAY,
        value=0.2,
    )

    candidate = by_code(
        page(database, user_id=user_id, subject_id=subject_id, as_of=now).candidates,
        "PHYS-MEC-NEWTON2",
    )

    assert candidate.recent_error_count == 1
    assert candidate.recent_error_severity == pytest.approx(0.8)
    assert candidate.selection_reason == SELECTION_REASON_ERROR_REPAIR
    assert candidate.lapse_count == 1


def test_weak_prerequisite_is_flagged_from_the_approved_graph(
    database: Engine, now: datetime
) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    prerequisite_id, prerequisite_version = concept_by_code(database, "PHYS-MEC-DISPLACEMENT")
    dependent_id, dependent_version = concept_by_code(database, "PHYS-MEC-VELOCITY")
    # The prerequisite was exposed long ago and never reviewed: it is weak.
    expose(
        database,
        user_id=user_id,
        concept_id=prerequisite_id,
        version_id=prerequisite_version,
        at=now - 40 * DAY,
    )
    expose(
        database,
        user_id=user_id,
        concept_id=dependent_id,
        version_id=dependent_version,
        at=now - 2 * DAY,
    )
    score(
        database,
        user_id=user_id,
        concept_id=dependent_id,
        version_id=dependent_version,
        at=now - 2 * DAY,
        value=0.1,
    )

    dependent = by_code(
        page(database, user_id=user_id, subject_id=subject_id, as_of=now).candidates,
        "PHYS-MEC-VELOCITY",
    )

    assert dependent.weak_prerequisite_concept_ids == (prerequisite_id,)
    assert dependent.selection_reason == SELECTION_REASON_WEAK_PREREQUISITE


def test_healthy_prerequisite_is_not_flagged(database: Engine, now: datetime) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    prerequisite_id, prerequisite_version = concept_by_code(database, "PHYS-MEC-DISPLACEMENT")
    dependent_id, dependent_version = concept_by_code(database, "PHYS-MEC-VELOCITY")
    expose(
        database,
        user_id=user_id,
        concept_id=prerequisite_id,
        version_id=prerequisite_version,
        at=now - 12 * HOUR,
    )
    expose(database, user_id=user_id, concept_id=dependent_id, version_id=dependent_version, at=now)

    dependent = by_code(
        page(database, user_id=user_id, subject_id=subject_id, as_of=now).candidates,
        "PHYS-MEC-VELOCITY",
    )

    assert dependent.weak_prerequisite_concept_ids == ()
    assert dependent.selection_reason == SELECTION_REASON_NEW_CONCEPT


def test_comeback_flag_uses_the_policy_threshold(database: Engine, now: datetime) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    concept_id, version_id = concept_by_code(database, "PHYS-MEC-ACCELERATION")
    expose(
        database, user_id=user_id, concept_id=concept_id, version_id=version_id, at=now - 25 * DAY
    )
    score(
        database,
        user_id=user_id,
        concept_id=concept_id,
        version_id=version_id,
        at=now - 24 * DAY,
        value=0.8,
    )

    candidate = by_code(
        page(
            database,
            user_id=user_id,
            subject_id=subject_id,
            as_of=now,
            horizon_days=MAX_HORIZON_DAYS,
        ).candidates,
        "PHYS-MEC-ACCELERATION",
    )

    assert candidate.is_comeback
    assert candidate.urgency == URGENCY_OVERDUE


def test_retention_reason_covers_due_but_healthy_concepts(database: Engine, now: datetime) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    concept_id, version_id = concept_by_code(database, "PHYS-WAV-SHM")
    expose(database, user_id=user_id, concept_id=concept_id, version_id=version_id, at=now)
    score(
        database,
        user_id=user_id,
        concept_id=concept_id,
        version_id=version_id,
        at=now,
        value=1.0,
    )

    candidate = by_code(
        page(
            database,
            user_id=user_id,
            subject_id=subject_id,
            as_of=now,
            horizon_days=MAX_HORIZON_DAYS,
        ).candidates,
        "PHYS-WAV-SHM",
    )

    assert candidate.recent_error_severity == 0.0
    assert candidate.selection_reason == SELECTION_REASON_RETENTION
    assert candidate.urgency == URGENCY_DUE


# ---------------------------------------------------------------------------
# pagination
# ---------------------------------------------------------------------------


def test_page_cap_and_cursor_pagination_cover_the_pool_once(
    database: Engine, now: datetime
) -> None:
    user_id = create_user(database)
    subject_id = physics_subject_id(database)
    with database.begin() as connection:
        rows = (
            connection.execute(
                text(
                    """
                    SELECT DISTINCT ON (c.id) c.id AS concept_id, cv.id AS version_id
                    FROM concepts c
                    JOIN concept_versions cv ON cv.concept_id = c.id
                    WHERE c.status = 'approved'
                      AND cv.content_status = 'approved'
                      AND c.subject_id = CAST(:subject_id AS uuid)
                    ORDER BY c.id, cv.version_no
                    """
                ),
                {"subject_id": str(subject_id)},
            )
            .mappings()
            .all()
        )
    assert len(rows) >= 12
    for row in rows:
        expose(
            database,
            user_id=user_id,
            concept_id=UUID(str(row["concept_id"])),
            version_id=UUID(str(row["version_id"])),
            at=now - 5 * DAY,
        )

    seen: list[UUID] = []
    cursor = None
    pages = 0
    while True:
        result = page(
            database, user_id=user_id, subject_id=subject_id, as_of=now, limit=5, cursor=cursor
        )
        assert len(result.candidates) <= 5
        seen.extend(candidate.concept_id for candidate in result.candidates)
        pages += 1
        cursor = result.next_cursor
        if cursor is None:
            break
        assert pages < 10

    assert pages == (len(rows) + 4) // 5
    assert len(seen) == len(rows)
    assert len(set(seen)) == len(rows)


def test_cursor_round_trip_and_malformed_values() -> None:
    concept_id = uuid4()
    at = datetime(2026, 10, 29, 12, 0, 0, 123456, tzinfo=UTC)

    decoded_at, decoded_concept = decode_cursor(encode_cursor(at, concept_id))

    assert decoded_at == at
    assert decoded_concept == concept_id
    for malformed in ("", "not-a-cursor", "x" * 500, encode_cursor(at, concept_id) + "extra"):
        with pytest.raises(ValueError):
            decode_cursor(malformed)


def test_selection_vocabulary_stays_a_subset_of_the_shared_contract() -> None:
    """Selection reasons and urgencies cannot drift from the shared allowlists."""
    from memora.modules.curriculum.constants import REASON_CODES

    assert set(SELECTION_REASON_CODES) <= REASON_CODES
    assert set(SELECTION_REASON_CODES) == {
        "forgetting_curve_overdue",
        "daily_retention_protect",
        "high_error_rate_repair",
        "weak_prerequisite_failure",
        "new_concept_introduction",
    }
    assert set(URGENCY_BANDS) == {"overdue", "due", "near_due"}
    assert SELECTION_INPUT_VERSION == "memory-selection-inputs/1"


def test_retrievability_bands_are_ordered() -> None:
    assert retrievability_band(1.0) == RETRIEVABILITY_BAND_FRESH
    assert retrievability_band(0.8) == RETRIEVABILITY_BAND_FRESH
    assert retrievability_band(0.79) == RETRIEVABILITY_BAND_SETTLING
    assert retrievability_band(0.5) == RETRIEVABILITY_BAND_SETTLING
    assert retrievability_band(0.49) == RETRIEVABILITY_BAND_FADING
    assert retrievability_band(0.25) == RETRIEVABILITY_BAND_FADING
    assert retrievability_band(0.24) == RETRIEVABILITY_BAND_CRITICAL
    assert retrievability_band(0.0) == RETRIEVABILITY_BAND_CRITICAL


# ---------------------------------------------------------------------------
# isolation and authorization
# ---------------------------------------------------------------------------


def test_learners_never_see_each_others_candidates(database: Engine, now: datetime) -> None:
    subject_id = physics_subject_id(database)
    user_a = create_user(database)
    user_b = create_user(database)
    concept_a, version_a = concept_by_code(database, "PHYS-MEA-DIMENSIONS")
    concept_b, version_b = concept_by_code(database, "PHYS-MEC-WORK")
    expose(database, user_id=user_a, concept_id=concept_a, version_id=version_a, at=now)
    expose(database, user_id=user_b, concept_id=concept_b, version_id=version_b, at=now)

    page_a = page(database, user_id=user_a, subject_id=subject_id, as_of=now)
    page_b = page(database, user_id=user_b, subject_id=subject_id, as_of=now)

    assert [c.concept_id for c in page_a.candidates] == [concept_a]
    assert [c.concept_id for c in page_b.candidates] == [concept_b]


def test_same_concept_keeps_per_learner_state(database: Engine, now: datetime) -> None:
    subject_id = physics_subject_id(database)
    user_a = create_user(database)
    user_b = create_user(database)
    concept_id, version_id = concept_by_code(database, "PHYS-MEC-MOMENTUM")
    expose(
        database, user_id=user_a, concept_id=concept_id, version_id=version_id, at=now - 10 * DAY
    )
    expose(database, user_id=user_b, concept_id=concept_id, version_id=version_id, at=now)

    candidate_a = by_code(
        page(database, user_id=user_a, subject_id=subject_id, as_of=now).candidates,
        "PHYS-MEC-MOMENTUM",
    )
    candidate_b = by_code(
        page(database, user_id=user_b, subject_id=subject_id, as_of=now).candidates,
        "PHYS-MEC-MOMENTUM",
    )

    assert candidate_a.concept_id == candidate_b.concept_id
    assert candidate_a.next_review_at < candidate_b.next_review_at
    assert candidate_a.urgency == URGENCY_OVERDUE
    assert candidate_b.urgency == URGENCY_DUE


def test_rls_scopes_selection_to_the_transaction_owner(database: Engine, now: datetime) -> None:
    subject_id = physics_subject_id(database)
    user_a = create_user(database)
    user_b = create_user(database)
    concept_id, version_id = concept_by_code(database, "PHYS-MEC-KINETIC-ENERGY")
    for user in (user_a, user_b):
        expose(database, user_id=user, concept_id=concept_id, version_id=version_id, at=now)

    with database.begin() as connection:
        connection.execute(text("SET LOCAL ROLE memora_api"))
        connection.execute(
            text("SELECT set_config('memora.user_id', :user_id, true)"),
            {"user_id": str(user_a)},
        )
        visible_states = connection.scalar(text("SELECT count(*) FROM learner_concept_states"))
        own_page = list_due_candidates(connection, user_id=user_a, subject_id=subject_id, as_of=now)
        # Even an explicit other-learner id cannot escape the RLS predicate.
        other_page = list_due_candidates(
            connection, user_id=user_b, subject_id=subject_id, as_of=now
        )

    assert visible_states == 1
    assert [c.concept_id for c in own_page.candidates] == [concept_id]
    assert other_page.candidates == ()
