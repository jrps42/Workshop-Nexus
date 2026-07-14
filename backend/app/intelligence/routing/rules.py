import re

from backend.app.models.session import Session
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


_GENERAL_LIFE_PHRASES = {
    "add to grocery list",
    "buy ground beef",
    "call the dentist",
    "grocery list",
    "pick up groceries",
    "remember to buy",
}


class RoutingRules:
    """
    Explainable text-scoring rules used by the routing engine.

    This class contains no database access and does not make the
    final routing decision. It only calculates evidence scores.
    """

    def tokenize(self, text: str) -> set[str]:
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

    def normalize_text(self, text: str) -> str:
        words = re.findall(
            r"[a-z0-9]+",
            text.lower(),
        )

        return " ".join(words)

    def workspace_text(
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

    def session_text(
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

    def score_workspace(
        self,
        content: str,
        workspace: Workspace,
    ) -> int:
        return self.score_entity(
            content=content,
            entity_name=workspace.name,
            comparison_text=self.workspace_text(workspace),
        )

    def score_session(
        self,
        content: str,
        session: Session,
    ) -> int:
        return self.score_entity(
            content=content,
            entity_name=session.title,
            comparison_text=self.session_text(session),
        )

    def score_entity(
        self,
        content: str,
        entity_name: str,
        comparison_text: str,
    ) -> int:
        capture_tokens = self.tokenize(content)

        score = self.token_overlap_score(
            capture_tokens=capture_tokens,
            comparison_text=comparison_text,
        )

        normalized_content = self.normalize_text(content)
        normalized_name = self.normalize_text(entity_name)

        # A direct mention of a workspace or session name is
        # particularly strong evidence.
        if (
            normalized_name
            and normalized_name in normalized_content
        ):
            score += 3

        # Words contained in the entity name are weighted slightly
        # more heavily than words found only in its description.
        name_tokens = self.tokenize(entity_name)

        score += len(
            capture_tokens.intersection(name_tokens)
        )

        return score

    def token_overlap_score(
        self,
        capture_tokens: set[str],
        comparison_text: str,
    ) -> int:
        comparison_tokens = self.tokenize(
            comparison_text
        )

        return len(
            capture_tokens.intersection(
                comparison_tokens
            )
        )

    def general_life_score(
        self,
        content: str,
    ) -> int:
        capture_tokens = self.tokenize(content)
        normalized_content = self.normalize_text(content)

        score = len(
            capture_tokens.intersection(
                _GENERAL_LIFE_TERMS
            )
        ) * 2

        for phrase in _GENERAL_LIFE_PHRASES:
            if phrase in normalized_content:
                score += 4

        return score

    def confidence(self, score: int) -> float:
        return min(
            0.97,
            0.55 + score * 0.07,
        )