"""Schemas de promociones."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.enums import TipoDescuento
from app.schemas.common import ORMModel


class PromocionRead(ORMModel):
    id: int
    codigo: str
    descripcion: str | None = None
    tipo_descuento: TipoDescuento
    valor: Decimal
    activo: bool
    valido_desde: datetime | None = None
    valido_hasta: datetime | None = None
    usos_maximos: int | None = None
    usos_actuales: int


class PromocionCreate(BaseModel):
    codigo: str = Field(min_length=1, max_length=40)
    descripcion: str | None = None
    tipo_descuento: TipoDescuento
    valor: Decimal = Field(ge=0)
    activo: bool = True
    valido_desde: datetime | None = None
    valido_hasta: datetime | None = None
    usos_maximos: int | None = Field(default=None, ge=1)


class PromocionUpdate(BaseModel):
    descripcion: str | None = None
    tipo_descuento: TipoDescuento | None = None
    valor: Decimal | None = Field(default=None, ge=0)
    activo: bool | None = None
    valido_desde: datetime | None = None
    valido_hasta: datetime | None = None
    usos_maximos: int | None = Field(default=None, ge=1)


class PromocionValidacionResponse(BaseModel):
    codigo: str
    valido: bool
    tipo_descuento: TipoDescuento | None = None
    valor: Decimal | None = None
    descripcion: str | None = None
    motivo: str | None = None
