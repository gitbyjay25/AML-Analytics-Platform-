from fastapi import APIRouter , Depends
from app.dependencies import require_analyst_or_manager
from app.schemas.risk_score import RiskScoreCalculateResult, RiskScoreOut
from app.services import risk_score_service

router = APIRouter(prefix="/risk-scores", tags=["risk-scores"])


@router.get("/{transaction_id}", response_model=RiskScoreOut)
def get_latest_score(transaction_id: int):
    return risk_score_service.get_latest_score(transaction_id)


@router.post("/{transaction_id}/calculate", response_model=RiskScoreCalculateResult)
def calculate_score(
    transaction_id: int,
    model_id: int | None = None,
    current_user: dict = Depends(require_analyst_or_manager),
):
    return risk_score_service.calculate_and_persist(transaction_id, model_id)