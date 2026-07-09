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


class CaptureCreate(CaptureBase):
    """
    Data required to create a new capture.
    """

    pass


class Capture(CaptureBase, table=True):
    """
    Represents a quick captured thought, note, link, or future artifact.
    """

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))