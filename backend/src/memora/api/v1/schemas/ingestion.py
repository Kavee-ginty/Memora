from __future__ import annotations

from typing import Annotated, Any, Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field, model_validator

from memora.api.v1.schemas.common import Page, UtcDatetime, Version
from memora.modules.ingestion.constants import (
    MAX_CANDIDATE_TITLE_CHARS,
    MAX_FILENAME_CHARS,
    MAX_MANUAL_TEXT_CHARS,
    CandidateStatus,
    DeletionStatus,
    InputType,
    LearningUpdateStatus,
    UploadStatus,
    VerificationDecisionValue,
)


def _require_files(schema: dict[str, Any]) -> None:
    req = schema.setdefault("required", [])
    if "files" not in req:
        req.append("files")


def _require_upload_grant_fields(schema: dict[str, Any]) -> None:
    req = schema.setdefault("required", [])
    for field in ("required_headers", "method"):
        if field not in req:
            req.append(field)


def _require_corrected_payload(schema: dict[str, Any]) -> None:
    req = schema.setdefault("required", [])
    if "corrected_payload" not in req:
        req.append("corrected_payload")


class DeclaredFile(BaseModel):
    model_config = ConfigDict(extra="forbid")
    declared_name: Annotated[str, Field(min_length=1, max_length=MAX_FILENAME_CHARS)]
    declared_media_type: Annotated[str, Field(min_length=1, max_length=120)]
    byte_size: Annotated[int, Field(gt=0)]
    content_sha256: Annotated[str, Field(pattern="^[0-9a-f]{64}$")]


class CreateLearningUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid", json_schema_extra=_require_files)
    subject_id: UUID
    input_type: InputType
    learned_at: UtcDatetime
    client_operation_id: UUID
    manual_text: Annotated[
        str | None, Field(min_length=1, max_length=MAX_MANUAL_TEXT_CHARS, repr=False)
    ] = None
    files: Annotated[list[DeclaredFile], Field(max_length=10)] = []

    @model_validator(mode="after")
    def _validate_source_shape(self) -> CreateLearningUpdateRequest:
        has_text = self.manual_text is not None and bool(self.manual_text.strip())
        has_files = bool(self.files)
        if self.input_type == InputType.MANUAL_TEXT and (not has_text or has_files):
            raise ValueError("manual_text input requires manual_text and no files")
        if self.input_type in {InputType.PDF, InputType.IMAGE} and (has_text or not has_files):
            raise ValueError("file input requires declared files and no manual_text")
        if self.input_type == InputType.MIXED and (not has_text or not has_files):
            raise ValueError("mixed input requires both manual_text and declared files")
        if len({file.declared_name for file in self.files}) != len(self.files):
            raise ValueError("declared file names must be unique within an update")
        return self


class UpdateLearningUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    version: Version
    learned_at: UtcDatetime | None = None
    manual_text: Annotated[
        str | None, Field(min_length=1, max_length=MAX_MANUAL_TEXT_CHARS, repr=False)
    ] = None


class RetryLearningUpdateRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    stage: Literal["extraction", "deletion"]


class SourceUploadSummary(BaseModel):
    id: UUID
    declared_name: str
    declared_media_type: str
    detected_media_type: str | None
    byte_size: int
    status: UploadStatus
    expires_at: UtcDatetime
    deleted_at: UtcDatetime | None
    deletion_status: DeletionStatus


class LearningUpdateResponse(BaseModel):
    id: UUID
    subject_id: UUID
    curriculum_version_id: UUID
    input_type: InputType
    status: LearningUpdateStatus
    learned_at: UtcDatetime
    failure_code: str | None
    expires_at: UtcDatetime | None
    has_manual_text: bool
    created_at: UtcDatetime
    updated_at: UtcDatetime
    row_version: int
    source_deletion_status: DeletionStatus
    uploads: list[SourceUploadSummary]


class LearningUpdateListResponse(Page[LearningUpdateResponse]):
    pass


class UploadGrantRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    declared_name: Annotated[str, Field(min_length=1, max_length=MAX_FILENAME_CHARS)]
    declared_media_type: Annotated[str, Field(min_length=1, max_length=120)]
    byte_size: Annotated[int, Field(gt=0)]
    content_sha256: Annotated[str, Field(pattern="^[0-9a-f]{64}$")]


class UploadGrantResponse(BaseModel):
    model_config = ConfigDict(json_schema_extra=_require_upload_grant_fields)
    upload_id: UUID
    url: Annotated[str, Field(repr=False)]
    method: Literal["PUT"] = "PUT"
    required_headers: dict[str, str] = Field(default_factory=dict)
    max_bytes: int
    expires_at: UtcDatetime
    checksum_rule: Annotated[str, Field(min_length=1)]


class FinalizeUploadRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    observed_size: Annotated[int, Field(gt=0)]
    content_sha256: Annotated[str, Field(pattern="^[0-9a-f]{64}$")]
    client_operation_id: UUID


class CandidateResponse(BaseModel):
    id: UUID
    candidate_type: str
    display_title: Annotated[str, Field(max_length=MAX_CANDIDATE_TITLE_CHARS)]
    display_summary: str
    confidence: Annotated[float, Field(ge=0, le=1)]
    confidence_band: Literal["high", "medium", "low"]
    requires_verification: bool
    status: CandidateStatus
    source_locator: dict[str, Any]
    candidate_version: int


class CandidateListResponse(Page[CandidateResponse]):
    pass


class VerificationDecision(BaseModel):
    model_config = ConfigDict(extra="forbid", json_schema_extra=_require_corrected_payload)
    candidate_id: UUID
    candidate_version: Version
    decision: VerificationDecisionValue
    corrected_payload: dict[str, Any] = Field(default_factory=dict)

    @model_validator(mode="after")
    def _validate_payload(self) -> VerificationDecision:
        if self.decision in {VerificationDecisionValue.EDIT, VerificationDecisionValue.MERGE}:
            if not self.corrected_payload:
                raise ValueError("edit and merge decisions require corrected_payload")
            return self
        if self.corrected_payload:
            raise ValueError("accept and reject decisions must not include corrected_payload")
        return self


class SubmitVerificationDecisionsRequest(BaseModel):
    model_config = ConfigDict(extra="forbid")
    decisions: Annotated[list[VerificationDecision], Field(min_length=1, max_length=100)]

    @model_validator(mode="after")
    def _unique_candidates(self) -> SubmitVerificationDecisionsRequest:
        ids = [decision.candidate_id for decision in self.decisions]
        if len(set(ids)) != len(ids):
            raise ValueError("a candidate may appear only once per request")
        return self


class VerificationDecisionResult(BaseModel):
    candidate_id: UUID
    candidate_status: CandidateStatus
    requires_verification: bool


class SubmitVerificationDecisionsResponse(BaseModel):
    learning_update: LearningUpdateResponse
    results: list[VerificationDecisionResult]


class LearningPathPreviewConcept(BaseModel):
    candidate_id: UUID
    title: str
    candidate_type: str
    concept_id: UUID | None
    concept_version_id: UUID | None


class LearningPathPreviewResponse(BaseModel):
    update_id: UUID
    status: LearningUpdateStatus
    concept_count: int
    first_concepts: list[LearningPathPreviewConcept]
    estimated_first_mission_minutes: int | None
    can_commit: bool
    blocked_reason: str | None


class FirstMissionSummary(BaseModel):
    mission_id: UUID
    status: str


class KnowledgeCommitResponse(BaseModel):
    learning_update: LearningUpdateResponse
    knowledge_commit_id: UUID
    commit_version: int
    committed_counts: dict[str, int]
    concept_mappings: list[LearningPathPreviewConcept]
    private_knowledge_count: int
    first_mission: FirstMissionSummary | None = None
    source_deletion_status: DeletionStatus


class IngestionErrorExample(BaseModel):
    """Documentation-only marker; errors use the shared envelope."""

    code: Literal["validation_failed"] = "validation_failed"
