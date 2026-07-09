"""Rutas de autenticación."""

from fastapi import APIRouter, status

from app.core.security import CurrentUserDep
from app.deps import DbDep
from app.schemas.auth import (
    LoginRequest,
    LogoutRequest,
    OlvidePasswordRequest,
    OlvidePasswordResponse,
    RefreshRequest,
    RegistroRequest,
    ResetPasswordRequest,
    TokenResponse,
)
from app.schemas.common import MessageResponse
from app.schemas.usuario import UsuarioRead
from app.services import auth as auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/registro", response_model=UsuarioRead, status_code=status.HTTP_201_CREATED)
async def registro(data: RegistroRequest, db: DbDep) -> UsuarioRead:
    usuario = await auth_service.registrar(db, data)
    return UsuarioRead.model_validate(usuario)


@router.post("/login", response_model=TokenResponse)
async def login(data: LoginRequest, db: DbDep) -> TokenResponse:
    return await auth_service.login(db, data)


@router.post("/refresh", response_model=TokenResponse)
async def refresh(data: RefreshRequest, db: DbDep) -> TokenResponse:
    return await auth_service.refresh(db, data.refresh_token)


@router.post("/logout", response_model=MessageResponse)
async def logout(data: LogoutRequest, db: DbDep, user: CurrentUserDep) -> MessageResponse:
    await auth_service.logout(db, user.id)
    return MessageResponse(detail="Sesión cerrada")


@router.post("/olvide-password", response_model=OlvidePasswordResponse)
async def olvide_password(
    data: OlvidePasswordRequest, db: DbDep
) -> OlvidePasswordResponse:
    return await auth_service.olvide_password(db, data.email)


@router.post("/reset-password", response_model=MessageResponse)
async def reset_password(data: ResetPasswordRequest, db: DbDep) -> MessageResponse:
    await auth_service.reset_password(db, data)
    return MessageResponse(detail="Contraseña actualizada")
