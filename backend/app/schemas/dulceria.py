"""Schemas de productos y combos."""

from decimal import Decimal

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class ProductoRead(ORMModel):
    id: int
    nombre: str
    descripcion: str | None = None
    precio: Decimal
    imagen_url: str | None = None
    categoria: str | None = None
    activo: bool


class ProductoCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=120)
    descripcion: str | None = None
    precio: Decimal = Field(ge=0)
    imagen_url: str | None = None
    categoria: str | None = None


class ProductoUpdate(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=120)
    descripcion: str | None = None
    precio: Decimal | None = Field(default=None, ge=0)
    imagen_url: str | None = None
    categoria: str | None = None
    activo: bool | None = None


class ComboItemInput(BaseModel):
    producto_id: int
    cantidad: int = Field(default=1, ge=1)


class ComboItemRead(ORMModel):
    producto_id: int
    cantidad: int


class ComboRead(ORMModel):
    id: int
    nombre: str
    descripcion: str | None = None
    precio: Decimal
    imagen_url: str | None = None
    activo: bool
    items: list[ComboItemRead] = []


class ComboCreate(BaseModel):
    nombre: str = Field(min_length=1, max_length=120)
    descripcion: str | None = None
    precio: Decimal = Field(ge=0)
    imagen_url: str | None = None
    items: list[ComboItemInput] = Field(default_factory=list)


class ComboUpdate(BaseModel):
    nombre: str | None = Field(default=None, min_length=1, max_length=120)
    descripcion: str | None = None
    precio: Decimal | None = Field(default=None, ge=0)
    imagen_url: str | None = None
    activo: bool | None = None
    items: list[ComboItemInput] | None = None
