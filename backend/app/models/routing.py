from uuid import UUID

from pydantic import BaseModel, Field


class RoutingRequest(BaseModel):
    content: str = Field(min_length=1)
    active_workspace_id: UUID | None = None
    active_session_id: UUID | None = None


class RoutingDecision(BaseModel):
    workspace_id: UUID | None = None
    session_id: UUID | None = None

    destination: str
    confidence: float
    reason: str