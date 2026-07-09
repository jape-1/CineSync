"""Tests de seguridad sin base de datos: hashing y JWT."""

import pytest
from fastapi import HTTPException

from app.core import security
from app.models.enums import RolUsuario


def test_hash_y_verify_password():
    hashed = security.hash_password("secreto123")
    assert hashed != "secreto123"
    assert security.verify_password("secreto123", hashed)
    assert not security.verify_password("otra", hashed)


def test_access_token_roundtrip():
    token = security.create_access_token(42, RolUsuario.administrador)
    payload = security.decode_token(token, security.TYPE_ACCESS)
    assert payload["sub"] == "42"
    assert payload["rol"] == "administrador"


def test_refresh_token_lleva_version():
    token = security.create_refresh_token(7, token_version=3)
    payload = security.decode_token(token, security.TYPE_REFRESH)
    assert payload["sub"] == "7"
    assert payload["ver"] == 3


def test_tipo_de_token_incorrecto_rechazado():
    access = security.create_access_token(1, RolUsuario.cliente)
    with pytest.raises(HTTPException):
        security.decode_token(access, security.TYPE_REFRESH)


def test_require_role_bloquea_rol_no_autorizado():
    checker = security.require_role(RolUsuario.administrador)
    with pytest.raises(HTTPException) as exc:
        checker(security.CurrentUser(id=1, rol=RolUsuario.cliente))
    assert exc.value.status_code == 403
