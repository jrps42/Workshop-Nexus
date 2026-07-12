from uuid import UUID

from backend.app.models.workspace import Workspace, WorkspaceCreate
from backend.app.repositories.workspace_repository import WorkspaceRepository


class WorkspaceService:
    """Business logic for workspaces."""

    def __init__(self, repository: WorkspaceRepository):
        self.repository = repository

    def create_workspace(self, data: WorkspaceCreate) -> Workspace:
        workspace = Workspace(
            name=data.name,
            description=data.description,
        )
        return self.repository.create(workspace)

    def list_workspaces(self) -> list[Workspace]:
        return self.repository.list_all()

    def get_workspace(self, workspace_id: UUID) -> Workspace | None:
        return self.repository.get_by_id(workspace_id)

    def delete_workspace(self, workspace_id: UUID) -> bool:
        return self.repository.delete(workspace_id)