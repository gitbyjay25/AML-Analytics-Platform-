from fastapi import APIRouter

from app.schemas.case import CaseCreate, CaseOut, CaseStatusUpdate
from app.services import case_service

router = APIRouter(prefix="/cases", tags=["cases"])


@router.post("", response_model=CaseOut)
def create_case(payload: CaseCreate):
    return case_service.create_case(
        payload.transaction_id, payload.analyst_id, payload.status, payload.notes
    )


@router.patch("/{case_id}", response_model=CaseOut)
def update_case_status(case_id: int, payload: CaseStatusUpdate):
    return case_service.update_case_status(case_id, payload.status, payload.notes)


@router.get("", response_model=list[CaseOut])
def get_case_queue(analyst_id: int | None = None):
    return case_service.get_queue(analyst_id)
