from __future__ import annotations

import hashlib
import json
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, datetime
from typing import Any
from uuid import UUID, uuid4

from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.api.security import AuthContext


class IdentityRepository:
    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    @contextmanager
    def _connection(
        self,
        auth: AuthContext,
        *,
        create_user: bool = False,
        default_timezone: str = "Asia/Colombo",
        default_locale: str = "en-LK",
    ) -> Iterator[tuple[Connection, UUID]]:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_api"))
            user_id = connection.scalar(
                text("SELECT memora_resolve_user_id(:issuer, :subject)"),
                {"issuer": auth.issuer, "subject": auth.subject},
            )
            if user_id is None:
                if not create_user:
                    raise ApiError(403, "operation_not_allowed", "Account setup is required.")
                user_id = uuid4()
                connection.execute(
                    text("SELECT set_config('memora.user_id', :user_id, true)"),
                    {"user_id": str(user_id)},
                )
                connection.execute(
                    text(
                        """
                        INSERT INTO users(
                            id, oidc_issuer, oidc_subject, status,
                            default_timezone, locale, last_authenticated_at
                        ) VALUES (
                            :id, :issuer, :subject, 'active',
                            :timezone, :locale, :authenticated_at
                        )
                        """
                    ),
                    {
                        "id": user_id,
                        "issuer": auth.issuer,
                        "subject": auth.subject,
                        "timezone": default_timezone,
                        "locale": default_locale,
                        "authenticated_at": auth.authenticated_at,
                    },
                )
                subject = (
                    connection.execute(
                        text(
                            """
                        SELECT s.id AS subject_id, cv.id AS curriculum_version_id
                        FROM subjects s
                        JOIN curriculum_versions cv ON cv.subject_id = s.id
                        WHERE s.code = 'physics'
                          AND s.status = 'approved'
                          AND cv.status = 'approved'
                        ORDER BY cv.valid_from DESC NULLS LAST, cv.created_at DESC
                        LIMIT 1
                        """
                        )
                    )
                    .mappings()
                    .first()
                )
                connection.execute(
                    text(
                        """
                        INSERT INTO user_profiles(
                            user_id, display_name, active_subject_id, curriculum_version_id
                        ) VALUES (
                            :user_id, 'Student', :subject_id, :curriculum_version_id
                        )
                        """
                    ),
                    {
                        "user_id": user_id,
                        "subject_id": subject["subject_id"] if subject else None,
                        "curriculum_version_id": (
                            subject["curriculum_version_id"] if subject else None
                        ),
                    },
                )
            else:
                user_id = UUID(str(user_id))
                connection.execute(
                    text("SELECT set_config('memora.user_id', :user_id, true)"),
                    {"user_id": str(user_id)},
                )
                if auth.authenticated_at is not None:
                    connection.execute(
                        text(
                            """
                            UPDATE users
                            SET last_authenticated_at = :authenticated_at,
                                updated_at = now(),
                                row_version = row_version + 1
                            WHERE id = :user_id
                              AND (
                                  last_authenticated_at IS NULL
                                  OR last_authenticated_at < :authenticated_at
                              )
                            """
                        ),
                        {"user_id": user_id, "authenticated_at": auth.authenticated_at},
                    )
            yield connection, user_id

    def bootstrap(
        self,
        auth: AuthContext,
        *,
        default_timezone: str,
        default_locale: str,
    ) -> dict[str, Any]:
        with self._connection(
            auth,
            create_user=True,
            default_timezone=default_timezone,
            default_locale=default_locale,
        ) as (connection, user_id):
            account = (
                connection.execute(
                    text(
                        """
                    SELECT u.status, p.display_name, p.onboarding_completed_at,
                           p.active_subject_id, p.curriculum_version_id
                    FROM users u
                    JOIN user_profiles p ON p.user_id = u.id
                    WHERE u.id = :user_id
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .one()
            )
            return {
                "user_id": user_id,
                "account": dict(account),
                "consents": self._consents(connection, user_id),
                "subjects": [
                    dict(row)
                    for row in connection.execute(
                        text(
                            """
                            SELECT s.id, s.code, s.name,
                                   cv.id AS curriculum_version_id,
                                   cv.edition_code AS curriculum_edition_code
                            FROM subjects s
                            JOIN curriculum_versions cv ON cv.subject_id = s.id
                            WHERE s.status = 'approved' AND cv.status = 'approved'
                            ORDER BY s.code, cv.valid_from DESC NULLS LAST
                            """
                        )
                    ).mappings()
                ],
                "active_mission": self._first(
                    connection,
                    """
                    SELECT id, subject_id, mission_date, status
                    FROM missions
                    WHERE user_id = :user_id AND status IN ('planned','started','paused')
                    ORDER BY mission_date DESC, sequence_no DESC
                    LIMIT 1
                    """,
                    user_id,
                ),
                "pending_learning_updates": self._many(
                    connection,
                    """
                    SELECT id, status, updated_at
                    FROM learning_updates
                    WHERE user_id = :user_id
                      AND status IN (
                          'draft','uploading','processing','verification_required','failed'
                      )
                    ORDER BY updated_at DESC LIMIT 20
                    """,
                    user_id,
                ),
                "pending_privacy_requests": self._many(
                    connection,
                    """
                    SELECT id, status, updated_at
                    FROM privacy_requests
                    WHERE user_id = :user_id
                      AND status IN ('requested','verifying','processing','failed')
                    ORDER BY updated_at DESC LIMIT 20
                    """,
                    user_id,
                ),
            }

    def profile(self, auth: AuthContext) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            return self._profile_row(connection, user_id)

    def update_profile(
        self,
        auth: AuthContext,
        *,
        version: int,
        idempotency_key: str,
        values: dict[str, Any],
    ) -> dict[str, Any]:
        request_hash = _request_hash({"version": version, **values})
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection, user_id, "updateProfile", idempotency_key, request_hash
            )
            if replay:
                return json.loads(replay)
            current_version = connection.scalar(
                text("SELECT row_version FROM user_profiles WHERE user_id=:user_id FOR UPDATE"),
                {"user_id": user_id},
            )
            if current_version != version:
                raise ApiError(
                    409,
                    "version_conflict",
                    "The profile changed. Refresh it and try again.",
                    "refresh_state",
                )
            connection.execute(
                text(
                    """
                    UPDATE user_profiles
                    SET display_name = CASE WHEN :set_display_name THEN :display_name
                                            ELSE display_name END,
                        updated_at = now(), row_version = row_version + 1
                    WHERE user_id = :user_id
                    """
                ),
                {
                    "user_id": user_id,
                    "set_display_name": "display_name" in values,
                    "display_name": values.get("display_name"),
                },
            )
            connection.execute(
                text(
                    """
                    UPDATE users
                    SET locale = CASE WHEN :set_locale THEN :locale ELSE locale END,
                        default_timezone = CASE WHEN :set_timezone THEN :timezone
                                                ELSE default_timezone END,
                        updated_at = now(), row_version = row_version + 1
                    WHERE id = :user_id
                    """
                ),
                {
                    "user_id": user_id,
                    "set_locale": "locale" in values,
                    "locale": values.get("locale"),
                    "set_timezone": "timezone" in values,
                    "timezone": values.get("timezone"),
                },
            )
            result = json.loads(json.dumps(self._profile_row(connection, user_id), default=str))
            self._complete_idempotency(
                connection,
                user_id,
                "updateProfile",
                idempotency_key,
                json.dumps(result, default=str, sort_keys=True),
            )
            return result

    def preferences(self, auth: AuthContext, *, default_reminders: int) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            self._ensure_preferences(connection, user_id, default_reminders)
            return self._preferences_row(connection, user_id)

    def update_preferences(
        self,
        auth: AuthContext,
        *,
        version: int,
        idempotency_key: str,
        values: dict[str, Any],
        default_reminders: int,
    ) -> dict[str, Any]:
        request_hash = _request_hash({"version": version, **values})
        notification_fields = {
            "notifications_enabled",
            "mission_enabled",
            "reward_enabled",
            "streak_enabled",
            "quiet_start_local",
            "quiet_end_local",
            "preferred_window_start_local",
            "preferred_window_end_local",
            "timezone",
            "lock_screen_detail",
            "max_daily_reminders",
        }
        with self._connection(auth) as (connection, user_id):
            self._ensure_preferences(connection, user_id, default_reminders)
            replay = self._claim_idempotency(
                connection, user_id, "updateProfilePreferences", idempotency_key, request_hash
            )
            if replay:
                return json.loads(replay)
            current_version = connection.scalar(
                text(
                    "SELECT row_version FROM notification_preferences "
                    "WHERE user_id=:user_id FOR UPDATE"
                ),
                {"user_id": user_id},
            )
            if current_version != version:
                raise ApiError(
                    409,
                    "version_conflict",
                    "The preferences changed. Refresh them and try again.",
                    "refresh_state",
                )
            parameters: dict[str, Any] = {"user_id": user_id}
            assignments: list[str] = []
            for field in sorted(notification_fields & values.keys()):
                assignments.append(f"{field} = :{field}")
                parameters[field] = values[field]
            assignments.extend(["updated_at = now()", "row_version = row_version + 1"])
            connection.execute(
                text(
                    "UPDATE notification_preferences SET "
                    + ", ".join(assignments)
                    + " WHERE user_id=:user_id"
                ),
                parameters,
            )
            if "accessibility" in values:
                connection.execute(
                    text(
                        """
                        UPDATE user_profiles
                        SET accessibility_preferences=(
                                accessibility_preferences || CAST(:accessibility AS jsonb)
                            ),
                            updated_at=now(), row_version=row_version+1
                        WHERE user_id=:user_id
                        """
                    ),
                    {
                        "user_id": user_id,
                        "accessibility": json.dumps(values["accessibility"], sort_keys=True),
                    },
                )
            result = json.loads(json.dumps(self._preferences_row(connection, user_id), default=str))
            self._complete_idempotency(
                connection,
                user_id,
                "updateProfilePreferences",
                idempotency_key,
                json.dumps(result, default=str, sort_keys=True),
            )
            return result

    def consent_records(self, auth: AuthContext) -> list[dict[str, Any]]:
        with self._connection(auth) as (connection, user_id):
            return self._consents(connection, user_id)

    def accept_consent(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        policy_id: str,
        policy_version: str,
        accepted_scopes: list[str],
        locale: str | None,
    ) -> dict[str, Any]:
        body = {
            "policy_id": policy_id,
            "policy_version": policy_version,
            "accepted_scopes": accepted_scopes,
        }
        request_hash = _request_hash(body)
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection,
                user_id,
                "acceptConsent",
                idempotency_key,
                request_hash,
            )
            if replay:
                return self._consent_by_id(connection, user_id, UUID(replay))

            consent_id = uuid4()
            decided_at = datetime.now(UTC)
            connection.execute(
                text(
                    """
                    INSERT INTO consent_records(
                        id, user_id, consent_type, policy_version,
                        decision, decided_at, evidence
                    ) VALUES (
                        :id, :user_id, :consent_type, :policy_version,
                        'granted', :decided_at, CAST(:evidence AS jsonb)
                    )
                    """
                ),
                {
                    "id": consent_id,
                    "user_id": user_id,
                    "consent_type": policy_id,
                    "policy_version": policy_version,
                    "decided_at": decided_at,
                    "evidence": json.dumps(
                        {
                            "schema_version": "1",
                            "channel": "mobile",
                            "locale": locale,
                            "accepted_scopes": accepted_scopes,
                        }
                    ),
                },
            )
            self._complete_idempotency(
                connection, user_id, "acceptConsent", idempotency_key, str(consent_id)
            )
            return {
                "id": consent_id,
                "policy_id": policy_id,
                "policy_version": policy_version,
                "decision": "granted",
                "accepted_scopes": accepted_scopes,
                "decided_at": decided_at,
            }

    def register_device(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        body_hash: str,
        installation_id: UUID,
        platform: str,
        ciphertext: bytes,
        fingerprint: str,
        locale: str,
        timezone: str,
        app_version: str,
    ) -> tuple[dict[str, Any], bool]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection,
                user_id,
                "registerDevice",
                idempotency_key,
                body_hash,
            )
            if replay:
                try:
                    result = json.loads(replay)
                except json.JSONDecodeError:
                    # Compatibility for registrations written before response snapshots.
                    result = self._device_by_id(connection, user_id, UUID(replay))
                    result.update({"locale": locale, "timezone": timezone})
                return result, False

            connection.execute(
                text("SELECT memora_transfer_device_token(:fingerprint)"),
                {"fingerprint": fingerprint},
            )
            existing = connection.scalar(
                text(
                    "SELECT id FROM device_registrations "
                    "WHERE user_id = :user_id AND installation_id = :installation_id"
                ),
                {"user_id": user_id, "installation_id": installation_id},
            )
            device_id = UUID(str(existing)) if existing else uuid4()
            last_seen_at = datetime.now(UTC)
            connection.execute(
                text(
                    """
                    INSERT INTO device_registrations(
                        id, user_id, installation_id, platform,
                        push_token_ciphertext, token_fingerprint,
                        app_version, last_seen_at, revoked_at
                    ) VALUES (
                        :id, :user_id, :installation_id, :platform,
                        :ciphertext, :fingerprint,
                        :app_version, :last_seen_at, NULL
                    )
                    ON CONFLICT (user_id, installation_id) DO UPDATE SET
                        platform = EXCLUDED.platform,
                        push_token_ciphertext = EXCLUDED.push_token_ciphertext,
                        token_fingerprint = EXCLUDED.token_fingerprint,
                        app_version = EXCLUDED.app_version,
                        last_seen_at = EXCLUDED.last_seen_at,
                        revoked_at = NULL,
                        updated_at = now(),
                        row_version = device_registrations.row_version + 1
                    """
                ),
                {
                    "id": device_id,
                    "user_id": user_id,
                    "installation_id": installation_id,
                    "platform": platform,
                    "ciphertext": ciphertext,
                    "fingerprint": fingerprint,
                    "app_version": app_version,
                    "last_seen_at": last_seen_at,
                },
            )
            connection.execute(
                text(
                    "UPDATE user_profiles SET updated_at=now(), row_version=row_version+1 "
                    "WHERE user_id=:user_id"
                ),
                {"user_id": user_id},
            )
            connection.execute(
                text(
                    """
                    UPDATE users SET locale = :locale, default_timezone = :timezone,
                                     updated_at = now(), row_version = row_version + 1
                    WHERE id = :user_id
                    """
                ),
                {"user_id": user_id, "locale": locale, "timezone": timezone},
            )
            result = {
                "id": device_id,
                "installation_id": installation_id,
                "platform": platform,
                "locale": locale,
                "timezone": timezone,
                "app_version": app_version,
                "last_seen_at": last_seen_at,
            }
            self._complete_idempotency(
                connection,
                user_id,
                "registerDevice",
                idempotency_key,
                json.dumps(result, default=str, sort_keys=True),
            )
            return result, existing is None

    def delete_device(self, auth: AuthContext, device_id: UUID) -> None:
        with self._connection(auth) as (connection, user_id):
            connection.execute(
                text(
                    """
                    UPDATE device_registrations
                    SET push_token_ciphertext = NULL, token_fingerprint = NULL,
                        revoked_at = COALESCE(revoked_at, now()), updated_at = now(),
                        row_version = row_version + 1
                    WHERE id = :device_id AND user_id = :user_id
                      AND (revoked_at IS NULL OR push_token_ciphertext IS NOT NULL)
                    """
                ),
                {"device_id": device_id, "user_id": user_id},
            )

    @staticmethod
    def _profile_row(connection: Connection, user_id: UUID) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT u.id AS user_id, p.display_name, u.locale,
                           u.default_timezone AS timezone, p.active_subject_id,
                           p.curriculum_version_id, p.row_version AS version
                    FROM users u JOIN user_profiles p ON p.user_id=u.id
                    WHERE u.id=:user_id
                    """
                ),
                {"user_id": user_id},
            )
            .mappings()
            .one()
        )
        return dict(row)

    @staticmethod
    def _ensure_preferences(connection: Connection, user_id: UUID, default_reminders: int) -> None:
        connection.execute(
            text(
                """
                INSERT INTO notification_preferences(
                    user_id, notifications_enabled, mission_enabled,
                    reward_enabled, streak_enabled, timezone,
                    lock_screen_detail, max_daily_reminders
                )
                SELECT id, false, true, true, true, default_timezone, 'minimal', :reminders
                FROM users WHERE id=:user_id
                ON CONFLICT (user_id) DO NOTHING
                """
            ),
            {"user_id": user_id, "reminders": default_reminders},
        )

    @staticmethod
    def _preferences_row(connection: Connection, user_id: UUID) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT n.notifications_enabled, n.mission_enabled,
                           n.reward_enabled, n.streak_enabled,
                           n.quiet_start_local, n.quiet_end_local,
                           n.preferred_window_start_local,
                           n.preferred_window_end_local, n.timezone,
                           n.lock_screen_detail, n.max_daily_reminders,
                           p.accessibility_preferences AS accessibility,
                           n.row_version AS version
                    FROM notification_preferences n
                    JOIN user_profiles p ON p.user_id=n.user_id
                    WHERE n.user_id=:user_id
                    """
                ),
                {"user_id": user_id},
            )
            .mappings()
            .one()
        )
        return dict(row)

    def claim_revocation(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        scope: str,
    ) -> bool:
        with self._connection(auth) as (connection, user_id):
            try:
                replay = self._claim_idempotency(
                    connection,
                    user_id,
                    "revokeSession",
                    idempotency_key,
                    _request_hash({"scope": scope}),
                )
            except ApiError as exc:
                if exc.code == "operation_in_progress":
                    return False
                raise
            return replay is not None

    def complete_revocation(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        scope: str,
        request_id: UUID,
        correlation_id: UUID,
    ) -> None:
        with self._connection(auth) as (connection, user_id):
            completed = self._complete_idempotency(
                connection,
                user_id,
                "revokeSession",
                idempotency_key,
                str(auth.session_id),
            )
            if not completed:
                return
            connection.execute(
                text(
                    """
                    INSERT INTO audit_events(
                        actor_type, actor_id, action, resource_type,
                        authorization_context, outcome, request_id,
                        correlation_id, safe_metadata
                    ) VALUES (
                        'user', :actor_id, 'session.revoke', 'session',
                        CAST(:authorization_context AS jsonb), 'succeeded',
                        :request_id, :correlation_id, CAST(:safe_metadata AS jsonb)
                    )
                    """
                ),
                {
                    "actor_id": str(user_id),
                    "authorization_context": json.dumps({"schema_version": "1", "role": auth.role}),
                    "request_id": request_id,
                    "correlation_id": correlation_id,
                    "safe_metadata": json.dumps({"schema_version": "1", "scope": scope}),
                },
            )

    @staticmethod
    def _consents(connection: Connection, user_id: UUID) -> list[dict[str, Any]]:
        return [
            dict(row)
            for row in connection.execute(
                text(
                    """
                    SELECT DISTINCT ON (consent_type)
                           id, consent_type, policy_version, decision, decided_at, evidence
                    FROM consent_records
                    WHERE user_id = :user_id
                    ORDER BY consent_type, decided_at DESC, created_at DESC
                    """
                ),
                {"user_id": user_id},
            ).mappings()
        ]

    @staticmethod
    def _first(connection: Connection, query: str, user_id: UUID) -> dict[str, Any] | None:
        row = connection.execute(text(query), {"user_id": user_id}).mappings().first()
        return dict(row) if row else None

    @staticmethod
    def _many(connection: Connection, query: str, user_id: UUID) -> list[dict[str, Any]]:
        return [
            dict(row) for row in connection.execute(text(query), {"user_id": user_id}).mappings()
        ]

    @staticmethod
    def _claim_idempotency(
        connection: Connection,
        user_id: UUID,
        operation: str,
        key: str,
        request_hash: str,
    ) -> str | None:
        inserted = connection.scalar(
            text(
                """
                INSERT INTO idempotency_records(
                    user_id, scope, operation, idempotency_key,
                    request_hash, status, expires_at
                ) VALUES (
                    :user_id, :scope, :operation, :key,
                    :request_hash, 'processing', now() + interval '24 hours'
                )
                ON CONFLICT (scope, operation, idempotency_key) DO NOTHING
                RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "scope": str(user_id),
                "operation": operation,
                "key": key,
                "request_hash": request_hash,
            },
        )
        if inserted is not None:
            return None
        record = (
            connection.execute(
                text(
                    """
                SELECT request_hash, status, response_reference
                FROM idempotency_records
                WHERE scope = :scope AND operation = :operation AND idempotency_key = :key
                """
                ),
                {"scope": str(user_id), "operation": operation, "key": key},
            )
            .mappings()
            .one()
        )
        if record["request_hash"] != request_hash:
            raise ApiError(
                409,
                "idempotency_key_reused",
                "Use a new idempotency key for this request.",
                "correct_input",
            )
        if record["status"] != "completed" or not record["response_reference"]:
            raise ApiError(
                409,
                "operation_in_progress",
                "This operation is still in progress.",
                "retry",
                retryable=True,
                retry_after_seconds=1,
            )
        return str(record["response_reference"])

    @staticmethod
    def _complete_idempotency(
        connection: Connection,
        user_id: UUID,
        operation: str,
        key: str,
        response_reference: str,
    ) -> bool:
        completed = connection.scalar(
            text(
                """
                UPDATE idempotency_records
                SET status = 'completed', response_reference = :reference,
                    updated_at = now(), row_version = row_version + 1
                WHERE user_id = :user_id AND operation = :operation
                  AND idempotency_key = :key AND status = 'processing'
                RETURNING id
                """
            ),
            {
                "user_id": user_id,
                "operation": operation,
                "key": key,
                "reference": response_reference,
            },
        )
        return completed is not None

    @staticmethod
    def _consent_by_id(connection: Connection, user_id: UUID, consent_id: UUID) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                SELECT id, consent_type AS policy_id, policy_version, decision,
                       evidence -> 'accepted_scopes' AS accepted_scopes, decided_at
                FROM consent_records WHERE id = :id AND user_id = :user_id
                """
                ),
                {"id": consent_id, "user_id": user_id},
            )
            .mappings()
            .one()
        )
        return dict(row)

    @staticmethod
    def _device_by_id(connection: Connection, user_id: UUID, device_id: UUID) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                SELECT id, installation_id, platform, app_version, last_seen_at
                FROM device_registrations WHERE id = :id AND user_id = :user_id
                """
                ),
                {"id": device_id, "user_id": user_id},
            )
            .mappings()
            .one()
        )
        return dict(row)


def _request_hash(value: dict[str, Any]) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"), default=str)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()
