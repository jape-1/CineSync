"""Autenticación del handshake WebSocket vía JWT en query param `token`.

Flutter no siempre soporta headers custom en el handshake, así que el token de
acceso viaja como query param (según `cinesync-api.md`).
"""

from __future__ import annotations

import jwt

from app.core.config import settings
from app.core.security import TYPE_ACCESS
from app.core.security import CurrentUser
from app.models.enums import RolUsuario


def authenticate_ws(token: str | None) -> CurrentUser | None:
    if not token:
        return None
    try:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
    except jwt.PyJWTError:
        return None
    if payload.get("type") != TYPE_ACCESS:
        return None
    try:
        return CurrentUser(id=int(payload["sub"]), rol=RolUsuario(payload["rol"]))
    except (KeyError, ValueError):
        return None
