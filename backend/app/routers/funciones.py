"""Rutas de funciones (cartelera pública + gestión admin + snapshot de asientos)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.core.security import get_current_user, require_admin
from app.deps import DbDep
from app.schemas.common import MessageResponse
from app.schemas.funcion import (
    AsientoMapaItem,
    FuncionCreate,
    FuncionDetalle,
    FuncionRead,
    FuncionUpdate,
)
from app.services import funcion as funcion_service

router = APIRouter(prefix="/funciones", tags=["funciones"])


@router.get("", response_model=list[FuncionRead])
async def listar(
    db: DbDep,
    pelicula_id: Annotated[int | None, Query()] = None,
    sala_id: Annotated[int | None, Query()] = None,
    fecha: Annotated[date | None, Query()] = None,
) -> list[FuncionRead]:
    funciones = await funcion_service.listar(
        db, pelicula_id=pelicula_id, sala_id=sala_id, fecha=fecha
    )
    return [FuncionRead.model_validate(f) for f in funciones]


@router.post(
    "",
    response_model=FuncionDetalle,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_admin)],
)
async def crear(data: FuncionCreate, db: DbDep) -> FuncionDetalle:
    funcion = await funcion_service.crear(db, data)
    return FuncionDetalle.model_validate(funcion)


@router.get("/{funcion_id}", response_model=FuncionDetalle)
async def detalle(funcion_id: int, db: DbDep) -> FuncionDetalle:
    funcion = await funcion_service.obtener_detalle(db, funcion_id)
    return FuncionDetalle.model_validate(funcion)


@router.get(
    "/{funcion_id}/asientos",
    response_model=list[AsientoMapaItem],
    dependencies=[Depends(get_current_user)],
)
async def snapshot_asientos(funcion_id: int, db: DbDep) -> list[AsientoMapaItem]:
    items = await funcion_service.snapshot_asientos(db, funcion_id)
    return [AsientoMapaItem.model_validate(i) for i in items]


@router.patch(
    "/{funcion_id}", response_model=FuncionDetalle, dependencies=[Depends(require_admin)]
)
async def actualizar(
    funcion_id: int, data: FuncionUpdate, db: DbDep
) -> FuncionDetalle:
    funcion = await funcion_service.actualizar(db, funcion_id, data)
    return FuncionDetalle.model_validate(funcion)


@router.delete(
    "/{funcion_id}",
    response_model=MessageResponse,
    dependencies=[Depends(require_admin)],
)
async def eliminar(funcion_id: int, db: DbDep) -> MessageResponse:
    await funcion_service.eliminar(db, funcion_id)
    return MessageResponse(detail="Función cancelada")
