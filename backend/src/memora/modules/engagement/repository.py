"""Owner-scoped persistence and deterministic projection queries for T15."""

# ruff: noqa: E501 -- keeping SQL projection expressions together aids review.

from __future__ import annotations

import json
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import date, datetime, timedelta
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.api.security import AuthContext
from memora.modules.engagement.constants import (
    MISSION_COMPLETED_EVENT,
    OUTBOX_SCHEMA_VERSION,
    REEF_POLICY_VERSION,
    REWARD_GRANTED_EVENT,
    STREAK_POLICY_VERSION,
    XP_POLICY_VERSION,
)
from memora.modules.engagement.policy import (
    ReefInputs,
    calculate_xp,
    project_reef,
    streak_qualification,
)


class EngagementRepository:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    @contextmanager
    def _connection(self, auth: AuthContext) -> Iterator[tuple[Connection, UUID]]:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_api"))
            user_id = connection.scalar(
                text("SELECT memora_resolve_user_id(:issuer, :subject)"),
                {"issuer": auth.issuer, "subject": auth.subject},
            )
            if user_id is None:
                raise ApiError(401, "token_invalid", "Your account could not be resolved.")
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(user_id)},
            )
            yield connection, UUID(str(user_id))

    def process_mission_completed(
        self,
        *,
        outbox_event_id: UUID,
        payload: dict[str, Any],
        correlation_id: UUID,
        now: datetime,
    ) -> dict[str, Any]:
        parsed = self._validate_completion(payload)
        user_id = parsed["user_id"]
        mission_id = parsed["mission_id"]
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_api"))
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(user_id)},
            )
            # Serialize all engagement consequences for one learner.
            if (
                connection.scalar(
                    text("SELECT id FROM users WHERE id = :user_id FOR UPDATE"),
                    {"user_id": user_id},
                )
                is None
            ):
                raise ValueError("source_user_missing")
            mission = (
                connection.execute(
                    text(
                        """
                        SELECT id, subject_id, mission_date, mission_timezone, status,
                               completion_summary
                        FROM missions
                        WHERE id = :mission_id AND user_id = :user_id
                        FOR UPDATE
                        """
                    ),
                    {"mission_id": mission_id, "user_id": user_id},
                )
                .mappings()
                .first()
            )
            if mission is None or mission["status"] != "completed":
                raise ValueError("source_mission_missing")
            if mission["completion_summary"].get("engagement_status") == "applied":
                return dict(mission["completion_summary"])
            existing = (
                connection.execute(
                    text(
                        """
                        SELECT id, amount, balance_after FROM xp_ledger
                        WHERE user_id = :user_id AND source_event_type = :event_type
                          AND source_event_id = :event_id AND entry_type = 'earn'
                        """
                    ),
                    {
                        "user_id": user_id,
                        "event_type": MISSION_COMPLETED_EVENT,
                        "event_id": outbox_event_id,
                    },
                )
                .mappings()
                .first()
            )
            if existing is not None:
                return dict(mission["completion_summary"])

            prior_rows = connection.execute(
                text(
                    """
                    SELECT local_date, qualification_type FROM streak_days
                    WHERE user_id = :user_id AND local_date < :mission_date
                    ORDER BY local_date
                    """
                ),
                {"user_id": user_id, "mission_date": mission["mission_date"]},
            ).mappings()
            prior = list(prior_rows)
            qualification, grace_date = streak_qualification(
                mission["mission_date"],
                [row["local_date"] for row in prior],
                [row["local_date"] for row in prior if row["qualification_type"] == "grace_used"],
            )
            if grace_date is not None:
                connection.execute(
                    text(
                        """
                        INSERT INTO streak_days(
                          user_id, local_date, timezone, qualification_type,
                          mission_id, grace_window_key, policy_version
                        ) VALUES (
                          :user_id, :local_date, :timezone, 'grace_used',
                          :mission_id, :window_key, :policy_version
                        ) ON CONFLICT (user_id, local_date) DO NOTHING
                        """
                    ),
                    {
                        "user_id": user_id,
                        "local_date": grace_date,
                        "timezone": mission["mission_timezone"],
                        "mission_id": mission_id,
                        "window_key": f"rolling7:{grace_date.isoformat()}",
                        "policy_version": STREAK_POLICY_VERSION,
                    },
                )
            connection.execute(
                text(
                    """
                    INSERT INTO streak_days(
                      user_id, local_date, timezone, qualification_type,
                      mission_id, grace_window_key, policy_version
                    ) VALUES (
                      :user_id, :local_date, :timezone, :qualification,
                      :mission_id, NULL, :policy_version
                    ) ON CONFLICT (user_id, local_date) DO NOTHING
                    """
                ),
                {
                    "user_id": user_id,
                    "local_date": mission["mission_date"],
                    "timezone": mission["mission_timezone"],
                    "qualification": qualification,
                    "mission_id": mission_id,
                    "policy_version": STREAK_POLICY_VERSION,
                },
            )

            xp_delta = calculate_xp(
                parsed["protected_count"],
                parsed["repaired_count"],
                comeback=qualification == "comeback_completed",
            )
            balance = int(
                connection.scalar(
                    text(
                        """
                        SELECT COALESCE((
                          SELECT balance_after FROM xp_ledger WHERE user_id=:u
                          ORDER BY earned_at DESC, created_at DESC, id DESC LIMIT 1
                        ), 0)
                        """
                    ),
                    {"u": user_id},
                )
                or 0
            )
            ledger_id: UUID | None = None
            if xp_delta:
                ledger_id = uuid4()
                balance += xp_delta
                connection.execute(
                    text(
                        """
                        INSERT INTO xp_ledger(
                          id, user_id, amount, entry_type, source_event_type,
                          source_event_id, reason_code, balance_after, earned_at, policy_version
                        ) VALUES (
                          :id, :user_id, :amount, 'earn', :event_type,
                          :event_id, 'mission_learning_evidence', :balance, :earned_at,
                          :policy_version
                        )
                        """
                    ),
                    {
                        "id": ledger_id,
                        "user_id": user_id,
                        "amount": xp_delta,
                        "event_type": MISSION_COMPLETED_EVENT,
                        "event_id": outbox_event_id,
                        "balance": balance,
                        "earned_at": parsed["completed_at"],
                        "policy_version": XP_POLICY_VERSION,
                    },
                )

            grants = self._grant_rewards(
                connection,
                user_id=user_id,
                ledger_id=ledger_id,
                balance=balance,
                correlation_id=correlation_id,
                now=now,
            )
            before = self._reef_row(connection, user_id, mission["subject_id"])
            after = self._rebuild_reef(
                connection,
                user_id=user_id,
                subject_id=mission["subject_id"],
                now=now,
            )
            streak_length = self._streak_length(connection, user_id, mission["mission_date"])
            result = {
                **dict(mission["completion_summary"]),
                "engagement_status": "applied",
                "xp_delta": xp_delta,
                "xp_balance": balance,
                "streak": {
                    "qualification": qualification,
                    "current_days": streak_length,
                    "grace_used": grace_date is not None,
                    "policy_version": STREAK_POLICY_VERSION,
                },
                "reef_before": self._reef_descriptor(before),
                "reef_after": self._reef_descriptor(after),
                "reward_grants": grants,
                "next_suggested_action": "progress",
            }
            connection.execute(
                text(
                    """
                    UPDATE missions SET completion_summary=CAST(:summary AS jsonb),
                      updated_at=:now, row_version=row_version+1
                    WHERE id=:mission_id AND user_id=:user_id
                    """
                ),
                {
                    "summary": json.dumps(result, default=str),
                    "now": now,
                    "mission_id": mission_id,
                    "user_id": user_id,
                },
            )
            return result

    def home(self, auth: AuthContext, *, now: datetime) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            mission = (
                connection.execute(
                    text(
                        """
                    SELECT id, subject_id, status, mission_date, estimated_minutes,
                           planned_item_count, completion_summary
                    FROM missions WHERE user_id=:user_id
                    ORDER BY mission_date DESC, sequence_no DESC LIMIT 1
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .first()
            )
            reef = (
                connection.execute(
                    text(
                        """
                    SELECT s.id AS subject_id,s.name AS subject_name,
                      COALESCE(rp.condition,'new') condition,
                      COALESCE(rp.health_score,0.5) health_score,
                      COALESCE(rp.due_memory_count,0) due_memory_count,
                      COALESCE(rp.prerequisite_risk,0) prerequisite_risk,
                      COALESCE(rp.recent_evidence_score,0.5) recent_evidence_score,
                      COALESCE(rp.projection_version,:version) projection_version,
                      COALESCE(rp.source_watermark,'none:0') source_watermark,
                      COALESCE(rp.projected_at,:now) projected_at
                    FROM user_profiles up JOIN subjects s ON s.id=up.active_subject_id
                    LEFT JOIN reef_projections rp ON rp.user_id=up.user_id AND rp.subject_id=s.id
                    WHERE up.user_id=:user_id LIMIT 1
                    """
                    ),
                    {"user_id": user_id, "version": REEF_POLICY_VERSION, "now": now},
                )
                .mappings()
                .first()
            )
            balance = int(
                connection.scalar(
                    text(
                        """
                        SELECT COALESCE((
                          SELECT balance_after FROM xp_ledger WHERE user_id=:u
                          ORDER BY earned_at DESC, created_at DESC, id DESC LIMIT 1
                        ), 0)
                        """
                    ),
                    {"u": user_id},
                )
                or 0
            )
            streak = self._current_streak(connection, user_id, now.date())
            if mission is None:
                state = "setup" if reef is None else "cared_for"
            else:
                state = {
                    "planned": "mission_ready",
                    "started": "mission_in_progress",
                    "paused": "mission_in_progress",
                    "completed": "mission_complete",
                }.get(mission["status"], "cared_for")
            return {
                "state": state,
                "mission": dict(mission) if mission is not None else None,
                "reef": self._reef_descriptor(reef),
                "xp_balance": balance,
                "streak_days": streak,
                "server_time": now,
            }

    def seabed(self, auth: AuthContext, *, now: datetime) -> list[dict[str, Any]]:
        with self._connection(auth) as (connection, user_id):
            rows = connection.execute(
                text(
                    """
                    SELECT s.id AS subject_id,s.name AS subject_name,
                      COALESCE(rp.condition,'new') condition,
                      COALESCE(rp.health_score,0.5) health_score,
                      COALESCE(rp.due_memory_count,0) due_memory_count,
                      COALESCE(rp.prerequisite_risk,0) prerequisite_risk,
                      COALESCE(rp.recent_evidence_score,0.5) recent_evidence_score,
                      COALESCE(rp.projection_version,:version) projection_version,
                      COALESCE(rp.source_watermark,'none:0') source_watermark,
                      COALESCE(rp.projected_at,:now) projected_at
                    FROM user_profiles up JOIN subjects s ON s.id=up.active_subject_id
                    LEFT JOIN reef_projections rp ON rp.user_id=up.user_id AND rp.subject_id=s.id
                    WHERE up.user_id=:user_id ORDER BY s.name,s.id
                    """
                ),
                {"user_id": user_id, "version": REEF_POLICY_VERSION, "now": now},
            ).mappings()
            return [dict(row) for row in rows]

    def reef(self, auth: AuthContext, subject_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            row = (
                connection.execute(
                    text(
                        """
                    SELECT rp.*, s.name AS subject_name FROM reef_projections rp
                    JOIN subjects s ON s.id=rp.subject_id
                    WHERE rp.user_id=:user_id AND rp.subject_id=:subject_id
                    """
                    ),
                    {"user_id": user_id, "subject_id": subject_id},
                )
                .mappings()
                .first()
            )
            if row is None:
                raise ApiError(404, "resource_not_found", "This reef is not available.")
            result = dict(row)
            result["rewards"] = self._reward_rows(connection, user_id, None)
            return result

    def rewards(self, auth: AuthContext, grant_id: UUID | None) -> list[dict[str, Any]]:
        with self._connection(auth) as (connection, user_id):
            return self._reward_rows(connection, user_id, grant_id)

    def update_placement(
        self,
        auth: AuthContext,
        grant_id: UUID,
        *,
        subject_id: UUID | None,
        placement_slot: str | None,
        version: int,
        idempotency_key: str,
        request_hash: str,
        now: datetime,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            operation = (
                connection.execute(
                    text(
                        """
                        SELECT request_hash,status FROM idempotency_records
                        WHERE scope=:scope AND operation='updateRewardPlacement'
                          AND idempotency_key=:key FOR UPDATE
                        """
                    ),
                    {"scope": f"user:{user_id}", "key": idempotency_key},
                )
                .mappings()
                .first()
            )
            if operation and operation["request_hash"] != request_hash:
                raise ApiError(409, "idempotency_key_reused", "Use a new idempotency key.")
            owned = connection.scalar(
                text("SELECT id FROM reward_grants WHERE id=:id AND user_id=:u"),
                {"id": grant_id, "u": user_id},
            )
            if owned is None:
                raise ApiError(404, "resource_not_found", "This reward is not available.")
            if operation and operation["status"] == "completed":
                return self._reward_rows(connection, user_id, grant_id)[0]
            if operation is None:
                connection.execute(
                    text(
                        """
                        INSERT INTO idempotency_records(
                          user_id,scope,operation,idempotency_key,request_hash,status,expires_at
                        ) VALUES (
                          :u,:scope,'updateRewardPlacement',:key,:hash,'processing',:expires
                        )
                        """
                    ),
                    {
                        "u": user_id,
                        "scope": f"user:{user_id}",
                        "key": idempotency_key,
                        "hash": request_hash,
                        "expires": now + timedelta(hours=24),
                    },
                )
            if (subject_id is None) != (placement_slot is None):
                raise ApiError(422, "validation_failed", "Choose both a reef and placement slot.")
            if (
                subject_id is not None
                and connection.scalar(
                    text("SELECT 1 FROM user_profiles WHERE user_id=:u AND active_subject_id=:s"),
                    {"u": user_id, "s": subject_id},
                )
                is None
            ):
                raise ApiError(404, "resource_not_found", "This reef is not available.")
            existing = (
                connection.execute(
                    text("SELECT row_version FROM reward_placements WHERE reward_grant_id=:id"),
                    {"id": grant_id},
                )
                .mappings()
                .first()
            )
            current_version = int(existing["row_version"]) if existing else 1
            if version != current_version:
                raise ApiError(409, "version_conflict", "Refresh this reward and try again.")
            connection.execute(
                text(
                    """
                    INSERT INTO reward_placements(
                      reward_grant_id,user_id,subject_id,placement_slot,row_version,updated_at
                    ) VALUES (:id,:u,:s,:slot,1,:now)
                    ON CONFLICT (reward_grant_id) DO UPDATE SET
                      subject_id=EXCLUDED.subject_id, placement_slot=EXCLUDED.placement_slot,
                      updated_at=EXCLUDED.updated_at,
                      row_version=reward_placements.row_version+1
                    """
                ),
                {"id": grant_id, "u": user_id, "s": subject_id, "slot": placement_slot, "now": now},
            )
            connection.execute(
                text(
                    """
                    UPDATE idempotency_records SET status='completed',response_reference=:ref,
                      updated_at=:now,row_version=row_version+1
                    WHERE scope=:scope AND operation='updateRewardPlacement'
                      AND idempotency_key=:key
                    """
                ),
                {
                    "ref": str(grant_id),
                    "now": now,
                    "scope": f"user:{user_id}",
                    "key": idempotency_key,
                },
            )
            return self._reward_rows(connection, user_id, grant_id)[0]

    def statistics(
        self,
        auth: AuthContext,
        *,
        start: date,
        end: date,
        timezone: str,
    ) -> dict[str, Any]:
        if end < start or (end - start).days > 92:
            raise ApiError(422, "validation_failed", "Choose a period of 93 days or less.")
        with self._connection(auth) as (connection, user_id):
            row = (
                connection.execute(
                    text(
                        """
                    SELECT
                      COALESCE((SELECT sum(amount) FROM xp_ledger
                        WHERE user_id=:u AND timezone(:timezone,earned_at)::date
                          BETWEEN :start AND :end),0) xp,
                      COALESCE((SELECT count(*) FROM missions
                        WHERE user_id=:u AND status='completed' AND mission_date BETWEEN :start AND :end),0) missions,
                      COALESCE((SELECT sum((completion_summary->>'protected_count')::int) FROM missions
                        WHERE user_id=:u AND status='completed' AND mission_date BETWEEN :start AND :end),0) protected,
                      COALESCE((SELECT sum((completion_summary->>'repaired_count')::int) FROM missions
                        WHERE user_id=:u AND status='completed' AND mission_date BETWEEN :start AND :end),0) repaired,
                      COALESCE((SELECT count(*) FROM streak_days
                        WHERE user_id=:u AND qualification_type <> 'grace_used'
                          AND local_date BETWEEN :start AND :end),0) active_days
                    """
                    ),
                    {"u": user_id, "start": start, "end": end, "timezone": timezone},
                )
                .mappings()
                .one()
            )
            series = connection.execute(
                text(
                    """
                    SELECT timezone(:timezone,earned_at)::date AS day, sum(amount)::int AS xp
                    FROM xp_ledger WHERE user_id=:u
                      AND timezone(:timezone,earned_at)::date BETWEEN :start AND :end
                    GROUP BY timezone(:timezone,earned_at)::date ORDER BY day
                    """
                ),
                {"u": user_id, "start": start, "end": end, "timezone": timezone},
            ).mappings()
            return {
                "period_start": start,
                "period_end": end,
                "timezone": timezone,
                "xp_earned": int(row["xp"]),
                "missions_completed": int(row["missions"]),
                "memories_protected": int(row["protected"]),
                "memories_repaired": int(row["repaired"]),
                "active_days": int(row["active_days"]),
                "xp_series": [dict(item) for item in series],
                "summary": (
                    f"{int(row['xp'])} XP from {int(row['missions'])} missions; "
                    f"{int(row['protected'])} memories protected and "
                    f"{int(row['repaired'])} repaired."
                ),
            }

    @staticmethod
    def _validate_completion(payload: dict[str, Any]) -> dict[str, Any]:
        try:
            if payload.get("schema_version") != OUTBOX_SCHEMA_VERSION:
                raise ValueError
            return {
                "user_id": UUID(str(payload["user_id"])),
                "mission_id": UUID(str(payload["mission_id"])),
                "protected_count": int(payload["protected_count"]),
                "repaired_count": int(payload["repaired_count"]),
                "completed_at": datetime.fromisoformat(
                    str(payload["completed_at"]).replace("Z", "+00:00")
                ),
            }
        except (KeyError, TypeError, ValueError) as exc:
            raise ValueError("invalid_event_payload") from exc

    def _grant_rewards(
        self,
        connection: Connection,
        *,
        user_id: UUID,
        ledger_id: UUID | None,
        balance: int,
        correlation_id: UUID,
        now: datetime,
    ) -> list[dict[str, Any]]:
        if ledger_id is None:
            return []
        definitions = connection.execute(
            text(
                """
                SELECT id, reward_code FROM reward_definitions d
                WHERE status='approved' AND xp_threshold <= :balance
                  AND NOT EXISTS (SELECT 1 FROM reward_grants g
                    WHERE g.user_id=:u AND g.reward_definition_id=d.id)
                ORDER BY xp_threshold, id
                """
            ),
            {"balance": balance, "u": user_id},
        ).mappings()
        grants: list[dict[str, Any]] = []
        for definition in definitions:
            grant_id = uuid4()
            connection.execute(
                text(
                    """
                    INSERT INTO reward_grants(
                      id,user_id,reward_definition_id,source_xp_ledger_id,granted_at
                    ) VALUES (:id,:u,:definition,:ledger,:now)
                    """
                ),
                {
                    "id": grant_id,
                    "u": user_id,
                    "definition": definition["id"],
                    "ledger": ledger_id,
                    "now": now,
                },
            )
            connection.execute(
                text(
                    """
                    INSERT INTO outbox_events(
                      domain_event_key,aggregate_type,aggregate_id,event_type,event_version,
                      payload,correlation_id,publication_status
                    ) VALUES (:key,'reward_grant',:id,:event,1,CAST(:payload AS jsonb),:correlation,'pending')
                    """
                ),
                {
                    "key": f"{REWARD_GRANTED_EVENT}:{grant_id}",
                    "id": grant_id,
                    "event": REWARD_GRANTED_EVENT,
                    "payload": json.dumps(
                        {
                            "schema_version": OUTBOX_SCHEMA_VERSION,
                            "user_id": str(user_id),
                            "grant_id": str(grant_id),
                        }
                    ),
                    "correlation": correlation_id,
                },
            )
            grants.append({"grant_id": str(grant_id), "reward_code": definition["reward_code"]})
        return grants

    def _rebuild_reef(
        self, connection: Connection, *, user_id: UUID, subject_id: UUID, now: datetime
    ) -> dict[str, Any]:
        facts = (
            connection.execute(
                text(
                    """
                WITH states AS (
                  SELECT lcs.* FROM learner_concept_states lcs
                  JOIN concepts c ON c.id=lcs.concept_id
                  WHERE lcs.user_id=:u AND c.subject_id=:s
                ), latest AS (
                  SELECT DISTINCT ON (md.concept_id) md.concept_id, md.reason_codes
                  FROM memory_decisions md JOIN concepts c ON c.id=md.concept_id
                  WHERE md.user_id=:u AND c.subject_id=:s
                  ORDER BY md.concept_id, md.decided_at DESC, md.id DESC
                )
                SELECT count(*) FILTER (WHERE eligible_review_count > 0)::int evidence_count,
                  COALESCE(avg(last_retrievability) FILTER (WHERE eligible_review_count > 0),0.5) retrievability,
                  COALESCE(count(*) FILTER (WHERE next_review_at <= :now)::numeric / NULLIF(count(*),0),0) due_ratio,
                  COALESCE((SELECT avg(CASE WHEN 'weak_prerequisite_failure'=ANY(reason_codes) THEN 1.0 ELSE 0.0 END) FROM latest),0) prerequisite_risk,
                  COALESCE((SELECT avg(score) FROM memory_events me JOIN concepts c ON c.id=me.concept_id
                    WHERE me.user_id=:u AND c.subject_id=:s AND me.is_eligible
                      AND me.observed_at >= :recent_since AND me.score IS NOT NULL),0.5) recent_score,
                  (SELECT max(observed_at) FROM memory_events me JOIN concepts c ON c.id=me.concept_id
                    WHERE me.user_id=:u AND c.subject_id=:s AND me.is_eligible) last_activity,
                  COALESCE(max(updated_at)::text,'none') || ':' || count(*)::text watermark,
                  count(*) FILTER (WHERE next_review_at <= :now)::int due_count
                FROM states
                """
                ),
                {
                    "u": user_id,
                    "s": subject_id,
                    "now": now,
                    "recent_since": now - timedelta(days=14),
                },
            )
            .mappings()
            .one()
        )
        decision = project_reef(
            ReefInputs(
                evidence_count=int(facts["evidence_count"] or 0),
                mean_retrievability=float(facts["retrievability"]),
                due_ratio=float(facts["due_ratio"]),
                prerequisite_risk=float(facts["prerequisite_risk"]),
                recent_evidence_score=float(facts["recent_score"]),
                last_activity_at=facts["last_activity"],
                projected_at=now,
            )
        )
        row = (
            connection.execute(
                text(
                    """
                INSERT INTO reef_projections(
                  user_id,subject_id,condition,health_score,due_memory_count,
                  prerequisite_risk,recent_evidence_score,projection_version,
                  source_watermark,projected_at
                ) VALUES (:u,:s,:condition,:score,:due,:risk,:recent,:version,:watermark,:now)
                ON CONFLICT (user_id,subject_id) DO UPDATE SET
                  condition=EXCLUDED.condition,health_score=EXCLUDED.health_score,
                  due_memory_count=EXCLUDED.due_memory_count,
                  prerequisite_risk=EXCLUDED.prerequisite_risk,
                  recent_evidence_score=EXCLUDED.recent_evidence_score,
                  projection_version=EXCLUDED.projection_version,
                  source_watermark=EXCLUDED.source_watermark,projected_at=EXCLUDED.projected_at,
                  updated_at=EXCLUDED.projected_at,row_version=reef_projections.row_version+1
                RETURNING *
                """
                ),
                {
                    "u": user_id,
                    "s": subject_id,
                    "condition": decision.condition,
                    "score": decision.health_score,
                    "due": int(facts["due_count"] or 0),
                    "risk": float(facts["prerequisite_risk"]),
                    "recent": float(facts["recent_score"]),
                    "version": REEF_POLICY_VERSION,
                    "watermark": facts["watermark"],
                    "now": now,
                },
            )
            .mappings()
            .one()
        )
        return dict(row)

    @staticmethod
    def _reef_row(connection: Connection, user_id: UUID, subject_id: UUID) -> dict[str, Any] | None:
        row = (
            connection.execute(
                text("SELECT * FROM reef_projections WHERE user_id=:u AND subject_id=:s"),
                {"u": user_id, "s": subject_id},
            )
            .mappings()
            .first()
        )
        return dict(row) if row else None

    @staticmethod
    def _reef_descriptor(row: Any) -> dict[str, Any] | None:
        if row is None:
            return None
        return {
            key: row[key]
            for key in (
                "subject_id",
                "condition",
                "health_score",
                "due_memory_count",
                "projection_version",
                "source_watermark",
                "projected_at",
            )
            if key in row
        }

    @staticmethod
    def _streak_length(connection: Connection, user_id: UUID, end: date) -> int:
        dates = list(
            connection.scalars(
                text(
                    "SELECT local_date FROM streak_days WHERE user_id=:u AND local_date<=:end ORDER BY local_date DESC"
                ),
                {"u": user_id, "end": end},
            )
        )
        count = 0
        expected = end
        for value in dates:
            if value != expected:
                break
            count += 1
            expected -= timedelta(days=1)
        return count

    def _current_streak(self, connection: Connection, user_id: UUID, today: date) -> int:
        latest = connection.scalar(
            text("SELECT max(local_date) FROM streak_days WHERE user_id=:u"), {"u": user_id}
        )
        if latest is None or latest < today - timedelta(days=1):
            return 0
        return self._streak_length(connection, user_id, latest)

    @staticmethod
    def _reward_rows(
        connection: Connection, user_id: UUID, grant_id: UUID | None
    ) -> list[dict[str, Any]]:
        rows = connection.execute(
            text(
                """
                SELECT g.id AS grant_id,d.reward_code,d.reward_type,d.title,d.asset_key,
                  g.granted_at,CASE WHEN p.subject_id IS NULL THEN 'unplaced' ELSE 'placed' END placement_state,
                  p.subject_id AS placed_subject_id,p.placement_slot,
                  COALESCE(p.row_version,1) AS version
                FROM reward_grants g JOIN reward_definitions d ON d.id=g.reward_definition_id
                LEFT JOIN reward_placements p ON p.reward_grant_id=g.id
                WHERE g.user_id=:u AND (:grant_id IS NULL OR g.id=:grant_id)
                ORDER BY g.granted_at DESC,g.id DESC
                """
            ),
            {"u": user_id, "grant_id": grant_id},
        ).mappings()
        result = []
        for row in rows:
            item = dict(row)
            item["permitted_actions"] = (
                ["place"] if row["placement_state"] == "unplaced" else ["move", "remove"]
            )
            result.append(item)
        return result
