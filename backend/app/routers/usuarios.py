"""Rutas de usuarios: perfil propio y gestión por administrador."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.core.security import CurrentUserDep, require_admin
from app.deps import DbDep
from app.models.enums import RolUsuario
from app.schemas.common import MessageResponse
from app.schemas.usuario import (
    UsuarioAdminUpdate,
    UsuarioCreate,
    UsuarioRead,
    UsuarioUpdateMe,
)
from app.services import usuario as usuario_service

router = APIRouter(prefix="/usuarios", tags=["usuarios"])


@router.get("/me", response_model=UsuarioRead)
async def leer_me(db: DbDep, user: CurrentUserDep) -> UsuarioRead:
    usuario = await usuario_service.get_me(db, user.id)
    return UsuarioRead.model_validate(usuario)


@router.patch("/me", response_model=UsuarioRead)
async def actualizar_me(
    data: UsuarioUpdateMe, db: DbDep, user: CurrentUserDep
) -> UsuarioRead:
    usuario = await usuario_service.update_me(db, user.id, data)
    return UsuarioRead.model_validate(usuario)


@router.get("", response_model=list[UsuarioRead], dependencies=[Depends(require_admin)])
async def listar(
    db: DbDep, rol: Annotated[RolUsuario | None, Query()] = None
) -> list[UsuarioRead]:
    usuarios = await usuario_service.listar(db, rol)
    return [UsuarioRead.model_validate(u) for u in usuarios]


@router.post(
    "",
    response_model=UsuarioRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_admin)],
)
async def crear(data: UsuarioCreate, db: DbDep) -> UsuarioRead:
    usuario = await usuario_service.crear(db, data)
    return UsuarioRead.model_validate(usuario)


@router.patch(
    "/{usuario_id}", response_model=UsuarioRead, dependencies=[Depends(require_admin)]
)
async def actualizar(
    usuario_id: int, data: UsuarioAdminUpdate, db: DbDep
) -> UsuarioRead:
    usuario = await usuario_service.actualizar(db, usuario_id, data)
    return UsuarioRead.model_validate(usuario)


@router.delete(
    "/{usuario_id}",
    response_model=MessageResponse,
    dependencies=[Depends(require_admin)],
)
async def desactivar(usuario_id: int, db: DbDep) -> MessageResponse:
    await usuario_service.desactivar(db, usuario_id)
    return MessageResponse(detail="Usuario desactivado")
