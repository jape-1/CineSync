"""Rutas de combos (listado público, gestión admin)."""

from fastapi import APIRouter, Depends, status

from app.core.security import require_admin
from app.deps import DbDep
from app.schemas.dulceria import ComboCreate, ComboRead, ComboUpdate
from app.services import dulceria as dulceria_service

router = APIRouter(prefix="/combos", tags=["combos"])


@router.get("", response_model=list[ComboRead])
async def listar(db: DbDep) -> list[ComboRead]:
    combos = await dulceria_service.listar_combos(db)
    return [ComboRead.model_validate(c) for c in combos]


@router.post(
    "",
    response_model=ComboRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_admin)],
)
async def crear(data: ComboCreate, db: DbDep) -> ComboRead:
    combo = await dulceria_service.crear_combo(db, data)
    return ComboRead.model_validate(combo)


@router.patch(
    "/{combo_id}", response_model=ComboRead, dependencies=[Depends(require_admin)]
)
async def actualizar(combo_id: int, data: ComboUpdate, db: DbDep) -> ComboRead:
    combo = await dulceria_service.actualizar_combo(db, combo_id, data)
    return ComboRead.model_validate(combo)
