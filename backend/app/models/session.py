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
    workspace_id: UUID | None = Field(
        default=None,
        foreign_key="workspace.id",
    )


class SessionCreate(SessionBase):
    """
    Data accepted when creating a session.

    A workspace is optional so sessions can also represent
    general work, research, or brainstorming.
    """

    pass


class Session(SessionBase, table=True):
    """
    Represents an optional period of focused activity.

    Captures do not require a session.
    """

    id: UUID = Field(default_factory=uuid4, primary_key=True)

    started_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )

    ended_at: datetime | None = None

    status: SessionStatus = SessionStatus.ACTIVE