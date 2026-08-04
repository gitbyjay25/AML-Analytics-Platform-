from app.exceptions import NotFoundError
from app.repositories import transaction_repo
from app.schemas.transaction import TransactionSearchParams


def get_transaction(transaction_id: int) -> dict:
    txn = transaction_repo.get_by_id(transaction_id)
    if not txn:
        raise NotFoundError(f"Transaction {transaction_id} not found")
    return txn


def search_transactions(params: TransactionSearchParams) -> list[dict]:
    return transaction_repo.search(params)
