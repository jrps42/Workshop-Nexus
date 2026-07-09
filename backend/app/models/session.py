from datetime import datetime, timezone
from enum import Enum
from uuid import UUID, uuid4

from sqlmodel import Field, SQLModel


class SessionStatus(str, Enum):
    ACTIVE = "active"
    COMPLETED = "completed"


class SessionBase(SQLModel):
    title: str
    summary: str | None = None
    location: str | None = None


class SessionCreate(SessionBase):
    """
    Data required to create a new session.
    """

    pass


class Session(SessionBase, table=True):
    """
    Represents a continuous period of work or activity.
    """

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    started_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    ended_at: datetime | None = None
    status: SessionStatus = SessionStatus.ACTIVE