import re
from uuid import UUID

from sqlmodel import Session as DatabaseSession, select

from backend.app.models.capture import Capture
from backend.app.models.session import Session
from backend.app.models.session_summary import SessionSummary


_ACTION_PREFIXES = (
    "need to ",
    "remember to ",
    "todo ",
    "to do ",
    "must ",
    "should ",
    "order ",
    "buy ",
    "replace ",
    "measure ",
    "check ",
    "inspect ",
    "clean ",
    "remove ",
    "install ",
    "research ",
    "look up ",
    "call ",
)

_ITEM_KEYWORDS = {
    "adapter",
    "adhesive",
    "battery",
    "bolt",
    "brush",
    "cable",
    "carpet",
    "cleaner",
    "filter",
    "fuel",
    "gasket",
    "glue",
    "hose",
    "motor",
    "paint",
    "pump",
    "screw",
    "sealant",
    "sender",
    "sensor",
    "tank",
    "tool",
    "wire",
}


class SessionSummaryService:
    """
    Produces an explainable summary from captures attached to a session.

    This version uses deterministic text rules rather than an LLM.
    """

    def __init__(self, database_session: DatabaseSession):
        self.database_session = database_session

    def generate_summary(
        self,
        session_id: UUID,
    ) -> SessionSummary | None:
        session = self.database_session.get(
            Session,
            session_id,
        )

        if session is None:
            return None

        statement = (
            select(Capture)
            .where(Capture.session_id == session_id)
            .order_by(Capture.created_at)
        )

        captures = list(
            self.database_session.exec(statement).all()
        )

        action_items: list[str] = []
        questions: list[str] = []
        referenced_items: set[str] = set()

        for capture in captures:
            sentences = self._sentences(capture.content)

            for sentence in sentences:
                normalized = sentence.strip()

                if not normalized:
                    continue

                if self._is_question(normalized):
                    questions.append(normalized)
                    continue

                if self._is_action_item(normalized):
                    action_items.append(normalized)

                referenced_items.update(
                    self._referenced_items(normalized)
                )

        summary = self._build_summary(
            session=session,
            captures=captures,
        )

        return SessionSummary(
            session_id=session.id,
            session_title=session.title,
            capture_count=len(captures),
            summary=summary,
            action_items=self._deduplicate(action_items),
            questions=self._deduplicate(questions),
            referenced_items=sorted(referenced_items),
        )

    def _build_summary(
        self,
        session: Session,
        captures: list[Capture],
    ) -> str:
        if not captures:
            return (
                f'No captures were recorded during '
                f'"{session.title}".'
            )

        capture_titles = [
            capture.title.strip()
            for capture in captures
            if capture.title.strip()
        ]

        preview_titles = capture_titles[:3]

        if not preview_titles:
            return (
                f'{len(captures)} captures were recorded during '
                f'"{session.title}".'
            )

        preview = "; ".join(preview_titles)

        if len(capture_titles) > 3:
            preview += f"; and {len(capture_titles) - 3} more"

        return (
            f'{len(captures)} captures were recorded during '
            f'"{session.title}". Main topics included: {preview}.'
        )

    def _sentences(self, text: str) -> list[str]:
        return [
            sentence.strip()
            for sentence in re.split(
                r"(?<=[.!?])\s+|\n+",
                text,
            )
            if sentence.strip()
        ]

    def _is_question(self, sentence: str) -> bool:
        stripped = sentence.strip().lower()

        if stripped.endswith("?"):
            return True

        return stripped.startswith(
            (
                "can ",
                "could ",
                "do ",
                "does ",
                "how ",
                "is ",
                "should ",
                "what ",
                "when ",
                "where ",
                "which ",
                "why ",
                "will ",
            )
        )

    def _is_action_item(self, sentence: str) -> bool:
        lowered = sentence.strip().lower()

        return lowered.startswith(_ACTION_PREFIXES)

    def _referenced_items(
        self,
        sentence: str,
    ) -> set[str]:
        words = set(
            re.findall(
                r"[a-z0-9-]+",
                sentence.lower(),
            )
        )

        return words.intersection(_ITEM_KEYWORDS)

    def _deduplicate(
        self,
        values: list[str],
    ) -> list[str]:
        seen: set[str] = set()
        result: list[str] = []

        for value in values:
            key = value.strip().lower()

            if not key or key in seen:
                continue

            seen.add(key)
            result.append(value.strip())

        return result