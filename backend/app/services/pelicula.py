"""Lógica de películas y géneros, incluida la importación desde TMDB."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.pelicula import Genero, Pelicula
from app.repositories import pelicula as pelicula_repo
from app.schemas.pelicula import ImportTmdbRequest, PeliculaCreate, PeliculaUpdate
from app.services import tmdb


async def listar(
    db: AsyncSession, genero: str | None, activa: bool | None
) -> list[Pelicula]:
    return await pelicula_repo.list_peliculas(db, genero=genero, activa=activa)


async def obtener(db: AsyncSession, pelicula_id: int) -> Pelicula:
    pelicula = await pelicula_repo.get(db, pelicula_id)
    if pelicula is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Película no encontrada")
    return pelicula


async def crear(db: AsyncSession, data: PeliculaCreate) -> Pelicula:
    generos = await pelicula_repo.get_generos_by_ids(db, data.generos)
    if len(generos) != len(set(data.generos)):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uno o más géneros no existen",
        )
    pelicula = Pelicula(
        titulo=data.titulo,
        sinopsis=data.sinopsis,
        poster_url=data.poster_url,
        backdrop_url=data.backdrop_url,
        duracion_min=data.duracion_min,
        clasificacion=data.clasificacion,
        fecha_estreno=data.fecha_estreno,
        calificacion=data.calificacion,
        activa=True,
        generos=generos,
    )
    await pelicula_repo.add(db, pelicula)
    await db.commit()
    return await obtener(db, pelicula.id)


async def actualizar(
    db: AsyncSession, pelicula_id: int, data: PeliculaUpdate
) -> Pelicula:
    pelicula = await obtener(db, pelicula_id)
    campos = data.model_dump(exclude_unset=True)
    generos_ids = campos.pop("generos", None)
    for campo, valor in campos.items():
        setattr(pelicula, campo, valor)
    if generos_ids is not None:
        pelicula.generos = await pelicula_repo.get_generos_by_ids(db, generos_ids)
    await db.commit()
    return await obtener(db, pelicula.id)


async def archivar(db: AsyncSession, pelicula_id: int) -> None:
    """Nunca se borra: se marca activa=False para no romper el historial."""
    pelicula = await obtener(db, pelicula_id)
    pelicula.activa = False
    await db.commit()


async def importar_tmdb(db: AsyncSession, data: ImportTmdbRequest) -> Pelicula:
    if data.tmdb_id is None and not data.titulo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Envía tmdb_id o titulo",
        )
    tmdb_id = data.tmdb_id or await tmdb.buscar_por_titulo(data.titulo)  # type: ignore[arg-type]

    existente = await pelicula_repo.get_by_tmdb(db, tmdb_id)
    detalle = await tmdb.obtener_detalle(tmdb_id)

    generos = [
        await pelicula_repo.get_or_create_genero_tmdb(db, g["tmdb_id"], g["nombre"])
        for g in detalle["generos"]
    ]

    if existente is not None:
        # Re-importar actualiza los datos de TMDB (idempotente por tmdb_id).
        pelicula = existente
        for campo in (
            "titulo",
            "sinopsis",
            "poster_url",
            "backdrop_url",
            "duracion_min",
            "clasificacion",
            "fecha_estreno",
            "calificacion",
        ):
            setattr(pelicula, campo, detalle[campo])
        pelicula.generos = generos
    else:
        pelicula = Pelicula(
            tmdb_id=detalle["tmdb_id"],
            titulo=detalle["titulo"],
            sinopsis=detalle["sinopsis"],
            poster_url=detalle["poster_url"],
            backdrop_url=detalle["backdrop_url"],
            duracion_min=detalle["duracion_min"],
            clasificacion=detalle["clasificacion"],
            fecha_estreno=detalle["fecha_estreno"],
            calificacion=detalle["calificacion"],
            activa=True,
            generos=generos,
        )
        await pelicula_repo.add(db, pelicula)

    await db.commit()
    return await obtener(db, pelicula.id)


async def listar_generos(db: AsyncSession) -> list[Genero]:
    return await pelicula_repo.list_generos(db)
