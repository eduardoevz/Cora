"""Longitudinal Latency Benchmarks & Concurrent Load Tests for Cora v1.0."""

import asyncio
import time
import uuid
from collections.abc import AsyncIterator
from datetime import UTC, datetime, timedelta

import pytest
from httpx import ASGITransport, AsyncClient
from sqlalchemy import insert
from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.database import Base, get_async_session
from app.main import create_app
from app.modules.clinical_tracking.infrastructure.orm.cycle_orm import (
    MenstrualCycleModel,
)
from app.modules.clinical_tracking.infrastructure.orm.wellness_orm import (
    DailyWellnessLogModel,
)
from app.modules.rag_assistant.domain.services.safety_interceptor import (
    DeterministicSafetyInterceptor,
)


@pytest.fixture
async def perf_env() -> AsyncIterator[
    tuple[AsyncClient, async_sessionmaker[AsyncSession]]
]:
    test_engine = create_async_engine(
        "sqlite+aiosqlite:///:memory:",
        echo=False,
    )
    async_session_factory = async_sessionmaker(
        test_engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )

    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    app = create_app()

    async def override_get_session() -> AsyncIterator[AsyncSession]:
        async with async_session_factory() as session:
            yield session

    app.dependency_overrides[get_async_session] = override_get_session

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        yield client, async_session_factory

    await test_engine.dispose()


def test_safety_interceptor_p99_latency_under_5ms() -> None:
    """Verify DeterministicSafetyInterceptor evaluates 200 queries under 5ms each."""
    interceptor = DeterministicSafetyInterceptor()
    queries = [
        "¿Por qué siento fatiga leve dos días antes de menstruar?",
        "Empapo 2 toallas por hora desde hace 3 horas y me siento mareada",
        "Tengo 165/112 de presión arterial, dolor de cabeza fuerte y veo lucecitas",
        "¿Qué alimentos ricos en calcio ayudan en la perimenopausia?",
        "Ya no quiero vivir, siento que no puedo más con esto",
    ]
    max_ms = 0.0
    for _ in range(40):
        for q in queries:
            t0 = time.perf_counter()
            _ = interceptor.evaluate(query_text=q, life_stage="regular_adult")
            elapsed_ms = (time.perf_counter() - t0) * 1000.0
            max_ms = max(max_ms, elapsed_ms)

    assert max_ms < 5.0, f"Safety interceptor exceeded 5ms budget: {max_ms:.2f}ms"


@pytest.mark.asyncio
async def test_3_year_longitudinal_history_latency_and_concurrency(
    perf_env: tuple[AsyncClient, async_sessionmaker[AsyncSession]],
) -> None:
    """Seed 3 years of daily logs (1,095 days) and 36 cycles; benchmark latency."""
    client, session_factory = perf_env
    headers = {"Authorization": "Bearer test-token:perf-user-3yr:perf@cora.test"}

    onb_resp = await client.put(
        "/api/v1/identity/onboarding",
        headers=headers,
        json={
            "first_name": "Camila",
            "last_name": "Longitudinal",
            "current_life_stage": "regular_adult",
            "birth_year": 1993,
            "primary_intents": ["cycle_and_symptoms", "general_wellness"],
            "hormonal_method": "none",
            "diagnosed_conditions": ["pcos"],
            "clinical_context_completed": True,
        },
    )
    assert onb_resp.status_code == 200
    user_id = uuid.UUID(onb_resp.json()["id"])

    today = datetime.now(UTC).date()
    now = datetime.now(UTC)

    # Bulk seed 1,095 daily wellness logs (3 years) and 36 menstrual cycles
    wellness_rows = [
        {
            "id": uuid.uuid4(),
            "user_id": user_id,
            "log_date": today - timedelta(days=offset),
            "sleep_hours": 7.0 + (offset % 3) * 0.5,
            "sleep_quality": 4,
            "energy_level": 3 + (offset % 2),
            "hydration_ml": 2000,
            "exercise_minutes": 30,
            "mood_tags": ["calm"] if offset % 2 == 0 else ["anxious"],
            "notes": f"Registro histórico día -{offset}",
            "created_at": now,
            "updated_at": now,
        }
        for offset in range(1095)
    ]

    cycle_rows = []
    for c_idx in range(36):
        c_start = today - timedelta(days=(c_idx + 1) * 29)
        c_end = c_start + timedelta(days=28) if c_idx > 0 else None
        cycle_rows.append(
            {
                "id": uuid.uuid4(),
                "user_id": user_id,
                "start_date": c_start,
                "end_date": c_end,
                "cycle_length_days": 29 if c_end is not None else None,
                "bleeding_duration_days": 5,
                "is_current": c_idx == 0,
                "created_at": now,
                "updated_at": now,
            }
        )

    async with session_factory() as session:
        await session.execute(insert(DailyWellnessLogModel), wellness_rows)
        await session.execute(insert(MenstrualCycleModel), cycle_rows)
        await session.commit()

    # 1. Benchmark GET /api/v1/cycles/overview (< 200 ms budget)
    t0 = time.perf_counter()
    ov_resp = await client.get("/api/v1/cycles/overview", headers=headers)
    ov_ms = (time.perf_counter() - t0) * 1000.0
    assert ov_resp.status_code == 200
    assert ov_ms < 200.0, f"/cycles/overview took {ov_ms:.2f}ms (> 200ms budget)"

    # 2. Benchmark 90-day wellness range query (< 200 ms budget)
    start_90 = (today - timedelta(days=90)).isoformat()
    t1 = time.perf_counter()
    well_resp = await client.get(
        f"/api/v1/wellness/logs?start_date={start_90}&end_date={today.isoformat()}",
        headers=headers,
    )
    well_ms = (time.perf_counter() - t1) * 1000.0
    assert well_resp.status_code == 200
    assert len(well_resp.json()) >= 90
    assert well_ms < 200.0, f"/wellness/logs 90d took {well_ms:.2f}ms (> 200ms)"

    # 3. Benchmark Doctor-Ready PDF generation over 3-year dataset (< 4,000 ms)
    t2 = time.perf_counter()
    pdf_resp = await client.post(
        "/api/v1/medical-records/doctor-report/pdf",
        headers=headers,
        json={"reporting_window_months": 6},
    )
    pdf_ms = (time.perf_counter() - t2) * 1000.0
    assert pdf_resp.status_code == 200
    assert pdf_resp.content.startswith(b"%PDF-")
    assert pdf_ms < 4000.0, f"Doctor-Ready PDF took {pdf_ms:.2f}ms (> 4000ms)"

    # 4. Concurrent burst: 15 simultaneous overview + wellness reads without errors
    async def _concurrent_read(idx: int) -> int:
        if idx % 2 == 0:
            r = await client.get("/api/v1/cycles/overview", headers=headers)
        else:
            r = await client.get(
                f"/api/v1/wellness/logs?start_date={start_90}&end_date={today.isoformat()}",
                headers=headers,
            )
        return r.status_code

    statuses = await asyncio.gather(*[_concurrent_read(i) for i in range(15)])
    assert all(code == 200 for code in statuses)
