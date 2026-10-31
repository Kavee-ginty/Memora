from datetime import UTC, datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from memora.api.v1.schemas.ingestion import (
    CreateLearningUpdateRequest,
    DeclaredFile,
    FinalizeUploadRequest,
    SubmitVerificationDecisionsRequest,
    UpdateLearningUpdateRequest,
    UploadGrantResponse,
    VerificationDecision,
)
from memora.modules.ingestion.constants import InputType, VerificationDecisionValue


def test_create_learning_update_redacts_manual_text_in_repr() -> None:
    secret = "SUPER_SECRET_STUDENT_PHYSICS_NOTE"
    request = CreateLearningUpdateRequest(
        subject_id=uuid4(),
        input_type=InputType.MANUAL_TEXT,
        learned_at=datetime.now(UTC),
        client_operation_id=uuid4(),
        manual_text=secret,
    )
    assert secret not in repr(request)


def test_create_learning_update_validates_input_type_shapes() -> None:
    subject_id = uuid4()
    op_id = uuid4()
    now = datetime.now(UTC)
    file1 = DeclaredFile(
        declared_name="notes.pdf",
        declared_media_type="application/pdf",
        byte_size=1024,
        content_sha256="a" * 64,
    )

    # manual_text with files fails
    with pytest.raises(
        ValidationError, match="manual_text input requires manual_text and no files"
    ):
        CreateLearningUpdateRequest(
            subject_id=subject_id,
            input_type=InputType.MANUAL_TEXT,
            learned_at=now,
            client_operation_id=op_id,
            manual_text="text",
            files=[file1],
        )

    # pdf with manual_text fails
    with pytest.raises(
        ValidationError, match="file input requires declared files and no manual_text"
    ):
        CreateLearningUpdateRequest(
            subject_id=subject_id,
            input_type=InputType.PDF,
            learned_at=now,
            client_operation_id=op_id,
            manual_text="text",
            files=[file1],
        )

    # pdf with no files fails
    with pytest.raises(
        ValidationError, match="file input requires declared files and no manual_text"
    ):
        CreateLearningUpdateRequest(
            subject_id=subject_id,
            input_type=InputType.PDF,
            learned_at=now,
            client_operation_id=op_id,
            files=[],
        )

    # mixed with only files fails
    with pytest.raises(
        ValidationError, match="mixed input requires both manual_text and declared files"
    ):
        CreateLearningUpdateRequest(
            subject_id=subject_id,
            input_type=InputType.MIXED,
            learned_at=now,
            client_operation_id=op_id,
            files=[file1],
        )

    # duplicate filenames fail
    file2 = DeclaredFile(
        declared_name="notes.pdf",
        declared_media_type="application/pdf",
        byte_size=2048,
        content_sha256="b" * 64,
    )
    with pytest.raises(ValidationError, match="declared file names must be unique"):
        CreateLearningUpdateRequest(
            subject_id=subject_id,
            input_type=InputType.PDF,
            learned_at=now,
            client_operation_id=op_id,
            files=[file1, file2],
        )


def test_update_learning_update_redacts_manual_text_in_repr() -> None:
    secret = "EDITED_SECRET_NOTE"
    request = UpdateLearningUpdateRequest(version=1, manual_text=secret)
    assert secret not in repr(request)


def test_upload_grant_response_redacts_presigned_url_in_repr() -> None:
    secret_url = "https://storage.provider.com/upload?sig=supersecrettoken"
    response = UploadGrantResponse(
        upload_id=uuid4(),
        url=secret_url,
        max_bytes=1024,
        expires_at=datetime.now(UTC),
        checksum_rule="sha256",
    )
    assert secret_url not in repr(response)


def test_verification_decision_payload_requirements() -> None:
    cid = uuid4()

    # accept with corrected_payload fails
    with pytest.raises(ValidationError, match="must not include corrected_payload"):
        VerificationDecision(
            candidate_id=cid,
            candidate_version=1,
            decision=VerificationDecisionValue.ACCEPT,
            corrected_payload={"title": "new"},
        )

    # edit without corrected_payload fails
    with pytest.raises(ValidationError, match="require corrected_payload"):
        VerificationDecision(
            candidate_id=cid,
            candidate_version=1,
            decision=VerificationDecisionValue.EDIT,
            corrected_payload={},
        )

    # edit with corrected_payload succeeds
    decision = VerificationDecision(
        candidate_id=cid,
        candidate_version=1,
        decision=VerificationDecisionValue.EDIT,
        corrected_payload={"title": "corrected"},
    )
    assert decision.decision == VerificationDecisionValue.EDIT


def test_submit_verification_decisions_rejects_duplicates() -> None:
    cid = uuid4()
    with pytest.raises(ValidationError, match="a candidate may appear only once"):
        SubmitVerificationDecisionsRequest(
            decisions=[
                VerificationDecision(
                    candidate_id=cid,
                    candidate_version=1,
                    decision=VerificationDecisionValue.ACCEPT,
                ),
                VerificationDecision(
                    candidate_id=cid,
                    candidate_version=1,
                    decision=VerificationDecisionValue.REJECT,
                ),
            ]
        )


def test_finalize_upload_request_validates_checksum_and_size() -> None:
    op_id = uuid4()
    with pytest.raises(ValidationError):
        FinalizeUploadRequest(observed_size=0, content_sha256="a" * 64, client_operation_id=op_id)

    with pytest.raises(ValidationError):
        FinalizeUploadRequest(
            observed_size=100, content_sha256="invalid_hex", client_operation_id=op_id
        )
