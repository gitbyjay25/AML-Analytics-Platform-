"""
Risk score reads go through vw_risk_scores_latest (never the raw table —
a transaction can have multiple historical scores, and the view is the
single place that knows how to pick the current one). Writes go through
sp_risk_score_upsert, the only validated write path for this table.
"""
from decimal import Decimal

from app.repositories.base import call_procedure, run_query


def get_latest(transaction_id: int) -> dict | None:
    rows = run_query(
        "SELECT * FROM vw_risk_scores_latest WHERE transaction_id = %s",
        (transaction_id,),
    )
    return rows[0] if rows else None


def upsert(
    transaction_id: int,
    rule_flag_score: Decimal,
    baseline_deviation_score: Decimal,
    peer_anomaly_score: Decimal,
    model_id: int | None,
) -> dict:
    result_sets = call_procedure(
        "sp_risk_score_upsert",
        [transaction_id, rule_flag_score, baseline_deviation_score, peer_anomaly_score, model_id],
    )
    # sp_risk_score_upsert's final SELECT is its one result set
    return result_sets[0][0]


def get_baseline_deviation(transaction_id: int) -> dict | None:
    """Reads vw_account_baseline_deviation for a specific transaction —
    used by the service layer to derive the deterministic baseline
    deviation component before calling upsert()."""
    rows = run_query(
        "SELECT * FROM vw_account_baseline_deviation WHERE transaction_id = %s",
        (transaction_id,),
    )
    return rows[0] if rows else None


def get_peer_anomaly(account_id: str) -> dict | None:
    """Reads vw_peer_group_anomaly for a specific account — used the same
    way, to derive the peer anomaly component."""
    rows = run_query(
        "SELECT * FROM vw_peer_group_anomaly WHERE account_id = %s",
        (account_id,),
    )
    return rows[0] if rows else None
