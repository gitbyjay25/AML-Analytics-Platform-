"""
The HTML frontend — the "lightweight FastAPI-backed Investigation
Workspace" from the design doc. Every route here calls the SAME service
layer the JSON API uses (transaction_service, case_service, etc.) — no
logic is duplicated, this is purely a different presentation of the same
backend. Auth here is cookie-based (see app/web_auth.py), separate from
the API's bearer-token auth, since browser pages and API clients
authenticate differently by convention.
"""
from fastapi import APIRouter, Depends, Form, Request
from fastapi.responses import RedirectResponse
from starlette.status import HTTP_303_SEE_OTHER

from app.core.templates import templates
from app.exceptions import AppError
from app.schemas.transaction import TransactionSearchParams
from app.services import auth_service, case_service, risk_score_service, transaction_service
from app.web_auth import get_current_user_from_cookie

router = APIRouter(prefix="/app", tags=["web"])

COOKIE_NAME = "access_token"


def _require_login(request: Request):
    """Not a FastAPI Depends() raiser on purpose — web pages should
    redirect to /app/login, not return a JSON 401 like the API does."""
    user = get_current_user_from_cookie(request)
    return user


# ---------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------
@router.get("/login")
def login_page(request: Request):
    return templates.TemplateResponse(request, "login.html", {"user": None})


@router.post("/login")
def login_submit(request: Request, email: str = Form(...), password: str = Form(...)):
    try:
        user = auth_service.authenticate(email, password)
    except AppError as exc:
        return templates.TemplateResponse(
            request, "login.html", {"user": None, "error": exc.message}, status_code=400
        )
    token = auth_service.create_access_token(user)
    response = RedirectResponse(url="/app/transactions", status_code=HTTP_303_SEE_OTHER)
    response.set_cookie(COOKIE_NAME, token, httponly=True, max_age=8 * 3600)
    return response


@router.get("/logout")
def logout():
    response = RedirectResponse(url="/app/login", status_code=HTTP_303_SEE_OTHER)
    response.delete_cookie(COOKIE_NAME)
    return response


# ---------------------------------------------------------------------
# Transaction Explorer
# ---------------------------------------------------------------------
@router.get("/transactions")
def transactions_page(
    request: Request,
    sender_account: str | None = None,
    country: str | None = None,
    payment_type: str | None = None,
    min_amount: str | None = None,
):
    user = _require_login(request)
    if not user:
        return RedirectResponse(url="/app/login", status_code=HTTP_303_SEE_OTHER)
    if min_amount == "":
        min_amount = None
    elif min_amount is not None:
        min_amount = float(min_amount)
    params = TransactionSearchParams(
        sender_account=sender_account or None,
        country=country or None,
        payment_type=payment_type or None,
        min_amount=min_amount,
    )
    results = transaction_service.search_transactions(params)
    return templates.TemplateResponse(
        request,
        "transactions.html",
        {"user": user, "transactions": results, "filters": params.model_dump()},
    )


@router.get("/transactions/{transaction_id}")
def transaction_detail_page(request: Request, transaction_id: int, flash: str | None = None):
    user = _require_login(request)
    if not user:
        return RedirectResponse(url="/app/login", status_code=HTTP_303_SEE_OTHER)

    txn = transaction_service.get_transaction(transaction_id)

    try:
        risk_score = risk_score_service.get_latest_score(transaction_id)
    except AppError:
        risk_score = None

    from app.repositories import risk_score_repo
    baseline = risk_score_repo.get_baseline_deviation(transaction_id)

    case = case_service.get_case_for_transaction(transaction_id)

    return templates.TemplateResponse(
        request,
        "transaction_detail.html",
        {
            "user": user, "txn": txn, "risk_score": risk_score,
            "baseline": baseline, "case": case, "flash": flash,
        },
    )


@router.post("/transactions/{transaction_id}/calculate")
def calculate_risk_score(request: Request, transaction_id: int):
    user = _require_login(request)
    if not user:
        return RedirectResponse(url="/app/login", status_code=HTTP_303_SEE_OTHER)
    risk_score_service.calculate_and_persist(transaction_id)
    return RedirectResponse(
        url=f"/app/transactions/{transaction_id}?flash=Risk+score+calculated", status_code=HTTP_303_SEE_OTHER
    )


# ---------------------------------------------------------------------
# Case management
# ---------------------------------------------------------------------
@router.post("/cases")
def create_case(
    request: Request,
    transaction_id: int = Form(...),
    status: str = Form("reviewed"),
    notes: str = Form(""),
):
    user = _require_login(request)
    if not user:
        return RedirectResponse(url="/app/login", status_code=HTTP_303_SEE_OTHER)
    # analyst_id comes from the logged-in session, same principle as the API
    case_service.create_case(transaction_id, user["user_id"], status, notes or None)
    return RedirectResponse(
        url=f"/app/transactions/{transaction_id}?flash=Case+created", status_code=HTTP_303_SEE_OTHER
    )


@router.post("/cases/{case_id}/status")
def update_case_status(
    request: Request,
    case_id: int,
    status: str = Form(...),
    notes: str = Form(""),
):
    user = _require_login(request)
    if not user:
        return RedirectResponse(url="/app/login", status_code=HTTP_303_SEE_OTHER)
    updated = case_service.update_case_status(case_id, status, notes or None)
    return RedirectResponse(
        url=f"/app/transactions/{updated['transaction_id']}?flash=Case+updated", status_code=HTTP_303_SEE_OTHER
    )


@router.get("/cases")
def cases_page(request: Request):
    user = _require_login(request)
    if not user:
        return RedirectResponse(url="/app/login", status_code=HTTP_303_SEE_OTHER)
    cases = case_service.get_queue(analyst_id=user["user_id"])
    return templates.TemplateResponse(request, "cases.html", {"user": user, "cases": cases})
