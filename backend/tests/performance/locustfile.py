"""Reproducible Load & Stress Profile for Cora API (Locust / HTTP Benchmark)."""

from datetime import UTC, datetime, timedelta
from typing import Any


class CoraLongitudinalWorkloadProfile:
    """Defines the canonical load-testing scenarios for Cora v1.0 endpoints."""

    def __init__(self, base_url: str = "http://localhost:8000") -> None:
        self.base_url = base_url

    def build_request_specs(self, uid: str = "load-user-1") -> list[dict[str, Any]]:
        """Return ordered HTTP request specifications for load testing."""
        today = datetime.now(UTC).date()
        start_30 = (today - timedelta(days=30)).isoformat()
        headers = {"Authorization": f"Bearer test-token:{uid}:{uid}@cora.test"}
        return [
            {
                "name": "GET /api/v1/health",
                "method": "GET",
                "path": "/api/v1/health",
                "headers": {},
                "p95_budget_ms": 50,
            },
            {
                "name": "GET /api/v1/cycles/overview",
                "method": "GET",
                "path": "/api/v1/cycles/overview",
                "headers": headers,
                "p95_budget_ms": 200,
            },
            {
                "name": "GET /api/v1/wellness/logs (30d)",
                "method": "GET",
                "path": (
                    f"/api/v1/wellness/logs?start_date={start_30}"
                    f"&end_date={today.isoformat()}"
                ),
                "headers": headers,
                "p95_budget_ms": 200,
            },
            {
                "name": "POST /api/v1/medical-records/doctor-report/pdf",
                "method": "POST",
                "path": "/api/v1/medical-records/doctor-report/pdf",
                "headers": headers,
                "json": {"reporting_window_months": 6},
                "p95_budget_ms": 4000,
            },
        ]
