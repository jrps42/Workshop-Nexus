from dataclasses import dataclass
from uuid import UUID


@dataclass(frozen=True)
class LearningAdjustment:
    """
    A future score adjustment produced from routing feedback.

    Positive values strengthen a destination.
    Negative values weaken it.
    """

    workspace_id: UUID | None = None
    session_id: UUID | None = None
    score_adjustment: int = 0
    reason: str = "No routing feedback has been applied."


class RoutingLearner:
    """
    Placeholder for personalized routing feedback.

    This initial implementation deliberately makes no changes to
    routing scores, preserving the router's current behavior.
    """

    def workspace_adjustment(
        self,
        content: str,
        workspace_id: UUID,
    ) -> LearningAdjustment:
        return LearningAdjustment(
            workspace_id=workspace_id,
        )

    def session_adjustment(
        self,
        content: str,
        session_id: UUID,
    ) -> LearningAdjustment:
        return LearningAdjustment(
            session_id=session_id,
        )