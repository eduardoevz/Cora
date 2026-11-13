"""Verify Cora Backend deployment health, latency, and OpenAPI contract."""

from __future__ import annotations

import argparse
import sys
import time
from typing import Any

import httpx


def verify_deployment(base_url: str, timeout: float = 10.0) -> bool:
    """Run smoke checks against the deployed Cora backend instance.

    Args:
        base_url: The base URL of the deployed instance (e.g., http://localhost:8000).
        timeout: Maximum seconds to wait per request.

    Returns:
        True if all checks succeed, False otherwise.
    """
    clean_base_url = base_url.rstrip("/")
    health_url = f"{clean_base_url}/api/v1/health"
    openapi_url = f"{clean_base_url}/openapi.json"

    print(f"[SMOKE CHECK] Verifying deployment at: {clean_base_url}")

    with httpx.Client(timeout=timeout) as client:
        # 1. Healthcheck probe
        start_time = time.perf_counter()
        try:
            health_resp = client.get(health_url)
            latency_ms = (time.perf_counter() - start_time) * 1000.0
        except Exception as exc:
            print(f"❌ [FAILED] Cannot connect to {health_url}: {exc}")
            return False

        if health_resp.status_code != 200:
            err_msg = health_resp.text[:100]
            print(f"❌ [FAILED] Healthcheck HTTP {health_resp.status_code}: {err_msg}")
            return False

        try:
            health_data: dict[str, Any] = health_resp.json()
        except Exception:
            raw_preview = health_resp.text[:80]
            print(f"❌ [FAILED] Healthcheck invalid JSON: {raw_preview}")
            return False

        if health_data.get("status") != "healthy":
            print(f"❌ [FAILED] Unexpected health status: {health_data}")
            return False

        print(
            f"✅ [PASSED] Healthcheck healthy (status={health_data.get('status')}, "
            f"service={health_data.get('service')}, latency={latency_ms:.2f}ms)"
        )

        # 2. OpenAPI schema probe
        try:
            openapi_resp = client.get(openapi_url)
        except Exception as exc:
            print(f"❌ [FAILED] Cannot fetch OpenAPI schema from {openapi_url}: {exc}")
            return False

        if openapi_resp.status_code != 200:
            print(f"❌ [FAILED] OpenAPI returned HTTP {openapi_resp.status_code}")
            return False

        try:
            openapi_data: dict[str, Any] = openapi_resp.json()
            title = openapi_data.get("info", {}).get("title", "")
            version = openapi_data.get("info", {}).get("version", "")
        except Exception:
            print("❌ [FAILED] OpenAPI response is not valid JSON")
            return False

        if "Cora" not in title:
            print(f"❌ [FAILED] Unexpected API title: {title}")
            return False

        print(f"✅ [PASSED] OpenAPI contract reachable ('{title}', v{version})")

    print("🎉 All deployment smoke checks passed successfully!")
    return True


def main() -> None:
    parser = argparse.ArgumentParser(description="Verify Cora backend deployment.")
    parser.add_argument(
        "--base-url",
        default="http://localhost:8000",
        help="Base URL of the running backend (default: http://localhost:8000)",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=10.0,
        help="Timeout in seconds for each request (default: 10.0)",
    )
    args = parser.parse_args()

    success = verify_deployment(base_url=args.base_url, timeout=args.timeout)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
