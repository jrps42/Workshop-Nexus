from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import Session as DatabaseSession

from backend.app.database import get_database_session
from backend.app.models.capture import Capture, CaptureCreate
from backend.app.repositories.capture_repository import CaptureRepository
from backend.app.services.capture_service import CaptureService

from pydantic import BaseModel

router = APIRouter(prefix="/captures", tags=["captures"])

class CaptureWorkspaceAssignment(BaseModel):
    workspace_id: UUID | None

def get_capture_service(
    database_session: DatabaseSession = Depends(get_database_session),
) -> CaptureService:
    repository = CaptureRepository(database_session)
    return CaptureService(repository)


@router.post("", response_model=Capture)
def create_capture(
    data: CaptureCreate,
    service: CaptureService = Depends(get_capture_service),
):
    return service.create_capture(data)


@router.get("", response_model=list[Capture])
def list_captures(
    service: CaptureService = Depends(get_capture_service),
):
    return service.list_captures()


@router.get("/{capture_id}", response_model=Capture)
def get_capture(
    capture_id: UUID,
    service: CaptureService = Depends(get_capture_service),
):
    capture = service.get_capture(capture_id)

    if capture is None:
        raise HTTPException(status_code=404, detail="Capture not found")

    return capture


@router.delete("/{capture_id}")
def delete_capture(
    capture_id: UUID,
    service: CaptureService = Depends(get_capture_service),
):
    deleted = service.delete_capture(capture_id)

    if not deleted:
        raise HTTPException(status_code=404, detail="Capture not found")

    return {"deleted": True}


@router.patch("/{capture_id}/workspace", response_model=Capture)
def assign_capture_workspace(
    capture_id: UUID,
    assignment: CaptureWorkspaceAssignment,
    service: CaptureService = Depends(get_capture_service),
):
    capture = service.assign_workspace(
        capture_id=capture_id,
        workspace_id=assignment.workspace_id,
    )

    if capture is None:
        raise HTTPException(
            status_code=404,
            detail="Capture not found",
        )

    return capture