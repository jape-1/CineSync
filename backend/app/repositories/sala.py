"""Acceso a datos de salas y asientos."""

from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.funcion import Funcion
from app.models.sala import Asiento, Sala


async def get(db: AsyncSession, sala_id: int) -> Sala | None:
    return await db.get(Sala, sala_id)


async def list_salas(db: AsyncSession) -> list[Sala]:
    result = await db.execute(select(Sala).order_by(Sala.id))
    return list(result.scalars().all())


async def add(db: AsyncSession, sala: Sala) -> Sala:
    db.add(sala)
    await db.flush()
    return sala


async def add_asientos(db: AsyncSession, asientos: list[Asiento]) -> None:
    db.add_all(asientos)
    await db.flush()


async def list_asientos(db: AsyncSession, sala_id: int) -> list[Asiento]:
    result = await db.execute(
        select(Asiento).where(Asiento.sala_id == sala_id).order_by(
            Asiento.fila, Asiento.numero
        )
    )
    return list(result.scalars().all())


async def count_funciones_futuras(db: AsyncSession, sala_id: int) -> int:
    result = await db.execute(
        select(func.count())
        .select_from(Funcion)
        .where(Funcion.sala_id == sala_id, Funcion.fin >= func.now())
    )
    return int(result.scalar_one())
