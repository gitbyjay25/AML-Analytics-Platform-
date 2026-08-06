from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer

from app.exceptions import AuthError
from app.services import auth_service

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


def get_current_user(token: str = Depends(oauth2_scheme)) -> dict:
    if not token:
        raise AuthError("Authentication required")
    return auth_service.decode_access_token(token)


def require_analyst_or_manager(
    current_user: dict = Depends(get_current_user),
) -> dict:
    if current_user["role"] not in ("analyst", "manager"):
        raise AuthError("Analyst or Manager role required")
    return current_user