from uuid import UUID

from pydantic import BaseModel


class SessionSummary(BaseModel):
    session_id: UUID
    session_title: str
    capture_count: int

    summary: str
    action_items: list[str]
    questions: list[str]
    referenced_items: list[str]