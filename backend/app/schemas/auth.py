"""Schemas de autenticación."""

from pydantic import BaseModel, EmailStr, Field


class RegistroRequest(BaseModel):
    nombre: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: str


class OlvidePasswordRequest(BaseModel):
    email: EmailStr


class OlvidePasswordResponse(BaseModel):
    # En un entorno real se enviaría por correo; aquí se retorna para pruebas.
    detail: str
    reset_token: str


class ResetPasswordRequest(BaseModel):
    reset_token: str
    nueva_password: str = Field(min_length=6, max_length=128)
