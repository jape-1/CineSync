"""Rutas de películas (cartelera pública + gestión admin + import TMDB)."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status

from app.core.security import require_admin
from app.deps import DbDep
from app.schemas.common import MessageResponse
from app.schemas.pelicula import (
    ImportTmdbRequest,
    PeliculaCreate,
    PeliculaRead,
    PeliculaUpdate,
)
from app.services import pelicula as pelicula_service

router = APIRouter(prefix="/peliculas", tags=["peliculas"])


@router.get("", response_model=list[PeliculaRead])
async def listar(
    db: DbDep,
    genero: Annotated[str | None, Query()] = None,
    activa: Annotated[bool | None, Query()] = None,
) -> list[PeliculaRead]:
    peliculas = await pelicula_service.listar(db, genero=genero, activa=activa)
    return [PeliculaRead.model_validate(p) for p in peliculas]


@router.post(
    "/importar-tmdb",
    response_model=PeliculaRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_admin)],
)
async def importar_tmdb(data: ImportTmdbRequest, db: DbDep) -> PeliculaRead:
    pelicula = await pelicula_service.importar_tmdb(db, data)
    return PeliculaRead.model_validate(pelicula)


@router.post(
    "",
    response_model=PeliculaRead,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(require_admin)],
)
async def crear(data: PeliculaCreate, db: DbDep) -> PeliculaRead:
    pelicula = await pelicula_service.crear(db, data)
    return PeliculaRead.model_validate(pelicula)


@router.get("/{pelicula_id}", response_model=PeliculaRead)
async def detalle(pelicula_id: int, db: DbDep) -> PeliculaRead:
    pelicula = await pelicula_service.obtener(db, pelicula_id)
    return PeliculaRead.model_validate(pelicula)


@router.patch(
    "/{pelicula_id}", response_model=PeliculaRead, dependencies=[Depends(require_admin)]
)
async def actualizar(
    pelicula_id: int, data: PeliculaUpdate, db: DbDep
) -> PeliculaRead:
    pelicula = await pelicula_service.actualizar(db, pelicula_id, data)
    return PeliculaRead.model_validate(pelicula)


@router.delete(
    "/{pelicula_id}",
    response_model=MessageResponse,
    dependencies=[Depends(require_admin)],
)
async def archivar(pelicula_id: int, db: DbDep) -> MessageResponse:
    await pelicula_service.archivar(db, pelicula_id)
    return MessageResponse(detail="Película archivada")
