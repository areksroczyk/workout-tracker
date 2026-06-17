"""Seed the exercises table with initial data. Idempotent — skips if exercises exist."""

import asyncio

from sqlalchemy import func, select

from app.database import async_session
from app.models.exercise import Exercise

EXERCISES = [
    # Push
    {"name": "Bench Press", "category": "Push", "description": "Barbell bench press on a flat bench.", "muscle_groups": ["Chest", "Triceps", "Front Deltoids"]},
    {"name": "Incline Bench Press", "category": "Push", "description": "Barbell bench press on an incline bench.", "muscle_groups": ["Upper Chest", "Triceps", "Front Deltoids"]},
    {"name": "Dumbbell Bench Press", "category": "Push", "description": "Dumbbell press on a flat bench.", "muscle_groups": ["Chest", "Triceps"]},
    {"name": "Overhead Press", "category": "Push", "description": "Standing barbell press overhead.", "muscle_groups": ["Shoulders", "Triceps"]},
    {"name": "Dumbbell Shoulder Press", "category": "Push", "description": "Seated or standing dumbbell press.", "muscle_groups": ["Shoulders", "Triceps"]},
    {"name": "Dumbbell Fly", "category": "Push", "description": "Flat bench dumbbell fly for chest isolation.", "muscle_groups": ["Chest"]},
    {"name": "Tricep Dips", "category": "Push", "description": "Bodyweight dips targeting triceps.", "muscle_groups": ["Triceps", "Chest", "Shoulders"]},
    {"name": "Tricep Pushdown", "category": "Push", "description": "Cable tricep pushdown.", "muscle_groups": ["Triceps"]},
    {"name": "Lateral Raise", "category": "Push", "description": "Dumbbell lateral raise for side deltoids.", "muscle_groups": ["Side Deltoids"]},
    {"name": "Cable Crossover", "category": "Push", "description": "Cable crossover for chest.", "muscle_groups": ["Chest"]},
    # Pull
    {"name": "Barbell Row", "category": "Pull", "description": "Bent-over barbell row.", "muscle_groups": ["Back", "Biceps"]},
    {"name": "Pull-Up", "category": "Pull", "description": "Bodyweight pull-up.", "muscle_groups": ["Lats", "Biceps", "Upper Back"]},
    {"name": "Lat Pulldown", "category": "Pull", "description": "Cable lat pulldown.", "muscle_groups": ["Lats", "Biceps"]},
    {"name": "Seated Cable Row", "category": "Pull", "description": "Seated cable row for mid-back.", "muscle_groups": ["Back", "Biceps"]},
    {"name": "Face Pull", "category": "Pull", "description": "Cable face pull for rear deltoids.", "muscle_groups": ["Rear Deltoids", "Upper Back"]},
    {"name": "Barbell Curl", "category": "Pull", "description": "Standing barbell bicep curl.", "muscle_groups": ["Biceps"]},
    {"name": "Hammer Curl", "category": "Pull", "description": "Dumbbell hammer curl.", "muscle_groups": ["Biceps", "Forearms"]},
    {"name": "Deadlift", "category": "Pull", "description": "Conventional barbell deadlift.", "muscle_groups": ["Back", "Hamstrings", "Glutes"]},
    {"name": "Dumbbell Row", "category": "Pull", "description": "Single-arm dumbbell row.", "muscle_groups": ["Back", "Biceps"]},
    {"name": "Chin-Up", "category": "Pull", "description": "Underhand grip pull-up.", "muscle_groups": ["Lats", "Biceps"]},
    # Legs
    {"name": "Squat", "category": "Legs", "description": "Barbell back squat.", "muscle_groups": ["Quads", "Glutes", "Hamstrings"]},
    {"name": "Leg Press", "category": "Legs", "description": "Machine leg press.", "muscle_groups": ["Quads", "Glutes"]},
    {"name": "Romanian Deadlift", "category": "Legs", "description": "Barbell Romanian deadlift.", "muscle_groups": ["Hamstrings", "Glutes", "Lower Back"]},
    {"name": "Leg Curl", "category": "Legs", "description": "Machine lying or seated leg curl.", "muscle_groups": ["Hamstrings"]},
    {"name": "Leg Extension", "category": "Legs", "description": "Machine leg extension.", "muscle_groups": ["Quads"]},
    {"name": "Calf Raise", "category": "Legs", "description": "Standing or seated calf raise.", "muscle_groups": ["Calves"]},
    {"name": "Bulgarian Split Squat", "category": "Legs", "description": "Single-leg split squat with rear foot elevated.", "muscle_groups": ["Quads", "Glutes"]},
    {"name": "Hip Thrust", "category": "Legs", "description": "Barbell hip thrust.", "muscle_groups": ["Glutes", "Hamstrings"]},
    {"name": "Front Squat", "category": "Legs", "description": "Barbell front squat.", "muscle_groups": ["Quads", "Core"]},
    {"name": "Goblet Squat", "category": "Legs", "description": "Dumbbell or kettlebell goblet squat.", "muscle_groups": ["Quads", "Glutes"]},
    # Core
    {"name": "Plank", "category": "Core", "description": "Isometric core hold.", "muscle_groups": ["Abs", "Obliques"]},
    {"name": "Hanging Leg Raise", "category": "Core", "description": "Hanging from a bar, raise legs.", "muscle_groups": ["Lower Abs", "Hip Flexors"]},
    {"name": "Cable Crunch", "category": "Core", "description": "Kneeling cable crunch.", "muscle_groups": ["Abs"]},
    {"name": "Ab Wheel Rollout", "category": "Core", "description": "Ab wheel rollout from knees or standing.", "muscle_groups": ["Abs", "Core"]},
    {"name": "Russian Twist", "category": "Core", "description": "Seated twist with or without weight.", "muscle_groups": ["Obliques", "Abs"]},
    # Cardio
    {"name": "Treadmill Run", "category": "Cardio", "description": "Running on a treadmill.", "muscle_groups": ["Legs", "Cardiovascular"]},
    {"name": "Rowing Machine", "category": "Cardio", "description": "Indoor rowing machine.", "muscle_groups": ["Back", "Legs", "Cardiovascular"]},
    {"name": "Jump Rope", "category": "Cardio", "description": "Skipping rope.", "muscle_groups": ["Calves", "Cardiovascular"]},
    {"name": "Cycling", "category": "Cardio", "description": "Stationary bike or outdoor cycling.", "muscle_groups": ["Legs", "Cardiovascular"]},
    {"name": "Stair Climber", "category": "Cardio", "description": "Stair climbing machine.", "muscle_groups": ["Legs", "Glutes", "Cardiovascular"]},
]


async def seed_exercises():
    async with async_session() as session:
        result = await session.execute(select(func.count(Exercise.id)))
        count = result.scalar()

        if count > 0:
            print(f"Exercises already seeded ({count} found). Skipping.")
            return

        for data in EXERCISES:
            exercise = Exercise(**data)
            session.add(exercise)

        await session.commit()
        print(f"Seeded {len(EXERCISES)} exercises.")


if __name__ == "__main__":
    asyncio.run(seed_exercises())
