from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import get_current_user
from app.models.exercise import Exercise
from app.models.session import Session, SessionExercise
from app.models.set import WorkoutSet
from app.models.user import User
from app.schemas.schemas import SessionCreate, SessionListResponse, SessionResponse

router = APIRouter(prefix="/sessions", tags=["sessions"])


def _session_detail_query(user_id: UUID):
    return (
        select(Session)
        .where(Session.user_id == user_id)
        .options(
            selectinload(Session.exercises)
            .selectinload(SessionExercise.exercise),
            selectinload(Session.exercises)
            .selectinload(SessionExercise.sets),
        )
    )


@router.get("", response_model=list[SessionListResponse])
async def list_sessions(
    skip: int = Query(0, ge=0),
    limit: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = (
        select(Session)
        .where(Session.user_id == current_user.id)
        .options(selectinload(Session.exercises))
        .order_by(Session.started_at.desc())
        .offset(skip)
        .limit(limit)
    )
    result = await db.execute(query)
    sessions = result.scalars().all()

    return [
        SessionListResponse(
            id=s.id,
            template_id=s.template_id,
            started_at=s.started_at,
            finished_at=s.finished_at,
            notes=s.notes,
            exercise_count=len(s.exercises),
        )
        for s in sessions
    ]


@router.post("", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
async def create_session(
    body: SessionCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if body.finished_at <= body.started_at:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="finished_at must be after started_at",
        )

    # Validate exercise IDs
    if body.exercises:
        exercise_ids = [e.exercise_id for e in body.exercises]
        result = await db.execute(select(Exercise.id).where(Exercise.id.in_(exercise_ids)))
        found = {row[0] for row in result.all()}
        missing = set(exercise_ids) - found
        if missing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Exercises not found: {[str(m) for m in missing]}",
            )

    session = Session(
        user_id=current_user.id,
        template_id=body.template_id,
        started_at=body.started_at,
        finished_at=body.finished_at,
        notes=body.notes,
    )
    db.add(session)
    await db.flush()

    for se_data in body.exercises:
        se = SessionExercise(
            session_id=session.id,
            exercise_id=se_data.exercise_id,
            order_index=se_data.order_index,
        )
        db.add(se)
        await db.flush()

        for set_data in se_data.sets:
            ws = WorkoutSet(
                session_exercise_id=se.id,
                set_number=set_data.set_number,
                weight_kg=set_data.weight_kg,
                reps=set_data.reps,
                completed=set_data.completed,
            )
            db.add(ws)

    await db.commit()

    result = await db.execute(_session_detail_query(current_user.id).where(Session.id == session.id))
    return result.scalar_one()


@router.get("/{session_id}", response_model=SessionResponse)
async def get_session(
    session_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(_session_detail_query(current_user.id).where(Session.id == session_id))
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")
    return session


@router.delete("/{session_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_session(
    session_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Session).where(Session.id == session_id, Session.user_id == current_user.id)
    )
    session = result.scalar_one_or_none()
    if not session:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Session not found")

    await db.delete(session)
    await db.commit()
    return None
