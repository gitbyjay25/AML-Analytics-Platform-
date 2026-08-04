from fastapi import APIRouter

from app.schemas.auth import LoginRequest, LoginResponse
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest):
    user = auth_service.authenticate(payload.email, payload.password)
    return LoginResponse(user_id=user["user_id"], full_name=user["full_name"], role=user["role"])
