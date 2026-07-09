from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session as DatabaseSession

from backend.app.database import get_database_session
from backend.app.models.session import Session, SessionCreate
from backend.app.repositories.session_repository import SessionRepository
from backend.app.services.session_service import SessionService

router = APIRouter(prefix="/sessions", tags=["sessions"])


def get_session_service(
    database_session: DatabaseSession = Depends(get_database_session),
) -> SessionService:
    repository = SessionRepository(database_session)
    return SessionService(repository)


@router.post("", response_model=Session)
def create_session(
    data: SessionCreate,
    service: SessionService = Depends(get_session_service),
):
    return service.create_session(data)


@router.get("", response_model=list[Session])
def list_sessions(
    service: SessionService = Depends(get_session_service),
):
    return service.list_sessions()


@router.get("/{session_id}", response_model=Session)
def get_session(
    session_id: UUID,
    service: SessionService = Depends(get_session_service),
):
    session = service.get_session(session_id)

    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")

    return session


@router.post("/{session_id}/complete", response_model=Session)
def complete_session(
    session_id: UUID,
    service: SessionService = Depends(get_session_service),
):
    session = service.complete_session(session_id)

    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")

    return session