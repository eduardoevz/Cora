import uuid

import pytest
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from app.core.database import Base
from app.core.idempotency import CachedMutationResponse, IdempotencyStore


@pytest.fixture
async def test_session() -> AsyncSession:
    engine = create_async_engine("sqlite+aiosqlite:///:memory:", echo=False)
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    session_maker = async_sessionmaker(engine, expire_on_commit=False)
    async with session_maker() as session:
        yield session

    await engine.dispose()


@pytest.mark.asyncio
async def test_idempotency_store_records_and_retrieves_cached_response(
    test_session: AsyncSession,
) -> None:
    store = IdempotencyStore(test_session)
    user_id = uuid.uuid4()
    mutation_id = uuid.uuid4()
    endpoint = "/api/v1/wellness/logs"
    request_hash = "sha256_mock_hash_123"

    # 1. First encounter: check should return None
    cached = await store.get_cached_response(user_id, mutation_id)
    assert cached is None

    # 2. Record successful response
    payload = {"status": "recorded", "id": str(uuid.uuid4())}
    await store.record_response(
        user_id=user_id,
        client_mutation_id=mutation_id,
        endpoint=endpoint,
        request_hash=request_hash,
        response_status=201,
        response_body=payload,
    )

    # 3. Second encounter: check must return the cached response
    cached_again = await store.get_cached_response(user_id, mutation_id)
    assert isinstance(cached_again, CachedMutationResponse)
    assert cached_again.response_status == 201
    assert cached_again.response_body == payload
    assert cached_again.client_mutation_id == mutation_id
