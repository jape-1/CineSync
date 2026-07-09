"""Acceso a datos de películas y géneros."""

from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.pelicula import Genero, Pelicula


async def get(db: AsyncSession, pelicula_id: int) -> Pelicula | None:
    stmt = (
        select(Pelicula)
        .where(Pelicula.id == pelicula_id)
        .options(selectinload(Pelicula.generos))
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def get_by_tmdb(db: AsyncSession, tmdb_id: int) -> Pelicula | None:
    stmt = (
        select(Pelicula)
        .where(Pelicula.tmdb_id == tmdb_id)
        .options(selectinload(Pelicula.generos))
    )
    result = await db.execute(stmt)
    return result.scalar_one_or_none()


async def list_peliculas(
    db: AsyncSession,
    genero: str | None = None,
    activa: bool | None = None,
) -> list[Pelicula]:
    stmt = select(Pelicula).options(selectinload(Pelicula.generos)).order_by(
        Pelicula.titulo
    )
    if activa is not None:
        stmt = stmt.where(Pelicula.activa == activa)
    if genero is not None:
        stmt = stmt.where(Pelicula.generos.any(Genero.nombre.ilike(genero)))
    result = await db.execute(stmt)
    return list(result.scalars().unique().all())


async def add(db: AsyncSession, pelicula: Pelicula) -> Pelicula:
    db.add(pelicula)
    await db.flush()
    return pelicula


# --- Géneros ---


async def list_generos(db: AsyncSession) -> list[Genero]:
    result = await db.execute(select(Genero).order_by(Genero.nombre))
    return list(result.scalars().all())


async def get_generos_by_ids(db: AsyncSession, ids: list[int]) -> list[Genero]:
    if not ids:
        return []
    result = await db.execute(select(Genero).where(Genero.id.in_(ids)))
    return list(result.scalars().all())


async def get_or_create_genero_tmdb(
    db: AsyncSession, tmdb_id: int, nombre: str
) -> Genero:
    result = await db.execute(select(Genero).where(Genero.tmdb_id == tmdb_id))
    genero = result.scalar_one_or_none()
    if genero is None:
        genero = Genero(tmdb_id=tmdb_id, nombre=nombre)
        db.add(genero)
        await db.flush()
    return genero
