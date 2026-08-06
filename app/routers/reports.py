from fastapi import APIRouter, Depends

from app.dependencies import require_analyst_or_manager
from app.schemas.report import ReportGenerateRequest, ReportGenerateResult
from app.services import report_service

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("/generate", response_model=ReportGenerateResult)
def generate_report(
    payload: ReportGenerateRequest,
    current_user: dict = Depends(require_analyst_or_manager),
):
    return report_service.generate_report(
        payload.report_type,
        payload.period_start,
        payload.period_end,
        current_user["user_id"],
        payload.file_path,
    )