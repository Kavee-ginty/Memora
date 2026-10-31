from __future__ import annotations

import hashlib
import json
import logging
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, datetime, timedelta
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.api.security import AuthContext
from memora.modules.privacy.constants import (
    ALLOWED_CANCELLATION_REASONS,
    EXPORT_DOWNLOAD_TTL_SECONDS,
    LEGAL_RETENTION_EXCEPTIONS,
    RECONCILER_VERSION,
    SCOPE_AUTH_PROVIDER,
    SCOPE_DATABASE,
    SCOPE_UPLOADS,
    WORKFLOW_VERSION,
)
from memora.modules.privacy.provider import get_auth_provider
from memora.modules.privacy.storage import (
    export_archive_exists,
    purge_upload_object,
    write_export_archive,
)

logger = logging.getLogger(__name__)


class PrivacyRepository:
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
                raise ApiError(
                    403,
                    "operation_not_allowed",
                    "Account setup is required.",
                )
            resolved = UUID(str(user_id))
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(resolved)},
            )
            yield connection, resolved

    @contextmanager
    def _user_scope_connection(self, user_id: UUID) -> Iterator[Connection]:
        with self.engine.begin() as connection:
            connection.execute(text("SET LOCAL ROLE memora_api"))
            connection.execute(
                text("SELECT set_config('memora.user_id', :user_id, true)"),
                {"user_id": str(user_id)},
            )
            yield connection

    def _claim_idempotency(
        self,
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
                    WHERE scope = :scope AND operation = :operation
                      AND idempotency_key = :key
                    """
                ),
                {"scope": str(user_id), "operation": operation, "key": key},
            )
            .mappings()
            .one_or_none()
        )
        if record is None:
            return None

        if record["request_hash"] != request_hash:
            raise ApiError(
                409,
                "idempotency_conflict",
                "Idempotency key has already been used with different request parameters.",
                "retry_with_new_key",
            )
        if record["status"] == "processing":
            raise ApiError(
                409,
                "concurrent_mutation",
                "Another request is currently processing with this idempotency key.",
                "retry_after_wait",
            )
        return record["response_reference"]

    def _complete_idempotency(
        self,
        connection: Connection,
        user_id: UUID,
        operation: str,
        key: str,
        response_ref: str,
    ) -> None:
        connection.execute(
            text(
                """
                UPDATE idempotency_records
                SET status = 'completed', response_reference = :ref,
                    updated_at = now(), row_version = row_version + 1
                WHERE scope = :scope AND operation = :operation
                  AND idempotency_key = :key
                """
            ),
            {
                "scope": str(user_id),
                "operation": operation,
                "key": key,
                "ref": response_ref,
            },
        )

    def _record_audit_event(
        self,
        connection: Connection,
        *,
        actor_id: str,
        action: str,
        resource_id: UUID,
        auth: AuthContext,
        safe_metadata: dict[str, Any],
        correlation_id: UUID | None = None,
    ) -> None:
        connection.execute(
            text(
                """
                INSERT INTO audit_events(
                    actor_type, actor_id, action, resource_type, resource_id,
                    authorization_context, outcome, correlation_id, safe_metadata
                ) VALUES (
                    'user', :actor_id, :action, 'privacy_request', :resource_id,
                    CAST(:authorization_context AS jsonb), 'succeeded',
                    :correlation_id, CAST(:safe_metadata AS jsonb)
                )
                """
            ),
            {
                "actor_id": actor_id,
                "action": action,
                "resource_id": resource_id,
                "authorization_context": json.dumps({"schema_version": "1", "role": auth.role}),
                "correlation_id": correlation_id,
                "safe_metadata": json.dumps(safe_metadata),
            },
        )

    def create_export_request(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        request_hash: str,
        request_id: UUID,
        format_choice: str = "json",
        correlation_id: UUID | None = None,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            # Advisory transaction lock for user export concurrency
            lock_key = f"privacy_request:{user_id}:export"
            connection.execute(
                text("SELECT pg_advisory_xact_lock(hashtextextended(:lock_key, 0))"),
                {"lock_key": lock_key},
            )

            replay = self._claim_idempotency(
                connection,
                user_id,
                "createPrivacyExport",
                idempotency_key,
                request_hash,
            )
            if replay is not None:
                return self._export_request_by_id(connection, user_id, UUID(replay))

            # Convergence rule: return active export if one is currently in progress
            active_existing = connection.execute(
                text(
                    """
                    SELECT id FROM privacy_requests
                    WHERE user_id = :user_id AND request_type = 'export'
                      AND status IN ('requested', 'verifying', 'processing')
                    ORDER BY created_at DESC
                    LIMIT 1
                    """
                ),
                {"user_id": user_id},
            ).scalar_one_or_none()

            if active_existing is not None:
                effective_id = UUID(str(active_existing))
                self._complete_idempotency(
                    connection,
                    user_id,
                    "createPrivacyExport",
                    idempotency_key,
                    str(effective_id),
                )
                return self._export_request_by_id(connection, user_id, effective_id)

            now = datetime.now(UTC)
            connection.execute(
                text(
                    """
                    INSERT INTO privacy_requests(
                        id, user_id, request_type, status,
                        verified_at, requested_at, workflow_version
                    ) VALUES (
                        :id, :user_id, 'export', 'requested',
                        :verified_at, :requested_at, :workflow_version
                    )
                    """
                ),
                {
                    "id": request_id,
                    "user_id": user_id,
                    "verified_at": now,
                    "requested_at": now,
                    "workflow_version": WORKFLOW_VERSION,
                },
            )

            # Enqueue background job
            connection.execute(
                text(
                    """
                    INSERT INTO background_jobs(
                        job_type, owner_user_id, resource_type, resource_id,
                        dedupe_key, status, max_attempts, available_at, payload
                    ) VALUES (
                        'privacy.export', :user_id, 'privacy_request', :resource_id,
                        :dedupe_key, 'queued', 3, now(), CAST(:payload AS jsonb)
                    )
                    """
                ),
                {
                    "user_id": user_id,
                    "resource_id": request_id,
                    "dedupe_key": f"privacy_export:{request_id}",
                    "payload": json.dumps(
                        {
                            "schema_version": "1",
                            "request_id": str(request_id),
                            "user_id": str(user_id),
                            "format": format_choice,
                        }
                    ),
                },
            )

            self._record_audit_event(
                connection,
                actor_id=str(user_id),
                action="privacy.export.requested",
                resource_id=request_id,
                auth=auth,
                safe_metadata={
                    "schema_version": "1",
                    "request_type": "export",
                    "format": format_choice,
                },
                correlation_id=correlation_id,
            )

            self._complete_idempotency(
                connection,
                user_id,
                "createPrivacyExport",
                idempotency_key,
                str(request_id),
            )
            return self._export_request_by_id(connection, user_id, request_id)

    def get_export_request(self, auth: AuthContext, request_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            return self._export_request_by_id(connection, user_id, request_id)

    def _export_request_by_id(
        self,
        connection: Connection,
        user_id: UUID,
        request_id: UUID,
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT id, request_type, status, requested_at,
                           completed_at, failure_code
                    FROM privacy_requests
                    WHERE id = :id AND user_id = :user_id AND request_type = 'export'
                    """
                ),
                {"id": request_id, "user_id": user_id},
            )
            .mappings()
            .one_or_none()
        )
        if row is None:
            raise ApiError(404, "not_found", "Export request not found.")

        data = dict(row)
        if data["status"] == "completed" and data["completed_at"] is not None:
            completed_time: datetime = data["completed_at"]
            expires_at = completed_time + timedelta(seconds=EXPORT_DOWNLOAD_TTL_SECONDS)
            now = datetime.now(UTC)
            if now < expires_at and export_archive_exists(request_id):
                raw_token = f"{request_id}:{completed_time.isoformat()}".encode()
                token = hashlib.sha256(raw_token).hexdigest()
                base_url = "https://storage.memora.internal/v1/privacy/exports"
                data["download_url"] = f"{base_url}/{request_id}/download?token={token}"
                data["download_expires_at"] = expires_at
            else:
                data["download_url"] = None
                data["download_expires_at"] = None
        else:
            data["download_url"] = None
            data["download_expires_at"] = None

        return data

    def create_deletion_request(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        request_hash: str,
        request_id: UUID,
        correlation_id: UUID | None = None,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            # Advisory transaction lock for user deletion concurrency
            lock_key = f"privacy_request:{user_id}:delete"
            connection.execute(
                text("SELECT pg_advisory_xact_lock(hashtextextended(:lock_key, 0))"),
                {"lock_key": lock_key},
            )

            replay = self._claim_idempotency(
                connection,
                user_id,
                "createPrivacyDeletion",
                idempotency_key,
                request_hash,
            )
            if replay is not None:
                return self._deletion_request_by_id(connection, user_id, UUID(replay))

            # Convergence rule: return active deletion request if already in progress
            active_existing = connection.execute(
                text(
                    """
                    SELECT id FROM privacy_requests
                    WHERE user_id = :user_id AND request_type = 'delete'
                      AND status IN ('requested', 'verifying', 'processing')
                    ORDER BY created_at DESC
                    LIMIT 1
                    """
                ),
                {"user_id": user_id},
            ).scalar_one_or_none()

            if active_existing is not None:
                effective_id = UUID(str(active_existing))
                self._complete_idempotency(
                    connection,
                    user_id,
                    "createPrivacyDeletion",
                    idempotency_key,
                    str(effective_id),
                )
                return self._deletion_request_by_id(connection, user_id, effective_id)

            now = datetime.now(UTC)
            connection.execute(
                text(
                    """
                    INSERT INTO privacy_requests(
                        id, user_id, request_type, status,
                        verified_at, requested_at, workflow_version
                    ) VALUES (
                        :id, :user_id, 'delete', 'requested',
                        :verified_at, :requested_at, :workflow_version
                    )
                    """
                ),
                {
                    "id": request_id,
                    "user_id": user_id,
                    "verified_at": now,
                    "requested_at": now,
                    "workflow_version": WORKFLOW_VERSION,
                },
            )

            # Mark user as deletion_pending
            connection.execute(
                text(
                    """
                    UPDATE users
                    SET status = 'deletion_pending', updated_at = now(),
                        row_version = row_version + 1
                    WHERE id = :user_id AND status = 'active'
                    """
                ),
                {"user_id": user_id},
            )

            # Enqueue background job
            connection.execute(
                text(
                    """
                    INSERT INTO background_jobs(
                        job_type, owner_user_id, resource_type, resource_id,
                        dedupe_key, status, max_attempts, available_at, payload
                    ) VALUES (
                        'privacy.deletion', :user_id, 'privacy_request', :resource_id,
                        :dedupe_key, 'queued', 3, now(), CAST(:payload AS jsonb)
                    )
                    """
                ),
                {
                    "user_id": user_id,
                    "resource_id": request_id,
                    "dedupe_key": f"privacy_deletion:{request_id}",
                    "payload": json.dumps(
                        {
                            "schema_version": "1",
                            "request_id": str(request_id),
                            "user_id": str(user_id),
                        }
                    ),
                },
            )

            self._record_audit_event(
                connection,
                actor_id=str(user_id),
                action="privacy.deletion.requested",
                resource_id=request_id,
                auth=auth,
                safe_metadata={
                    "schema_version": "1",
                    "request_type": "delete",
                },
                correlation_id=correlation_id,
            )

            self._complete_idempotency(
                connection,
                user_id,
                "createPrivacyDeletion",
                idempotency_key,
                str(request_id),
            )
            return self._deletion_request_by_id(connection, user_id, request_id)

    def get_deletion_request(self, auth: AuthContext, request_id: UUID) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            return self._deletion_request_by_id(connection, user_id, request_id)

    def _deletion_request_by_id(
        self,
        connection: Connection,
        user_id: UUID,
        request_id: UUID,
    ) -> dict[str, Any]:
        row = (
            connection.execute(
                text(
                    """
                    SELECT id, request_type, status, requested_at,
                           completed_at, failure_code
                    FROM privacy_requests
                    WHERE id = :id AND user_id = :user_id AND request_type = 'delete'
                    """
                ),
                {"id": request_id, "user_id": user_id},
            )
            .mappings()
            .one_or_none()
        )
        if row is None:
            raise ApiError(404, "not_found", "Deletion request not found.")

        data = dict(row)
        proof_rows = (
            connection.execute(
                text(
                    """
                SELECT id, scope, provider, target_fingerprint, result, verified_at
                FROM deletion_proofs
                WHERE privacy_request_id = :request_id
                ORDER BY created_at ASC
                """
                ),
                {"request_id": request_id},
            )
            .mappings()
            .all()
        )

        data["proofs"] = [dict(proof) for proof in proof_rows]
        data["retention_exceptions"] = (
            LEGAL_RETENTION_EXCEPTIONS if data["status"] == "completed" else []
        )
        return data

    def cancel_deletion_request(
        self,
        auth: AuthContext,
        *,
        request_id: UUID,
        idempotency_key: str,
        request_hash: str,
        reason: str | None = None,
        correlation_id: UUID | None = None,
    ) -> dict[str, Any]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection,
                user_id,
                "cancelPrivacyDeletion",
                idempotency_key,
                request_hash,
            )
            if replay is not None:
                return self._deletion_request_by_id(connection, user_id, UUID(replay))

            row = (
                connection.execute(
                    text(
                        """
                        SELECT id, status, row_version
                        FROM privacy_requests
                        WHERE id = :id AND user_id = :user_id AND request_type = 'delete'
                        FOR UPDATE
                        """
                    ),
                    {"id": request_id, "user_id": user_id},
                )
                .mappings()
                .one_or_none()
            )
            if row is None:
                raise ApiError(404, "not_found", "Deletion request not found.")

            status = row["status"]
            if status == "cancelled":
                self._complete_idempotency(
                    connection,
                    user_id,
                    "cancelPrivacyDeletion",
                    idempotency_key,
                    str(request_id),
                )
                return self._deletion_request_by_id(connection, user_id, request_id)

            if status not in {"requested", "verifying"}:
                raise ApiError(
                    409,
                    "deletion_cancellation_disallowed",
                    f"Deletion request in '{status}' status cannot be cancelled.",
                    "correct_input",
                )

            connection.execute(
                text(
                    """
                    UPDATE privacy_requests
                    SET status = 'cancelled', updated_at = now(), row_version = row_version + 1
                    WHERE id = :id AND user_id = :user_id
                    """
                ),
                {"id": request_id, "user_id": user_id},
            )

            connection.execute(
                text(
                    """
                    UPDATE users
                    SET status = 'active', updated_at = now(), row_version = row_version + 1
                    WHERE id = :user_id AND status = 'deletion_pending'
                    """
                ),
                {"user_id": user_id},
            )

            # Cancel background job if still queued or waiting retry
            connection.execute(
                text(
                    """
                    UPDATE background_jobs
                    SET status = 'cancelled', updated_at = now(), row_version = row_version + 1
                    WHERE resource_id = :request_id AND status IN ('queued', 'retry_wait')
                    """
                ),
                {"request_id": request_id},
            )

            # Audit metadata must only contain allowlisted reason codes, never free user text
            safe_reason = reason if reason in ALLOWED_CANCELLATION_REASONS else "user_requested"

            self._record_audit_event(
                connection,
                actor_id=str(user_id),
                action="privacy.deletion.cancelled",
                resource_id=request_id,
                auth=auth,
                safe_metadata={
                    "schema_version": "1",
                    "reason": safe_reason,
                },
                correlation_id=correlation_id,
            )

            self._complete_idempotency(
                connection,
                user_id,
                "cancelPrivacyDeletion",
                idempotency_key,
                str(request_id),
            )
            return self._deletion_request_by_id(connection, user_id, request_id)

    # =========================================================================
    # Worker Methods (Executed with memora_worker role)
    # =========================================================================

    def execute_export_job(self, request_id: UUID, user_id: UUID) -> None:
        with self._user_scope_connection(user_id) as connection:
            req = (
                connection.execute(
                    text(
                        """
                    SELECT status FROM privacy_requests
                    WHERE id = :id AND user_id = :user_id AND request_type = 'export'
                    FOR UPDATE
                    """
                    ),
                    {"id": request_id, "user_id": user_id},
                )
                .mappings()
                .one_or_none()
            )

            if req is None or req["status"] in {"completed", "cancelled"}:
                return

            connection.execute(
                text(
                    """
                    UPDATE privacy_requests
                    SET status = 'processing', updated_at = now(), row_version = row_version + 1
                    WHERE id = :id
                    """
                ),
                {"id": request_id},
            )

            now = datetime.now(UTC)

            # Query complete learner profile and history
            profile_row = (
                connection.execute(
                    text(
                        """
                    SELECT u.id, u.status, u.default_timezone, u.locale, u.created_at,
                           p.display_name, p.active_subject_id, p.accessibility_preferences
                    FROM users u
                    LEFT JOIN user_profiles p ON u.id = p.user_id
                    WHERE u.id = :user_id
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .one_or_none()
            )
            profile_data = dict(profile_row) if profile_row else {}

            notif_row = (
                connection.execute(
                    text("SELECT * FROM notification_preferences WHERE user_id = :user_id"),
                    {"user_id": user_id},
                )
                .mappings()
                .one_or_none()
            )
            notif_data = dict(notif_row) if notif_row else {}

            consent_rows = (
                connection.execute(
                    text(
                        """
                    SELECT consent_type, policy_version, granted_at, valid_until
                    FROM consent_records WHERE user_id = :user_id
                    ORDER BY granted_at DESC
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .all()
            )
            consent_data = [dict(r) for r in consent_rows]

            concept_rows = (
                connection.execute(
                    text(
                        """
                    SELECT concept_id, retrievability, stability, state, next_review_at,
                           last_reviewed_at, review_count, lapse_count
                    FROM learner_concept_states WHERE user_id = :user_id
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .all()
            )
            concept_data = [dict(r) for r in concept_rows]

            mission_rows = (
                connection.execute(
                    text(
                        """
                    SELECT id, subject_id, mission_date, sequence_no, status,
                           planned_item_count, started_at, completed_at
                    FROM missions WHERE user_id = :user_id
                    ORDER BY mission_date DESC
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .all()
            )
            missions_data = [dict(r) for r in mission_rows]

            attempt_rows = (
                connection.execute(
                    text(
                        """
                    SELECT id, mission_item_id, attempt_no, submitted_at,
                           elapsed_ms, is_offline_submission
                    FROM attempts WHERE user_id = :user_id
                    ORDER BY submitted_at DESC
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .all()
            )
            attempts_data = [dict(r) for r in attempt_rows]

            pk_rows = (
                connection.execute(
                    text(
                        """
                    SELECT id, learning_update_id, item_type, structured_content,
                           confidence, status, created_at
                    FROM private_knowledge_items WHERE user_id = :user_id
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .all()
            )
            pk_data = [dict(r) for r in pk_rows]

            xp_rows = (
                connection.execute(
                    text(
                        """
                    SELECT id, amount, entry_type, source_event_type, created_at
                    FROM xp_ledger WHERE user_id = :user_id
                    ORDER BY created_at DESC
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .all()
            )
            xp_data = [dict(r) for r in xp_rows]

            export_payload = {
                "schema_version": "1.0",
                "request_id": str(request_id),
                "user_id": str(user_id),
                "exported_at": now.isoformat(),
                "profile": profile_data,
                "notification_preferences": notif_data,
                "consent_history": consent_data,
                "concept_progress": concept_data,
                "missions": missions_data,
                "attempts": attempts_data,
                "private_knowledge": pk_data,
                "xp_ledger": xp_data,
            }

            summary_text = (
                f"Memora Learner Data Export\n"
                f"===========================\n"
                f"Student ID: {user_id}\n"
                f"Display Name: {profile_data.get('display_name', 'Student')}\n"
                f"Export Date: {now.isoformat()}\n\n"
                f"Overview of Personal Learning Data:\n"
                f"- Tracked Concept States: {len(concept_data)}\n"
                f"- Missions Recorded: {len(missions_data)}\n"
                f"- Practice Attempts: {len(attempts_data)}\n"
                f"- Private Knowledge Items: {len(pk_data)}\n"
                f"- XP Ledger Entries: {len(xp_data)}\n"
                f"- Consent History Entries: {len(consent_data)}\n\n"
                f"This archive contains export.json with your full machine-readable data.\n"
            )

            # Persist the export archive
            write_export_archive(
                request_id,
                json.dumps(export_payload, default=str, indent=2).encode("utf-8"),
                summary_text,
            )

            if not export_archive_exists(request_id):
                raise RuntimeError(f"Export archive generation failed for request {request_id}")

            connection.execute(
                text(
                    """
                    UPDATE privacy_requests
                    SET status = 'completed', completed_at = :completed_at,
                        updated_at = :completed_at, row_version = row_version + 1
                    WHERE id = :id
                    """
                ),
                {"id": request_id, "completed_at": now},
            )

            connection.execute(
                text(
                    """
                    INSERT INTO audit_events(
                        actor_type, actor_id, action, resource_type, resource_id,
                        authorization_context, outcome, safe_metadata
                    ) VALUES (
                        'system', 'memora_worker', 'privacy.export.completed',
                        'privacy_request', :id,
                        '{"schema_version": "1", "role": "memora_worker"}'::jsonb,
                        'succeeded', '{"schema_version": "1", "status": "completed"}'::jsonb
                    )
                    """
                ),
                {"id": request_id},
            )

    def execute_deletion_job(self, request_id: UUID, user_id: UUID) -> None:
        with self._user_scope_connection(user_id) as connection:
            req = (
                connection.execute(
                    text(
                        """
                    SELECT status FROM privacy_requests
                    WHERE id = :id AND user_id = :user_id AND request_type = 'delete'
                    FOR UPDATE
                    """
                    ),
                    {"id": request_id, "user_id": user_id},
                )
                .mappings()
                .one_or_none()
            )

            if req is None or req["status"] in {"completed", "cancelled"}:
                return

            connection.execute(
                text(
                    """
                    UPDATE privacy_requests
                    SET status = 'processing', updated_at = now(), row_version = row_version + 1
                    WHERE id = :id
                    """
                ),
                {"id": request_id},
            )

            now = datetime.now(UTC)
            user_fingerprint = hashlib.sha256(str(user_id).encode()).hexdigest()

            # -----------------------------------------------------------------
            # Scope 1: Database Learner State (Delete private data and vectors)
            # -----------------------------------------------------------------
            connection.execute(
                text("DELETE FROM learner_concept_states WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            connection.execute(
                text("DELETE FROM private_knowledge_items WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            connection.execute(
                text("DELETE FROM reef_projections WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            connection.execute(
                text("DELETE FROM notification_preferences WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            connection.execute(
                text("DELETE FROM device_registrations WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            connection.execute(
                text("DELETE FROM question_reports WHERE user_id = :user_id"),
                {"user_id": user_id},
            )

            # Anonymize profile
            connection.execute(
                text(
                    """
                    UPDATE user_profiles
                    SET display_name = 'Deleted Learner',
                        accessibility_preferences = '{"schema_version":"1"}'::jsonb,
                        active_subject_id = NULL,
                        updated_at = now(), row_version = row_version + 1
                    WHERE user_id = :user_id
                    """
                ),
                {"user_id": user_id},
            )

            # Verification of Scope 1
            remaining_states = connection.scalar(
                text("SELECT count(*) FROM learner_concept_states WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            remaining_knowledge = connection.scalar(
                text("SELECT count(*) FROM private_knowledge_items WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            remaining_devices = connection.scalar(
                text("SELECT count(*) FROM device_registrations WHERE user_id = :user_id"),
                {"user_id": user_id},
            )
            if remaining_states != 0 or remaining_knowledge != 0 or remaining_devices != 0:
                raise RuntimeError(
                    f"Database deletion verification failed: states={remaining_states}, "
                    f"knowledge={remaining_knowledge}, devices={remaining_devices}"
                )

            connection.execute(
                text(
                    """
                    INSERT INTO deletion_proofs(
                        privacy_request_id, scope, provider, target_fingerprint,
                        result, verified_at, reconciler_version
                    ) VALUES (
                        :request_id, :scope, 'postgres', :fingerprint,
                        'deleted', :verified_at, :reconciler_version
                    )
                    """
                ),
                {
                    "request_id": request_id,
                    "scope": SCOPE_DATABASE,
                    "fingerprint": user_fingerprint,
                    "verified_at": now,
                    "reconciler_version": RECONCILER_VERSION,
                },
            )

            # -----------------------------------------------------------------
            # Scope 2: Temporary Uploads
            # -----------------------------------------------------------------
            active_uploads = (
                connection.execute(
                    text(
                        """
                    SELECT id, object_key FROM source_uploads
                    WHERE user_id = :user_id AND status != 'deleted'
                    """
                    ),
                    {"user_id": user_id},
                )
                .mappings()
                .all()
            )

            for up in active_uploads:
                purge_upload_object(up["object_key"])

            connection.execute(
                text(
                    """
                    UPDATE source_uploads
                    SET status = 'deleted', deleted_at = :now, updated_at = :now,
                        row_version = row_version + 1
                    WHERE user_id = :user_id AND status != 'deleted'
                    """
                ),
                {"user_id": user_id, "now": now},
            )

            remaining_uploads = connection.scalar(
                text(
                    """
                    SELECT count(*) FROM source_uploads
                    WHERE user_id = :user_id AND status != 'deleted'
                    """
                ),
                {"user_id": user_id},
            )
            if remaining_uploads != 0:
                raise RuntimeError(
                    f"Uploads deletion verification failed: remaining={remaining_uploads}"
                )

            connection.execute(
                text(
                    """
                    INSERT INTO deletion_proofs(
                        privacy_request_id, scope, provider, target_fingerprint,
                        result, verified_at, reconciler_version
                    ) VALUES (
                        :request_id, :scope, 'storage', :fingerprint,
                        'deleted', :verified_at, :reconciler_version
                    )
                    """
                ),
                {
                    "request_id": request_id,
                    "scope": SCOPE_UPLOADS,
                    "fingerprint": user_fingerprint,
                    "verified_at": now,
                    "reconciler_version": RECONCILER_VERSION,
                },
            )

            # -----------------------------------------------------------------
            # Scope 3: Auth Provider
            # -----------------------------------------------------------------
            user_row = (
                connection.execute(
                    text("SELECT oidc_subject FROM users WHERE id = :user_id"),
                    {"user_id": user_id},
                )
                .mappings()
                .one()
            )
            oidc_subject = user_row["oidc_subject"]

            auth_prov = get_auth_provider()
            deleted_from_provider = auth_prov.delete_user(user_id, oidc_subject)
            if not deleted_from_provider or not auth_prov.verify_user_absent(user_id, oidc_subject):
                raise RuntimeError("Auth provider deletion verification failed")

            connection.execute(
                text(
                    """
                    INSERT INTO deletion_proofs(
                        privacy_request_id, scope, provider, target_fingerprint,
                        result, verified_at, reconciler_version
                    ) VALUES (
                        :request_id, :scope, 'supabase', :fingerprint,
                        'deleted', :verified_at, :reconciler_version
                    )
                    """
                ),
                {
                    "request_id": request_id,
                    "scope": SCOPE_AUTH_PROVIDER,
                    "fingerprint": user_fingerprint,
                    "verified_at": now,
                    "reconciler_version": RECONCILER_VERSION,
                },
            )

            # -----------------------------------------------------------------
            # Mark user and request completed
            # -----------------------------------------------------------------
            connection.execute(
                text(
                    """
                    UPDATE users
                    SET status = 'deleted', deleted_at = :now, updated_at = :now,
                        row_version = row_version + 1
                    WHERE id = :user_id
                    """
                ),
                {"user_id": user_id, "now": now},
            )

            connection.execute(
                text(
                    """
                    UPDATE privacy_requests
                    SET status = 'completed', completed_at = :now, updated_at = :now,
                        row_version = row_version + 1
                    WHERE id = :id
                    """
                ),
                {"id": request_id, "now": now},
            )

            connection.execute(
                text(
                    """
                    INSERT INTO audit_events(
                        actor_type, actor_id, action, resource_type, resource_id,
                        authorization_context, outcome, safe_metadata
                    ) VALUES (
                        'system', 'memora_worker', 'privacy.deletion.completed',
                        'privacy_request', :id,
                        '{"schema_version": "1", "role": "memora_worker"}'::jsonb,
                        'succeeded', '{"schema_version": "1", "status": "completed"}'::jsonb
                    )
                    """
                ),
                {"id": request_id},
            )
