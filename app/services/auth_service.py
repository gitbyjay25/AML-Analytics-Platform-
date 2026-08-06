"""
Password verification happens here, in Python, using passlib — never in
SQL. See the architecture doc's correction: MySQL has no safe, timing-safe
hash-comparison primitive, so authentication logic cannot live in a
stored procedure. The DB's only role is user_repo.get_by_email().
"""
from passlib.context import CryptContext

from app.exceptions import BusinessRuleError, NotFoundError ,AuthError
from app.repositories import user_repo
from datetime import datetime, timedelta, timezone
import jwt

from app.core.config import settings

_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(plain_password: str) -> str:
    return _pwd_context.hash(plain_password)


def authenticate(email: str, plain_password: str) -> dict:
    user = user_repo.get_by_email(email)
    if not user:
        raise NotFoundError("No account found for that email")
    if not user["is_active"]:
        raise BusinessRuleError("This account has been deactivated")
    if not _pwd_context.verify(plain_password, user["password_hash"]):
        raise BusinessRuleError("Incorrect password")
    return user

def create_access_token(user: dict) -> str:
    expire = datetime.now(timezone.utc) + timedelta(
        minutes=settings.jwt_expire_minutes
    )

    payload = {
        "sub": str(user["user_id"]),
        "role": user["role"],
        "full_name": user["full_name"],
        "exp": expire,
    }

    return jwt.encode(
        payload,
        settings.jwt_secret_key,
        algorithm=settings.jwt_algorithm,
    )


def decode_access_token(token: str) -> dict:
    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
    except jwt.ExpiredSignatureError:
        raise AuthError("Session expired, please log in again")
    except jwt.InvalidTokenError:
        raise AuthError("Invalid authentication token")

    return {
        "user_id": int(payload["sub"]),
        "role": payload["role"],
        "full_name": payload["full_name"],
    }