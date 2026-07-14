import re
from uuid import UUID

from sqlmodel import Session as DatabaseSession, select

from backend.app.models.routing import (
    RoutingDecision,
    RoutingRequest,
)
from backend.app.models.session import (
    Session,
    SessionStatus,
)
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


# These terms indicate that a capture is probably a personal
# reminder or errand rather than project work.
_GENERAL_LIFE_TERMS = {
    "appointment",
    "beef",
    "bread",
    "call",
    "dentist",
    "doctor",
    "eggs",
    "errand",
    "grocery",
    "groceries",
    "laundry",
    "milk",
    "pharmacy",
    "shopping",
    "store",
}


# These phrases are strong indicators that the capture should
# remain in the Inbox unless it also has clear project evidence.
_GENERAL_LIFE_PHRASES = {
    "add to grocery list",
    "buy ground beef",
    "call the dentist",
    "grocery list",
    "pick up groceries",
    "remember to buy",
}


class RoutingService:
    """
    Provides explainable capture-routing recommendations.

    Active context is treated as a useful hint, not a forced
    destination. Uncertain or unrelated captures remain in Inbox.
    """

    def __init__(
        self,
        database_session: DatabaseSession,
    ):
        self.database_session = database_session

    def suggest_route(
        self,
        request: RoutingRequest,
    ) -> RoutingDecision:
        content = request.content.strip()
        capture_tokens = self._tokenize(content)

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

        life_score = self._general_life_score(
            content=content,
            capture_tokens=capture_tokens,
        )

        active_workspace_score = 0
        active_session_score = 0

        if active_workspace is not None:
            active_workspace_score = self._score_entity(
                content=content,
                capture_tokens=capture_tokens,
                entity_name=active_workspace.name,
                comparison_text=self._workspace_text(
                    active_workspace
                ),
            )

        if active_session is not None:
            active_session_score = self._score_entity(
                content=content,
                capture_tokens=capture_tokens,
                entity_name=active_session.title,
                comparison_text=self._session_text(
                    active_session
                ),
            )

            session_workspace = self._get_workspace(
                active_session.workspace_id,
                workspace_by_id,
            )

            session_workspace_score = 0

            if session_workspace is not None:
                session_workspace_score = self._score_entity(
                    content=content,
                    capture_tokens=capture_tokens,
                    entity_name=session_workspace.name,
                    comparison_text=self._workspace_text(
                        session_workspace
                    ),
                )

            combined_session_score = (
                active_session_score * 3
                + session_workspace_score * 2
            )

            # A session needs meaningful evidence. Merely having
            # an active session is not sufficient.
            if (
                combined_session_score >= 4
                and combined_session_score > life_score
            ):
                return RoutingDecision(
                    workspace_id=active_session.workspace_id,
                    session_id=active_session.id,
                    destination="active_session",
                    confidence=self._confidence(
                        combined_session_score
                    ),
                    reason=(
                        "The capture strongly matches the active "
                        "session or its workspace."
                    ),
                )

        # General-life language wins when there is no clear
        # workspace or session evidence.
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
                confidence=self._confidence(life_score),
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
                confidence=self._confidence(
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
            score = self._score_entity(
                content=content,
                capture_tokens=capture_tokens,
                entity_name=workspace.name,
                comparison_text=self._workspace_text(
                    workspace
                ),
            )

            if score > best_workspace_score:
                best_workspace = workspace
                best_workspace_score = score

        if (
            best_workspace is not None
            and best_workspace_score >= 2
            and best_workspace_score > life_score
        ):
            return RoutingDecision(
                workspace_id=best_workspace.id,
                session_id=None,
                destination="workspace",
                confidence=self._confidence(
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

    def _score_entity(
        self,
        content: str,
        capture_tokens: set[str],
        entity_name: str,
        comparison_text: str,
    ) -> int:
        score = self._token_overlap_score(
            capture_tokens,
            comparison_text,
        )

        normalized_content = self._normalize_text(content)
        normalized_name = self._normalize_text(entity_name)

        # Exact workspace/session name mentions are strong evidence.
        if (
            normalized_name
            and normalized_name in normalized_content
        ):
            score += 3

        # Individual name tokens are slightly more important than
        # description tokens.
        name_tokens = self._tokenize(entity_name)

        score += len(
            capture_tokens.intersection(name_tokens)
        )

        return score

    def _token_overlap_score(
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

    def _general_life_score(
        self,
        content: str,
        capture_tokens: set[str],
    ) -> int:
        normalized_content = self._normalize_text(
            content
        )

        score = len(
            capture_tokens.intersection(
                _GENERAL_LIFE_TERMS
            )
        ) * 2

        for phrase in _GENERAL_LIFE_PHRASES:
            if phrase in normalized_content:
                score += 4

        return score

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

    def _normalize_text(self, text: str) -> str:
        words = re.findall(
            r"[a-z0-9]+",
            text.lower(),
        )

        return " ".join(words)

    def _confidence(self, score: int) -> float:
        return min(
            0.97,
            0.55 + score * 0.07,
        )