"""Generación y verificación del QR firmado de una compra.

El código QR es un JWT firmado con `JWT_SECRET` (`type=ticket`) que agrupa toda la
compra. Es autocontenido: un `jti` aleatorio lo hace único e impredecible sin el
secreto. La cadena se guarda en `Compra.qr_codigo`; es lo que el cliente renderiza
y el trabajador escanea. La validación verifica la firma (integridad) y luego busca
la compra por ese `qr_codigo`.
"""

from __future__ import annotations

import secrets
from datetime import datetime, timezone

import jwt

from app.core.config import settings

TYPE_TICKET = "ticket"


def generar_codigo() -> str:
    payload = {
        "type": TYPE_TICKET,
        "jti": secrets.token_urlsafe(24),
        "iat": datetime.now(timezone.utc),
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def firma_valida(codigo: str) -> bool:
    """True si el código fue emitido por nosotros (firma + tipo correctos)."""
    try:
        payload = jwt.decode(
            codigo, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
    except jwt.PyJWTError:
        return False
    return payload.get("type") == TYPE_TICKET
