"""Seguridad: hashing de contraseñas, emisión/validación de JWT y dependencias
de autorización por rol.

El rol viaja como claim dentro del access token; `require_role` lo verifica sin
tocar la base de datos (según el PRD). Los access tokens son cortos, así que la
desactivación de un usuario surte efecto al expirar su token vigente.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Annotated, Any

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from passlib.context import CryptContext

from app.core.config import settings
from app.models.enums import RolUsuario

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# tokenUrl solo documenta el flujo en /docs; el login real es JSON.
oauth2_scheme = OAuth2PasswordBearer(
    tokenUrl=f"{settings.api_v1_prefix}/auth/login", auto_error=True
)

TYPE_ACCESS = "access"
TYPE_REFRESH = "refresh"
TYPE_RESET = "reset"


# --- Hashing ---------------------------------------------------------------


def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


# --- JWT -------------------------------------------------------------------


def _encode(payload: dict[str, Any], expires: timedelta) -> str:
    now = datetime.now(timezone.utc)
    to_encode = {**payload, "iat": now, "exp": now + expires}
    return jwt.encode(to_encode, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_access_token(user_id: int, rol: RolUsuario) -> str:
    return _encode(
        {"sub": str(user_id), "rol": rol.value, "type": TYPE_ACCESS},
        timedelta(minutes=settings.access_token_expire_minutes),
    )


def create_refresh_token(user_id: int, token_version: int) -> str:
    return _encode(
        {"sub": str(user_id), "ver": token_version, "type": TYPE_REFRESH},
        timedelta(days=settings.refresh_token_expire_days),
    )


def create_reset_token(user_id: int) -> str:
    return _encode(
        {"sub": str(user_id), "type": TYPE_RESET},
        timedelta(minutes=settings.reset_token_expire_minutes),
    )


def decode_token(token: str, expected_type: str) -> dict[str, Any]:
    try:
        payload = jwt.decode(
            token, settings.jwt_secret, algorithms=[settings.jwt_algorithm]
        )
    except jwt.ExpiredSignatureError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expirado",
        ) from exc
    except jwt.PyJWTError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido",
        ) from exc
    if payload.get("type") != expected_type:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Tipo de token incorrecto",
        )
    return payload


# --- Principal + dependencias ---------------------------------------------


@dataclass(frozen=True)
class CurrentUser:
    id: int
    rol: RolUsuario


def get_current_user(token: Annotated[str, Depends(oauth2_scheme)]) -> CurrentUser:
    payload = decode_token(token, TYPE_ACCESS)
    try:
        user_id = int(payload["sub"])
        rol = RolUsuario(payload["rol"])
    except (KeyError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido",
        ) from exc
    return CurrentUser(id=user_id, rol=rol)


CurrentUserDep = Annotated[CurrentUser, Depends(get_current_user)]


def require_role(*roles: RolUsuario):
    """Genera una dependencia que exige que el rol del token esté entre `roles`."""

    allowed = set(roles)

    def _checker(user: CurrentUserDep) -> CurrentUser:
        if user.rol not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="No tienes permiso para esta acción",
            )
        return user

    return _checker


# Dependencias reutilizables por rol.
require_admin = require_role(RolUsuario.administrador)
require_trabajador = require_role(RolUsuario.trabajador, RolUsuario.administrador)
require_cliente = require_role(RolUsuario.cliente)
