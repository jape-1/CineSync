"""Acceso a datos de promociones."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.promocion import Promocion


async def get(db: AsyncSession, promocion_id: int) -> Promocion | None:
    return await db.get(Promocion, promocion_id)


async def get_by_codigo(db: AsyncSession, codigo: str) -> Promocion | None:
    result = await db.execute(select(Promocion).where(Promocion.codigo == codigo))
    return result.scalar_one_or_none()


async def list_promociones(db: AsyncSession) -> list[Promocion]:
    result = await db.execute(select(Promocion).order_by(Promocion.id))
    return list(result.scalars().all())


async def add(db: AsyncSession, promocion: Promocion) -> Promocion:
    db.add(promocion)
    await db.flush()
    return promocion
