from datetime import date
from decimal import Decimal

from fastapi import APIRouter, Depends

from app.schemas.transaction import TransactionOut, TransactionSearchParams
from app.services import transaction_service

router = APIRouter(prefix="/transactions", tags=["transactions"])


@router.get("", response_model=list[TransactionOut])
def search_transactions(params: TransactionSearchParams = Depends()):
    return transaction_service.search_transactions(params)


@router.get("/{transaction_id}", response_model=TransactionOut)
def get_transaction(transaction_id: int):
    return transaction_service.get_transaction(transaction_id)
