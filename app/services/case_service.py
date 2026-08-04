from app.exceptions import NotFoundError
from app.repositories import case_repo


def create_case(transaction_id: int, analyst_id: int, status: str, notes: str | None) -> dict:
    case_id = case_repo.create(transaction_id, analyst_id, status, notes)
    return case_repo.get_by_id(case_id)


def update_case_status(case_id: int, new_status: str, notes: str | None) -> dict:
    case_repo.update_status(case_id, new_status, notes)
    updated = case_repo.get_by_id(case_id)
    if not updated:
        raise NotFoundError(f"Case {case_id} not found")
    return updated


def get_queue(analyst_id: int | None = None) -> list[dict]:
    return case_repo.get_queue(analyst_id)
