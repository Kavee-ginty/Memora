"""Persistence for question reports, snapshots and reviewed content imports.

`QuestionReportRepository` always runs as `memora_api` with a transaction-local
owner. `QuestionImportRepository` is deliberately separate: reviewed content is
written by a privileged offline import path, never by a student request.
"""

from __future__ import annotations

import json
from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, datetime
from typing import Any
from uuid import UUID

from sqlalchemy import Connection, Engine, text

from memora.api.errors import ApiError
from memora.api.security import AuthContext
from memora.modules.questions.constants import (
    ATTEMPT_EVIDENCE_ELIGIBLE,
    ATTEMPT_EVIDENCE_LIMITED,
    LIMITING_REPORT_TYPES,
    OPEN_REPORT_STATUSES,
)
from memora.modules.questions.models import (
    ConceptMappingSnapshot,
    QuestionOptionSnapshot,
    QuestionRubricSnapshot,
    QuestionSnapshot,
    ValidatedQuestionImport,
)
from memora.modules.questions.validation import (
    QuestionValidationError,
    canonical_content_hash,
    parse_question_content,
    parse_rubric_payload,
)

_REPORT_COLUMNS = """
    id, question_version_id, attempt_id, report_type,
    (description_ciphertext IS NOT NULL) AS description_present,
    status, resolution_code, submitted_at, resolved_at
"""


class QuestionReportRepository:
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

    def create_report(
        self,
        auth: AuthContext,
        *,
        idempotency_key: str,
        request_hash: str,
        report_id: UUID,
        question_version_id: UUID,
        attempt_id: UUID | None,
        report_type: str,
        description_ciphertext: bytes | None,
        submitted_at: datetime,
    ) -> tuple[dict[str, Any], bool]:
        with self._connection(auth) as (connection, user_id):
            replay = self._claim_idempotency(
                connection,
                user_id,
                "createQuestionReport",
                idempotency_key,
                request_hash,
            )
            if replay is not None:
                return self._report_by_id(connection, user_id, UUID(replay)), False

            self._assert_report_target(
                connection,
                user_id,
                question_version_id=question_version_id,
                attempt_id=attempt_id,
            )
            connection.execute(
                text(
                    """
                    INSERT INTO question_reports(
                        id, user_id, question_version_id, attempt_id, report_type,
                        description_ciphertext, status, submitted_at
                    ) VALUES (
                        :id, :user_id, :question_version_id, :attempt_id, :report_type,
                        :description_ciphertext, 'submitted', :submitted_at
                    )
                    """
                ),
                {
                    "id": report_id,
                    "user_id": user_id,
                    "question_version_id": question_version_id,
                    "attempt_id": attempt_id,
                    "report_type": report_type,
                    "description_ciphertext": description_ciphertext,
                    "submitted_at": submitted_at,
                },
            )
            self._complete_idempotency(
                connection,
                user_id,
                "createQuestionReport",
                idempotency_key,
                str(report_id),
            )
            return self._report_by_id(connection, user_id, report_id), True

    def list_reports(
        self,
        auth: AuthContext,
        *,
        limit: int,
        before: tuple[datetime, UUID] | None,
    ) -> tuple[list[dict[str, Any]], bool]:
        with self._connection(auth) as (connection, user_id):
            parameters: dict[str, Any] = {"user_id": user_id, "limit": limit + 1}
            before_clause = ""
            if before is not None:
                before_clause = (
                    "AND (submitted_at, id) < "
                    "(CAST(:before_at AS timestamptz), CAST(:before_id AS uuid))"
                )
                parameters.update({"before_at": before[0], "before_id": before[1]})
            rows = (
                connection.execute(
                    text(
                        f"""
                        SELECT {_REPORT_COLUMNS}
                        FROM question_reports
                        WHERE user_id = :user_id
                        {before_clause}
                        ORDER BY submitted_at DESC, id DESC
                        LIMIT :limit
                        """
                    ),
                    parameters,
                )
                .mappings()
                .all()
            )
            has_more = len(rows) > limit
            return [dict(row) for row in rows[:limit]], has_more

    def get_report(self, auth: AuthContext, *, report_id: UUID) -> dict[str, Any] | None:
        with self._connection(auth) as (connection, user_id):
            return self._report_by_id(connection, user_id, report_id, missing_ok=True)

    def attempt_evidence_eligibility(self, auth: AuthContext, *, attempt_id: UUID) -> str:
        """Return whether an owner's attempt evidence is safe for high-impact use.

        T13 must treat `limited_pending_review` as "do not use for memory, XP or
        streak updates" until the linked report is resolved or dismissed. The
        query is owner-scoped under the same `memora_api` role as report access.
        """

        with self._connection(auth) as (connection, user_id):
            row = (
                connection.execute(
                    text(
                        """
                        SELECT EXISTS (
                            SELECT 1
                            FROM question_reports qr
                            WHERE qr.user_id = a.user_id
                              AND qr.attempt_id = a.id
                              AND qr.report_type = ANY(:report_types)
                              AND qr.status = ANY(:open_statuses)
                        ) AS limited
                        FROM attempts a
                        WHERE a.id = :attempt_id AND a.user_id = :user_id
                        """
                    ),
                    {
                        "attempt_id": attempt_id,
                        "user_id": user_id,
                        "report_types": sorted(LIMITING_REPORT_TYPES),
                        "open_statuses": sorted(OPEN_REPORT_STATUSES),
                    },
                )
                .mappings()
                .first()
            )
        if row is None:
            raise ApiError(404, "resource_not_found", "Attempt was not found.")
        return ATTEMPT_EVIDENCE_LIMITED if row["limited"] else ATTEMPT_EVIDENCE_ELIGIBLE

    def load_snapshot(self, auth: AuthContext, *, question_version_id: UUID) -> QuestionSnapshot:
        """Load a pinned version; attempt-scoped RLS keeps retired history readable."""

        with self._connection(auth) as (connection, _):
            return self._load_snapshot(connection, question_version_id)

    @staticmethod
    def _assert_report_target(
        connection: Connection,
        user_id: UUID,
        *,
        question_version_id: UUID,
        attempt_id: UUID | None,
    ) -> None:
        if attempt_id is not None:
            exists = connection.scalar(
                text(
                    """
                    SELECT 1
                    FROM attempts a
                    JOIN mission_items mi ON mi.id = a.mission_item_id
                    WHERE a.id = :attempt_id
                      AND a.user_id = :user_id
                      AND mi.question_version_id = :question_version_id
                    """
                ),
                {
                    "attempt_id": attempt_id,
                    "user_id": user_id,
                    "question_version_id": question_version_id,
                },
            )
        else:
            exists = connection.scalar(
                text(
                    """
                    SELECT 1
                    FROM question_versions
                    WHERE id = :question_version_id
                      AND validation_status = 'approved'
                    """
                ),
                {"question_version_id": question_version_id},
            )
        if not exists:
            raise ApiError(404, "resource_not_found", "Question report target was not found.")

    @staticmethod
    def _report_by_id(
        connection: Connection,
        user_id: UUID,
        report_id: UUID,
        *,
        missing_ok: bool = False,
    ) -> dict[str, Any] | None:
        row = (
            connection.execute(
                text(
                    f"""
                    SELECT {_REPORT_COLUMNS}
                    FROM question_reports
                    WHERE id = :report_id AND user_id = :user_id
                    """
                ),
                {"report_id": report_id, "user_id": user_id},
            )
            .mappings()
            .first()
        )
        if row is None:
            if missing_ok:
                return None
            raise ApiError(404, "resource_not_found", "Question report was not found.")
        return dict(row)

    @staticmethod
    def _load_snapshot(connection: Connection, question_version_id: UUID) -> QuestionSnapshot:
        version = (
            connection.execute(
                text(
                    """
                    SELECT qv.id, qv.question_type, qv.prompt, qv.explanation,
                           qv.content_payload, qv.trust_label, qv.validation_status,
                           q.question_code, q.source_class
                    FROM question_versions qv
                    JOIN questions q ON q.id = qv.question_id
                    WHERE qv.id = :question_version_id
                    """
                ),
                {"question_version_id": question_version_id},
            )
            .mappings()
            .first()
        )
        if version is None:
            raise QuestionValidationError(
                "question_not_found",
                "The pinned question version is not available.",
                "question_version_id",
            )

        option_rows = (
            connection.execute(
                text(
                    """
                    SELECT option_key, display_text, accessible_image_ref, is_correct,
                           explanation, display_order
                    FROM question_options
                    WHERE question_version_id = :question_version_id
                    ORDER BY display_order
                    """
                ),
                {"question_version_id": question_version_id},
            )
            .mappings()
            .all()
        )
        rubric = (
            connection.execute(
                text(
                    """
                    SELECT id, rubric_type, rubric_version, rubric_payload, max_score,
                           evidence_ceiling, status
                    FROM question_rubrics
                    WHERE question_version_id = :question_version_id
                    """
                ),
                {"question_version_id": question_version_id},
            )
            .mappings()
            .first()
        )
        if rubric is None:
            raise QuestionValidationError(
                "rubric_missing",
                "The pinned question version has no grading rubric.",
                "rubric",
            )
        concept_rows = (
            connection.execute(
                text(
                    """
                    SELECT concept_version_id, learning_objective_id, mapping_role, weight
                    FROM question_concept_maps
                    WHERE question_version_id = :question_version_id
                    ORDER BY mapping_role, concept_version_id
                    """
                ),
                {"question_version_id": question_version_id},
            )
            .mappings()
            .all()
        )

        content = parse_question_content(version["question_type"], version["content_payload"])
        rubric_payload = parse_rubric_payload(
            version["question_type"],
            rubric["rubric_type"],
            rubric["rubric_payload"],
        )
        if version["question_type"] in {"mcq", "diagram_interpretation"} and not option_rows:
            raise QuestionValidationError(
                "options_missing",
                "The pinned question version has no answer options.",
                "options",
            )
        return QuestionSnapshot(
            question_version_id=UUID(str(version["id"])),
            question_code=str(version["question_code"]),
            source_class=str(version["source_class"]),
            validation_status=str(version["validation_status"]),
            question_type=str(version["question_type"]),
            prompt=str(version["prompt"]),
            explanation=str(version["explanation"]),
            trust_label=str(version["trust_label"]),
            content=content,
            options=tuple(
                QuestionOptionSnapshot(
                    option_key=str(option["option_key"]),
                    display_text=str(option["display_text"]),
                    accessible_image_ref=option["accessible_image_ref"],
                    is_correct=bool(option["is_correct"]),
                    explanation=str(option["explanation"]),
                    display_order=int(option["display_order"]),
                )
                for option in option_rows
            ),
            rubric=QuestionRubricSnapshot(
                id=UUID(str(rubric["id"])),
                rubric_type=str(rubric["rubric_type"]),
                rubric_version=int(rubric["rubric_version"]),
                payload=rubric_payload,
                max_score=rubric["max_score"],
                evidence_ceiling=rubric["evidence_ceiling"],
                status=str(rubric["status"]),
            ),
            concept_mappings=tuple(
                ConceptMappingSnapshot(
                    concept_version_id=UUID(str(mapping["concept_version_id"])),
                    learning_objective_id=(
                        UUID(str(mapping["learning_objective_id"]))
                        if mapping["learning_objective_id"] is not None
                        else None
                    ),
                    mapping_role=str(mapping["mapping_role"]),
                    weight=mapping["weight"],
                )
                for mapping in concept_rows
            ),
        )

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
                    WHERE scope = :scope AND operation = :operation
                      AND idempotency_key = :key
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


class QuestionImportRepository:
    """Privileged reviewed-content import. Never wire this into a request route."""

    def __init__(self, engine: Engine) -> None:
        self.engine = engine

    def import_question(self, imported: ValidatedQuestionImport) -> dict[str, Any]:
        with self.engine.begin() as connection:
            lock_key = f"{imported.bundle.subject_id}:{imported.bundle.question_code}"
            connection.execute(
                text("SELECT pg_advisory_xact_lock(hashtextextended(:key, 0))"),
                {"key": lock_key},
            )
            self._validate_references(connection, imported)
            parent = (
                connection.execute(
                    text(
                        """
                        SELECT id, subject_id, source_class, status
                        FROM questions
                        WHERE subject_id = :subject_id AND question_code = :question_code
                        """
                    ),
                    {
                        "subject_id": imported.bundle.subject_id,
                        "question_code": imported.bundle.question_code,
                    },
                )
                .mappings()
                .first()
            )
            if parent is not None and parent["source_class"] != imported.bundle.source_class:
                raise QuestionValidationError(
                    "source_class_mismatch",
                    "A question code cannot change its source class.",
                    "source_class",
                )

            versions = []
            if parent is not None:
                versions = (
                    connection.execute(
                        text(
                            """
                            SELECT id, version_no, question_type, prompt, explanation,
                                   content_payload, trust_label, curriculum_version_id,
                                   validation_status, model_key, prompt_version,
                                   grounding_evidence_ids, validator_version,
                                   validation_score, generation_trace_ref
                            FROM question_versions
                            WHERE question_id = :question_id
                            ORDER BY version_no
                            """
                        ),
                        {"question_id": parent["id"]},
                    )
                    .mappings()
                    .all()
                )
                for version in versions:
                    stored_hash = self._stored_content_hash(
                        connection,
                        parent=parent,
                        version=version,
                    )
                    if stored_hash != imported.content_hash:
                        continue
                    if version["validation_status"] != imported.bundle.validation_status:
                        raise QuestionValidationError(
                            "duplicate_question_version",
                            "Identical content already exists with a different status.",
                            "validation_status",
                        )
                    return {
                        "question_id": UUID(str(parent["id"])),
                        "question_version_id": UUID(str(version["id"])),
                        "version_no": int(version["version_no"]),
                        "validation_status": str(version["validation_status"]),
                        "created": False,
                        "content_hash": imported.content_hash,
                    }

            approved = imported.bundle.validation_status == "approved"
            if parent is None:
                question_id = connection.scalar(
                    text(
                        """
                        INSERT INTO questions(
                            subject_id, question_code, source_class, status,
                            author_principal, reviewer_principal
                        ) VALUES (
                            :subject_id, :question_code, :source_class, :status,
                            :author_principal, :reviewer_principal
                        )
                        RETURNING id
                        """
                    ),
                    {
                        "subject_id": imported.bundle.subject_id,
                        "question_code": imported.bundle.question_code,
                        "source_class": imported.bundle.source_class,
                        "status": "approved" if approved else "draft",
                        "author_principal": imported.bundle.author_principal,
                        "reviewer_principal": imported.bundle.reviewer_principal,
                    },
                )
                question_id = UUID(str(question_id))
            else:
                question_id = UUID(str(parent["id"]))
                connection.execute(
                    text(
                        """
                        UPDATE questions
                        SET status = CASE WHEN :approved THEN 'approved' ELSE status END,
                            author_principal = COALESCE(:author_principal, author_principal),
                            reviewer_principal = COALESCE(
                                :reviewer_principal, reviewer_principal
                            ),
                            updated_at = now(),
                            row_version = row_version + 1
                        WHERE id = :question_id
                        """
                    ),
                    {
                        "approved": approved,
                        "author_principal": imported.bundle.author_principal,
                        "reviewer_principal": imported.bundle.reviewer_principal,
                        "question_id": question_id,
                    },
                )

            version_no = max((int(version["version_no"]) for version in versions), default=0) + 1
            version_id = connection.scalar(
                text(
                    """
                    INSERT INTO question_versions(
                        question_id, version_no, question_type, prompt, explanation,
                        content_payload, trust_label, curriculum_version_id,
                        validation_status, model_key, prompt_version,
                        grounding_evidence_ids, validator_version, validation_score,
                        generation_trace_ref
                    ) VALUES (
                        :question_id, :version_no, :question_type, :prompt, :explanation,
                        CAST(:content_payload AS jsonb), :trust_label,
                        :curriculum_version_id, 'draft', :model_key,
                        :prompt_version, CAST(:grounding_evidence_ids AS uuid[]),
                        :validator_version, :validation_score, :generation_trace_ref
                    )
                    RETURNING id
                    """
                ),
                {
                    "question_id": question_id,
                    "version_no": version_no,
                    "question_type": imported.bundle.question_type,
                    "prompt": imported.bundle.prompt,
                    "explanation": imported.bundle.explanation,
                    "content_payload": json.dumps(
                        imported.content.model_dump(mode="json"), ensure_ascii=False
                    ),
                    "trust_label": imported.trust_label,
                    "curriculum_version_id": imported.bundle.curriculum_version_id,
                    "model_key": imported.bundle.model_key,
                    "prompt_version": imported.bundle.prompt_version,
                    "grounding_evidence_ids": imported.bundle.grounding_evidence_ids,
                    "validator_version": imported.bundle.validator_version,
                    "validation_score": imported.bundle.validation_score,
                    "generation_trace_ref": imported.bundle.generation_trace_ref,
                },
            )
            version_id = UUID(str(version_id))

            for option in imported.bundle.options:
                connection.execute(
                    text(
                        """
                        INSERT INTO question_options(
                            question_version_id, option_key, display_text,
                            accessible_image_ref, is_correct, explanation, display_order
                        ) VALUES (
                            :question_version_id, :option_key, :display_text,
                            :accessible_image_ref, :is_correct, :explanation, :display_order
                        )
                        """
                    ),
                    {
                        "question_version_id": version_id,
                        "option_key": option.option_key,
                        "display_text": option.display_text,
                        "accessible_image_ref": option.accessible_image_ref,
                        "is_correct": option.is_correct,
                        "explanation": option.explanation,
                        "display_order": option.display_order,
                    },
                )

            connection.execute(
                text(
                    """
                    INSERT INTO question_rubrics(
                        question_version_id, rubric_type, rubric_version, rubric_payload,
                        max_score, evidence_ceiling, status
                    ) VALUES (
                        :question_version_id, :rubric_type, 1,
                        CAST(:rubric_payload AS jsonb), :max_score,
                        :evidence_ceiling, :status
                    )
                    """
                ),
                {
                    "question_version_id": version_id,
                    "rubric_type": imported.bundle.rubric.rubric_type,
                    "rubric_payload": json.dumps(
                        imported.rubric_payload.model_dump(mode="json"), ensure_ascii=False
                    ),
                    "max_score": imported.bundle.rubric.max_score,
                    "evidence_ceiling": imported.bundle.rubric.evidence_ceiling,
                    "status": imported.bundle.rubric.status,
                },
            )

            for mapping in imported.bundle.concept_mappings:
                connection.execute(
                    text(
                        """
                        INSERT INTO question_concept_maps(
                            question_version_id, concept_version_id,
                            learning_objective_id, mapping_role, weight,
                            provenance_type, provenance_ref
                        ) VALUES (
                            :question_version_id, :concept_version_id,
                            :learning_objective_id, :mapping_role, :weight,
                            :provenance_type, :provenance_ref
                        )
                        """
                    ),
                    {
                        "question_version_id": version_id,
                        "concept_version_id": mapping.concept_version_id,
                        "learning_objective_id": mapping.learning_objective_id,
                        "mapping_role": mapping.mapping_role,
                        "weight": mapping.weight,
                        "provenance_type": mapping.provenance_type,
                        "provenance_ref": mapping.provenance_ref,
                    },
                )

            if approved:
                # Children are staged under a draft version so the immutability
                # trigger cannot mistake reviewed import for an edit of live content.
                # The deferred publication guard validates the complete set when
                # this transaction publishes the version.
                connection.execute(
                    text(
                        """
                        UPDATE question_versions
                        SET validation_status = 'approved',
                            updated_at = now(),
                            row_version = row_version + 1
                        WHERE id = :version_id
                        """
                    ),
                    {"version_id": version_id},
                )

            return {
                "question_id": question_id,
                "question_version_id": version_id,
                "version_no": version_no,
                "validation_status": imported.bundle.validation_status,
                "created": True,
                "content_hash": imported.content_hash,
            }

    @staticmethod
    def _validate_references(connection: Connection, imported: ValidatedQuestionImport) -> None:
        bundle = imported.bundle
        curriculum = (
            connection.execute(
                text(
                    """
                    SELECT cv.subject_id, cv.status, s.status AS subject_status
                    FROM curriculum_versions cv
                    JOIN subjects s ON s.id = cv.subject_id
                    WHERE cv.id = :curriculum_version_id
                    """
                ),
                {"curriculum_version_id": bundle.curriculum_version_id},
            )
            .mappings()
            .first()
        )
        if (
            curriculum is None
            or UUID(str(curriculum["subject_id"])) != bundle.subject_id
            or curriculum["status"] != "approved"
            or curriculum["subject_status"] != "approved"
        ):
            raise QuestionValidationError(
                "curriculum_invalid",
                "The question curriculum must be approved and belong to its subject.",
                "curriculum_version_id",
            )

        curriculum_aligned = False
        for mapping in bundle.concept_mappings:
            concept = (
                connection.execute(
                    text(
                        """
                        SELECT c.subject_id, c.status AS concept_status,
                               cv.content_status
                        FROM concept_versions cv
                        JOIN concepts c ON c.id = cv.concept_id
                        WHERE cv.id = :concept_version_id
                        """
                    ),
                    {"concept_version_id": mapping.concept_version_id},
                )
                .mappings()
                .first()
            )
            if (
                concept is None
                or UUID(str(concept["subject_id"])) != bundle.subject_id
                or concept["concept_status"] != "approved"
                or concept["content_status"] != "approved"
            ):
                raise QuestionValidationError(
                    "concept_mapping_invalid",
                    "A concept mapping must reference an approved concept in this subject.",
                    "concept_mappings",
                )

            if mapping.learning_objective_id is not None:
                objective = (
                    connection.execute(
                        text(
                            """
                            SELECT curriculum_version_id, status
                            FROM learning_objectives
                            WHERE id = :objective_id
                            """
                        ),
                        {"objective_id": mapping.learning_objective_id},
                    )
                    .mappings()
                    .first()
                )
                if (
                    objective is None
                    or UUID(str(objective["curriculum_version_id"])) != bundle.curriculum_version_id
                    or objective["status"] != "approved"
                ):
                    raise QuestionValidationError(
                        "concept_mapping_invalid",
                        "A concept mapping must reference an approved objective "
                        "in this curriculum.",
                        "concept_mappings",
                    )
                aligned = (
                    connection.scalar(
                        text(
                            """
                            SELECT 1
                            FROM concept_objective_maps
                            WHERE concept_version_id = :concept_version_id
                              AND learning_objective_id = :objective_id
                            """
                        ),
                        {
                            "concept_version_id": mapping.concept_version_id,
                            "objective_id": mapping.learning_objective_id,
                        },
                    )
                    is not None
                )
                if not aligned:
                    raise QuestionValidationError(
                        "concept_mapping_invalid",
                        "A concept mapping must align its concept with its learning objective.",
                        "concept_mappings",
                    )
            else:
                aligned = (
                    connection.scalar(
                        text(
                            """
                            SELECT 1
                            FROM concept_objective_maps com
                            JOIN learning_objectives lo ON lo.id = com.learning_objective_id
                            WHERE com.concept_version_id = :concept_version_id
                              AND lo.curriculum_version_id = :curriculum_version_id
                              AND lo.status = 'approved'
                            """
                        ),
                        {
                            "concept_version_id": mapping.concept_version_id,
                            "curriculum_version_id": bundle.curriculum_version_id,
                        },
                    )
                    is not None
                )
            curriculum_aligned = curriculum_aligned or aligned

        if bundle.validation_status == "approved" and not curriculum_aligned:
            raise QuestionValidationError(
                "curriculum_mapping_missing",
                "An approved question must map to an objective in its curriculum.",
                "concept_mappings",
            )

        if bundle.source_class == "ai_generated":
            QuestionImportRepository._validate_grounding_evidence(connection, imported)

    @staticmethod
    def _validate_grounding_evidence(
        connection: Connection, imported: ValidatedQuestionImport
    ) -> None:
        bundle = imported.bundle
        for claim_id in bundle.grounding_evidence_ids:
            claim = (
                connection.execute(
                    text(
                        """
                        SELECT kc.status AS claim_status,
                               cv.content_status AS concept_content_status,
                               c.status AS concept_status,
                               c.subject_id,
                               EXISTS (
                                   SELECT 1
                                   FROM concept_objective_maps com
                                   JOIN learning_objectives lo
                                     ON lo.id = com.learning_objective_id
                                   WHERE com.concept_version_id = cv.id
                                     AND lo.curriculum_version_id = :curriculum_version_id
                                     AND lo.status = 'approved'
                               ) AS curriculum_aligned
                        FROM knowledge_claims kc
                        JOIN concept_versions cv ON cv.id = kc.concept_version_id
                        JOIN concepts c ON c.id = cv.concept_id
                        WHERE kc.id = :claim_id
                        """
                    ),
                    {
                        "claim_id": claim_id,
                        "curriculum_version_id": bundle.curriculum_version_id,
                    },
                )
                .mappings()
                .first()
            )
            if (
                claim is None
                or claim["claim_status"] != "approved"
                or claim["concept_content_status"] != "approved"
                or claim["concept_status"] != "approved"
                or UUID(str(claim["subject_id"])) != bundle.subject_id
                or not claim["curriculum_aligned"]
            ):
                raise QuestionValidationError(
                    "grounding_evidence_invalid",
                    "Generated content must cite approved knowledge claims in this curriculum.",
                    "grounding_evidence_ids",
                )

    @staticmethod
    def _stored_content_hash(
        connection: Connection,
        *,
        parent: Any,
        version: Any,
    ) -> str:
        options = (
            connection.execute(
                text(
                    """
                    SELECT option_key, display_text, accessible_image_ref, is_correct,
                           explanation, display_order
                    FROM question_options
                    WHERE question_version_id = :question_version_id
                    ORDER BY display_order
                    """
                ),
                {"question_version_id": version["id"]},
            )
            .mappings()
            .all()
        )
        rubric = (
            connection.execute(
                text(
                    """
                    SELECT rubric_type, rubric_version, rubric_payload, max_score,
                           evidence_ceiling, status
                    FROM question_rubrics
                    WHERE question_version_id = :question_version_id
                    """
                ),
                {"question_version_id": version["id"]},
            )
            .mappings()
            .first()
        )
        if rubric is None:
            raise QuestionValidationError(
                "rubric_missing",
                "A stored question version has no grading rubric.",
                "rubric",
            )
        mappings = (
            connection.execute(
                text(
                    """
                    SELECT concept_version_id, learning_objective_id, mapping_role,
                           weight, provenance_type, provenance_ref
                    FROM question_concept_maps
                    WHERE question_version_id = :question_version_id
                    """
                ),
                {"question_version_id": version["id"]},
            )
            .mappings()
            .all()
        )
        content = parse_question_content(str(version["question_type"]), version["content_payload"])
        rubric_payload = parse_rubric_payload(
            str(version["question_type"]),
            str(rubric["rubric_type"]),
            rubric["rubric_payload"],
        )
        return canonical_content_hash(
            subject_id=parent["subject_id"],
            curriculum_version_id=version["curriculum_version_id"],
            question_type=str(version["question_type"]),
            source_class=str(parent["source_class"]),
            trust_label=str(version["trust_label"]),
            prompt=str(version["prompt"]),
            explanation=str(version["explanation"]),
            content=content.model_dump(mode="json"),
            options=options,
            rubric_type=str(rubric["rubric_type"]),
            rubric_version=int(rubric["rubric_version"]),
            rubric_payload=rubric_payload.model_dump(mode="json"),
            rubric_max_score=rubric["max_score"],
            rubric_evidence_ceiling=rubric["evidence_ceiling"],
            rubric_status=str(rubric["status"]),
            mappings=mappings,
            model_key=version["model_key"],
            prompt_version=version["prompt_version"],
            grounding_evidence_ids=version["grounding_evidence_ids"] or (),
            validator_version=version["validator_version"],
            validation_score=version["validation_score"],
            generation_trace_ref=version["generation_trace_ref"],
        )


def utc_now() -> datetime:
    return datetime.now(UTC)
