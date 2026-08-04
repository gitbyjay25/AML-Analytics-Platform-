from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


class RiskScoreOut(BaseModel):
    risk_score_id: int
    transaction_id: int
    rule_flag_score: Decimal
    baseline_deviation_score: Decimal
    peer_anomaly_score: Decimal
    combined_score: Decimal
    risk_label: str
    model_id: int | None = None
    created_at: datetime


class RiskScoreCalculateResult(BaseModel):
    risk_score_id: int
    combined_score: Decimal
    risk_label: str


class RiskScoreComponents(BaseModel):
    """Input for a manual/override score calculation, mainly for testing
    or for a future ML-model integration to pass in its own component."""
    rule_flag_score: Decimal = Field(ge=0, le=100)
    baseline_deviation_score: Decimal = Field(ge=0, le=100)
    peer_anomaly_score: Decimal = Field(ge=0, le=100)
    model_id: int | None = None
