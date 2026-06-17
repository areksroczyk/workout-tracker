import uuid
from datetime import datetime, timezone

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exercise import Exercise


@pytest_asyncio.fixture
async def exercises(db: AsyncSession):
    exs = [
        Exercise(name="Bench Press", category="Push", muscle_groups=["Chest"]),
        Exercise(name="Squat", category="Legs", muscle_groups=["Quads"]),
    ]
    for ex in exs:
        db.add(ex)
    await db.commit()
    for ex in exs:
        await db.refresh(ex)
    return exs


def _session_payload(exercises, **overrides):
    base = {
        "started_at": "2025-01-15T10:00:00Z",
        "finished_at": "2025-01-15T11:15:00Z",
        "template_id": None,
        "notes": "Great workout",
        "exercises": [
            {
                "exercise_id": str(exercises[0].id),
                "order_index": 0,
                "sets": [
                    {"set_number": 1, "weight_kg": 80, "reps": 8, "completed": True},
                    {"set_number": 2, "weight_kg": 80, "reps": 6, "completed": True},
                ],
            },
            {
                "exercise_id": str(exercises[1].id),
                "order_index": 1,
                "sets": [
                    {"set_number": 1, "weight_kg": 100, "reps": 5, "completed": True},
                ],
            },
        ],
    }
    base.update(overrides)
    return base


@pytest.mark.asyncio
async def test_create_session(client, exercises):
    resp = await client.post("/api/v1/sessions", json=_session_payload(exercises))
    assert resp.status_code == 201
    data = resp.json()
    assert data["notes"] == "Great workout"
    assert len(data["exercises"]) == 2
    assert len(data["exercises"][0]["sets"]) == 2


@pytest.mark.asyncio
async def test_list_sessions(client, exercises):
    await client.post("/api/v1/sessions", json=_session_payload(exercises))
    await client.post(
        "/api/v1/sessions",
        json=_session_payload(
            exercises,
            started_at="2025-01-16T10:00:00Z",
            finished_at="2025-01-16T11:00:00Z",
        ),
    )

    resp = await client.get("/api/v1/sessions")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 2
    assert "exercise_count" in data[0]


@pytest.mark.asyncio
async def test_get_session_detail(client, exercises):
    create_resp = await client.post("/api/v1/sessions", json=_session_payload(exercises))
    session_id = create_resp.json()["id"]

    resp = await client.get(f"/api/v1/sessions/{session_id}")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data["exercises"]) == 2
    assert len(data["exercises"][0]["sets"]) == 2


@pytest.mark.asyncio
async def test_delete_session(client, exercises):
    create_resp = await client.post("/api/v1/sessions", json=_session_payload(exercises))
    session_id = create_resp.json()["id"]

    resp = await client.delete(f"/api/v1/sessions/{session_id}")
    assert resp.status_code == 204

    resp = await client.get(f"/api/v1/sessions/{session_id}")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_create_session_invalid_times(client, exercises):
    resp = await client.post(
        "/api/v1/sessions",
        json=_session_payload(
            exercises,
            started_at="2025-01-15T12:00:00Z",
            finished_at="2025-01-15T10:00:00Z",
        ),
    )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_create_session_invalid_exercise(client, exercises):
    payload = _session_payload(exercises)
    payload["exercises"][0]["exercise_id"] = str(uuid.uuid4())
    resp = await client.post("/api/v1/sessions", json=payload)
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_get_session_not_found(client, exercises):
    resp = await client.get(f"/api/v1/sessions/{uuid.uuid4()}")
    assert resp.status_code == 404
