from datetime import date

from app.repositories import report_repo


def generate_report(
    report_type: str,
    period_start: date,
    period_end: date,
    generated_by: int,
    file_path: str | None,
) -> dict:
    # NOTE: file_path here is where FastAPI will write the exported CSV/PDF
    # snapshot of the returned metrics — that export step is a follow-up
    # piece (file generation), not implemented in this pass.
    return report_repo.generate(report_type, period_start, period_end, generated_by, file_path)
