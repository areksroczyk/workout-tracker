"""Seed demo templates and workout history for an existing user.

Usage (after logging in via the iOS app at least once):
    python -m app.seed_demo --email twoj@email.com

List users in the database:
    python -m app.seed_demo --list
"""

import argparse
import asyncio
from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select

from app.database import async_session, init_db
from app.models.exercise import Exercise
from app.models.session import Session, SessionExercise
from app.models.set import WorkoutSet
from app.models.template import Template, TemplateExercise
from app.models.user import User
from app.seed import seed_exercises

DEMO_MARKER = "Push Day"

DEMO_TEMPLATES = [
    {
        "name": "Push Day",
        "exercises": ["Bench Press", "Overhead Press", "Tricep Pushdown", "Lateral Raise"],
    },
    {
        "name": "Pull Day",
        "exercises": ["Barbell Row", "Pull-Up", "Barbell Curl", "Face Pull"],
    },
    {
        "name": "Leg Day",
        "exercises": ["Squat", "Romanian Deadlift", "Leg Curl", "Calf Raise"],
    },
]

DEMO_SESSIONS = [
    {
        "template_name": "Push Day",
        "days_ago": 14,
        "duration_minutes": 68,
        "notes": "Solid session, PR on bench.",
        "exercises": [
            ("Bench Press", [(60, 10), (70, 8), (80, 6)]),
            ("Overhead Press", [(40, 8), (45, 6), (45, 5)]),
            ("Tricep Pushdown", [(25, 12), (30, 10), (30, 8)]),
            ("Lateral Raise", [(8, 15), (10, 12), (10, 10)]),
        ],
    },
    {
        "template_name": "Pull Day",
        "days_ago": 10,
        "duration_minutes": 72,
        "notes": None,
        "exercises": [
            ("Barbell Row", [(60, 8), (70, 6), (70, 6)]),
            ("Pull-Up", [(0, 8), (0, 6), (0, 5)]),
            ("Barbell Curl", [(20, 12), (25, 10), (25, 8)]),
            ("Face Pull", [(15, 15), (17.5, 12), (17.5, 12)]),
        ],
    },
    {
        "template_name": "Leg Day",
        "days_ago": 7,
        "duration_minutes": 75,
        "notes": "Legs were heavy today.",
        "exercises": [
            ("Squat", [(60, 8), (80, 6), (100, 4)]),
            ("Romanian Deadlift", [(60, 10), (70, 8), (80, 6)]),
            ("Leg Curl", [(30, 12), (35, 10), (35, 10)]),
            ("Calf Raise", [(40, 15), (50, 12), (50, 12)]),
        ],
    },
    {
        "template_name": "Push Day",
        "days_ago": 3,
        "duration_minutes": 65,
        "notes": None,
        "exercises": [
            ("Bench Press", [(60, 10), (75, 8), (82.5, 5)]),
            ("Overhead Press", [(40, 8), (47.5, 6), (50, 4)]),
            ("Tricep Pushdown", [(27.5, 12), (32.5, 10), (32.5, 8)]),
            ("Lateral Raise", [(8, 15), (10, 12), (12, 10)]),
        ],
    },
    {
        "template_name": None,
        "days_ago": 1,
        "duration_minutes": 45,
        "notes": "Quick upper body session.",
        "exercises": [
            ("Dumbbell Bench Press", [(22.5, 10), (25, 8), (27.5, 6)]),
            ("Chin-Up", [(0, 6), (0, 5), (0, 4)]),
        ],
    },
]


async def _get_exercise_map(session) -> dict[str, Exercise]:
    result = await session.execute(select(Exercise))
    exercises = result.scalars().all()
    return {ex.name: ex for ex in exercises}


async def _list_users(session) -> list[User]:
    result = await session.execute(select(User).order_by(User.email))
    return list(result.scalars().all())


async def _user_has_demo_data(session, user_id) -> bool:
    result = await session.execute(
        select(func.count(Template.id)).where(
            Template.user_id == user_id,
            Template.name == DEMO_MARKER,
        )
    )
    return (result.scalar() or 0) > 0


async def seed_demo_for_user(email: str, force: bool = False) -> None:
    await init_db()
    await seed_exercises()

    async with async_session() as session:
        result = await session.execute(select(User).where(User.email == email))
        user = result.scalar_one_or_none()
        if not user:
            users = await _list_users(session)
            if users:
                print(f"User not found: {email}\n")
                print("Users in database:")
                for u in users:
                    print(f"  - {u.email} ({u.name or 'no name'})")
            else:
                print("No users in database. Log in via the iOS app first.")
            return

        if await _user_has_demo_data(session, user.id) and not force:
            print(f"Demo data already exists for {email}. Use --force to replace.")
            return

        if force:
            await _clear_user_data(session, user.id)

        exercise_map = await _get_exercise_map(session)
        missing = {name for t in DEMO_TEMPLATES for name in t["exercises"]} - set(exercise_map)
        if missing:
            print(f"Missing exercises in database: {sorted(missing)}")
            return

        template_ids: dict[str, Template] = {}
        for tpl_data in DEMO_TEMPLATES:
            template = Template(user_id=user.id, name=tpl_data["name"])
            session.add(template)
            await session.flush()

            for order_index, exercise_name in enumerate(tpl_data["exercises"]):
                session.add(
                    TemplateExercise(
                        template_id=template.id,
                        exercise_id=exercise_map[exercise_name].id,
                        order_index=order_index,
                    )
                )

            template_ids[tpl_data["name"]] = template

        now = datetime.now(timezone.utc)
        for session_data in DEMO_SESSIONS:
            started_at = now - timedelta(days=session_data["days_ago"], hours=10)
            finished_at = started_at + timedelta(minutes=session_data["duration_minutes"])
            template = template_ids.get(session_data["template_name"]) if session_data["template_name"] else None

            workout = Session(
                user_id=user.id,
                template_id=template.id if template else None,
                started_at=started_at,
                finished_at=finished_at,
                notes=session_data["notes"],
            )
            session.add(workout)
            await session.flush()

            for order_index, (exercise_name, sets) in enumerate(session_data["exercises"]):
                se = SessionExercise(
                    session_id=workout.id,
                    exercise_id=exercise_map[exercise_name].id,
                    order_index=order_index,
                )
                session.add(se)
                await session.flush()

                for set_number, (weight_kg, reps) in enumerate(sets, start=1):
                    session.add(
                        WorkoutSet(
                            session_exercise_id=se.id,
                            set_number=set_number,
                            weight_kg=Decimal(str(weight_kg)),
                            reps=reps,
                            completed=True,
                        )
                    )

        await session.commit()
        print(f"Seeded demo data for {email}:")
        print(f"  - {len(DEMO_TEMPLATES)} templates")
        print(f"  - {len(DEMO_SESSIONS)} workout sessions")
        print("Pull to refresh in the iOS app (Workout + History tabs).")


async def _clear_user_data(session, user_id) -> None:
    templates = await session.execute(select(Template).where(Template.user_id == user_id))
    for template in templates.scalars():
        await session.delete(template)

    sessions = await session.execute(select(Session).where(Session.user_id == user_id))
    for workout in sessions.scalars():
        await session.delete(workout)

    await session.flush()


async def main() -> None:
    parser = argparse.ArgumentParser(description="Seed demo workout data for a user.")
    parser.add_argument("--email", help="Email of the user (must have logged in once)")
    parser.add_argument("--list", action="store_true", help="List users in the database")
    parser.add_argument("--force", action="store_true", help="Replace existing demo data")
    args = parser.parse_args()

    await init_db()

    if args.list:
        async with async_session() as session:
            users = await _list_users(session)
            if not users:
                print("No users found. Log in via the iOS app first.")
                return
            print("Users in database:")
            for user in users:
                has_demo = await _user_has_demo_data(session, user.id)
                status = "demo data present" if has_demo else "no demo data"
                print(f"  - {user.email} ({status})")
        return

    if not args.email:
        parser.error("Provide --email or use --list")
        return

    await seed_demo_for_user(args.email, force=args.force)


if __name__ == "__main__":
    asyncio.run(main())
