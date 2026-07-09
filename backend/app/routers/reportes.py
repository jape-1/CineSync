"""Rutas de reportes (admin): ventas y ocupación."""

from datetime import date
from typing import Annotated

from fastapi import APIRouter, Depends, Query

from app.core.security import require_admin
from app.deps import DbDep
from app.schemas.reporte import OcupacionReporte, VentasReporte
from app.services import reporte as reporte_service

router = APIRouter(
    prefix="/reportes", tags=["reportes"], dependencies=[Depends(require_admin)]
)


@router.get("/ventas", response_model=VentasReporte)
async def ventas(
    db: DbDep,
    fecha: Annotated[date | None, Query()] = None,
    funcion_id: Annotated[int | None, Query()] = None,
    sala_id: Annotated[int | None, Query()] = None,
) -> VentasReporte:
    return await reporte_service.ventas(db, fecha, funcion_id, sala_id)


@router.get("/ocupacion", response_model=OcupacionReporte)
async def ocupacion(
    db: DbDep,
    fecha: Annotated[date | None, Query()] = None,
    funcion_id: Annotated[int | None, Query()] = None,
    sala_id: Annotated[int | None, Query()] = None,
) -> OcupacionReporte:
    return await reporte_service.ocupacion(db, fecha, funcion_id, sala_id)
