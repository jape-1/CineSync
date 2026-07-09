"""Rutas de promociones (validación para cliente, gestión admin)."""

from fastapi import APIRouter, Depends, status

from app.core.security import require_admin, require_cliente
from app.deps import DbDep
from app.schemas.promocion import (
    PromocionCreate,
    PromocionRead,
    PromocionUpdate,
    PromocionValidacionResponse,
)
from app.services import promocion as promocion_service

router = APIRouter(prefix="/promociones", tags=["promociones"])


@router.get(
    "/validar/{codigo}",
    response_model=PromocionValidacionResponse,
    dependencies=[Depends(require_cliente)],
)
async def validar(codigo: str, db: DbDep) -> PromocionValidacionResponse:
    return await promocion_service.validar(db, codigo)


@router.get(
    "", response_model=list[PromocionRead], dependencies=[Depends(require_admin)]
)
async def listar(db: DbDep) -> list[PromocionRead]:
    promociones = await promocion_service.listar(db)
    return [PromocionRead.model_validate(p) for p in promociones]


@router.post(
    "",
    response_model=PromocionRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_admin)],
)
async def crear(data: PromocionCreate, db: DbDep) -> PromocionRead:
    promocion = await promocion_service.crear(db, data)
    return PromocionRead.model_validate(promocion)


@router.patch(
    "/{promocion_id}", response_model=PromocionRead, dependencies=[Depends(require_admin)]
)
async def actualizar(
    promocion_id: int, data: PromocionUpdate, db: DbDep
) -> PromocionRead:
    promocion = await promocion_service.actualizar(db, promocion_id, data)
    return PromocionRead.model_validate(promocion)
