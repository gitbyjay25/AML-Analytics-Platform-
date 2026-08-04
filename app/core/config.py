"""
Application configuration, loaded from environment variables / .env file.
No credentials or connection details are hardcoded anywhere else in the app.
"""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(".env", ".venv/.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    db_host: str = "127.0.0.1"
    db_port: int = 3306
    db_user: str = "root"
    db_password: str = "Jay.@123"
    db_name: str = "aml_analytics"
    db_pool_size: int = 5

    app_name: str = "AML Transaction Analytics Platform API"
    environment: str = "development"


settings = Settings()
