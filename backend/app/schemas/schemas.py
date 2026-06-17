from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel


class GoogleAuthRequest(BaseModel):
    google_id_token: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserBasic"


class UserBasic(BaseModel):
    id: UUID
    email: str
    name: str | None

    model_config = {"from_attributes": True}


class ExerciseResponse(BaseModel):
    id: UUID
    name: str
    category: str
    description: str | None
    muscle_groups: list[str] | None

    model_config = {"from_attributes": True}


class TemplateExerciseResponse(BaseModel):
    id: UUID
    exercise_id: UUID
    order_index: int
    exercise: ExerciseResponse | None = None

    model_config = {"from_attributes": True}


class TemplateResponse(BaseModel):
    id: UUID
    name: str
    created_at: datetime
    updated_at: datetime
    exercises: list[TemplateExerciseResponse] = []

    model_config = {"from_attributes": True}


class TemplateExerciseCreate(BaseModel):
    exercise_id: UUID
    order_index: int


class TemplateCreate(BaseModel):
    name: str
    exercises: list[TemplateExerciseCreate] = []


class SetResponse(BaseModel):
    id: UUID
    set_number: int
    weight_kg: Decimal
    reps: int
    completed: bool

    model_config = {"from_attributes": True}


class SessionExerciseResponse(BaseModel):
    id: UUID
    exercise_id: UUID
    order_index: int
    exercise: ExerciseResponse | None = None
    sets: list[SetResponse] = []

    model_config = {"from_attributes": True}


class SessionResponse(BaseModel):
    id: UUID
    template_id: UUID | None
    started_at: datetime
    finished_at: datetime
    notes: str | None
    synced_at: datetime | None
    exercises: list[SessionExerciseResponse] = []

    model_config = {"from_attributes": True}


class SessionListResponse(BaseModel):
    id: UUID
    template_id: UUID | None
    started_at: datetime
    finished_at: datetime
    notes: str | None
    exercise_count: int = 0

    model_config = {"from_attributes": True}


class SetCreate(BaseModel):
    set_number: int
    weight_kg: Decimal
    reps: int
    completed: bool = False


class SessionExerciseCreate(BaseModel):
    exercise_id: UUID
    order_index: int
    sets: list[SetCreate] = []


class SessionCreate(BaseModel):
    started_at: datetime
    finished_at: datetime
    template_id: UUID | None = None
    notes: str | None = None
    exercises: list[SessionExerciseCreate] = []


class UserResponse(BaseModel):
    id: UUID
    email: str
    name: str | None
    avatar_url: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class UserUpdate(BaseModel):
    name: str | None = None


class ErrorResponse(BaseModel):
    error: str
    message: str
    status_code: int
