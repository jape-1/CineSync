"""Base declarativa y mixins comunes para todos los modelos."""

from datetime import datetime

from sqlalchemy import func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    """Base declarativa única para el metadata de la app."""


class TimestampMixin:
    """Agrega `creado_en` gestionado por la BD."""

    creado_en: Mapped[datetime] = mapped_column(
        server_default=func.now(),
        nullable=False,
    )
