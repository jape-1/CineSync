"""Lógica de autenticación: registro, login, refresh, logout y recuperación."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import security
from app.models.enums import RolUsuario
from app.models.usuario import Usuario
from app.repositories import usuario as usuario_repo
from app.schemas.auth import (
    LoginRequest,
    OlvidePasswordResponse,
    RegistroRequest,
    ResetPasswordRequest,
    TokenResponse,
)


async def registrar(db: AsyncSession, data: RegistroRequest) -> Usuario:
    if await usuario_repo.get_by_email(db, data.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El email ya está registrado",
        )
    usuario = Usuario(
        nombre=data.nombre,
        email=data.email,
        password_hash=security.hash_password(data.password),
        rol=RolUsuario.cliente,
    )
    await usuario_repo.add(db, usuario)
    await db.commit()
    await db.refresh(usuario)
    return usuario


def _emitir_tokens(usuario: Usuario) -> TokenResponse:
    return TokenResponse(
        access_token=security.create_access_token(usuario.id, usuario.rol),
        refresh_token=security.create_refresh_token(usuario.id, usuario.token_version),
    )


async def login(db: AsyncSession, data: LoginRequest) -> TokenResponse:
    usuario = await usuario_repo.get_by_email(db, data.email)
    if usuario is None or not security.verify_password(
        data.password, usuario.password_hash
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Credenciales inválidas",
        )
    if not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Usuario desactivado",
        )
    return _emitir_tokens(usuario)


async def refresh(db: AsyncSession, refresh_token: str) -> TokenResponse:
    payload = security.decode_token(refresh_token, security.TYPE_REFRESH)
    usuario = await usuario_repo.get_by_id(db, int(payload["sub"]))
    if usuario is None or not usuario.activo:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido",
        )
    if payload.get("ver") != usuario.token_version:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Sesión revocada, inicia sesión de nuevo",
        )
    return _emitir_tokens(usuario)


async def logout(db: AsyncSession, user_id: int) -> None:
    """Invalida los refresh tokens del usuario incrementando su token_version."""
    usuario = await usuario_repo.get_by_id(db, user_id)
    if usuario is not None:
        usuario.token_version += 1
        await db.commit()


async def olvide_password(db: AsyncSession, email: str) -> OlvidePasswordResponse:
    usuario = await usuario_repo.get_by_email(db, email)
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No existe una cuenta con ese email",
        )
    token = security.create_reset_token(usuario.id)
    # En producción esto se enviaría por correo, no en la respuesta.
    return OlvidePasswordResponse(
        detail="Código de recuperación generado", reset_token=token
    )


async def reset_password(db: AsyncSession, data: ResetPasswordRequest) -> None:
    payload = security.decode_token(data.reset_token, security.TYPE_RESET)
    usuario = await usuario_repo.get_by_id(db, int(payload["sub"]))
    if usuario is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Usuario no encontrado",
        )
    usuario.password_hash = security.hash_password(data.nueva_password)
    usuario.token_version += 1  # cierra sesiones existentes
    await db.commit()
