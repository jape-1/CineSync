"""Promociones / códigos de descuento."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    DateTime,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.enums import TipoDescuento, pg_enum


class Promocion(Base):
    __tablename__ = "promociones"

    id: Mapped[int] = mapped_column(primary_key=True)
    codigo: Mapped[str] = mapped_column(String(40), unique=True, index=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    tipo_descuento: Mapped[TipoDescuento] = mapped_column(
        pg_enum(TipoDescuento, 16),
        nullable=False,
    )
    valor: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    activo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    valido_desde: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    valido_hasta: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    usos_maximos: Mapped[int | None] = mapped_column(Integer, nullable=True)
    usos_actuales: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
