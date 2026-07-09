"""Schemas de reportes de administración."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel


class VentasReporte(BaseModel):
    num_compras: int
    num_entradas: int
    total_recaudado: Decimal


class OcupacionItem(BaseModel):
    funcion_id: int
    pelicula_titulo: str
    sala_nombre: str
    inicio: datetime
    total_asientos: int
    ocupados: int
    porcentaje: float


class OcupacionReporte(BaseModel):
    items: list[OcupacionItem]
    ocupacion_global: float
