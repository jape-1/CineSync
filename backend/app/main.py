"""Punto de entrada de la API de CineSync.

Arquitectura por capas: router → service → repository → model/schema.
Los routers de cada dominio se irán registrando por fase.
"""

import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.realtime.tasks import seat_lock_sweeper
from app.routers import (
    auth,
    combos,
    compras,
    funciones,
    generos,
    health,
    peliculas,
    productos,
    promociones,
    reportes,
    salas,
    usuarios,
    validaciones,
    ws,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Arranca la tarea de fondo que expira los bloqueos de asientos vencidos.
    sweeper = asyncio.create_task(seat_lock_sweeper())
    yield
    sweeper.cancel()
    try:
        await sweeper
    except asyncio.CancelledError:
        pass


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    debug=settings.debug,
    lifespan=lifespan,
)

# CORS abierto para desarrollo (permite un cliente Flutter web contra el API).
# Se usan tokens Bearer en headers, no cookies, así que allow_credentials=False.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check en la raíz (sin prefijo de versión).
app.include_router(health.router)

# API v1.
_v1 = settings.api_v1_prefix
app.include_router(auth.router, prefix=_v1)
app.include_router(usuarios.router, prefix=_v1)
app.include_router(peliculas.router, prefix=_v1)
app.include_router(generos.router, prefix=_v1)
app.include_router(salas.router, prefix=_v1)
app.include_router(funciones.router, prefix=_v1)
app.include_router(productos.router, prefix=_v1)
app.include_router(combos.router, prefix=_v1)
app.include_router(promociones.router, prefix=_v1)
app.include_router(compras.router, prefix=_v1)
app.include_router(validaciones.router, prefix=_v1)
app.include_router(reportes.router, prefix=_v1)

# Canales WebSocket (sin prefijo de versión, según cinesync-api.md).
app.include_router(ws.router)


@app.get("/", tags=["health"])
async def root() -> dict[str, str]:
    return {"name": settings.app_name, "docs": "/docs"}
