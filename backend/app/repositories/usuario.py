"""Acceso a datos de usuarios."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import RolUsuario
from app.models.usuario import Usuario


async def get_by_id(db: AsyncSession, user_id: int) -> Usuario | None:
    return await db.get(Usuario, user_id)


async def get_by_email(db: AsyncSession, email: str) -> Usuario | None:
    result = await db.execute(select(Usuario).where(Usuario.email == email))
    return result.scalar_one_or_none()


async def list_usuarios(
    db: AsyncSession, rol: RolUsuario | None = None
) -> list[Usuario]:
    stmt = select(Usuario).order_by(Usuario.id)
    if rol is not None:
        stmt = stmt.where(Usuario.rol == rol)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def add(db: AsyncSession, usuario: Usuario) -> Usuario:
    db.add(usuario)
    await db.flush()
    await db.refresh(usuario)
    return usuario
