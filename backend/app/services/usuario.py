"""Lógica de usuarios: perfil propio y gestión por administrador."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import security
from app.models.enums import RolUsuario
from app.models.usuario import Usuario
from app.repositories import usuario as usuario_repo
from app.schemas.usuario import UsuarioAdminUpdate, UsuarioCreate, UsuarioUpdateMe


async def get_me(db: AsyncSession, user_id: int) -> Usuario:
    usuario = await usuario_repo.get_by_id(db, user_id)
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No encontrado")
    return usuario


async def update_me(
    db: AsyncSession, user_id: int, data: UsuarioUpdateMe
) -> Usuario:
    usuario = await get_me(db, user_id)
    if data.nombre is not None:
        usuario.nombre = data.nombre
    if data.password is not None:
        usuario.password_hash = security.hash_password(data.password)
    await db.commit()
    await db.refresh(usuario)
    return usuario


async def listar(db: AsyncSession, rol: RolUsuario | None) -> list[Usuario]:
    return await usuario_repo.list_usuarios(db, rol)


async def crear(db: AsyncSession, data: UsuarioCreate) -> Usuario:
    if data.rol == RolUsuario.cliente:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Los clientes se crean por el registro público",
        )
    if await usuario_repo.get_by_email(db, data.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="El email ya está registrado"
        )
    usuario = Usuario(
        nombre=data.nombre,
        email=data.email,
        password_hash=security.hash_password(data.password),
        rol=data.rol,
        turno=data.turno,
    )
    await usuario_repo.add(db, usuario)
    await db.commit()
    await db.refresh(usuario)
    return usuario


async def actualizar(
    db: AsyncSession, user_id: int, data: UsuarioAdminUpdate
) -> Usuario:
    usuario = await usuario_repo.get_by_id(db, user_id)
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No encontrado")
    if data.activo is not None:
        usuario.activo = data.activo
    if data.rol is not None:
        usuario.rol = data.rol
    if data.turno is not None:
        usuario.turno = data.turno
    # Cambios de rol/estado revocan sesiones existentes.
    usuario.token_version += 1
    await db.commit()
    await db.refresh(usuario)
    return usuario


async def desactivar(db: AsyncSession, user_id: int) -> None:
    usuario = await usuario_repo.get_by_id(db, user_id)
    if usuario is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No encontrado")
    usuario.activo = False
    usuario.token_version += 1
    await db.commit()
