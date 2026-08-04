from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.core.config import settings
from app.core.db import init_pool
from app.exceptions import AppError, BusinessRuleError, DatabaseError, NotFoundError
from app.routers import auth, cases, reports, risk_scores, transactions

app = FastAPI(title=settings.app_name)

@app.get("/")
def root():
    return {"message": "API is running successfully!"}

@app.on_event("startup")
def on_startup():
    try:
        init_pool()
    except Exception as exc:
        print(f"Database startup unavailable: {exc}")


# ---------------------------------------------------------------------
# Centralized exception handling: every router/service raises one of the
# typed exceptions in app.exceptions, and this is the ONLY place that
# maps them to HTTP status codes. No router carries its own try/except.
# ---------------------------------------------------------------------
@app.exception_handler(NotFoundError)
def handle_not_found(request: Request, exc: NotFoundError):
    return JSONResponse(status_code=404, content={"detail": exc.message})


@app.exception_handler(BusinessRuleError)
def handle_business_rule(request: Request, exc: BusinessRuleError):
    return JSONResponse(status_code=400, content={"detail": exc.message})


@app.exception_handler(DatabaseError)
def handle_database_error(request: Request, exc: DatabaseError):
    # Deliberately generic message to the caller — exc.message (which may
    # contain internal detail) should go to server-side logging instead.
    return JSONResponse(status_code=500, content={"detail": "Internal database error"})


@app.exception_handler(AppError)
def handle_app_error(request: Request, exc: AppError):
    return JSONResponse(status_code=500, content={"detail": "Internal error"})


app.include_router(auth.router)
app.include_router(transactions.router)
app.include_router(risk_scores.router)
app.include_router(cases.router)
app.include_router(reports.router)


@app.get("/health")
def health():
    return {"status": "ok"}
