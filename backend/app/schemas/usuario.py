"""Schemas de usuarios."""

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.models.enums import RolUsuario, TurnoTrabajador
from app.schemas.common import ORMModel


class UsuarioRead(ORMModel):
    id: int
    nombre: str
    email: EmailStr
    rol: RolUsuario
    turno: TurnoTrabajador | None = None
    activo: bool
    creado_en: datetime


class UsuarioUpdateMe(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=120)
    password: str | None = Field(default=None, min_length=6, max_length=128)


class UsuarioCreate(BaseModel):
    """Alta manual de trabajador o administrador (solo admin)."""

    nombre: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)
    rol: RolUsuario = RolUsuario.trabajador
    turno: TurnoTrabajador | None = None


class UsuarioAdminUpdate(BaseModel):
    activo: bool | None = None
    rol: RolUsuario | None = None
    turno: TurnoTrabajador | None = None
