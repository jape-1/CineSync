"""Lógica de promociones y validación de códigos."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.promocion import Promocion
from app.repositories import promocion as promocion_repo
from app.schemas.promocion import (
    PromocionCreate,
    PromocionUpdate,
    PromocionValidacionResponse,
)


async def listar(db: AsyncSession) -> list[Promocion]:
    return await promocion_repo.list_promociones(db)


async def crear(db: AsyncSession, data: PromocionCreate) -> Promocion:
    if await promocion_repo.get_by_codigo(db, data.codigo):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe una promoción con ese código",
        )
    promocion = Promocion(**data.model_dump(), usos_actuales=0)
    await promocion_repo.add(db, promocion)
    await db.commit()
    await db.refresh(promocion)
    return promocion


async def actualizar(
    db: AsyncSession, promocion_id: int, data: PromocionUpdate
) -> Promocion:
    promocion = await promocion_repo.get(db, promocion_id)
    if promocion is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Promoción no encontrada")
    for campo, valor in data.model_dump(exclude_unset=True).items():
        setattr(promocion, campo, valor)
    await db.commit()
    await db.refresh(promocion)
    return promocion


def _motivo_invalidez(promocion: Promocion | None) -> str | None:
    if promocion is None:
        return "El código no existe"
    if not promocion.activo:
        return "La promoción está inactiva"
    ahora = datetime.now(timezone.utc)
    if promocion.valido_desde and ahora < promocion.valido_desde:
        return "La promoción aún no está vigente"
    if promocion.valido_hasta and ahora > promocion.valido_hasta:
        return "La promoción ya venció"
    if (
        promocion.usos_maximos is not None
        and promocion.usos_actuales >= promocion.usos_maximos
    ):
        return "La promoción alcanzó su límite de usos"
    return None


async def validar(db: AsyncSession, codigo: str) -> PromocionValidacionResponse:
    promocion = await promocion_repo.get_by_codigo(db, codigo)
    motivo = _motivo_invalidez(promocion)
    if motivo is not None:
        return PromocionValidacionResponse(codigo=codigo, valido=False, motivo=motivo)
    assert promocion is not None
    return PromocionValidacionResponse(
        codigo=codigo,
        valido=True,
        tipo_descuento=promocion.tipo_descuento,
        valor=promocion.valor,
        descripcion=promocion.descripcion,
    )
