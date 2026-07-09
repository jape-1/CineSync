"""Lógica de productos y combos."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.dulceria import Combo, ComboProducto, Producto
from app.repositories import dulceria as dulceria_repo
from app.schemas.dulceria import (
    ComboCreate,
    ComboUpdate,
    ProductoCreate,
    ProductoUpdate,
)


# --- Productos ---


async def listar_productos(db: AsyncSession) -> list[Producto]:
    return await dulceria_repo.list_productos(db)


async def obtener_producto(db: AsyncSession, producto_id: int) -> Producto:
    producto = await dulceria_repo.get_producto(db, producto_id)
    if producto is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Producto no encontrado")
    return producto


async def crear_producto(db: AsyncSession, data: ProductoCreate) -> Producto:
    producto = Producto(**data.model_dump(), activo=True)
    await dulceria_repo.add_producto(db, producto)
    await db.commit()
    await db.refresh(producto)
    return producto


async def actualizar_producto(
    db: AsyncSession, producto_id: int, data: ProductoUpdate
) -> Producto:
    producto = await obtener_producto(db, producto_id)
    for campo, valor in data.model_dump(exclude_unset=True).items():
        setattr(producto, campo, valor)
    await db.commit()
    await db.refresh(producto)
    return producto


# --- Combos ---


async def _construir_items(
    db: AsyncSession, items_input
) -> list[ComboProducto]:
    items: list[ComboProducto] = []
    for item in items_input:
        producto = await dulceria_repo.get_producto(db, item.producto_id)
        if producto is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"El producto {item.producto_id} no existe",
            )
        items.append(
            ComboProducto(producto_id=item.producto_id, cantidad=item.cantidad)
        )
    return items


async def listar_combos(db: AsyncSession) -> list[Combo]:
    return await dulceria_repo.list_combos(db)


async def obtener_combo(db: AsyncSession, combo_id: int) -> Combo:
    combo = await dulceria_repo.get_combo(db, combo_id)
    if combo is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Combo no encontrado")
    return combo


async def crear_combo(db: AsyncSession, data: ComboCreate) -> Combo:
    combo = Combo(
        nombre=data.nombre,
        descripcion=data.descripcion,
        precio=data.precio,
        imagen_url=data.imagen_url,
        activo=True,
        items=await _construir_items(db, data.items),
    )
    await dulceria_repo.add_combo(db, combo)
    await db.commit()
    return await obtener_combo(db, combo.id)


async def actualizar_combo(
    db: AsyncSession, combo_id: int, data: ComboUpdate
) -> Combo:
    combo = await obtener_combo(db, combo_id)
    campos = data.model_dump(exclude_unset=True)
    items_input = campos.pop("items", None)
    for campo, valor in campos.items():
        setattr(combo, campo, valor)
    if items_input is not None:
        nuevos = await _construir_items(db, data.items)
        await dulceria_repo.replace_combo_items(db, combo, nuevos)
    await db.commit()
    return await obtener_combo(db, combo.id)
