from datetime import datetime, timezone
from enum import Enum
from uuid import UUID, uuid4

from pydantic import BaseModel, Field


class SessionStatus(str, Enum):
    ACTIVE = "active"
    COMPLETED = "completed"


class SessionCreate(BaseModel):
    """
    Data required to create a new session.

    The system generates identity, timestamps, and status.
    """

    title: str

    summary: str | None = None

    location: str | None = None


class Session(BaseModel):
    """
    Represents a continuous period of work or activity.

    Sessions provide temporal context for artifacts,
    observations, tasks, and conversations.
    """

    id: UUID = Field(default_factory=uuid4)

    title: str

    summary: str | None = None
    location: str | None = None

    started_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    ended_at: datetime | None = None

    status: SessionStatus = SessionStatus.ACTIVE