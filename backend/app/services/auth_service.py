import uuid
from datetime import datetime, timedelta, timezone

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.user import User


async def verify_google_token(token: str) -> dict:
    """Verify a Google ID token and return the decoded payload."""
    # Try Web Client ID first, then iOS Client ID
    audiences = [settings.GOOGLE_WEB_CLIENT_ID]
    if settings.GOOGLE_IOS_CLIENT_ID:
        audiences.append(settings.GOOGLE_IOS_CLIENT_ID)

    for audience in audiences:
        try:
            payload = google_id_token.verify_oauth2_token(
                token,
                google_requests.Request(),
                audience,
            )
            return payload
        except ValueError:
            continue

    raise ValueError("Invalid Google token: could not verify with any known client ID")


def create_access_token(user_id: uuid.UUID) -> str:
    """Create a JWT access token for the given user."""
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "iat": now,
        "exp": now + timedelta(minutes=settings.JWT_EXPIRY_MINUTES),
    }
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


def decode_access_token(token: str) -> dict:
    """Decode and verify a JWT access token."""
    try:
        return jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    except JWTError as e:
        raise ValueError(f"Invalid token: {e}") from e


async def get_or_create_user(db: AsyncSession, google_payload: dict) -> User:
    """Find an existing user by google_id, or create a new one."""
    google_id = google_payload["sub"]
    email = google_payload.get("email", "")
    name = google_payload.get("name")
    avatar_url = google_payload.get("picture")

    result = await db.execute(select(User).where(User.google_id == google_id))
    user = result.scalar_one_or_none()

    if user:
        user.name = name
        user.avatar_url = avatar_url
        await db.commit()
        await db.refresh(user)
        return user

    user = User(
        google_id=google_id,
        email=email,
        name=name,
        avatar_url=avatar_url,
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    return user
