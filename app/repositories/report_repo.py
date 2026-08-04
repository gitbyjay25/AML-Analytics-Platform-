"""
Report generation goes through sp_report_generate — the single write path
that logs the immutable metadata row and returns the aggregated metrics
the service layer then hands off for file export.
"""
from datetime import date

from app.repositories.base import call_procedure


def generate(
    report_type: str,
    period_start: date,
    period_end: date,
    generated_by: int,
    file_path: str | None,
) -> dict:
    result_sets = call_procedure(
        "sp_report_generate",
        [report_type, period_start, period_end, generated_by, file_path],
    )
    return result_sets[0][0]
