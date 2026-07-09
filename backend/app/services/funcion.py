"""Lógica de funciones: valida solapamiento y autogenera los asientos-función."""

from __future__ import annotations

from datetime import timedelta

from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import EstadoAsientoFuncion
from app.models.funcion import AsientoFuncion, Funcion
from app.repositories import funcion as funcion_repo
from app.repositories import pelicula as pelicula_repo
from app.repositories import sala as sala_repo
from app.schemas.funcion import FuncionCreate, FuncionUpdate

_DURACION_DEFECTO_MIN = 120


async def listar(db: AsyncSession, **filtros) -> list[Funcion]:
    return await funcion_repo.list_funciones(db, **filtros)


async def obtener_detalle(db: AsyncSession, funcion_id: int) -> Funcion:
    funcion = await funcion_repo.get_detalle(db, funcion_id)
    if funcion is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Función no encontrada")
    return funcion


async def obtener(db: AsyncSession, funcion_id: int) -> Funcion:
    funcion = await funcion_repo.get(db, funcion_id)
    if funcion is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Función no encontrada")
    return funcion


async def crear(db: AsyncSession, data: FuncionCreate) -> Funcion:
    pelicula = await pelicula_repo.get(db, data.pelicula_id)
    if pelicula is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Película inexistente")
    sala = await sala_repo.get(db, data.sala_id)
    if sala is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Sala inexistente")

    fin = data.fin
    if fin is None:
        dur = pelicula.duracion_min or _DURACION_DEFECTO_MIN
        fin = data.inicio + timedelta(minutes=dur)
    if fin <= data.inicio:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El fin de la función debe ser posterior al inicio",
        )

    funcion = Funcion(
        pelicula_id=data.pelicula_id,
        sala_id=data.sala_id,
        inicio=data.inicio,
        fin=fin,
        precio_base=data.precio_base,
        idioma=data.idioma,
        formato=data.formato,
    )
    db.add(funcion)
    try:
        await db.flush()  # dispara el EXCLUDE anti-solapamiento
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ya existe una función que se solapa en esa sala y horario",
        ) from exc

    # Genera un AsientoFuncion (estado libre) por cada asiento de la sala.
    asientos = await sala_repo.list_asientos(db, data.sala_id)
    filas = [
        AsientoFuncion(
            funcion_id=funcion.id,
            asiento_id=a.id,
            estado=EstadoAsientoFuncion.libre,
        )
        for a in asientos
    ]
    await funcion_repo.add_asiento_funciones(db, filas)
    await db.commit()
    return await obtener_detalle(db, funcion.id)


async def snapshot_asientos(db: AsyncSession, funcion_id: int) -> list[dict]:
    """Estado actual de todos los asientos de una función (para el cliente)."""
    await obtener(db, funcion_id)  # valida existencia
    filas = await funcion_repo.list_asiento_funciones(db, funcion_id)
    return [
        {
            "asiento_funcion_id": af.id,
            "asiento_id": af.asiento_id,
            "fila": af.asiento.fila,
            "numero": af.asiento.numero,
            "tipo": af.asiento.tipo,
            "estado": af.estado,
            "reservado_hasta": af.reservado_hasta,
        }
        for af in filas
    ]


async def actualizar(
    db: AsyncSession, funcion_id: int, data: FuncionUpdate
) -> Funcion:
    funcion = await obtener(db, funcion_id)
    for campo, valor in data.model_dump(exclude_unset=True).items():
        setattr(funcion, campo, valor)
    if funcion.fin <= funcion.inicio:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="El fin de la función debe ser posterior al inicio",
        )
    try:
        await db.flush()
    except IntegrityError as exc:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="El nuevo horario se solapa con otra función en esa sala",
        ) from exc
    await db.commit()
    return await obtener_detalle(db, funcion.id)


async def eliminar(db: AsyncSession, funcion_id: int) -> None:
    funcion = await obtener(db, funcion_id)
    await db.delete(funcion)
    await db.commit()
