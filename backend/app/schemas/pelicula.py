"""Schemas de películas y géneros."""

from datetime import date

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class GeneroRead(ORMModel):
    id: int
    nombre: str
    tmdb_id: int | None = None


class PeliculaRead(ORMModel):
    id: int
    tmdb_id: int | None = None
    titulo: str
    sinopsis: str | None = None
    poster_url: str | None = None
    backdrop_url: str | None = None
    duracion_min: int | None = None
    clasificacion: str | None = None
    fecha_estreno: date | None = None
    calificacion: float | None = None
    activa: bool
    generos: list[GeneroRead] = []


class PeliculaCreate(BaseModel):
    titulo: str = Field(min_length=1, max_length=255)
    sinopsis: str | None = None
    poster_url: str | None = None
    backdrop_url: str | None = None
    duracion_min: int | None = Field(default=None, ge=1)
    clasificacion: str | None = None
    fecha_estreno: date | None = None
    calificacion: float | None = Field(default=None, ge=0, le=10)
    # Ids de géneros ya existentes en la BD.
    generos: list[int] = []


class PeliculaUpdate(BaseModel):
    titulo: str | None = Field(default=None, min_length=1, max_length=255)
    sinopsis: str | None = None
    poster_url: str | None = None
    backdrop_url: str | None = None
    duracion_min: int | None = Field(default=None, ge=1)
    clasificacion: str | None = None
    fecha_estreno: date | None = None
    calificacion: float | None = Field(default=None, ge=0, le=10)
    activa: bool | None = None
    generos: list[int] | None = None


class ImportTmdbRequest(BaseModel):
    """Importa desde TMDB por id directo o por búsqueda de título."""

    tmdb_id: int | None = None
    titulo: str | None = None
