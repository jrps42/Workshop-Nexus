from uuid import UUID

from sqlmodel import Session as DatabaseSession, select

from backend.app.intelligence.routing.learner import (
    RoutingLearner,
)
from backend.app.intelligence.routing.rules import (
    RoutingRules,
)
from backend.app.models.routing import (
    RoutingDecision,
    RoutingRequest,
)
from backend.app.models.session import (
    Session,
    SessionStatus,
)
from backend.app.models.workspace import Workspace


class RoutingEngine:
    """
    Coordinates routing rules, active context, and future
    personalized learning.

    The engine makes the final routing decision. Individual
    evidence sources remain isolated in separate classes.
    """

    def __init__(
        self,
        database_session: DatabaseSession,
        rules: RoutingRules | None = None,
        learner: RoutingLearner | None = None,
    ):
        self.database_session = database_session
        self.rules = rules or RoutingRules()
        self.learner = learner or RoutingLearner()

    def suggest(
        self,
        request: RoutingRequest,
    ) -> RoutingDecision:
        content = request.content.strip()

        workspaces = list(
            self.database_session.exec(
                select(Workspace)
            ).all()
        )

        sessions = list(
            self.database_session.exec(
                select(Session)
            ).all()
        )

        workspace_by_id = {
            workspace.id: workspace
            for workspace in workspaces
        }

        session_by_id = {
            session.id: session
            for session in sessions
        }

        active_workspace = self._get_workspace(
            request.active_workspace_id,
            workspace_by_id,
        )

        active_session = self._get_active_session(
            request.active_session_id,
            session_by_id,
        )

        life_score = self.rules.general_life_score(
            content
        )

        active_workspace_score = 0
        active_session_score = 0

        if active_workspace is not None:
            active_workspace_score = (
                self.rules.score_workspace(
                    content,
                    active_workspace,
                )
            )

            adjustment = (
                self.learner.workspace_adjustment(
                    content=content,
                    workspace_id=active_workspace.id,
                )
            )

            active_workspace_score += (
                adjustment.score_adjustment
            )

        if active_session is not None:
            active_session_score = (
                self.rules.score_session(
                    content,
                    active_session,
                )
            )

            session_adjustment = (
                self.learner.session_adjustment(
                    content=content,
                    session_id=active_session.id,
                )
            )

            active_session_score += (
                session_adjustment.score_adjustment
            )

            session_workspace = self._get_workspace(
                active_session.workspace_id,
                workspace_by_id,
            )

            session_workspace_score = 0

            if session_workspace is not None:
                session_workspace_score = (
                    self.rules.score_workspace(
                        content,
                        session_workspace,
                    )
                )

            combined_session_score = (
                active_session_score * 3
                + session_workspace_score * 2
            )

            if (
                combined_session_score >= 4
                and combined_session_score > life_score
            ):
                return RoutingDecision(
                    workspace_id=active_session.workspace_id,
                    session_id=active_session.id,
                    destination="active_session",
                    confidence=self.rules.confidence(
                        combined_session_score
                    ),
                    reason=(
                        "The capture strongly matches the active "
                        "session or its workspace."
                    ),
                )

        strongest_active_score = max(
            active_workspace_score,
            active_session_score,
        )

        if (
            life_score >= 3
            and life_score > strongest_active_score
        ):
            return RoutingDecision(
                workspace_id=None,
                session_id=None,
                destination="inbox",
                confidence=self.rules.confidence(
                    life_score
                ),
                reason=(
                    "The capture appears to be a general reminder, "
                    "errand, or personal thought unrelated to the "
                    "active project context."
                ),
            )

        if (
            active_workspace is not None
            and active_workspace_score >= 2
        ):
            return RoutingDecision(
                workspace_id=active_workspace.id,
                session_id=None,
                destination="active_workspace",
                confidence=self.rules.confidence(
                    active_workspace_score
                ),
                reason=(
                    "The capture matches the active workspace, "
                    "but not the active session strongly enough."
                ),
            )

        best_workspace: Workspace | None = None
        best_workspace_score = 0

        for workspace in workspaces:
            workspace_score = self.rules.score_workspace(
                content,
                workspace,
            )

            adjustment = (
                self.learner.workspace_adjustment(
                    content=content,
                    workspace_id=workspace.id,
                )
            )

            workspace_score += adjustment.score_adjustment

            if workspace_score > best_workspace_score:
                best_workspace = workspace
                best_workspace_score = workspace_score

        if (
            best_workspace is not None
            and best_workspace_score >= 2
            and best_workspace_score > life_score
        ):
            return RoutingDecision(
                workspace_id=best_workspace.id,
                session_id=None,
                destination="workspace",
                confidence=self.rules.confidence(
                    best_workspace_score
                ),
                reason=(
                    f'The capture matches the workspace '
                    f'"{best_workspace.name}".'
                ),
            )

        return RoutingDecision(
            workspace_id=None,
            session_id=None,
            destination="inbox",
            confidence=0.65,
            reason=(
                "No workspace or session matched strongly enough, "
                "so the capture remains in the Inbox."
            ),
        )

    def _get_workspace(
        self,
        workspace_id: UUID | None,
        workspace_by_id: dict[UUID, Workspace],
    ) -> Workspace | None:
        if workspace_id is None:
            return None

        return workspace_by_id.get(workspace_id)

    def _get_active_session(
        self,
        session_id: UUID | None,
        session_by_id: dict[UUID, Session],
    ) -> Session | None:
        if session_id is None:
            return None

        session = session_by_id.get(session_id)

        if session is None:
            return None

        if session.status != SessionStatus.ACTIVE:
            return None

        return session