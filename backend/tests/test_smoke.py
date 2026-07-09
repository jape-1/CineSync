"""Smoke tests de la Fase 1 — no requieren base de datos.

Verifican que la app importa, que las 16 entidades están registradas en el
metadata y que los enums se almacenan por su valor (p. ej. "2D").
"""

from app.main import app
from app.models import Base
from app.models.enums import TipoSala, pg_enum

EXPECTED_TABLES = {
    "usuarios",
    "generos",
    "peliculas",
    "pelicula_generos",
    "salas",
    "asientos",
    "funciones",
    "asiento_funciones",
    "productos",
    "combos",
    "combo_productos",
    "promociones",
    "compras",
    "compra_asientos",
    "compra_productos",
    "validaciones_qr",
}


def test_las_16_entidades_registradas():
    tablas = set(Base.metadata.tables.keys())
    assert EXPECTED_TABLES.issubset(tablas)
    assert len(EXPECTED_TABLES) == 16


def test_app_expone_health_y_root():
    rutas = {r.path for r in app.routes}
    assert "/health" in rutas
    assert "/" in rutas


def test_enum_se_guarda_por_valor():
    # values_callable => la BD guarda "2D"/"3D"/"VIP", no "dosd"/"tresd"/"vip".
    tipo = pg_enum(TipoSala, 8)
    assert set(tipo.enums) == {"2D", "3D", "VIP"}


def test_compras_qr_codigo_unico():
    compras = Base.metadata.tables["compras"]
    assert compras.c.qr_codigo.unique is True


def test_funciones_tiene_rango_horario():
    funciones = Base.metadata.tables["funciones"]
    assert "inicio" in funciones.c
    assert "fin" in funciones.c
