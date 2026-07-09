"""Espera a que PostgreSQL acepte conexiones antes de migrar/arrancar.

Se ejecuta en el entrypoint del contenedor. Reintenta un `SELECT 1` hasta que la
BD responde o se agota el número de intentos.
"""

import asyncio
import sys

from sqlalchemy import text

from app.core.database import engine


async def wait(max_attempts: int = 30, delay: float = 2.0) -> None:
    for attempt in range(1, max_attempts + 1):
        try:
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            print(f"Base de datos lista (intento {attempt}).")
            await engine.dispose()
            return
        except Exception as exc:  # noqa: BLE001
            print(f"BD no disponible (intento {attempt}/{max_attempts}): {exc}")
            await asyncio.sleep(delay)
    await engine.dispose()
    print("No se pudo conectar a la base de datos. Abortando.")
    sys.exit(1)


if __name__ == "__main__":
    asyncio.run(wait())
