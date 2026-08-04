"""
Plain query only — see the architecture doc's correction on this point.
Password verification happens in the service layer with a real hashing
library; the DB's only job is to hand back the stored hash for a given
email. Putting hash comparison in SQL would be a security anti-pattern.
"""
from app.repositories.base import run_query


def get_by_email(email: str) -> dict | None:
    rows = run_query(
        "SELECT user_id, full_name, email, password_hash, role, is_active "
        "FROM users WHERE email = %s",
        (email,),
    )
    return rows[0] if rows else None
