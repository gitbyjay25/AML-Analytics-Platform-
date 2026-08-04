"""
Custom exception hierarchy. Repositories never let raw mysql.connector.Error
or generic exceptions reach the router layer — they translate DB errors into
one of these, and a single FastAPI exception handler (see main.py) converts
each type into a consistent HTTP response.
"""


class AppError(Exception):
    """Base class for all application-raised errors."""
    def __init__(self, message: str):
        self.message = message
        super().__init__(message)


class NotFoundError(AppError):
    """Requested resource does not exist. Maps to HTTP 404."""
    pass


class BusinessRuleError(AppError):
    """
    A stored procedure rejected the operation via SIGNAL SQLSTATE '45000'
    (e.g. duplicate active case, invalid state transition, score out of
    range). Maps to HTTP 400 — the message is safe to show the caller since
    it's a deliberate, human-readable SIGNAL message, not a raw DB error.
    """
    pass


class DatabaseError(AppError):
    """Unexpected database failure. Maps to HTTP 500 — message is logged,
    not shown to the caller (could leak schema/internal details)."""
    pass
