"""Servicio de reportes de administración."""

from __future__ import annotations

from datetime import date

from sqlalchemy.ext.asyncio import AsyncSession

from app.repositories import reporte as reporte_repo
from app.schemas.reporte import (
    OcupacionItem,
    OcupacionReporte,
    VentasReporte,
)


async def ventas(
    db: AsyncSession,
    fecha: date | None,
    funcion_id: int | None,
    sala_id: int | None,
) -> VentasReporte:
    data = await reporte_repo.ventas(db, fecha, funcion_id, sala_id)
    return VentasReporte(**data)


async def ocupacion(
    db: AsyncSession,
    fecha: date | None,
    funcion_id: int | None,
    sala_id: int | None,
) -> OcupacionReporte:
    filas = await reporte_repo.ocupacion(db, fecha, funcion_id, sala_id)
    items = [OcupacionItem(**f) for f in filas]
    total = sum(i.total_asientos for i in items)
    ocupados = sum(i.ocupados for i in items)
    global_pct = round(100 * ocupados / total, 1) if total else 0.0
    return OcupacionReporte(items=items, ocupacion_global=global_pct)
