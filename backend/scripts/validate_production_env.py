"""Automated production environment and secret validator for Cora Backend."""

from __future__ import annotations

import argparse
import asyncio
import os
import sys
from typing import NamedTuple


class ValidationResult(NamedTuple):
    is_valid: bool
    errors: list[str]
    warnings: list[str]


INSECURE_PLACEHOLDERS = {
    "changeme",
    "change_me",
    "your-secret-here",
    "your-api-key",
    "your-project-id",
    "example",
    "todo",
    "placeholder",
    "test-secret",
}

REQUIRED_VARS = [
    "ENVIRONMENT",
    "DATABASE_URL",
    "FIREBASE_PROJECT_ID",
    "R2_ENDPOINT_URL",
    "R2_ACCESS_KEY_ID",
    "R2_SECRET_ACCESS_KEY",
    "R2_BUCKET_NAME",
    "GEMINI_API_KEY",
]


def audit_env_variables(env: dict[str, str]) -> ValidationResult:
    """Audit the presence and format of environment variables without network calls."""
    errors: list[str] = []
    warnings: list[str] = []

    for var_name in REQUIRED_VARS:
        val = env.get(var_name, "").strip()
        if not val:
            errors.append(f"Missing required variable: {var_name}")
            continue

        lower_val = val.lower()
        if any(p in lower_val for p in INSECURE_PLACEHOLDERS):
            errors.append(
                f"Variable {var_name} contains an insecure placeholder: '{val[:15]}...'"
            )

    env_val = env.get("ENVIRONMENT", "").strip().lower()
    if env_val and env_val != "production":
        warnings.append(
            f"ENVIRONMENT is set to '{env_val}', expected 'production' for live release"
        )

    db_url = env.get("DATABASE_URL", "").strip()
    if db_url and not (
        db_url.startswith("postgresql+asyncpg://") or db_url.startswith("postgresql://")
    ):
        errors.append(
            "DATABASE_URL must be a PostgreSQL connection string (postgresql+asyncpg://)"
        )

    if db_url and "ssl=" not in db_url and "sslmode=" not in db_url:
        warnings.append(
            "DATABASE_URL does not specify ssl=require (recommended for Neon)"
        )

    r2_endpoint = env.get("R2_ENDPOINT_URL", "").strip()
    if r2_endpoint and not (
        r2_endpoint.startswith("https://") and "r2.cloudflarestorage.com" in r2_endpoint
    ):
        warnings.append(
            f"R2_ENDPOINT_URL does not match Cloudflare R2: {r2_endpoint[:25]}..."
        )

    return ValidationResult(
        is_valid=len(errors) == 0,
        errors=errors,
        warnings=warnings,
    )


async def check_live_database_connection(db_url: str) -> tuple[bool, str]:
    """Test live connectivity to PostgreSQL database."""
    try:
        from sqlalchemy import text
        from sqlalchemy.ext.asyncio import create_async_engine

        engine = create_async_engine(db_url, echo=False)
        async with engine.connect() as conn:
            result = await conn.execute(text("SELECT 1;"))
            val = result.scalar()
            if val != 1:
                return False, f"Unexpected DB query response: {val}"
        await engine.dispose()
        return True, "PostgreSQL connection and query successful"
    except Exception as exc:
        return False, f"Database connection failed: {exc}"


def check_live_gemini_connection(api_key: str) -> tuple[bool, str]:
    """Test live connectivity to Google Gemini API."""
    try:
        from google import genai

        client = genai.Client(api_key=api_key)
        # Fast metadata check
        model = client.models.get(model="gemini-2.5-flash")
        return True, f"Gemini API key verified (model {model.name} accessible)"
    except Exception as exc:
        return False, f"Gemini API check failed: {exc}"


async def run_full_validation(
    env: dict[str, str],
    skip_network: bool = False,
) -> bool:
    """Run environmental audit and optional live network checks."""
    print("🔍 [AUDIT] Running production environment audit...")
    audit = audit_env_variables(env)

    for warning in audit.warnings:
        print(f"⚠️  [WARNING] {warning}")

    if not audit.is_valid:
        for error in audit.errors:
            print(f"❌ [ERROR] {error}")
        print("\n🚫 Audit failed: fix the above errors before deploying.")
        return False

    print("✅ [AUDIT PASSED] Required environment variables are present.")

    if skip_network:
        print("⏩ [SKIPPED] Network connectivity tests skipped (--skip-network).")
        return True

    print("\n🌐 [NETWORK] Testing live connections to external services...")
    all_live_ok = True

    # 1. Database check
    db_url = env["DATABASE_URL"]
    db_ok, db_msg = await check_live_database_connection(db_url)
    if db_ok:
        print(f"✅ [DATABASE] {db_msg}")
    else:
        print(f"❌ [DATABASE] {db_msg}")
        all_live_ok = False

    # 2. Gemini check
    gemini_key = env["GEMINI_API_KEY"]
    gemini_ok, gemini_msg = check_live_gemini_connection(gemini_key)
    if gemini_ok:
        print(f"✅ [GEMINI API] {gemini_msg}")
    else:
        print(f"❌ [GEMINI API] {gemini_msg}")
        all_live_ok = False

    if all_live_ok:
        print("\n🎉 All production environment checks passed successfully!")
    else:
        print("\n🚫 Some live connectivity checks failed. Verify credentials.")

    return all_live_ok


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate production environment variables for Cora."
    )
    parser.add_argument(
        "--skip-network",
        action="store_true",
        help="Skip live network connectivity tests (useful for CI/dry-run).",
    )
    parser.add_argument(
        "--env-file",
        help="Path to an .env file to load for validation (default: reads os.environ).",
    )
    args = parser.parse_args()

    env_data = dict(os.environ)
    if args.env_file and os.path.exists(args.env_file):
        with open(args.env_file, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    env_data[k.strip()] = v.strip().strip("'\"")

    success = asyncio.run(run_full_validation(env_data, skip_network=args.skip_network))
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
