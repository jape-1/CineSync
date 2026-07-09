"""Salas y sus asientos físicos."""

from __future__ import annotations

from sqlalchemy import (
    Boolean,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import TipoAsiento, TipoSala, pg_enum


class Sala(Base):
    __tablename__ = "salas"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(80), nullable=False)
    tipo: Mapped[TipoSala] = mapped_column(
        pg_enum(TipoSala, 8),
        default=TipoSala.dosd,
        nullable=False,
    )
    filas: Mapped[int] = mapped_column(Integer, nullable=False)
    columnas: Mapped[int] = mapped_column(Integer, nullable=False)
    activa: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    asientos: Mapped[list["Asiento"]] = relationship(
        back_populates="sala", cascade="all, delete-orphan"
    )
    funciones: Mapped[list["Funcion"]] = relationship(back_populates="sala")  # noqa: F821


class Asiento(Base):
    __tablename__ = "asientos"
    __table_args__ = (
        UniqueConstraint("sala_id", "fila", "numero", name="uq_asiento_sala_fila_numero"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    sala_id: Mapped[int] = mapped_column(
        ForeignKey("salas.id", ondelete="CASCADE"), nullable=False, index=True
    )
    fila: Mapped[str] = mapped_column(String(4), nullable=False)
    numero: Mapped[int] = mapped_column(Integer, nullable=False)
    tipo: Mapped[TipoAsiento] = mapped_column(
        pg_enum(TipoAsiento, 20),
        default=TipoAsiento.normal,
        nullable=False,
    )

    sala: Mapped[Sala] = relationship(back_populates="asientos")
