"""
Transaction lookups. Both of these are plain parameterized queries by
design (Category 3 in the architecture doc) — single-table reads with no
business logic to encapsulate, and dynamic multi-filter search is more
maintainable as conditionally-built SQL here than as a stored procedure
with a wall of `(param IS NULL OR col = param)` conditions.
"""
from app.repositories.base import run_query
from app.schemas.transaction import TransactionSearchParams


def get_by_id(transaction_id: int) -> dict | None:
    rows = run_query(
        "SELECT * FROM transactions WHERE transaction_id = %s",
        (transaction_id,),
    )
    return rows[0] if rows else None


def search(params: TransactionSearchParams) -> list[dict]:
    clauses = []
    values: list = []

    if params.sender_account:
        clauses.append("sender_account = %s")
        values.append(params.sender_account)
    if params.receiver_account:
        clauses.append("receiver_account = %s")
        values.append(params.receiver_account)
    if params.country:
        clauses.append("country = %s")
        values.append(params.country)
    if params.payment_type:
        clauses.append("payment_type = %s")
        values.append(params.payment_type)
    if params.min_amount is not None:
        clauses.append("amount >= %s")
        values.append(params.min_amount)
    if params.max_amount is not None:
        clauses.append("amount <= %s")
        values.append(params.max_amount)
    if params.date_from:
        clauses.append("txn_timestamp >= %s")
        values.append(params.date_from)
    if params.date_to:
        clauses.append("txn_timestamp <= %s")
        values.append(params.date_to)

    where_sql = f"WHERE {' AND '.join(clauses)}" if clauses else ""
    offset = (params.page - 1) * params.page_size

    sql = f"""
        SELECT * FROM transactions
        {where_sql}
        ORDER BY txn_timestamp DESC
        LIMIT %s OFFSET %s
    """
    values.extend([params.page_size, offset])

    return run_query(sql, tuple(values))
