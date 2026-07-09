"""Tests del ConnectionManager (sin BD ni sockets reales)."""

from app.realtime.manager import (
    STAFF_ROOM,
    ConnectionManager,
    funcion_room,
    usuario_room,
)


class FakeWS:
    def __init__(self) -> None:
        self.sent: list[dict] = []
        self.accepted = False

    async def accept(self) -> None:
        self.accepted = True

    async def send_json(self, message: dict) -> None:
        self.sent.append(message)


class DeadWS(FakeWS):
    async def send_json(self, message: dict) -> None:
        raise RuntimeError("socket muerto")


def test_room_keys():
    assert funcion_room(5) == "funcion:5"
    assert usuario_room(9) == "usuario:9"
    assert STAFF_ROOM == "staff:dashboard"


async def test_connect_count_broadcast_disconnect():
    m = ConnectionManager()
    ws = FakeWS()
    await m.connect("sala", ws)
    assert ws.accepted and m.count("sala") == 1
    await m.broadcast("sala", {"event": "hola"})
    assert ws.sent == [{"event": "hola"}]
    m.disconnect("sala", ws)
    assert m.count("sala") == 0


async def test_broadcast_descarta_socket_muerto():
    m = ConnectionManager()
    vivo, muerto = FakeWS(), DeadWS()
    await m.connect("sala", vivo)
    await m.connect("sala", muerto)
    await m.broadcast("sala", {"x": 1})
    assert m.count("sala") == 1  # el muerto fue removido
    assert vivo.sent == [{"x": 1}]
