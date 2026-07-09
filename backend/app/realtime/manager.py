"""Gestor de conexiones WebSocket agrupadas por "sala" (canal).

Una única instancia global `manager` mantiene, por clave de canal, el conjunto de
sockets conectados y sabe difundir mensajes JSON a todos ellos.
"""

from __future__ import annotations

from collections import defaultdict

from starlette.websockets import WebSocket


def funcion_room(funcion_id: int) -> str:
    return f"funcion:{funcion_id}"


def usuario_room(usuario_id: int) -> str:
    return f"usuario:{usuario_id}"


STAFF_ROOM = "staff:dashboard"


class ConnectionManager:
    def __init__(self) -> None:
        self._rooms: dict[str, set[WebSocket]] = defaultdict(set)

    async def connect(self, room: str, ws: WebSocket) -> None:
        await ws.accept()
        self._rooms[room].add(ws)

    def disconnect(self, room: str, ws: WebSocket) -> None:
        conns = self._rooms.get(room)
        if conns is not None:
            conns.discard(ws)
            if not conns:
                self._rooms.pop(room, None)

    def count(self, room: str) -> int:
        return len(self._rooms.get(room, ()))

    async def send_personal(self, ws: WebSocket, message: dict) -> None:
        await ws.send_json(message)

    async def broadcast(self, room: str, message: dict) -> None:
        for ws in list(self._rooms.get(room, ())):
            try:
                await ws.send_json(message)
            except Exception:  # noqa: BLE001 — socket muerto: lo removemos
                self.disconnect(room, ws)


manager = ConnectionManager()
