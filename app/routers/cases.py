from fastapi import APIRouter, Depends
from app.dependencies import require_analyst_or_manager
from app.schemas.case import CaseCreate, CaseOut, CaseStatusUpdate
from app.services import case_service

router = APIRouter(prefix="/cases", tags=["cases"])


@router.post("", response_model=CaseOut)
def create_case(
    payload: CaseCreate,
    current_user: dict = Depends(require_analyst_or_manager),
):
    return case_service.create_case(
        payload.transaction_id,
        current_user["user_id"],
        payload.status,
        payload.notes,
    )


@router.patch("/{case_id}", response_model=CaseOut)
def update_case_status(
    case_id: int,
    payload: CaseStatusUpdate,
    current_user: dict = Depends(require_analyst_or_manager),
):
    return case_service.update_case_status(
        case_id,
        payload.status,
        payload.notes,
    )


@router.get("", response_model=list[CaseOut])
def get_case_queue(
    analyst_id: int | None = None,
    current_user: dict = Depends(require_analyst_or_manager),
):
    return case_service.get_queue(analyst_id)
