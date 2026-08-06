"""
All case writes go through sp_case_create / sp_case_update_status — these
enforce the duplicate-active-case rule and the cleared-is-terminal
state-transition rule, which must hold regardless of caller. Reads use
vw_case_queue, which encapsulates the priority ordering (escalated first,
then oldest first) so it's identical wherever it's used.
"""
from app.repositories.base import call_procedure, run_query


def create(transaction_id: int, analyst_id: int, status: str, notes: str | None) -> int:
    result_sets = call_procedure(
        "sp_case_create", [transaction_id, analyst_id, status, notes]
    )
    return result_sets[0][0]["case_id"]


def update_status(case_id: int, new_status: str, notes: str | None) -> None:
    call_procedure("sp_case_update_status", [case_id, new_status, notes])


def get_queue(analyst_id: int | None = None) -> list[dict]:
    if analyst_id:
        return run_query(
            "SELECT * FROM vw_case_queue WHERE analyst_id = %s", (analyst_id,)
        )
    return run_query("SELECT * FROM vw_case_queue")


def get_by_id(case_id: int) -> dict | None:
    rows = run_query("SELECT * FROM case_notes WHERE case_id = %s", (case_id,))
    return rows[0] if rows else None


def get_by_transaction_id(transaction_id: int) -> dict | None:
    rows = run_query(
        """
        SELECT *
        FROM case_notes
        WHERE transaction_id = %s
        ORDER BY created_at DESC
        LIMIT 1
        """,
        (transaction_id,),
    )
    return rows[0] if rows else None