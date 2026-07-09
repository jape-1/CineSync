"""Schemas de salas y asientos."""

from pydantic import BaseModel, Field

from app.models.enums import TipoAsiento, TipoSala
from app.schemas.common import ORMModel


class AsientoRead(ORMModel):
    id: int
    fila: str
    numero: int
    tipo: TipoAsiento


class SalaRead(ORMModel):
    id: int
    nombre: str
    tipo: TipoSala
    filas: int
    columnas: int
    activa: bool


class SalaCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=80)
    tipo: TipoSala = TipoSala.dosd
    filas: int = Field(ge=1, le=26)  # A..Z
    columnas: int = Field(ge=1, le=60)


class SalaUpdate(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=80)
    tipo: TipoSala | None = None
    activa: bool | None = None
