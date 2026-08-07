from pydantic import BaseModel, EmailStr


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class LoginResponse(BaseModel):
    user_id: int
    full_name: str
    role: str
    access_token: str
    token_type: str = "bearer"

