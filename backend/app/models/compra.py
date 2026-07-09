"""Compra (un QR por compra) y sus líneas de asientos y productos."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import TYPE_CHECKING

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin
from app.models.enums import EstadoQR, pg_enum

if TYPE_CHECKING:
    from app.models.dulceria import Combo, Producto


class Compra(Base, TimestampMixin):
    __tablename__ = "compras"

    id: Mapped[int] = mapped_column(primary_key=True)
    usuario_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    funcion_id: Mapped[int] = mapped_column(
        ForeignKey("funciones.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    promocion_id: Mapped[int | None] = mapped_column(
        ForeignKey("promociones.id", ondelete="SET NULL"), nullable=True
    )
    subtotal: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    descuento: Mapped[Decimal] = mapped_column(
        Numeric(10, 2), default=Decimal("0"), nullable=False
    )
    total: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)

    # Un solo QR agrupa todos los asientos de la compra.
    qr_codigo: Mapped[str] = mapped_column(
        String(512), unique=True, index=True, nullable=False
    )
    qr_estado: Mapped[EstadoQR] = mapped_column(
        pg_enum(EstadoQR, 16),
        default=EstadoQR.activo,
        nullable=False,
    )
    usado_en: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    usuario: Mapped["Usuario"] = relationship(back_populates="compras")  # noqa: F821
    funcion: Mapped["Funcion"] = relationship()  # noqa: F821
    promocion: Mapped["Promocion | None"] = relationship()  # noqa: F821
    asientos: Mapped[list["CompraAsiento"]] = relationship(
        back_populates="compra", cascade="all, delete-orphan"
    )
    productos: Mapped[list["CompraProducto"]] = relationship(
        back_populates="compra", cascade="all, delete-orphan"
    )


class CompraAsiento(Base):
    """M:N entre una compra y los asientos (por función) que reserva."""

    __tablename__ = "compra_asientos"

    compra_id: Mapped[int] = mapped_column(
        ForeignKey("compras.id", ondelete="CASCADE"), primary_key=True
    )
    asiento_funcion_id: Mapped[int] = mapped_column(
        ForeignKey("asiento_funciones.id", ondelete="RESTRICT"), primary_key=True
    )

    compra: Mapped[Compra] = relationship(back_populates="asientos")
    asiento_funcion: Mapped["AsientoFuncion"] = relationship()  # noqa: F821


class CompraProducto(Base):
    """Línea de dulcería de una compra: producto suelto o combo (uno de los dos)."""

    __tablename__ = "compra_productos"
    __table_args__ = (
        CheckConstraint(
            "(producto_id IS NOT NULL) <> (combo_id IS NOT NULL)",
            name="ck_compra_producto_uno_u_otro",
        ),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    compra_id: Mapped[int] = mapped_column(
        ForeignKey("compras.id", ondelete="CASCADE"), nullable=False, index=True
    )
    producto_id: Mapped[int | None] = mapped_column(
        ForeignKey("productos.id", ondelete="RESTRICT"), nullable=True
    )
    combo_id: Mapped[int | None] = mapped_column(
        ForeignKey("combos.id", ondelete="RESTRICT"), nullable=True
    )
    cantidad: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    precio_unitario: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)

    compra: Mapped[Compra] = relationship(back_populates="productos")
    producto: Mapped["Producto | None"] = relationship()
    combo: Mapped["Combo | None"] = relationship()
