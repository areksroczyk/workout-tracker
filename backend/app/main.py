from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded

from app.config import settings
from app.database import init_db
from app.middleware.rate_limit import limiter
from app.routers import auth, exercises, sessions, templates, users
from app.seed import seed_exercises


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    await seed_exercises()
    yield


app = FastAPI(
    title="Liftd API",
    description="Workout tracker backend",
    version="1.0.0",
    lifespan=lifespan,
)

# Rate limiting
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers — all under /api/v1
app.include_router(auth.router, prefix="/api/v1")
app.include_router(exercises.router, prefix="/api/v1")
app.include_router(templates.router, prefix="/api/v1")
app.include_router(sessions.router, prefix="/api/v1")
app.include_router(users.router, prefix="/api/v1")


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.exception_handler(404)
async def not_found_handler(request: Request, exc):
    return JSONResponse(
        status_code=404,
        content={"error": "not_found", "message": "Resource not found", "status_code": 404},
    )
