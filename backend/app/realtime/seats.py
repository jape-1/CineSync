"""Bloqueo temporal de asientos en tiempo real + difusión del mapa.

Estados (AsientoFuncion.estado): libre → reservado_temporal (TTL) → ocupado.
El TTL se renueva al re-seleccionar el mismo asiento. La expiración la barre una
tarea de fondo (ver `tasks.py`).
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.enums import EstadoAsientoFuncion
from app.models.funcion import AsientoFuncion
from app.realtime.manager import funcion_room, manager
from app.repositories import funcion as funcion_repo


def _seat_dict(af: AsientoFuncion) -> dict:
    return {
        "asiento_funcion_id": af.id,
        "asiento_id": af.asiento_id,
        "fila": af.asiento.fila,
        "numero": af.asiento.numero,
        "tipo": af.asiento.tipo.value,
        "estado": af.estado.value,
        "reservado_por": af.reservado_por,
        "reservado_hasta": (
            af.reservado_hasta.isoformat() if af.reservado_hasta else None
        ),
    }


async def build_seat_map(db: AsyncSession, funcion_id: int) -> list[dict]:
    filas = await funcion_repo.list_asiento_funciones(db, funcion_id)
    return [_seat_dict(af) for af in filas]


async def broadcast_seat_map(db: AsyncSession, funcion_id: int) -> None:
    seats = await build_seat_map(db, funcion_id)
    await manager.broadcast(
        funcion_room(funcion_id),
        {"event": "seat_map_update", "funcion_id": funcion_id, "seats": seats},
    )


async def broadcast_viewers(funcion_id: int) -> None:
    await manager.broadcast(
        funcion_room(funcion_id),
        {"event": "viewers_count", "count": manager.count(funcion_room(funcion_id))},
    )


async def _lock(db: AsyncSession, funcion_id: int, af_id: int) -> AsientoFuncion | None:
    stmt = (
        select(AsientoFuncion)
        .where(AsientoFuncion.id == af_id, AsientoFuncion.funcion_id == funcion_id)
        .with_for_update()
    )
    return (await db.execute(stmt)).scalar_one_or_none()


async def select_seat(
    db: AsyncSession, funcion_id: int, af_id: int, user_id: int
) -> dict:
    af = await _lock(db, funcion_id, af_id)
    if af is None:
        await db.rollback()
        return {"ok": False, "detail": "Asiento inexistente"}

    hasta = datetime.now(timezone.utc) + timedelta(seconds=settings.seat_lock_ttl_seconds)
    if af.estado == EstadoAsientoFuncion.libre:
        af.estado = EstadoAsientoFuncion.reservado_temporal
        af.reservado_por = user_id
        af.reservado_hasta = hasta
    elif (
        af.estado == EstadoAsientoFuncion.reservado_temporal
        and af.reservado_por == user_id
    ):
        af.reservado_hasta = hasta  # renueva el TTL
    else:
        await db.rollback()
        return {"ok": False, "detail": "Asiento no disponible"}

    await db.commit()
    return {"ok": True, "asiento_funcion_id": af_id, "reservado_hasta": hasta.isoformat()}


async def release_seat(
    db: AsyncSession, funcion_id: int, af_id: int, user_id: int
) -> dict:
    af = await _lock(db, funcion_id, af_id)
    if (
        af is not None
        and af.estado == EstadoAsientoFuncion.reservado_temporal
        and af.reservado_por == user_id
    ):
        af.estado = EstadoAsientoFuncion.libre
        af.reservado_por = None
        af.reservado_hasta = None
        await db.commit()
        return {"ok": True, "asiento_funcion_id": af_id}
    await db.rollback()
    return {"ok": False, "detail": "No tienes ese asiento reservado"}


async def release_all_for_user(
    db: AsyncSession, funcion_id: int, user_id: int
) -> bool:
    stmt = (
        select(AsientoFuncion)
        .where(
            AsientoFuncion.funcion_id == funcion_id,
            AsientoFuncion.estado == EstadoAsientoFuncion.reservado_temporal,
            AsientoFuncion.reservado_por == user_id,
        )
        .with_for_update()
    )
    filas = list((await db.execute(stmt)).scalars().all())
    for af in filas:
        af.estado = EstadoAsientoFuncion.libre
        af.reservado_por = None
        af.reservado_hasta = None
    if filas:
        await db.commit()
    return bool(filas)


async def expire_locks(db: AsyncSession) -> set[int]:
    """Libera los bloqueos vencidos. Devuelve los ids de función afectados."""
    ahora = datetime.now(timezone.utc)
    stmt = (
        select(AsientoFuncion)
        .where(
            AsientoFuncion.estado == EstadoAsientoFuncion.reservado_temporal,
            AsientoFuncion.reservado_hasta < ahora,
        )
        .with_for_update(skip_locked=True)
    )
    filas = list((await db.execute(stmt)).scalars().all())
    afectadas: set[int] = set()
    for af in filas:
        af.estado = EstadoAsientoFuncion.libre
        af.reservado_por = None
        af.reservado_hasta = None
        afectadas.add(af.funcion_id)
    if filas:
        await db.commit()
    return afectadas
