"""Acceso a datos de validaciones de QR."""

from __future__ import annotations

from datetime import date, datetime, time, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.compra import Compra
from app.models.enums import ResultadoValidacion
from app.models.validacion import ValidacionQR


async def add(db: AsyncSession, validacion: ValidacionQR) -> ValidacionQR:
    db.add(validacion)
    await db.flush()
    return validacion


async def count_validas_hoy(db: AsyncSession) -> int:
    hoy = datetime.now(timezone.utc).date()
    inicio = datetime.combine(hoy, time.min, tzinfo=timezone.utc)
    fin = datetime.combine(hoy, time.max, tzinfo=timezone.utc)
    stmt = select(func.count(ValidacionQR.id)).where(
        ValidacionQR.resultado == ResultadoValidacion.valido,
        ValidacionQR.escaneado_en >= inicio,
        ValidacionQR.escaneado_en <= fin,
    )
    return int((await db.execute(stmt)).scalar_one())


async def list_historial(
    db: AsyncSession,
    funcion_id: int | None = None,
    fecha: date | None = None,
) -> list[ValidacionQR]:
    stmt = select(ValidacionQR).order_by(ValidacionQR.escaneado_en.desc())
    if fecha is not None:
        inicio = datetime.combine(fecha, time.min, tzinfo=timezone.utc)
        fin = datetime.combine(fecha, time.max, tzinfo=timezone.utc)
        stmt = stmt.where(
            ValidacionQR.escaneado_en >= inicio, ValidacionQR.escaneado_en <= fin
        )
    if funcion_id is not None:
        # Filtra por la función a través de la compra asociada.
        stmt = stmt.join(Compra, ValidacionQR.compra_id == Compra.id).where(
            Compra.funcion_id == funcion_id
        )
    result = await db.execute(stmt)
    return list(result.scalars().all())
