from uuid import UUID

from fastapi import APIRouter, HTTPException

from backend.app.models.session import Session, SessionCreate
from backend.app.repositories.session_repository import SessionRepository
from backend.app.services.session_service import SessionService

router = APIRouter(prefix="/sessions", tags=["sessions"])

_repository = SessionRepository()
_service = SessionService(_repository)


@router.post("", response_model=Session)
def create_session(data: SessionCreate):
    return _service.create_session(data)


@router.get("", response_model=list[Session])
def list_sessions():
    return _service.list_sessions()


@router.get("/{session_id}", response_model=Session)
def get_session(session_id: UUID):
    session = _service.get_session(session_id)

    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")

    return session


@router.post("/{session_id}/complete", response_model=Session)
def complete_session(session_id: UUID):
    session = _service.complete_session(session_id)

    if session is None:
        raise HTTPException(status_code=404, detail="Session not found")

    return session