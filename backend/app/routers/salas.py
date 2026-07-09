"""Rutas de salas (gestión admin)."""

from fastapi import APIRouter, Depends, status

from app.core.security import require_admin
from app.deps import DbDep
from app.schemas.common import MessageResponse
from app.schemas.sala import SalaCreate, SalaRead, SalaUpdate
from app.services import sala as sala_service

router = APIRouter(
    prefix="/salas", tags=["salas"], dependencies=[Depends(require_admin)]
)


@router.get("", response_model=list[SalaRead])
async def listar(db: DbDep) -> list[SalaRead]:
    salas = await sala_service.listar(db)
    return [SalaRead.model_validate(s) for s in salas]


@router.post("", response_model=SalaRead, status_code=status.HTTP_201_CREATED)
async def crear(data: SalaCreate, db: DbDep) -> SalaRead:
    sala = await sala_service.crear(db, data)
    return SalaRead.model_validate(sala)


@router.patch("/{sala_id}", response_model=SalaRead)
async def actualizar(sala_id: int, data: SalaUpdate, db: DbDep) -> SalaRead:
    sala = await sala_service.actualizar(db, sala_id, data)
    return SalaRead.model_validate(sala)


@router.delete("/{sala_id}", response_model=MessageResponse)
async def eliminar(sala_id: int, db: DbDep) -> MessageResponse:
    await sala_service.eliminar(db, sala_id)
    return MessageResponse(detail="Sala eliminada")
