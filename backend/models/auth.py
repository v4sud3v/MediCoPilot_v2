from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime

class SignUpRequest(BaseModel):
    email: EmailStr
    password: str
    name: str
    specialization: Optional[str] = None

class SignInRequest(BaseModel):
    email: EmailStr
    password: str

class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: dict
    doctor: Optional[dict] = None

class DoctorProfile(BaseModel):
    id: str
    name: str
    email: str
    specialization: Optional[str] = None
    created_at: datetime

class PasswordResetRequest(BaseModel):
    email: EmailStr

class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    specialization: Optional[str] = None

class MessageResponse(BaseModel):
    message: str
