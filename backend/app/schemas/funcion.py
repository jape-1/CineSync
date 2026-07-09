"""Schemas de funciones (proyecciones)."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.enums import EstadoAsientoFuncion, TipoAsiento
from app.schemas.common import ORMModel
from app.schemas.pelicula import PeliculaRead
from app.schemas.sala import SalaRead


class AsientoMapaItem(BaseModel):
    """Estado de un asiento dentro de una función (snapshot para el cliente)."""

    asiento_funcion_id: int
    asiento_id: int
    fila: str
    numero: int
    tipo: TipoAsiento
    estado: EstadoAsientoFuncion
    reservado_hasta: datetime | None = None


class FuncionRead(ORMModel):
    id: int
    pelicula_id: int
    sala_id: int
    inicio: datetime
    fin: datetime
    precio_base: Decimal
    idioma: str | None = None
    formato: str | None = None


class FuncionDetalle(FuncionRead):
    pelicula: PeliculaRead
    sala: SalaRead


class FuncionCreate(BaseModel):
    pelicula_id: int
    sala_id: int
    inicio: datetime
    # Si no se envía, se calcula con la duración de la película (o 120 min).
    fin: datetime | None = None
    precio_base: Decimal = Field(ge=0)
    idioma: str | None = None
    formato: str | None = None


class FuncionUpdate(BaseModel):
    inicio: datetime | None = None
    fin: datetime | None = None
    precio_base: Decimal | None = Field(default=None, ge=0)
    idioma: str | None = None
    formato: str | None = None
