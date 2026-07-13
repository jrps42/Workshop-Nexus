from fastapi import APIRouter, Depends
from sqlmodel import Session as DatabaseSession

from backend.app.database import get_database_session
from backend.app.models.routing import (
    RoutingDecision,
    RoutingRequest,
)
from backend.app.services.routing_service import (
    RoutingService,
)

router = APIRouter(
    prefix="/routing",
    tags=["routing"],
)


def get_routing_service(
    database_session: DatabaseSession = Depends(
        get_database_session
    ),
) -> RoutingService:
    return RoutingService(database_session)


@router.post(
    "/suggest",
    response_model=RoutingDecision,
)
def suggest_capture_route(
    request: RoutingRequest,
    service: RoutingService = Depends(
        get_routing_service
    ),
):
    return service.suggest_route(request)