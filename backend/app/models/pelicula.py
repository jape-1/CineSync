"""Películas, géneros y su relación M:N."""

from __future__ import annotations

from datetime import date

from sqlalchemy import (
    Boolean,
    Date,
    Float,
    ForeignKey,
    Integer,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base, TimestampMixin


class Genero(Base):
    __tablename__ = "generos"

    id: Mapped[int] = mapped_column(primary_key=True)
    tmdb_id: Mapped[int | None] = mapped_column(Integer, unique=True, nullable=True)
    nombre: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)

    peliculas: Mapped[list["Pelicula"]] = relationship(
        secondary="pelicula_generos", back_populates="generos"
    )


class Pelicula(Base, TimestampMixin):
    __tablename__ = "peliculas"

    id: Mapped[int] = mapped_column(primary_key=True)
    tmdb_id: Mapped[int | None] = mapped_column(Integer, unique=True, nullable=True)
    titulo: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    sinopsis: Mapped[str | None] = mapped_column(Text, nullable=True)
    poster_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    backdrop_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    duracion_min: Mapped[int | None] = mapped_column(Integer, nullable=True)
    clasificacion: Mapped[str | None] = mapped_column(String(16), nullable=True)
    fecha_estreno: Mapped[date | None] = mapped_column(Date, nullable=True)
    calificacion: Mapped[float | None] = mapped_column(Float, nullable=True)
    activa: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False, index=True)

    generos: Mapped[list[Genero]] = relationship(
        secondary="pelicula_generos", back_populates="peliculas"
    )
    funciones: Mapped[list["Funcion"]] = relationship(back_populates="pelicula")  # noqa: F821


class PeliculaGenero(Base):
    __tablename__ = "pelicula_generos"

    pelicula_id: Mapped[int] = mapped_column(
        ForeignKey("peliculas.id", ondelete="CASCADE"), primary_key=True
    )
    genero_id: Mapped[int] = mapped_column(
        ForeignKey("generos.id", ondelete="CASCADE"), primary_key=True
    )
