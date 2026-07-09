from uuid import UUID

from backend.app.models.session import Session, SessionCreate, SessionStatus
from backend.app.repositories.session_repository import SessionRepository


class SessionService:
    """
    Business logic for Sessions.
    """

    def __init__(self, repository: SessionRepository):
        self.repository = repository

    def create_session(self, data: SessionCreate) -> Session:
        session = Session(
            title=data.title,
            summary=data.summary,
            location=data.location,
        )
        return self.repository.create(session)

    def list_sessions(self) -> list[Session]:
        return self.repository.list_all()

    def get_session(self, session_id: UUID) -> Session | None:
        return self.repository.get_by_id(session_id)

    def complete_session(self, session_id: UUID) -> Session | None:
        session = self.repository.get_by_id(session_id)

        if session is None:
            return None

        session.status = SessionStatus.COMPLETED
        return self.repository.update(session)