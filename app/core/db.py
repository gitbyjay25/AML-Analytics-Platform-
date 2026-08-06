"""
Single shared connection pool for the whole application.
Never opened per-request — repositories borrow a connection from this pool
and return it when done (handled via the get_connection context manager).
"""
from contextlib import contextmanager

import mysql.connector
from mysql.connector import pooling

from app.core.config import settings
from app.exceptions import DatabaseError

_pool: pooling.MySQLConnectionPool | None = None


def init_pool() -> None:
    global _pool
    if _pool is not None:
        return

    try:
        _pool = pooling.MySQLConnectionPool(
            pool_name="aml_pool",
            pool_size=settings.db_pool_size,
            host=settings.db_host,
            port=settings.db_port,
            user=settings.db_user,
            password=settings.db_password,
            database=settings.db_name,
            autocommit=False,
        )
    except Exception as exc:
        import traceback

        traceback.print_exc()
        raise


@contextmanager
def get_connection():
    """
    Yields a pooled connection. Always returns it to the pool afterward,
    even on error — callers must not manage commit/rollback themselves
    for procedure calls (procedures manage their own transactions).
    """
    if _pool is None:
        try:
            init_pool()
        except DatabaseError:
            raise
    if _pool is None:
        raise DatabaseError("Database connection is not available")

    conn = _pool.get_connection()
    try:
        yield conn
    finally:
        conn.close()  # returns the connection to the pool, does not truly close it
