"""
The JSON API (app/dependencies.py) authenticates via Bearer token in the
Authorization header — correct for an API consumed by Swagger/external
clients. The HTML frontend authenticates via an httponly cookie instead,
since that's the standard, secure pattern for browser-rendered pages (no
JS needed to attach a header on every request). Both paths decode the
exact same JWT — this file just reads it from a different place.
"""
from fastapi import Request

from app.exceptions import AuthError
from app.services import auth_service


def get_current_user_from_cookie(request: Request) -> dict | None:
    token = request.cookies.get("access_token")
    if not token:
        return None
    try:
        return auth_service.decode_access_token(token)
    except AuthError:
        return None
