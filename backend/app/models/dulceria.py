"""Dulcería: productos individuales, combos y su composición."""

from __future__ import annotations

from decimal import Decimal

from sqlalchemy import (
    Boolean,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base


class Producto(Base):
    __tablename__ = "productos"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    precio: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    imagen_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    categoria: Mapped[str | None] = mapped_column(String(60), nullable=True)
    activo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    combos: Mapped[list["Combo"]] = relationship(
        secondary="combo_productos", back_populates="productos"
    )


class Combo(Base):
    __tablename__ = "combos"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(Text, nullable=True)
    precio: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    imagen_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    activo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)

    productos: Mapped[list[Producto]] = relationship(
        secondary="combo_productos", back_populates="combos"
    )
    items: Mapped[list["ComboProducto"]] = relationship(
        back_populates="combo",
        cascade="all, delete-orphan",
        overlaps="productos,combos",
    )


class ComboProducto(Base):
    __tablename__ = "combo_productos"

    combo_id: Mapped[int] = mapped_column(
        ForeignKey("combos.id", ondelete="CASCADE"), primary_key=True
    )
    producto_id: Mapped[int] = mapped_column(
        ForeignKey("productos.id", ondelete="RESTRICT"), primary_key=True
    )
    cantidad: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    combo: Mapped[Combo] = relationship(
        back_populates="items", overlaps="productos,combos"
    )
    producto: Mapped[Producto] = relationship(overlaps="productos,combos")
