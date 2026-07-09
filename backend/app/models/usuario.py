"""Usuario del sistema (cliente / trabajador / administrador)."""

from __future__ import annotations

from sqlalchemy import Boolean, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin
from app.models.enums import RolUsuario, TurnoTrabajador, pg_enum


class Usuario(Base, TimestampMixin):
    __tablename__ = "usuarios"

    id: Mapped[int] = mapped_column(primary_key=True)
    nombre: Mapped[str] = mapped_column(String(120), nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    rol: Mapped[RolUsuario] = mapped_column(
        pg_enum(RolUsuario, 20),
        default=RolUsuario.cliente,
        nullable=False,
    )
    # Solo aplica a trabajadores; nulo para el resto.
    turno: Mapped[TurnoTrabajador | None] = mapped_column(
        pg_enum(TurnoTrabajador, 20),
        nullable=True,
    )
    activo: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    # Se incrementa en cada logout para invalidar los refresh tokens emitidos.
    token_version: Mapped[int] = mapped_column(
        Integer, default=0, server_default="0", nullable=False
    )

    compras: Mapped[list["Compra"]] = relationship(back_populates="usuario")  # noqa: F821
