import re
from uuid import UUID

from sqlmodel import Session as DatabaseSession, select

from backend.app.models.routing import RoutingDecision, RoutingRequest
from backend.app.models.session import Session, SessionStatus
from backend.app.models.workspace import Workspace


_STOP_WORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "has",
    "have",
    "i",
    "in",
    "is",
    "it",
    "my",
    "of",
    "on",
    "or",
    "that",
    "the",
    "this",
    "to",
    "was",
    "with",
}


class RoutingService:
    """
    Provides explainable capture-routing recommendations.

    This first implementation uses token matching rather than an LLM.
    """

    def __init__(self, database_session: DatabaseSession):
        self.database_session = database_session

    def suggest_route(
        self,
        request: RoutingRequest,
    ) -> RoutingDecision:
        capture_tokens = self._tokenize(request.content)

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

        if active_session is not None:
            session_score = self._score_text(
                capture_tokens,
                self._session_text(active_session),
            )

            related_workspace = self._get_workspace(
                active_session.workspace_id,
                workspace_by_id,
            )

            workspace_score = 0

            if related_workspace is not None:
                workspace_score = self._score_text(
                    capture_tokens,
                    self._workspace_text(related_workspace),
                )

            combined_score = (
                session_score * 3
                + workspace_score * 2
            )

            if combined_score >= 3:
                return RoutingDecision(
                    workspace_id=active_session.workspace_id,
                    session_id=active_session.id,
                    destination="active_session",
                    confidence=self._confidence(
                        combined_score,
                    ),
                    reason=(
                        "The capture overlaps with the active "
                        "session or its workspace."
                    ),
                )

        if active_workspace is not None:
            active_workspace_score = self._score_text(
                capture_tokens,
                self._workspace_text(active_workspace),
            )

            if active_workspace_score >= 1:
                return RoutingDecision(
                    workspace_id=active_workspace.id,
                    session_id=None,
                    destination="active_workspace",
                    confidence=self._confidence(
                        active_workspace_score * 2,
                    ),
                    reason=(
                        "The capture matches the active "
                        "workspace, but not strongly enough "
                        "to attach to the active session."
                    ),
                )

        best_workspace: Workspace | None = None
        best_workspace_score = 0

        for workspace in workspaces:
            score = self._score_text(
                capture_tokens,
                self._workspace_text(workspace),
            )

            if score > best_workspace_score:
                best_workspace = workspace
                best_workspace_score = score

        if (
            best_workspace is not None
            and best_workspace_score >= 1
        ):
            return RoutingDecision(
                workspace_id=best_workspace.id,
                session_id=None,
                destination="workspace",
                confidence=self._confidence(
                    best_workspace_score * 2,
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
            confidence=0.5,
            reason=(
                "No workspace or session matched with enough "
                "confidence, so the capture should remain in "
                "the Inbox."
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

    def _workspace_text(
        self,
        workspace: Workspace,
    ) -> str:
        return " ".join(
            part
            for part in [
                workspace.name,
                workspace.description,
            ]
            if part
        )

    def _session_text(
        self,
        session: Session,
    ) -> str:
        return " ".join(
            part
            for part in [
                session.title,
                session.summary,
                session.location,
            ]
            if part
        )

    def _score_text(
        self,
        capture_tokens: set[str],
        comparison_text: str,
    ) -> int:
        comparison_tokens = self._tokenize(
            comparison_text
        )

        return len(
            capture_tokens.intersection(
                comparison_tokens
            )
        )

    def _tokenize(self, text: str) -> set[str]:
        words = re.findall(
            r"[a-z0-9]+",
            text.lower(),
        )

        return {
            word
            for word in words
            if len(word) >= 3
            and word not in _STOP_WORDS
        }

    def _confidence(self, score: int) -> float:
        return min(0.95, 0.5 + score * 0.1)