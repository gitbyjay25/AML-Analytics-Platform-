from datetime import datetime
from typing import Literal

from pydantic import BaseModel

CaseStatus = Literal["reviewed", "escalated", "cleared"]


class CaseCreate(BaseModel):
    transaction_id: int
    analyst_id: int
    status: CaseStatus = "reviewed"
    notes: str | None = None


class CaseStatusUpdate(BaseModel):
    status: CaseStatus
    notes: str | None = None


class CaseOut(BaseModel):
    case_id: int
    transaction_id: int
    analyst_id: int
    status: str
    notes: str | None = None
    created_at: datetime
    updated_at: datetime
