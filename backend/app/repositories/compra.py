"""Acceso a datos de compras."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.compra import Compra, CompraAsiento, CompraProducto
from app.models.enums import EstadoQR
from app.models.funcion import AsientoFuncion, Funcion


def _detalle_options():
    return (
        selectinload(Compra.usuario),
        selectinload(Compra.funcion).selectinload(Funcion.pelicula),
        selectinload(Compra.funcion).selectinload(Funcion.sala),
        selectinload(Compra.asientos)
        .selectinload(CompraAsiento.asiento_funcion)
        .selectinload(AsientoFuncion.asiento),
        selectinload(Compra.productos).selectinload(CompraProducto.producto),
        selectinload(Compra.productos).selectinload(CompraProducto.combo),
    )


async def get(db: AsyncSession, compra_id: int) -> Compra | None:
    stmt = select(Compra).where(Compra.id == compra_id).options(*_detalle_options())
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_by_qr(db: AsyncSession, codigo: str) -> Compra | None:
    stmt = (
        select(Compra).where(Compra.qr_codigo == codigo).options(*_detalle_options())
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def list_by_user(
    db: AsyncSession, user_id: int, estado: EstadoQR | None = None
) -> list[Compra]:
    stmt = (
        select(Compra)
        .where(Compra.usuario_id == user_id)
        .options(*_detalle_options())
        .order_by(Compra.creado_en.desc())
    )
    if estado is not None:
        stmt = stmt.where(Compra.qr_estado == estado)
    result = await db.execute(stmt)
    return list(result.scalars().unique().all())


async def lock_asiento_funciones(
    db: AsyncSession, funcion_id: int, ids: list[int]
) -> list[AsientoFuncion]:
    """Bloquea (FOR UPDATE) los asiento-función para evitar doble reserva."""
    stmt = (
        select(AsientoFuncion)
        .where(AsientoFuncion.funcion_id == funcion_id, AsientoFuncion.id.in_(ids))
        .with_for_update()
    )
    result = await db.execute(stmt)
    return list(result.scalars().all())


async def add(db: AsyncSession, compra: Compra) -> Compra:
    db.add(compra)
    await db.flush()
    return compra
