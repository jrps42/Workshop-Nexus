from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session as DatabaseSession

from backend.app.database import get_database_session
from backend.app.models.session_summary import SessionSummary
from backend.app.services.session_summary_service import (
    SessionSummaryService,
)

router = APIRouter(
    prefix="/sessions",
    tags=["session intelligence"],
)


def get_session_summary_service(
    database_session: DatabaseSession = Depends(
        get_database_session
    ),
) -> SessionSummaryService:
    return SessionSummaryService(database_session)


@router.get(
    "/{session_id}/summary",
    response_model=SessionSummary,
)
def generate_session_summary(
    session_id: UUID,
    service: SessionSummaryService = Depends(
        get_session_summary_service
    ),
):
    summary = service.generate_summary(session_id)

    if summary is None:
        raise HTTPException(
            status_code=404,
            detail="Session not found",
        )

    return summary