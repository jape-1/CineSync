"""Enumeraciones del dominio.

Se almacenan como VARCHAR + CHECK (native_enum=False) para evitar el dolor de
`ALTER TYPE` de los enums nativos de PostgreSQL al evolucionar el esquema.
"""

from enum import StrEnum

from sqlalchemy import Enum as SAEnum


def pg_enum(enum_cls: type[StrEnum], length: int) -> SAEnum:
    """Columna enum como VARCHAR + CHECK, almacenando el *valor* del miembro.

    `values_callable` garantiza que en la BD se guarde ``"2D"`` (el valor) y no
    ``"dosd"`` (el nombre). Modelos y migración deben usar este mismo helper para
    mantener el DDL idéntico.
    """
    return SAEnum(
        enum_cls,
        native_enum=False,
        length=length,
        values_callable=lambda e: [m.value for m in e],
    )


class RolUsuario(StrEnum):
    cliente = "cliente"
    trabajador = "trabajador"
    administrador = "administrador"


class TurnoTrabajador(StrEnum):
    manana = "manana"
    tarde = "tarde"
    noche = "noche"


class TipoSala(StrEnum):
    dosd = "2D"
    tresd = "3D"
    vip = "VIP"


class TipoAsiento(StrEnum):
    normal = "normal"
    vip = "vip"
    discapacitado = "discapacitado"


class EstadoAsientoFuncion(StrEnum):
    libre = "libre"
    reservado_temporal = "reservado_temporal"
    ocupado = "ocupado"


class EstadoQR(StrEnum):
    activo = "activo"
    usado = "usado"
    cancelado = "cancelado"


class TipoDescuento(StrEnum):
    porcentaje = "porcentaje"
    monto = "monto"


class ResultadoValidacion(StrEnum):
    valido = "valido"
    usado = "usado"
    invalido = "invalido"
