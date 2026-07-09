"""Schemas de validación de QR por el trabajador."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel

from app.models.enums import ResultadoValidacion


class ValidacionRequest(BaseModel):
    codigo_escaneado: str


class TicketInfo(BaseModel):
    compra_id: int
    pelicula_titulo: str
    sala_nombre: str
    inicio: datetime
    asientos: list[str]  # p. ej. ["A1", "A2"]
    cliente_nombre: str


class ValidacionResponse(BaseModel):
    resultado: ResultadoValidacion
    motivo: str | None = None
    ticket: TicketInfo | None = None


class ValidacionHistorialItem(BaseModel):
    id: int
    compra_id: int | None
    resultado: ResultadoValidacion
    codigo_escaneado: str
    escaneado_en: datetime
    trabajador_id: int
