"""Rutas de géneros (solo lectura; se pueblan al importar de TMDB)."""

from fastapi import APIRouter

from app.deps import DbDep
from app.schemas.pelicula import GeneroRead
from app.services import pelicula as pelicula_service

router = APIRouter(prefix="/generos", tags=["generos"])


@router.get("", response_model=list[GeneroRead])
async def listar(db: DbDep) -> list[GeneroRead]:
    generos = await pelicula_service.listar_generos(db)
    return [GeneroRead.model_validate(g) for g in generos]
