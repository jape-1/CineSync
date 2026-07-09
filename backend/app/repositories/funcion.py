"""Acceso a datos de funciones y de sus asientos-función."""

from __future__ import annotations

from datetime import date, datetime, time, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.funcion import AsientoFuncion, Funcion
from app.models.pelicula import Pelicula


async def get(db: AsyncSession, funcion_id: int) -> Funcion | None:
    return await db.get(Funcion, funcion_id)


async def get_detalle(db: AsyncSession, funcion_id: int) -> Funcion | None:
    stmt = (
        select(Funcion)
        .where(Funcion.id == funcion_id)
        .options(
            selectinload(Funcion.pelicula).selectinload(Pelicula.generos),
            selectinload(Funcion.sala),
        )
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def list_funciones(
    db: AsyncSession,
    pelicula_id: int | None = None,
    sala_id: int | None = None,
    fecha: date | None = None,
) -> list[Funcion]:
    stmt = select(Funcion).order_by(Funcion.inicio)
    if pelicula_id is not None:
        stmt = stmt.where(Funcion.pelicula_id == pelicula_id)
    if sala_id is not None:
        stmt = stmt.where(Funcion.sala_id == sala_id)
    if fecha is not None:
        inicio_dia = datetime.combine(fecha, time.min, tzinfo=timezone.utc)
        fin_dia = datetime.combine(fecha, time.max, tzinfo=timezone.utc)
        stmt = stmt.where(Funcion.inicio >= inicio_dia, Funcion.inicio <= fin_dia)
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def add(db: AsyncSession, funcion: Funcion) -> Funcion:
    db.add(funcion)
    await db.flush()
    return funcion


async def add_asiento_funciones(
    db: AsyncSession, filas: list[AsientoFuncion]
) -> None:
    db.add_all(filas)
    await db.flush()


async def list_asiento_funciones(
    db: AsyncSession, funcion_id: int
) -> list[AsientoFuncion]:
    stmt = (
        select(AsientoFuncion)
        .where(AsientoFuncion.funcion_id == funcion_id)
        .options(selectinload(AsientoFuncion.asiento))
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())
