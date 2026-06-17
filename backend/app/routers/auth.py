from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.schemas import GoogleAuthRequest, TokenResponse, UserBasic
from app.services.auth_service import (
    create_access_token,
    get_or_create_user,
    verify_google_token,
)

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/google", response_model=TokenResponse)
async def google_auth(request: GoogleAuthRequest, db: AsyncSession = Depends(get_db)):
    """Verify a Google ID token, create/update the user, and return a JWT."""
    try:
        google_payload = await verify_google_token(request.google_id_token)
    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid Google ID token",
        )

    user = await get_or_create_user(db, google_payload)
    access_token = create_access_token(user.id)

    return TokenResponse(
        access_token=access_token,
        user=UserBasic.model_validate(user),
    )


@router.post("/refresh", response_model=TokenResponse)
async def refresh_token(current_user: User = Depends(get_current_user)):
    """Issue a fresh JWT for an authenticated user."""
    access_token = create_access_token(current_user.id)
    return TokenResponse(
        access_token=access_token,
        user=UserBasic.model_validate(current_user),
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(current_user: User = Depends(get_current_user)):
    """Logout endpoint. Stateless JWT — client clears the token."""
    return None
