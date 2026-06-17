import uuid

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


@pytest.mark.asyncio
async def test_create_template(client, exercises):
    resp = await client.post(
        "/api/v1/templates",
        json={
            "name": "Push Day",
            "exercises": [
                {"exercise_id": str(exercises[0].id), "order_index": 0},
            ],
        },
    )
    assert resp.status_code == 201
    data = resp.json()
    assert data["name"] == "Push Day"
    assert len(data["exercises"]) == 1


@pytest.mark.asyncio
async def test_list_templates(client, exercises):
    await client.post("/api/v1/templates", json={"name": "Template 1", "exercises": []})
    await client.post("/api/v1/templates", json={"name": "Template 2", "exercises": []})

    resp = await client.get("/api/v1/templates")
    assert resp.status_code == 200
    assert len(resp.json()) == 2


@pytest.mark.asyncio
async def test_update_template(client, exercises):
    create_resp = await client.post("/api/v1/templates", json={"name": "Old Name", "exercises": []})
    template_id = create_resp.json()["id"]

    resp = await client.put(
        f"/api/v1/templates/{template_id}",
        json={
            "name": "New Name",
            "exercises": [{"exercise_id": str(exercises[1].id), "order_index": 0}],
        },
    )
    assert resp.status_code == 200
    assert resp.json()["name"] == "New Name"
    assert len(resp.json()["exercises"]) == 1


@pytest.mark.asyncio
async def test_delete_template(client, exercises):
    create_resp = await client.post("/api/v1/templates", json={"name": "To Delete", "exercises": []})
    template_id = create_resp.json()["id"]

    resp = await client.delete(f"/api/v1/templates/{template_id}")
    assert resp.status_code == 204

    resp = await client.get(f"/api/v1/templates/{template_id}")
    assert resp.status_code == 404


@pytest.mark.asyncio
async def test_create_template_empty_name(client, exercises):
    resp = await client.post("/api/v1/templates", json={"name": "  ", "exercises": []})
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_create_template_invalid_exercise(client, exercises):
    resp = await client.post(
        "/api/v1/templates",
        json={
            "name": "Bad Template",
            "exercises": [{"exercise_id": str(uuid.uuid4()), "order_index": 0}],
        },
    )
    assert resp.status_code == 400
