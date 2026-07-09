from uuid import UUID

from sqlmodel import Session as DatabaseSession, select

from backend.app.models.session import Session


class SessionRepository:
    """
    SQLite-backed storage for Sessions.
    """

    def __init__(self, database_session: DatabaseSession):
        self.database_session = database_session

    def create(self, session: Session) -> Session:
        self.database_session.add(session)
        self.database_session.commit()
        self.database_session.refresh(session)
        return session

    def get_by_id(self, session_id: UUID) -> Session | None:
        return self.database_session.get(Session, session_id)

    def list_all(self) -> list[Session]:
        statement = select(Session)
        return list(self.database_session.exec(statement).all())

    def update(self, session: Session) -> Session:
        self.database_session.add(session)
        self.database_session.commit()
        self.database_session.refresh(session)
        return session

    def delete(self, session_id: UUID) -> bool:
        session = self.get_by_id(session_id)

        if session is None:
            return False

        self.database_session.delete(session)
        self.database_session.commit()
        return True