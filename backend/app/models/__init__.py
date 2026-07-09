"""Registro central de modelos.

Importar todos aquí garantiza que `Base.metadata` conozca las 16 entidades
antes de que Alembic genere/compare migraciones.
"""

from app.models.base import Base
from app.models.usuario import Usuario
from app.models.pelicula import Genero, Pelicula, PeliculaGenero
from app.models.sala import Asiento, Sala
from app.models.funcion import AsientoFuncion, Funcion
from app.models.dulceria import Combo, ComboProducto, Producto
from app.models.promocion import Promocion
from app.models.compra import Compra, CompraAsiento, CompraProducto
from app.models.validacion import ValidacionQR

__all__ = [
    "Base",
    "Usuario",
    "Genero",
    "Pelicula",
    "PeliculaGenero",
    "Sala",
    "Asiento",
    "Funcion",
    "AsientoFuncion",
    "Producto",
    "Combo",
    "ComboProducto",
    "Compra",
    "CompraAsiento",
    "CompraProducto",
    "Promocion",
    "ValidacionQR",
]
