from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel


class TransactionOut(BaseModel):
    transaction_id: int
    sender_account: str
    receiver_account: str
    amount: Decimal
    currency: str
    country: str
    payment_type: str
    txn_timestamp: datetime
    label: str | None = None


class TransactionSearchParams(BaseModel):
    sender_account: str | None = None
    receiver_account: str | None = None
    country: str | None = None
    payment_type: str | None = None
    min_amount: Decimal | None = None
    max_amount: Decimal | None = None
    date_from: date | None = None
    date_to: date | None = None
    page: int = 1
    page_size: int = 50
