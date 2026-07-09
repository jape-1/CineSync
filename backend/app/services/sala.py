"""Lógica de salas: crea la sala y autogenera sus asientos físicos."""

from __future__ import annotations

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.enums import TipoAsiento, TipoSala
from app.models.sala import Asiento, Sala
from app.repositories import sala as sala_repo
from app.schemas.sala import SalaCreate, SalaUpdate

_FILAS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"


async def listar(db: AsyncSession) -> list[Sala]:
    return await sala_repo.list_salas(db)


async def obtener(db: AsyncSession, sala_id: int) -> Sala:
    sala = await sala_repo.get(db, sala_id)
    if sala is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sala no encontrada")
    return sala


async def crear(db: AsyncSession, data: SalaCreate) -> Sala:
    sala = Sala(
        nombre=data.nombre,
        tipo=data.tipo,
        filas=data.filas,
        columnas=data.columnas,
        activa=True,
    )
    await sala_repo.add(db, sala)

    # Autogenera la matriz de asientos: fila A,B,C... × números 1..columnas.
    tipo_asiento = TipoAsiento.vip if data.tipo == TipoSala.vip else TipoAsiento.normal
    asientos = [
        Asiento(
            sala_id=sala.id,
            fila=_FILAS[f],
            numero=n,
            tipo=tipo_asiento,
        )
        for f in range(data.filas)
        for n in range(1, data.columnas + 1)
    ]
    await sala_repo.add_asientos(db, asientos)
    await db.commit()
    await db.refresh(sala)
    return sala


async def actualizar(db: AsyncSession, sala_id: int, data: SalaUpdate) -> Sala:
    sala = await obtener(db, sala_id)
    for campo, valor in data.model_dump(exclude_unset=True).items():
        setattr(sala, campo, valor)
    await db.commit()
    await db.refresh(sala)
    return sala


async def eliminar(db: AsyncSession, sala_id: int) -> None:
    sala = await obtener(db, sala_id)
    if await sala_repo.count_funciones_futuras(db, sala_id) > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="La sala tiene funciones futuras y no puede eliminarse",
        )
    await db.delete(sala)
    await db.commit()
