"""Rutas de validación de QR (trabajador / admin)."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.core.security import CurrentUser, require_trabajador
from app.deps import DbDep
from app.schemas.validacion import (
    ValidacionHistorialItem,
    ValidacionRequest,
    ValidacionResponse,
)
from app.services import validacion as validacion_service

router = APIRouter(prefix="/validaciones", tags=["validaciones"])

TrabajadorDep = Annotated[CurrentUser, Depends(require_trabajador)]


@router.post("", response_model=ValidacionResponse)
async def validar(
    data: ValidacionRequest, db: DbDep, user: TrabajadorDep
) -> ValidacionResponse:
    return await validacion_service.validar(db, user.id, data.codigo_escaneado)


@router.get("/historial", response_model=list[ValidacionHistorialItem])
async def historial(
    db: DbDep,
    user: TrabajadorDep,
    funcion_id: Annotated[int | None, Query()] = None,
    fecha: Annotated[date | None, Query()] = None,
) -> list[ValidacionHistorialItem]:
    return await validacion_service.historial(db, funcion_id=funcion_id, fecha=fecha)
