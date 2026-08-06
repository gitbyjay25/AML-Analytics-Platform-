from datetime import date
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel

ReportType = Literal["daily", "weekly", "monthly"]


class ReportGenerateRequest(BaseModel):
    report_type: ReportType
    period_start: date
    period_end: date
    file_path: str | None = None


class ReportGenerateResult(BaseModel):
    report_id: int
    total_transactions: int
    high_risk_count: int
    escalated_cases: int
    cleared_cases: int
    avg_transaction_amount: Decimal | None = None
