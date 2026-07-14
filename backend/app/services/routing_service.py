from sqlmodel import Session as DatabaseSession

from backend.app.intelligence.routing.engine import (
    RoutingEngine,
)
from backend.app.models.routing import (
    RoutingDecision,
    RoutingRequest,
)


class RoutingService:
    """
    Application-facing service for capture routing.

    Routing intelligence is delegated to RoutingEngine.
    """

    def __init__(
        self,
        database_session: DatabaseSession,
    ):
        self.engine = RoutingEngine(
            database_session
        )

    def suggest_route(
        self,
        request: RoutingRequest,
    ) -> RoutingDecision:
        return self.engine.suggest(request)