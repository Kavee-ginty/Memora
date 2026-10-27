from __future__ import annotations

from typing import Annotated, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from memora.api.v1.schemas.common import UtcDatetime
from memora.modules.questions.constants import MAX_REPORT_DESCRIPTION_LENGTH

ReportType = Literal[
    "question_error",
    "answer_error",
    "explanation_error",
    "grading_dispute",
    "accessibility",
]
ReportStatus = Literal["submitted", "triaged", "under_review", "resolved", "dismissed"]
EvidenceState = Literal["recorded", "limited_pending_review"]


class QuestionReportCreateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)

    report_type: ReportType
    description: (
        Annotated[
            str,
            Field(min_length=1, max_length=MAX_REPORT_DESCRIPTION_LENGTH),
        ]
        | None
    ) = None
    attempt_id: UUID | None = None

    @model_validator(mode="after")
    def _grading_dispute_needs_attempt(self) -> QuestionReportCreateRequest:
        if self.report_type == "grading_dispute" and self.attempt_id is None:
            raise ValueError("a grading dispute needs the related attempt")
        return self


class QuestionReportSummary(BaseModel):
    id: UUID
    question_version_id: UUID
    attempt_id: UUID | None
    report_type: ReportType
    status: ReportStatus
    submitted_at: UtcDatetime
    resolved_at: UtcDatetime | None
    description_present: bool
    evidence_state: EvidenceState


class QuestionReportResponse(QuestionReportSummary):
    resolution_code: str | None
    review_required: bool
