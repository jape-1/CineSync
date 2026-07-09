"""Difusiones a los canales de staff y de usuario.

Se invocan desde los servicios REST (checkout, validación) y desde el propio
módulo realtime para mantener sincronizados el mapa de asientos, el dashboard del
personal y el estado del ticket del cliente.
"""

from __future__ import annotations

from sqlalchemy.ext.asyncio import AsyncSession

from app.realtime.manager import STAFF_ROOM, manager, usuario_room
from app.repositories import reporte as reporte_repo
from app.repositories import validacion as validacion_repo


def _ocupacion_serializable(filas: list[dict]) -> list[dict]:
    return [{**f, "inicio": f["inicio"].isoformat()} for f in filas]


async def build_occupancy(db: AsyncSession) -> dict:
    filas = await reporte_repo.ocupacion(db)
    total = sum(f["total_asientos"] for f in filas)
    ocupados = sum(f["ocupados"] for f in filas)
    return {
        "event": "occupancy_update",
        "ocupacion_global": round(100 * ocupados / total, 1) if total else 0.0,
        "funciones": _ocupacion_serializable(filas),
    }


async def broadcast_occupancy(db: AsyncSession) -> None:
    await manager.broadcast(STAFF_ROOM, await build_occupancy(db))


async def build_validation_count(db: AsyncSession) -> dict:
    return {
        "event": "validation_count_update",
        "validaciones_hoy": await validacion_repo.count_validas_hoy(db),
    }


async def broadcast_validation_count(db: AsyncSession) -> None:
    await manager.broadcast(STAFF_ROOM, await build_validation_count(db))


async def notify_ticket_validated(usuario_id: int, compra_id: int) -> None:
    await manager.broadcast(
        usuario_room(usuario_id),
        {
            "event": "ticket_status_changed",
            "compra_id": compra_id,
            "estado": "usado",
        },
    )
