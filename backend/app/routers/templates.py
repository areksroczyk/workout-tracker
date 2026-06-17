from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.database import get_db
from app.dependencies import get_current_user
from app.models.exercise import Exercise
from app.models.template import Template, TemplateExercise
from app.models.user import User
from app.schemas.schemas import TemplateCreate, TemplateResponse

router = APIRouter(prefix="/templates", tags=["templates"])


def _templates_query(user_id: UUID):
    return (
        select(Template)
        .where(Template.user_id == user_id)
        .options(selectinload(Template.exercises).selectinload(TemplateExercise.exercise))
        .order_by(Template.updated_at.desc())
    )


@router.get("", response_model=list[TemplateResponse])
async def list_templates(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(_templates_query(current_user.id))
    return result.scalars().all()


@router.post("", response_model=TemplateResponse, status_code=status.HTTP_201_CREATED)
async def create_template(
    body: TemplateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not body.name.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Template name is required")

    # Validate exercise IDs exist
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

    template = Template(user_id=current_user.id, name=body.name.strip())
    db.add(template)
    await db.flush()

    for ex in body.exercises:
        te = TemplateExercise(
            template_id=template.id,
            exercise_id=ex.exercise_id,
            order_index=ex.order_index,
        )
        db.add(te)

    await db.commit()

    result = await db.execute(_templates_query(current_user.id).where(Template.id == template.id))
    return result.scalar_one()


@router.get("/{template_id}", response_model=TemplateResponse)
async def get_template(
    template_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(_templates_query(current_user.id).where(Template.id == template_id))
    template = result.scalar_one_or_none()
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")
    return template


@router.put("/{template_id}", response_model=TemplateResponse)
async def update_template(
    template_id: UUID,
    body: TemplateCreate,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Template)
        .where(Template.id == template_id, Template.user_id == current_user.id)
        .options(selectinload(Template.exercises))
    )
    template = result.scalar_one_or_none()
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")

    if not body.name.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Template name is required")

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

    template.name = body.name.strip()

    # Replace exercises: clear the collection and add new ones
    template.exercises.clear()
    await db.flush()

    for ex in body.exercises:
        te = TemplateExercise(
            template_id=template.id,
            exercise_id=ex.exercise_id,
            order_index=ex.order_index,
        )
        template.exercises.append(te)

    await db.commit()

    result = await db.execute(_templates_query(current_user.id).where(Template.id == template.id))
    return result.scalar_one()


@router.delete("/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_template(
    template_id: UUID,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    result = await db.execute(
        select(Template).where(Template.id == template_id, Template.user_id == current_user.id)
    )
    template = result.scalar_one_or_none()
    if not template:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")

    await db.delete(template)
    await db.commit()
    return None
