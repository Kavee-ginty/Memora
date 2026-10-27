from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, Header, Query, status

from memora.api.openapi import COMMON_ERROR_RESPONSES
from memora.api.operation_ids import OperationId
from memora.api.security import AuthenticatedRequest, get_authenticated_request
from memora.api.v1.schemas.common import Page
from memora.api.v1.schemas.headers import IdempotencyHeaders, RequestHeaders
from memora.api.v1.schemas.question_reports import (
    QuestionReportCreateRequest,
    QuestionReportResponse,
    QuestionReportSummary,
)
from memora.modules.questions.service import QuestionService, get_question_service

router = APIRouter()


@router.post(
    "/questions/{question_version_id}/reports",
    response_model=QuestionReportResponse,
    status_code=status.HTTP_201_CREATED,
    operation_id=OperationId.CREATE_QUESTION_REPORT,
    tags=["reports"],
    summary="Report a question, answer, explanation or grading issue",
    description=(
        "Idempotently records a bounded report without changing historical content "
        "or grading, and states whether disputed evidence is limited pending review."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def create_question_report(
    question_version_id: UUID,
    body: QuestionReportCreateRequest,
    _: Annotated[RequestHeaders, Header()],
    idempotency: Annotated[IdempotencyHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[QuestionService, Depends(get_question_service)],
) -> QuestionReportResponse:
    result, _created = service.create_report(
        auth,
        question_version_id,
        body,
        idempotency_key=idempotency.idempotency_key,
    )
    return result


@router.get(
    "/question-reports",
    response_model=Page[QuestionReportSummary],
    operation_id=OperationId.LIST_QUESTION_REPORTS,
    tags=["reports"],
    summary="List the authenticated student's question reports",
    description="Returns owner-scoped reports in stable reverse submission order.",
    responses=COMMON_ERROR_RESPONSES,
)
def list_question_reports(
    _: Annotated[RequestHeaders, Header()],
    authenticated: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[QuestionService, Depends(get_question_service)],
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
    cursor: Annotated[str | None, Query(min_length=1, max_length=512)] = None,
) -> Page[QuestionReportSummary]:
    return service.list_reports(authenticated, cursor=cursor, limit=limit)


@router.get(
    "/question-reports/{report_id}",
    response_model=QuestionReportResponse,
    operation_id=OperationId.GET_QUESTION_REPORT,
    tags=["reports"],
    summary="Read a question report and its safe resolution state",
    description=(
        "Returns only the authenticated owner's report, status and safe resolution code. "
        "Reviewer identity, internal notes and report text are never returned."
    ),
    responses=COMMON_ERROR_RESPONSES,
)
def get_question_report(
    report_id: UUID,
    _: Annotated[RequestHeaders, Header()],
    auth: Annotated[AuthenticatedRequest, Depends(get_authenticated_request)],
    service: Annotated[QuestionService, Depends(get_question_service)],
) -> QuestionReportResponse:
    return service.get_report(auth, report_id)
