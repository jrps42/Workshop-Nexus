from datetime import datetime, timezone
from enum import Enum
from uuid import UUID, uuid4

from sqlmodel import Field, SQLModel


class CaptureType(str, Enum):
    TEXT = "text"
    LINK = "link"
    FILE = "file"
    PHOTO = "photo"
    VOICE = "voice"


class CaptureBase(SQLModel):
    title: str
    content: str
    capture_type: CaptureType = CaptureType.TEXT

    workspace_id: UUID | None = Field(
        default=None,
        foreign_key="workspace.id",
    )

    session_id: UUID | None = Field(
        default=None,
        foreign_key="session.id",
    )


class CaptureCreate(CaptureBase):
    """
    Data accepted when creating a capture.

    Both workspace and session context are optional.
    """

    pass


class Capture(CaptureBase, table=True):
    """
    Represents a quick thought, note, link, or future artifact.
    """

    id: UUID = Field(default_factory=uuid4, primary_key=True)

    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )