"""
Password verification happens here, in Python, using passlib — never in
SQL. See the architecture doc's correction: MySQL has no safe, timing-safe
hash-comparison primitive, so authentication logic cannot live in a
stored procedure. The DB's only role is user_repo.get_by_email().
"""
from passlib.context import CryptContext

from app.exceptions import BusinessRuleError, NotFoundError
from app.repositories import user_repo

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
