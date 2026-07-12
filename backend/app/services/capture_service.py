from uuid import UUID

from backend.app.models.capture import Capture, CaptureCreate
from backend.app.repositories.capture_repository import CaptureRepository


class CaptureService:
    """
    Business logic for captures.
    """

    def __init__(self, repository: CaptureRepository):
        self.repository = repository

    def create_capture(self, data: CaptureCreate) -> Capture:
        capture = Capture(
            title=data.title,
            content=data.content,
            capture_type=data.capture_type,
            workspace_id=data.workspace_id,
            session_id=data.session_id,
        )

        return self.repository.create(capture)

    def list_captures(self) -> list[Capture]:
        return self.repository.list_all()

    def get_capture(self, capture_id: UUID) -> Capture | None:
        return self.repository.get_by_id(capture_id)

    def delete_capture(self, capture_id: UUID) -> bool:
        return self.repository.delete(capture_id)

    def assign_workspace(
        self,
        capture_id: UUID,
        workspace_id: UUID | None,
    ) -> Capture | None:
        return self.repository.assign_workspace(
            capture_id=capture_id,
            workspace_id=workspace_id,
        )