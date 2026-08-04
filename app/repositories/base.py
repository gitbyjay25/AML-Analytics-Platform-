"""
Shared helpers for the repository layer. Every repository calls
call_procedure() or run_query() from here rather than talking to
mysql.connector directly — this is the one place that knows how to
translate a DB-level SIGNAL error into a typed application exception.
"""
from typing import Any

import mysql.connector

from app.core.db import get_connection
from app.exceptions import BusinessRuleError, DatabaseError

# SIGNAL SQLSTATE '45000' always surfaces as this errno in mysql-connector-python
_SIGNAL_ERRNO = 1644


def _translate_error(exc: mysql.connector.Error) -> Exception:
    if getattr(exc, "errno", None) == _SIGNAL_ERRNO:
        # exc.msg contains the exact MESSAGE_TEXT from the procedure's SIGNAL —
        # safe to surface directly, it was written to be a clear business message.
        return BusinessRuleError(exc.msg)
    return DatabaseError(f"Unexpected database error: {exc}")


def call_procedure(proc_name: str, params: list[Any]) -> list[list[dict]]:
    """
    Calls a stored procedure and returns all result sets as lists of dicts.
    Most procedures in this app return either nothing or one result set
    (e.g. the new ID / a summary row) — callers pick out what they need.
    """
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.callproc(proc_name, params)
            results = [
                [row for row in result_set]
                for result_set in cursor.stored_results()
            ]
            conn.commit()
            return results
        except mysql.connector.Error as exc:
            conn.rollback()
            raise _translate_error(exc) from exc
        finally:
            cursor.close()


def run_query(sql: str, params: tuple = ()) -> list[dict]:
    """
    For the plain parameterized queries (Category 3 from the architecture
    doc) — single-table lookups with no business logic, kept out of the
    stored procedure layer on purpose.
    """
    with get_connection() as conn:
        cursor = conn.cursor(dictionary=True)
        try:
            cursor.execute(sql, params)
            return cursor.fetchall()
        except mysql.connector.Error as exc:
            raise _translate_error(exc) from exc
        finally:
            cursor.close()
