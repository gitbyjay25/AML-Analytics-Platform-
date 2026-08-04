"""
Combines the three deterministic signals into component scores, then
delegates the validated write to sp_risk_score_upsert. The scoring
heuristics here (thresholds, scaling) are intentionally simple and
Python-side — if a trained ML model is added later, it plugs in as an
additional component the same way, without touching the DB layer.
"""
from decimal import Decimal

from app.exceptions import NotFoundError
from app.repositories import risk_score_repo, transaction_repo

HIGH_AMOUNT_THRESHOLD = Decimal("10000")


def _rule_flag_score(txn: dict) -> Decimal:
    score = Decimal("0")
    if txn["amount"] >= HIGH_AMOUNT_THRESHOLD:
        score += Decimal("50")
    if txn["payment_type"] == "wire" and txn["amount"] >= Decimal("5000"):
        score += Decimal("20")
    return min(score, Decimal("100"))


def _baseline_deviation_score(transaction_id: int) -> Decimal:
    row = risk_score_repo.get_baseline_deviation(transaction_id)
    if not row or row["z_score"] is None:
        return Decimal("0")
    # Scale |z| into a 0-100 range; |z| >= 5 is treated as maximally deviant
    z = abs(Decimal(str(row["z_score"])))
    return min(z * Decimal("20"), Decimal("100"))


def _peer_anomaly_score(sender_account: str) -> Decimal:
    row = risk_score_repo.get_peer_anomaly(sender_account)
    if not row or row["is_anomalous"] is None:
        return Decimal("0")
    return Decimal("80") if row["is_anomalous"] == 1 else Decimal("10")


def calculate_and_persist(transaction_id: int, model_id: int | None = None) -> dict:
    txn = transaction_repo.get_by_id(transaction_id)
    if not txn:
        raise NotFoundError(f"Transaction {transaction_id} not found")

    rule_flag = _rule_flag_score(txn)
    baseline_dev = _baseline_deviation_score(transaction_id)
    peer_anomaly = _peer_anomaly_score(txn["sender_account"])

    return risk_score_repo.upsert(
        transaction_id, rule_flag, baseline_dev, peer_anomaly, model_id
    )


def get_latest_score(transaction_id: int) -> dict:
    score = risk_score_repo.get_latest(transaction_id)
    if not score:
        raise NotFoundError(f"No risk score exists yet for transaction {transaction_id}")
    return score
