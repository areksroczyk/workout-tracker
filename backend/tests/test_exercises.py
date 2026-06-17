import uuid

import pytest
import pytest_asyncio
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exercise import Exercise


@pytest_asyncio.fixture
async def seeded_exercises(db: AsyncSession):
    exercises = [
        Exercise(name="Bench Press", category="Push", description="Flat bench", muscle_groups=["Chest"]),
        Exercise(name="Squat", category="Legs", description="Back squat", muscle_groups=["Quads"]),
        Exercise(name="Pull-Up", category="Pull", description="Bodyweight", muscle_groups=["Lats"]),
        Exercise(name="Plank", category="Core", description="Isometric", muscle_groups=["Abs"]),
        Exercise(name="Treadmill Run", category="Cardio", description="Running", muscle_groups=["Legs"]),
    ]
    for ex in exercises:
        db.add(ex)
    await db.commit()
    for ex in exercises:
        await db.refresh(ex)
    return exercises


@pytest.mark.asyncio
async def test_list_exercises(client, seeded_exercises):
    resp = await client.get("/api/v1/exercises")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 5


@pytest.mark.asyncio
async def test_filter_exercises_by_category(client, seeded_exercises):
    resp = await client.get("/api/v1/exercises?category=Push")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["name"] == "Bench Press"


@pytest.mark.asyncio
async def test_search_exercises(client, seeded_exercises):
    resp = await client.get("/api/v1/exercises?search=bench")
    assert resp.status_code == 200
    data = resp.json()
    assert len(data) == 1
    assert data[0]["name"] == "Bench Press"


@pytest.mark.asyncio
async def test_get_exercise_by_id(client, seeded_exercises):
    exercise_id = str(seeded_exercises[0].id)
    resp = await client.get(f"/api/v1/exercises/{exercise_id}")
    assert resp.status_code == 200
    assert resp.json()["name"] == "Bench Press"


@pytest.mark.asyncio
async def test_get_exercise_not_found(client, seeded_exercises):
    resp = await client.get(f"/api/v1/exercises/{uuid.uuid4()}")
    assert resp.status_code == 404
