"""Queries agregadas para reportes (sin tablas de agregación, según el PRD)."""

from __future__ import annotations

from datetime import date, datetime, time, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.compra import Compra, CompraAsiento
from app.models.enums import EstadoAsientoFuncion, EstadoQR
from app.models.funcion import AsientoFuncion, Funcion
from app.models.pelicula import Pelicula
from app.models.sala import Sala


def _rango_dia(fecha: date) -> tuple[datetime, datetime]:
    return (
        datetime.combine(fecha, time.min, tzinfo=timezone.utc),
        datetime.combine(fecha, time.max, tzinfo=timezone.utc),
    )


def _filtros_compra(fecha, funcion_id, sala_id):
    condiciones = [Compra.qr_estado != EstadoQR.cancelado]
    if funcion_id is not None:
        condiciones.append(Compra.funcion_id == funcion_id)
    if sala_id is not None:
        condiciones.append(Funcion.sala_id == sala_id)
    if fecha is not None:
        ini, fin = _rango_dia(fecha)
        condiciones.append(Funcion.inicio >= ini)
        condiciones.append(Funcion.inicio <= fin)
    return condiciones


async def ventas(
    db: AsyncSession,
    fecha: date | None = None,
    funcion_id: int | None = None,
    sala_id: int | None = None,
) -> dict:
    condiciones = _filtros_compra(fecha, funcion_id, sala_id)

    stmt = (
        select(func.count(Compra.id), func.coalesce(func.sum(Compra.total), 0))
        .join(Funcion, Funcion.id == Compra.funcion_id)
        .where(*condiciones)
    )
    num_compras, total = (await db.execute(stmt)).one()

    stmt_ent = (
        select(func.count(CompraAsiento.compra_id))
        .join(Compra, Compra.id == CompraAsiento.compra_id)
        .join(Funcion, Funcion.id == Compra.funcion_id)
        .where(*condiciones)
    )
    num_entradas = (await db.execute(stmt_ent)).scalar_one()

    return {
        "num_compras": int(num_compras),
        "num_entradas": int(num_entradas),
        "total_recaudado": Decimal(total),
    }


async def ocupacion(
    db: AsyncSession,
    fecha: date | None = None,
    funcion_id: int | None = None,
    sala_id: int | None = None,
) -> list[dict]:
    ocupados_expr = func.count(AsientoFuncion.id).filter(
        AsientoFuncion.estado == EstadoAsientoFuncion.ocupado
    )
    stmt = (
        select(
            Funcion.id,
            Pelicula.titulo,
            Sala.nombre,
            Funcion.inicio,
            func.count(AsientoFuncion.id).label("total"),
            ocupados_expr.label("ocupados"),
        )
        .join(Pelicula, Pelicula.id == Funcion.pelicula_id)
        .join(Sala, Sala.id == Funcion.sala_id)
        .join(AsientoFuncion, AsientoFuncion.funcion_id == Funcion.id)
        .group_by(Funcion.id, Pelicula.titulo, Sala.nombre, Funcion.inicio)
        .order_by(Funcion.inicio)
    )
    if funcion_id is not None:
        stmt = stmt.where(Funcion.id == funcion_id)
    if sala_id is not None:
        stmt = stmt.where(Funcion.sala_id == sala_id)
    if fecha is not None:
        ini, fin = _rango_dia(fecha)
        stmt = stmt.where(Funcion.inicio >= ini, Funcion.inicio <= fin)

    filas = (await db.execute(stmt)).all()
    return [
        {
            "funcion_id": f.id,
            "pelicula_titulo": f.titulo,
            "sala_nombre": f.nombre,
            "inicio": f.inicio,
            "total_asientos": int(f.total),
            "ocupados": int(f.ocupados),
            "porcentaje": round(100 * f.ocupados / f.total, 1) if f.total else 0.0,
        }
        for f in filas
    ]
