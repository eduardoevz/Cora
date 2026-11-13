"""Unit tests for the automated production environment validator."""

from scripts.validate_production_env import audit_env_variables


def test_valid_production_environment_passes_audit() -> None:
    valid_env = {
        "ENVIRONMENT": "production",
        "DATABASE_URL": (
            "postgresql+asyncpg://app_user:strong_secret_pwd@ep-test-123.neon.tech/cora"
            "?ssl=require"
        ),
        "FIREBASE_PROJECT_ID": "cora-health-production-99",
        "R2_ENDPOINT_URL": "https://a1b2c3d4.r2.cloudflarestorage.com",
        "R2_ACCESS_KEY_ID": "0123456789abcdef0123456789abcdef",
        "R2_SECRET_ACCESS_KEY": "fedcba9876543210fedcba9876543210fedcba98",
        "R2_BUCKET_NAME": "cora-medical-records-prod",
        "GEMINI_API_KEY": "AIzaSyDUMMY_KEY_VAL_FOR_UNIT_TEST_1234567890",
    }

    result = audit_env_variables(valid_env)
    assert result.is_valid is True
    assert len(result.errors) == 0
    assert len(result.warnings) == 0


def test_missing_required_variables_fails_audit() -> None:
    incomplete_env = {
        "ENVIRONMENT": "production",
        "DATABASE_URL": "postgresql+asyncpg://user:pass@localhost/db?ssl=require",
    }

    result = audit_env_variables(incomplete_env)
    assert result.is_valid is False
    assert any("FIREBASE_PROJECT_ID" in err for err in result.errors)
    assert any("GEMINI_API_KEY" in err for err in result.errors)
    assert any("R2_BUCKET_NAME" in err for err in result.errors)


def test_insecure_placeholder_detection_fails_audit() -> None:
    placeholder_env = {
        "ENVIRONMENT": "production",
        "DATABASE_URL": "postgresql+asyncpg://user:changeme@localhost/db?ssl=require",
        "FIREBASE_PROJECT_ID": "your-project-id",
        "R2_ENDPOINT_URL": "https://account.r2.cloudflarestorage.com",
        "R2_ACCESS_KEY_ID": "placeholder",
        "R2_SECRET_ACCESS_KEY": "valid_secret_key_12345",
        "R2_BUCKET_NAME": "cora-bucket",
        "GEMINI_API_KEY": "your-api-key",
    }

    result = audit_env_variables(placeholder_env)
    assert result.is_valid is False
    assert any("DATABASE_URL" in err and "placeholder" in err for err in result.errors)
    assert any(
        "FIREBASE_PROJECT_ID" in err and "placeholder" in err for err in result.errors
    )
    assert any(
        "GEMINI_API_KEY" in err and "placeholder" in err for err in result.errors
    )


def test_invalid_database_url_scheme_fails_audit() -> None:
    bad_db_env = {
        "ENVIRONMENT": "production",
        "DATABASE_URL": "mysql://user:pass@localhost/db",
        "FIREBASE_PROJECT_ID": "cora-prod",
        "R2_ENDPOINT_URL": "https://account.r2.cloudflarestorage.com",
        "R2_ACCESS_KEY_ID": "valid_key",
        "R2_SECRET_ACCESS_KEY": "valid_secret",
        "R2_BUCKET_NAME": "cora-bucket",
        "GEMINI_API_KEY": "valid_gemini_key",
    }

    result = audit_env_variables(bad_db_env)
    assert result.is_valid is False
    assert any("PostgreSQL connection string" in err for err in result.errors)


def test_non_production_environment_issues_warning() -> None:
    staging_env = {
        "ENVIRONMENT": "staging",
        "DATABASE_URL": "postgresql+asyncpg://user:pass@localhost/db?ssl=require",
        "FIREBASE_PROJECT_ID": "cora-staging",
        "R2_ENDPOINT_URL": "https://account.r2.cloudflarestorage.com",
        "R2_ACCESS_KEY_ID": "valid_key",
        "R2_SECRET_ACCESS_KEY": "valid_secret",
        "R2_BUCKET_NAME": "cora-bucket",
        "GEMINI_API_KEY": "valid_gemini_key",
    }

    result = audit_env_variables(staging_env)
    assert result.is_valid is True  # Warning does not invalidate
    assert any("expected 'production'" in w for w in result.warnings)
