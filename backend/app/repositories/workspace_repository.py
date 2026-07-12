from uuid import UUID

from sqlmodel import Session as DatabaseSession, select

from backend.app.models.workspace import Workspace


class WorkspaceRepository:
    """SQLite-backed storage for workspaces."""

    def __init__(self, database_session: DatabaseSession):
        self.database_session = database_session

    def create(self, workspace: Workspace) -> Workspace:
        self.database_session.add(workspace)
        self.database_session.commit()
        self.database_session.refresh(workspace)
        return workspace

    def get_by_id(self, workspace_id: UUID) -> Workspace | None:
        return self.database_session.get(Workspace, workspace_id)

    def list_all(self) -> list[Workspace]:
        statement = select(Workspace).order_by(Workspace.name)
        return list(self.database_session.exec(statement).all())

    def delete(self, workspace_id: UUID) -> bool:
        workspace = self.get_by_id(workspace_id)

        if workspace is None:
            return False

        self.database_session.delete(workspace)
        self.database_session.commit()
        return True