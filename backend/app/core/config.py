from functools import lru_cache
from typing import Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings and environment configuration."""

    environment: Literal["development", "test", "testing", "production"] = "test"
    app_name: str = "Cora Backend"
    app_version: str = "0.1.0"
    api_v1_prefix: str = "/api/v1"

    # Database
    database_url: str = (
        "postgresql+asyncpg://cora_user:cora_password@localhost:5432/cora_db"
    )

    # Firebase Auth
    firebase_project_id: str = "cora-health-app"
    firebase_credentials_path: str = "./secrets/firebase_service_account.json"
    firebase_credentials_json: str | None = None

    # Cloudflare R2
    r2_account_id: str = "mock-account-id"
    r2_access_key_id: str = "mock-access-key"
    r2_secret_access_key: str = "mock-secret-key"
    r2_bucket_name: str = "cora-medical-documents"
    r2_endpoint_url: str = "https://mock-account.r2.cloudflarestorage.com"

    # Gemini AI
    gemini_api_key: str = "mock-gemini-key"
    gemini_generation_model: str = "gemini-3.8-flash"
    gemini_embedding_model: str = "gemini-embedding-2"
    gemini_embedding_dimensions: int = 768
    gemini_store_interactions: bool = False

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, v: str) -> str:
        """Ensure asyncpg dialect is present for async PostgreSQL connections."""
        if isinstance(v, str):
            if v.startswith("postgres://"):
                return "postgresql+asyncpg://" + v[len("postgres://") :]
            if v.startswith("postgresql://") and not v.startswith(
                "postgresql+asyncpg://"
            ):
                return "postgresql+asyncpg://" + v[len("postgresql://") :]
        return v


@lru_cache
def get_settings() -> Settings:
    """Return cached application settings instance."""
    return Settings()
