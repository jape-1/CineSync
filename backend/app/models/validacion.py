"""Auditoría de cada escaneo de QR por parte del trabajador."""

from __future__ import annotations

from datetime import datetime

from sqlalchemy import (
    DateTime,
    ForeignKey,
    String,
    func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import ResultadoValidacion, pg_enum


class ValidacionQR(Base):
    __tablename__ = "validaciones_qr"

    id: Mapped[int] = mapped_column(primary_key=True)
    # Nulo cuando el código escaneado no corresponde a ninguna compra.
    compra_id: Mapped[int | None] = mapped_column(
        ForeignKey("compras.id", ondelete="SET NULL"), nullable=True, index=True
    )
    trabajador_id: Mapped[int] = mapped_column(
        ForeignKey("usuarios.id", ondelete="RESTRICT"), nullable=False, index=True
    )
    codigo_escaneado: Mapped[str] = mapped_column(String(512), nullable=False)
    resultado: Mapped[ResultadoValidacion] = mapped_column(
        pg_enum(ResultadoValidacion, 16),
        nullable=False,
    )
    escaneado_en: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), nullable=False
    )

    compra: Mapped["Compra | None"] = relationship()  # noqa: F821
    trabajador: Mapped["Usuario"] = relationship()  # noqa: F821
