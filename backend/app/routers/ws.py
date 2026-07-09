"""Canales WebSocket de CineSync.

El JWT de acceso viaja como query param `token` y se valida en el handshake antes
de aceptar la conexión (Flutter no siempre soporta headers custom aquí).
"""

from __future__ import annotations

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.core.database import AsyncSessionLocal
from app.models.enums import RolUsuario
from app.realtime import notifications, seats
from app.realtime.manager import STAFF_ROOM, funcion_room, manager, usuario_room
from app.realtime.ws_auth import authenticate_ws

router = APIRouter(tags=["websocket"])

_POLICY_VIOLATION = 1008


@router.websocket("/ws/funciones/{funcion_id}")
async def ws_funcion(websocket: WebSocket, funcion_id: int, token: str | None = None):
    user = authenticate_ws(token)
    if user is None:
        await websocket.close(code=_POLICY_VIOLATION)
        return

    room = funcion_room(funcion_id)
    await manager.connect(room, websocket)
    async with AsyncSessionLocal() as db:
        mapa = await seats.build_seat_map(db, funcion_id)
    await websocket.send_json(
        {"event": "seat_map_update", "funcion_id": funcion_id, "seats": mapa}
    )
    await seats.broadcast_viewers(funcion_id)

    try:
        while True:
            data = await websocket.receive_json()
            action = data.get("action")
            af_id = data.get("asiento_funcion_id")
            if action not in ("select_seat", "release_seat") or not isinstance(af_id, int):
                await websocket.send_json(
                    {"event": "error", "detail": "Mensaje inválido"}
                )
                continue
            async with AsyncSessionLocal() as db:
                if action == "select_seat":
                    res = await seats.select_seat(db, funcion_id, af_id, user.id)
                else:
                    res = await seats.release_seat(db, funcion_id, af_id, user.id)
            if res.get("ok"):
                await websocket.send_json({"event": f"{action}_ok", **res})
                async with AsyncSessionLocal() as db:
                    await seats.broadcast_seat_map(db, funcion_id)
            else:
                await websocket.send_json({"event": "error", "action": action, **res})
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(room, websocket)
        # Libera los bloqueos temporales que el usuario dejó sin comprar.
        async with AsyncSessionLocal() as db:
            libero = await seats.release_all_for_user(db, funcion_id, user.id)
            if libero:
                await seats.broadcast_seat_map(db, funcion_id)
        await seats.broadcast_viewers(funcion_id)


@router.websocket("/ws/usuarios/{usuario_id}")
async def ws_usuario(websocket: WebSocket, usuario_id: int, token: str | None = None):
    user = authenticate_ws(token)
    if user is None or (
        user.id != usuario_id and user.rol != RolUsuario.administrador
    ):
        await websocket.close(code=_POLICY_VIOLATION)
        return

    room = usuario_room(usuario_id)
    await manager.connect(room, websocket)
    try:
        while True:
            await websocket.receive_text()  # solo mantiene viva la conexión
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(room, websocket)


@router.websocket("/ws/staff/dashboard")
async def ws_staff(websocket: WebSocket, token: str | None = None):
    user = authenticate_ws(token)
    if user is None or user.rol not in (
        RolUsuario.trabajador,
        RolUsuario.administrador,
    ):
        await websocket.close(code=_POLICY_VIOLATION)
        return

    await manager.connect(STAFF_ROOM, websocket)
    async with AsyncSessionLocal() as db:
        await websocket.send_json(await notifications.build_occupancy(db))
        await websocket.send_json(await notifications.build_validation_count(db))
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(STAFF_ROOM, websocket)
