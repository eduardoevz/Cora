"""Automated zero-touch deployment script for Cora Backend on Render.com.

Interacts with the Render REST API to create/update the service, configure
environment variables, trigger deployment, poll until live, and run smoke tests
and clinical RAG ingestion.
"""

from __future__ import annotations

import argparse
import asyncio
import os
import sys
import time
from typing import Any, cast

from dotenv import load_dotenv
import httpx

load_dotenv()

from app.core.config import get_settings

RENDER_API_BASE = "https://api.render.com/v1"


def get_headers(api_key: str) -> dict[str, str]:
    """Return standard headers for Render API requests."""
    return {
        "Authorization": f"Bearer {api_key.strip()}",
        "Accept": "application/json",
        "Content-Type": "application/json",
    }


def get_owner_id(client: httpx.Client, api_key: str) -> str:
    """Fetch the default owner (user/team) ID for the account."""
    resp = client.get(f"{RENDER_API_BASE}/owners", headers=get_headers(api_key))
    if resp.status_code != 200:
        raise RuntimeError(
            f"Failed to query Render owners (HTTP {resp.status_code}): {resp.text}"
        )
    owners = resp.json()
    if not owners:
        raise RuntimeError("No owners found in Render account.")
    # Return first owner
    owner_info = owners[0]
    owner_data = owner_info.get("owner", owner_info)
    owner_id = str(owner_data["id"])
    owner_name = owner_data.get("name", "Account")
    print(f"✅ [RENDER API] Authenticated as: {owner_name} ({owner_id})")
    return owner_id


def find_existing_service(
    client: httpx.Client, api_key: str, service_name: str
) -> dict[str, Any] | None:
    """Look up an existing service by name."""
    resp = client.get(
        f"{RENDER_API_BASE}/services",
        headers=get_headers(api_key),
        params={"name": service_name, "limit": 10},
    )
    if resp.status_code != 200:
        raise RuntimeError(
            f"Failed to search Render services (HTTP {resp.status_code}): {resp.text}"
        )
    services = resp.json()
    for svc in services:
        service_data = svc.get("service", svc)
        if service_data.get("name") == service_name:
            return cast(dict[str, Any], service_data)
    return None


def create_web_service(
    client: httpx.Client,
    api_key: str,
    owner_id: str,
    service_name: str,
    env_vars: list[dict[str, str]],
    region: str = "oregon",
    plan: str = "starter",
) -> dict[str, Any]:
    """Create a new Docker web service connected to the Cora repository."""
    payload = {
        "type": "web_service",
        "name": service_name,
        "ownerId": owner_id,
        "repo": "https://github.com/eduardoevz/Cora",
        "branch": "main",
        "autoDeploy": "yes",
        "serviceDetails": {
            "env": "docker",
            "region": region,
            "plan": plan,
            "dockerfilePath": "backend/Dockerfile",
            "dockerContext": "backend",
            "healthCheckPath": "/api/v1/health",
            "preDeployCommand": "alembic upgrade head",
            "envVars": env_vars,
        },
    }

    print(f"🚀 [RENDER API] Creating web service '{service_name}'...")
    resp = client.post(
        f"{RENDER_API_BASE}/services",
        headers=get_headers(api_key),
        json=payload,
    )
    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Failed to create Render service (HTTP {resp.status_code}): {resp.text}"
        )
    result = resp.json().get("service", resp.json())
    return cast(dict[str, Any], result)


def update_service_env_vars(
    client: httpx.Client,
    api_key: str,
    service_id: str,
    env_vars: list[dict[str, str]],
) -> None:
    """Sync environment variables to an existing service."""
    print(f"🔄 [RENDER API] Updating environment variables for service {service_id}...")
    resp = client.put(
        f"{RENDER_API_BASE}/services/{service_id}/env-vars",
        headers=get_headers(api_key),
        json=env_vars,
    )
    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Failed to update env-vars (HTTP {resp.status_code}): {resp.text}"
        )
    print("✅ [RENDER API] Environment variables updated.")


def trigger_deploy(client: httpx.Client, api_key: str, service_id: str) -> str:
    """Trigger a new build and deploy for the service."""
    print(f"🚀 [RENDER API] Triggering deployment for service {service_id}...")
    resp = client.post(
        f"{RENDER_API_BASE}/services/{service_id}/deploys",
        headers=get_headers(api_key),
        json={"clearCache": "do_not_clear"},
    )
    if resp.status_code not in (200, 201):
        raise RuntimeError(
            f"Failed to trigger deploy (HTTP {resp.status_code}): {resp.text}"
        )
    deploy_data = resp.json().get("deploy", resp.json())
    deploy_id = str(deploy_data["id"])
    print(f"✅ [RENDER API] Deployment started: {deploy_id}")
    return deploy_id


def wait_for_deploy(
    client: httpx.Client,
    api_key: str,
    service_id: str,
    deploy_id: str,
    timeout_minutes: int = 15,
) -> bool:
    """Poll deployment status until it reaches 'live' or fails."""
    print(f"⏳ [RENDER API] Waiting for deployment {deploy_id} to complete...")
    start_time = time.time()
    max_duration = timeout_minutes * 60

    last_status = ""
    while time.time() - start_time < max_duration:
        resp = client.get(
            f"{RENDER_API_BASE}/services/{service_id}/deploys/{deploy_id}",
            headers=get_headers(api_key),
        )
        if resp.status_code != 200:
            print(f"⚠️ [WARN] Error polling deploy (HTTP {resp.status_code})")
            time.sleep(10)
            continue

        deploy = resp.json().get("deploy", resp.json())
        status = deploy.get("status", "unknown")

        if status != last_status:
            print(f"   ↳ Status: {status} ({int(time.time() - start_time)}s elapsed)")
            last_status = status

        if status == "live":
            print(f"🎉 [SUCCESS] Service is LIVE on Render! ({deploy_id})")
            return True
        elif status in {"build_failed", "update_failed", "canceled", "deactivated"}:
            print(f"❌ [FAILED] Deployment ended with status: {status}")
            return False

        time.sleep(12)

    print("❌ [TIMEOUT] Deployment timed out.")
    return False


async def run_automated_deploy(
    render_api_key: str,
    gemini_api_key: str | None = None,
    database_url: str | None = None,
    region: str = "oregon",
    plan: str = "starter",
    service_name: str = "cora-backend",
    skip_ingestion: bool = False,
    dry_run: bool = False,
) -> bool:
    """Orchestrate the full deployment lifecycle on Render."""
    settings = get_settings()

    db_url = database_url or settings.database_url
    gemini_key = gemini_api_key or settings.gemini_api_key

    # Format env vars for Render API
    env_vars = [
        {"key": "ENVIRONMENT", "value": "production"},
        {"key": "PORT", "value": "10000"},
        {"key": "DATABASE_URL", "value": db_url},
        {"key": "FIREBASE_PROJECT_ID", "value": settings.firebase_project_id},
        {"key": "R2_ENDPOINT_URL", "value": settings.r2_endpoint_url},
        {"key": "R2_ACCESS_KEY_ID", "value": settings.r2_access_key_id},
        {"key": "R2_SECRET_ACCESS_KEY", "value": settings.r2_secret_access_key},
        {"key": "R2_BUCKET_NAME", "value": settings.r2_bucket_name},
        {"key": "GEMINI_API_KEY", "value": gemini_key},
    ]

    if dry_run:
        print("🔍 [DRY RUN] Validating Render API key...")
        with httpx.Client(timeout=15.0) as client:
            owner_id = get_owner_id(client, render_api_key)
            existing = find_existing_service(client, render_api_key, service_name)
            if existing:
                s_id = existing.get("id")
                s_name = existing.get("name")
                print(f"ℹ️ Found existing service: {s_id} ({s_name})")
            else:
                print(f"ℹ️ Service '{service_name}' does not exist yet.")
        return True

    with httpx.Client(timeout=30.0) as client:
        owner_id = get_owner_id(client, render_api_key)
        existing_service = find_existing_service(client, render_api_key, service_name)

        if existing_service:
            service_id = str(existing_service["id"])
            print(f"ℹ️ Service '{service_name}' exists (ID: {service_id}). Updating...")
            update_service_env_vars(client, render_api_key, service_id, env_vars)
            deploy_id = trigger_deploy(client, render_api_key, service_id)
            service_url = existing_service.get("serviceDetails", {}).get("url")
        else:
            new_service = create_web_service(
                client=client,
                api_key=render_api_key,
                owner_id=owner_id,
                service_name=service_name,
                env_vars=env_vars,
                region=region,
                plan=plan,
            )
            service_id = str(new_service["id"])
            update_service_env_vars(client, render_api_key, service_id, env_vars)
            service_url = new_service.get("serviceDetails", {}).get("url")
            # Wait for auto-triggered initial deploy
            time.sleep(5)
            # Find the initial deploy ID
            deploys_resp = client.get(
                f"{RENDER_API_BASE}/services/{service_id}/deploys",
                headers=get_headers(render_api_key),
                params={"limit": 1},
            )
            deploys = deploys_resp.json()
            if deploys:
                deploy_data = deploys[0].get("deploy", deploys[0])
                deploy_id = str(deploy_data["id"])
            else:
                deploy_id = trigger_deploy(client, render_api_key, service_id)

        # Wait for deployment to be live
        success = wait_for_deploy(client, render_api_key, service_id, deploy_id)
        if not success:
            return False

        # Refresh service details to get final live URL
        svc_resp = client.get(
            f"{RENDER_API_BASE}/services/{service_id}",
            headers=get_headers(render_api_key),
        )
        if svc_resp.status_code == 200:
            svc_data = svc_resp.json().get("service", svc_resp.json())
            service_url = svc_data.get("serviceDetails", {}).get("url", service_url)

    if not service_url:
        print(f"⚠️ Could not resolve public URL for service {service_id}")
        return True

    print(f"\n🌐 [RENDER SERVICE LIVE] URL: {service_url}")

    # Run Smoke Checks
    print("\n🔍 [STEP 1/2] Running smoke verification checks...")
    from scripts.verify_deployment import verify_deployment

    smoke_ok = verify_deployment(service_url)
    if not smoke_ok:
        print("❌ Smoke checks failed!")
        return False

    # Ingest Clinical Corpus into Production DB
    if not skip_ingestion:
        print("\n📚 [STEP 2/2] Running automated clinical RAG corpus ingestion...")
        from scripts.ingest_clinical_library import run_ingestion

        os.environ["DATABASE_URL"] = db_url
        os.environ["GEMINI_API_KEY"] = gemini_key
        count = await run_ingestion(dry_run=False)
        print(f"🎉 Ingestion complete: {count} clinical chunks verified in database.")

    print("\n=======================================================")
    print("✅ DEPLOYMENT 100% COMPLETE & VERIFIED ON RENDER!")
    print(f"API Endpoint: {service_url}")
    print(f"Health Probe: {service_url}/api/v1/health")
    print(f"OpenAPI Spec: {service_url}/openapi.json")
    print("=======================================================\n")
    return True


def main() -> None:
    """CLI entrypoint."""
    parser = argparse.ArgumentParser(
        description="Automated zero-touch deployment of Cora Backend to Render.com"
    )
    parser.add_argument(
        "--render-api-key",
        default=os.getenv("RENDER_API_KEY"),
        help="Render API Bearer Token (rnd_...)",
    )
    parser.add_argument(
        "--gemini-api-key",
        default=os.getenv("GEMINI_API_KEY"),
        help="Valid Google Gemini API Key",
    )
    parser.add_argument(
        "--database-url",
        default=os.getenv("DATABASE_URL"),
        help="Production PostgreSQL Database URL (Neon)",
    )
    parser.add_argument(
        "--region",
        default="oregon",
        choices=["oregon", "ohio", "frankfurt", "singapore"],
        help="Render deployment region",
    )
    parser.add_argument(
        "--plan",
        default="starter",
        choices=["free", "starter", "standard", "pro"],
        help="Render compute plan",
    )
    parser.add_argument(
        "--service-name",
        default="cora-backend",
        help="Name of the web service on Render",
    )
    parser.add_argument(
        "--skip-ingestion",
        action="store_true",
        help="Skip automated RAG library ingestion",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate API key and check service state without deploying",
    )

    args = parser.parse_args()

    api_key = args.render_api_key
    if not api_key:
        print(
            "❌ [ERROR] Render API Key is required. Set RENDER_API_KEY env "
            "or pass --render-api-key."
        )
        sys.exit(1)

    ok = asyncio.run(
        run_automated_deploy(
            render_api_key=api_key,
            gemini_api_key=args.gemini_api_key,
            database_url=args.database_url,
            region=args.region,
            plan=args.plan,
            service_name=args.service_name,
            skip_ingestion=args.skip_ingestion,
            dry_run=args.dry_run,
        )
    )
    if not ok:
        sys.exit(1)


if __name__ == "__main__":
    main()
