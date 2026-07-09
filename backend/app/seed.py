"""Seed idempotente: crea el administrador inicial si no existe ninguno.

Se ejecuta en el entrypoint tras las migraciones. Las credenciales salen de
`SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD` (con defaults de desarrollo).
"""

import asyncio

from sqlalchemy import select

from app.core.config import settings
from app.core.database import AsyncSessionLocal, engine
from app.core.security import hash_password
from app.models.enums import RolUsuario
from app.models.usuario import Usuario


async def seed_admin() -> None:
    async with AsyncSessionLocal() as db:
        existe = await db.execute(
            select(Usuario).where(Usuario.rol == RolUsuario.administrador)
        )
        if existe.scalars().first() is not None:
            print("Seed: ya existe un administrador, no se crea otro.")
            return
        admin = Usuario(
            nombre=settings.seed_admin_nombre,
            email=settings.seed_admin_email,
            password_hash=hash_password(settings.seed_admin_password),
            rol=RolUsuario.administrador,
        )
        db.add(admin)
        await db.commit()
        print(f"Seed: administrador creado ({settings.seed_admin_email}).")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(seed_admin())
