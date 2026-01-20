from fastapi import APIRouter, HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from supabase import create_client, Client
from typing import Optional
import jwt
from datetime import datetime, timedelta
from models.auth import (
    SignUpRequest, 
    SignInRequest, 
    AuthResponse, 
    DoctorProfile,
    PasswordResetRequest,
    UpdateProfileRequest,
    MessageResponse
)
from config import settings

router = APIRouter(prefix="/auth", tags=["Authentication"])
security = HTTPBearer()

# Initialize Supabase client
supabase: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_PUBLISHABLE_KEY)
# For admin operations (creating users in doctors table)
supabase_admin: Client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SECRET_KEY)


def create_access_token(data: dict) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.JWT_SECRET_KEY, algorithm=settings.JWT_ALGORITHM)
    return encoded_jwt


def verify_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> dict:
    """Verify JWT token and return user data"""
    try:
        token = credentials.credentials
        payload = jwt.decode(token, settings.JWT_SECRET_KEY, algorithms=[settings.JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has expired"
        )
    except jwt.JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )


@router.post("/signup", response_model=AuthResponse)
async def signup(request: SignUpRequest):
    """
    Register a new doctor account.
    Creates both auth user and doctor record in database.
    """
    try:
        # Create auth user in Supabase
        auth_response = supabase.auth.sign_up(
            credentials={
                "email": request.email,
                "password": request.password
            },
            options={
                "data": {
                    "name": request.name,
                    "specialization": request.specialization
                }
            }
        )
        
        if not auth_response.user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Failed to create user"
            )
        
        user_id = auth_response.user.id
        
        # Insert doctor record into doctors table
        doctor_data = {
            "id": user_id,
            "name": request.name,
            "email": request.email,
            "specialization": request.specialization
        }
        
        doctor_response = supabase_admin.table("doctors").insert(doctor_data).execute()
        
        # Create custom JWT token
        access_token = create_access_token({
            "sub": user_id,
            "email": request.email,
            "name": request.name
        })
        
        return AuthResponse(
            access_token=access_token,
            user={
                "id": user_id,
                "email": request.email,
                "email_confirmed_at": None  # Will be set after email confirmation
            },
            doctor=doctor_data
        )
        
    except Exception as e:
        error_message = str(e)
        if "already registered" in error_message.lower() or "duplicate" in error_message.lower():
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Email already registered"
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Signup failed: {error_message}"
        )


@router.post("/signin", response_model=AuthResponse)
async def signin(request: SignInRequest):
    """
    Sign in an existing doctor.
    Returns JWT token and user/doctor data.
    """
    try:
        # Sign in with Supabase
        auth_response = supabase.auth.sign_in_with_password(
            credentials={
                "email": request.email,
                "password": request.password
            }
        )
        
        if not auth_response.user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid credentials"
            )
        
        user_id = auth_response.user.id
        
        # Get doctor details from doctors table
        doctor_response = supabase.table("doctors").select("*").eq("id", user_id).execute()
        
        doctor_data = None
        if doctor_response.data and len(doctor_response.data) > 0:
            doctor_data = doctor_response.data[0]
        
        # Create custom JWT token
        access_token = create_access_token({
            "sub": user_id,
            "email": request.email,
            "name": doctor_data.get("name") if doctor_data else None
        })
        
        return AuthResponse(
            access_token=access_token,
            user={
                "id": user_id,
                "email": auth_response.user.email,
                "email_confirmed_at": auth_response.user.email_confirmed_at
            },
            doctor=doctor_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        error_message = str(e)
        if "invalid" in error_message.lower() or "credentials" in error_message.lower():
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password"
            )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Sign in failed: {error_message}"
        )


@router.post("/signout", response_model=MessageResponse)
async def signout(current_user: dict = Depends(verify_token)):
    """
    Sign out the current user.
    Invalidates the Supabase session.
    """
    try:
        supabase.auth.sign_out()
        return MessageResponse(message="Successfully signed out")
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Sign out failed: {str(e)}"
        )


@router.get("/profile", response_model=DoctorProfile)
async def get_profile(current_user: dict = Depends(verify_token)):
    """
    Get the current doctor's profile.
    """
    try:
        user_id = current_user.get("sub")
        
        doctor_response = supabase.table("doctors").select("*").eq("id", user_id).execute()
        
        if not doctor_response.data or len(doctor_response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Doctor profile not found"
            )
        
        return doctor_response.data[0]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get profile: {str(e)}"
        )


@router.put("/profile", response_model=DoctorProfile)
async def update_profile(
    request: UpdateProfileRequest,
    current_user: dict = Depends(verify_token)
):
    """
    Update the current doctor's profile.
    """
    try:
        user_id = current_user.get("sub")
        
        # Build update data
        update_data = {}
        if request.name is not None:
            update_data["name"] = request.name
        if request.specialization is not None:
            update_data["specialization"] = request.specialization
        
        if not update_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No fields to update"
            )
        
        # Update doctor record
        doctor_response = supabase.table("doctors").update(update_data).eq("id", user_id).execute()
        
        if not doctor_response.data or len(doctor_response.data) == 0:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Doctor profile not found"
            )
        
        return doctor_response.data[0]
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update profile: {str(e)}"
        )


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(request: PasswordResetRequest):
    """
    Send password reset email to the user.
    """
    try:
        supabase.auth.reset_password_email(request.email)
        return MessageResponse(
            message="Password reset link sent to your email"
        )
    except Exception as e:
        # Don't reveal if email exists or not for security
        return MessageResponse(
            message="If the email exists, a password reset link has been sent"
        )


@router.get("/verify", response_model=MessageResponse)
async def verify_token_endpoint(current_user: dict = Depends(verify_token)):
    """
    Verify if the current token is valid.
    """
    return MessageResponse(message="Token is valid")
