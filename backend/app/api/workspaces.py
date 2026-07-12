from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session as DatabaseSession

from backend.app.database import get_database_session
from backend.app.models.workspace import Workspace, WorkspaceCreate
from backend.app.repositories.workspace_repository import WorkspaceRepository
from backend.app.services.workspace_service import (WorkspaceAlreadyExistsError, WorkspaceService,)

router = APIRouter(
    prefix="/workspaces",
    tags=["workspaces"],
)


def get_workspace_service(
    database_session: DatabaseSession = Depends(get_database_session),
) -> WorkspaceService:
    repository = WorkspaceRepository(database_session)
    return WorkspaceService(repository)


@router.post("", response_model=Workspace)
def create_workspace(
    data: WorkspaceCreate,
    service: WorkspaceService = Depends(get_workspace_service),
):
    try:
        return service.create_workspace(data)
    except WorkspaceAlreadyExistsError as error:
        raise HTTPException(
            status_code=409,
            detail=str(error),
        ) from error


@router.get("", response_model=list[Workspace])
def list_workspaces(
    service: WorkspaceService = Depends(get_workspace_service),
):
    return service.list_workspaces()


@router.get("/{workspace_id}", response_model=Workspace)
def get_workspace(
    workspace_id: UUID,
    service: WorkspaceService = Depends(get_workspace_service),
):
    workspace = service.get_workspace(workspace_id)

    if workspace is None:
        raise HTTPException(
            status_code=404,
            detail="Workspace not found",
        )

    return workspace


@router.delete("/{workspace_id}")
def delete_workspace(
    workspace_id: UUID,
    service: WorkspaceService = Depends(get_workspace_service),
):
    deleted = service.delete_workspace(workspace_id)

    if not deleted:
        raise HTTPException(
            status_code=404,
            detail="Workspace not found",
        )

    return {"deleted": True}