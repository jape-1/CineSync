"""Acceso a datos de productos y combos."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.dulceria import Combo, ComboProducto, Producto


# --- Productos ---


async def get_producto(db: AsyncSession, producto_id: int) -> Producto | None:
    return await db.get(Producto, producto_id)


async def list_productos(db: AsyncSession) -> list[Producto]:
    result = await db.execute(select(Producto).order_by(Producto.id))
    return list(result.scalars().all())


async def add_producto(db: AsyncSession, producto: Producto) -> Producto:
    db.add(producto)
    await db.flush()
    return producto


# --- Combos ---


async def get_combo(db: AsyncSession, combo_id: int) -> Combo | None:
    stmt = (
        select(Combo)
        .where(Combo.id == combo_id)
        .options(selectinload(Combo.items))
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def list_combos(db: AsyncSession) -> list[Combo]:
    stmt = select(Combo).options(selectinload(Combo.items)).order_by(Combo.id)
    result = await db.execute(stmt)
    return list(result.scalars().unique().all())


async def add_combo(db: AsyncSession, combo: Combo) -> Combo:
    db.add(combo)
    await db.flush()
    return combo


async def replace_combo_items(
    db: AsyncSession, combo: Combo, items: list[ComboProducto]
) -> None:
    combo.items.clear()
    await db.flush()
    for item in items:
        item.combo_id = combo.id
        db.add(item)
    await db.flush()
