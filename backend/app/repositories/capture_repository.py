from uuid import UUID

from sqlmodel import Session as DatabaseSession, select

from backend.app.models.capture import Capture


class CaptureRepository:
    """
    SQLite-backed storage for Captures.
    """

    def __init__(self, database_session: DatabaseSession):
        self.database_session = database_session

    def create(self, capture: Capture) -> Capture:
        self.database_session.add(capture)
        self.database_session.commit()
        self.database_session.refresh(capture)
        return capture

    def get_by_id(self, capture_id: UUID) -> Capture | None:
        return self.database_session.get(Capture, capture_id)

    def list_all(self) -> list[Capture]:
        statement = select(Capture).order_by(Capture.created_at.desc())
        return list(self.database_session.exec(statement).all())

    def delete(self, capture_id: UUID) -> bool:
        capture = self.get_by_id(capture_id)

        if capture is None:
            return False

        self.database_session.delete(capture)
        self.database_session.commit()
        return True

    def assign_workspace(
        self,
        capture_id: UUID,
        workspace_id: UUID | None,
    ) -> Capture | None:
        capture = self.get_by_id(capture_id)

        if capture is None:
            return None

        capture.workspace_id = workspace_id
        self.database_session.add(capture)
        self.database_session.commit()
        self.database_session.refresh(capture)

        return capture