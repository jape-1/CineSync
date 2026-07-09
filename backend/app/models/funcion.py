"""Funciones (proyecciones) y el estado en tiempo real de cada asiento.

La restricción anti-solapamiento vive en la migración (EXCLUDE USING gist sobre
`sala_id` y el rango `tstzrange(inicio, fin)`), que requiere la extensión
`btree_gist`. Aquí se declara como comentario para mantener el modelo alineado.
"""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import (
    DateTime,
    ForeignKey,
    Numeric,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import EstadoAsientoFuncion, pg_enum


class Funcion(Base):
    __tablename__ = "funciones"

    id: Mapped[int] = mapped_column(primary_key=True)
    pelicula_id: Mapped[int] = mapped_column(
        ForeignKey("peliculas.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    sala_id: Mapped[int] = mapped_column(
        ForeignKey("salas.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    inicio: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    fin: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    precio_base: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    idioma: Mapped[str | None] = mapped_column(String(40), nullable=True)
    formato: Mapped[str | None] = mapped_column(String(16), nullable=True)

    pelicula: Mapped["Pelicula"] = relationship(back_populates="funciones")  # noqa: F821
    sala: Mapped["Sala"] = relationship(back_populates="funciones")  # noqa: F821
    asientos_funcion: Mapped[list["AsientoFuncion"]] = relationship(
        back_populates="funcion", cascade="all, delete-orphan"
    )


class AsientoFuncion(Base):
    """Estado en vivo de un asiento dentro de una función concreta."""

    __tablename__ = "asiento_funciones"
    __table_args__ = (
        UniqueConstraint("funcion_id", "asiento_id", name="uq_asiento_funcion"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    funcion_id: Mapped[int] = mapped_column(
        ForeignKey("funciones.id", ondelete="CASCADE"), nullable=False, index=True
    )
    asiento_id: Mapped[int] = mapped_column(
        ForeignKey("asientos.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    estado: Mapped[EstadoAsientoFuncion] = mapped_column(
        pg_enum(EstadoAsientoFuncion, 24),
        default=EstadoAsientoFuncion.libre,
        nullable=False,
    )
    # Bloqueo temporal (TTL): quién lo tiene y hasta cuándo.
    reservado_por: Mapped[int | None] = mapped_column(
        ForeignKey("usuarios.id", ondelete="SET NULL"), nullable=True
    )
    reservado_hasta: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    funcion: Mapped[Funcion] = relationship(back_populates="asientos_funcion")
    asiento: Mapped["Asiento"] = relationship()  # noqa: F821
