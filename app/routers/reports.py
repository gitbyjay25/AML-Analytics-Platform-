from fastapi import APIRouter

from app.schemas.report import ReportGenerateRequest, ReportGenerateResult
from app.services import report_service

router = APIRouter(prefix="/reports", tags=["reports"])


@router.post("/generate", response_model=ReportGenerateResult)
def generate_report(payload: ReportGenerateRequest):
    return report_service.generate_report(
        payload.report_type,
        payload.period_start,
        payload.period_end,
        payload.generated_by,
        payload.file_path,
    )
