"""Schemas de compras (checkout, historial, detalle)."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field, model_validator

from app.models.enums import EstadoQR
from app.schemas.common import ORMModel


class CompraProductoInput(BaseModel):
    producto_id: int | None = None
    combo_id: int | None = None
    cantidad: int = Field(default=1, ge=1)

    @model_validator(mode="after")
    def _uno_u_otro(self) -> "CompraProductoInput":
        if (self.producto_id is None) == (self.combo_id is None):
            raise ValueError("Envía exactamente uno: producto_id o combo_id")
        return self


class CompraCreate(BaseModel):
    funcion_id: int
    # Ids de asiento_funcion (los del snapshot / mapa de asientos).
    asientos: list[int] = Field(min_length=1)
    productos: list[CompraProductoInput] = Field(default_factory=list)
    promocion_codigo: str | None = None


class CompraAsientoRead(BaseModel):
    asiento_funcion_id: int
    fila: str
    numero: int


class CompraProductoRead(ORMModel):
    id: int
    producto_id: int | None = None
    combo_id: int | None = None
    nombre: str
    cantidad: int
    precio_unitario: Decimal


class FuncionResumen(BaseModel):
    id: int
    inicio: datetime
    fin: datetime
    pelicula_titulo: str
    sala_nombre: str


class CompraRead(BaseModel):
    id: int
    funcion: FuncionResumen
    asientos: list[CompraAsientoRead]
    productos: list[CompraProductoRead]
    subtotal: Decimal
    descuento: Decimal
    total: Decimal
    qr_codigo: str
    qr_estado: EstadoQR
    creado_en: datetime
    usado_en: datetime | None = None
