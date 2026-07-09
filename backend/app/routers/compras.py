"""Rutas de compras (checkout, historial, detalle, cancelación)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.core.security import CurrentUser, CurrentUserDep, require_cliente
from app.deps import DbDep
from app.models.enums import EstadoQR
from app.schemas.compra import CompraCreate, CompraRead
from app.services import compra as compra_service

router = APIRouter(prefix="/compras", tags=["compras"])

ClienteDep = Annotated[CurrentUser, Depends(require_cliente)]


@router.post("", response_model=CompraRead, status_code=status.HTTP_201_CREATED)
async def crear(data: CompraCreate, db: DbDep, user: ClienteDep) -> CompraRead:
    return await compra_service.crear(db, user.id, data)


@router.get("", response_model=list[CompraRead])
async def historial(
    db: DbDep,
    user: ClienteDep,
    estado: Annotated[EstadoQR | None, Query()] = None,
) -> list[CompraRead]:
    return await compra_service.historial(db, user.id, estado)


@router.get("/{compra_id}", response_model=CompraRead)
async def detalle(compra_id: int, db: DbDep, user: CurrentUserDep) -> CompraRead:
    return await compra_service.detalle(db, compra_id, user.id, user.rol)


@router.post("/{compra_id}/cancelar", response_model=CompraRead)
async def cancelar(compra_id: int, db: DbDep, user: ClienteDep) -> CompraRead:
    return await compra_service.cancelar(db, compra_id, user.id)
