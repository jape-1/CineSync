"""Tarea de fondo que expira los bloqueos temporales de asientos.

Corre cada `seat_lock_sweep_seconds` (10s por defecto): libera los asientos cuyo
TTL venció y difunde el mapa actualizado a los clientes de esas funciones.
"""

from __future__ import annotations

import asyncio
import logging

from app.core.config import settings
from app.core.database import AsyncSessionLocal
from app.realtime import notifications, seats

logger = logging.getLogger("cinesync.realtime")


async def seat_lock_sweeper() -> None:
    while True:
        await asyncio.sleep(settings.seat_lock_sweep_seconds)
        try:
            async with AsyncSessionLocal() as db:
                afectadas = await seats.expire_locks(db)
            for funcion_id in afectadas:
                async with AsyncSessionLocal() as db:
                    await seats.broadcast_seat_map(db, funcion_id)
            if afectadas:
                async with AsyncSessionLocal() as db:
                    await notifications.broadcast_occupancy(db)
        except asyncio.CancelledError:
            raise
        except Exception:  # noqa: BLE001
            logger.exception("Error en el barrido de bloqueos vencidos")
