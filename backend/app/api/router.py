from fastapi import APIRouter
from app.api.v1 import auth, sync

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/v1/auth", tags=["auth"])
api_router.include_router(sync.router, prefix="/v1", tags=["sync"])
