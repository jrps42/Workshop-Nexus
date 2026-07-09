from uuid import UUID

from backend.app.models.session import Session


class SessionRepository:
    """
    In-memory storage for Sessions.

    This will later be replaced with SQLite without changing the API/service layer.
    """

    def __init__(self):
        self._sessions: dict[UUID, Session] = {}

    def create(self, session: Session) -> Session:
        self._sessions[session.id] = session
        return session

    def get_by_id(self, session_id: UUID) -> Session | None:
        return self._sessions.get(session_id)

    def list_all(self) -> list[Session]:
        return list(self._sessions.values())

    def update(self, session: Session) -> Session:
        self._sessions[session.id] = session
        return session

    def delete(self, session_id: UUID) -> bool:
        if session_id not in self._sessions:
            return False

        del self._sessions[session_id]
        return True