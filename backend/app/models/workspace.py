from datetime import datetime, timezone
from uuid import UUID, uuid4

from sqlmodel import Field, SQLModel


class WorkspaceBase(SQLModel):
    """Shared fields for workspace models."""

    name: str
    description: str | None = None


class WorkspaceCreate(WorkspaceBase):
    """Data accepted when creating a workspace."""

    pass


class Workspace(WorkspaceBase, table=True):
    """Represents a major area of activity or interest."""

    id: UUID = Field(default_factory=uuid4, primary_key=True)
    created_at: datetime = Field(
        default_factory=lambda: datetime.now(timezone.utc)
    )