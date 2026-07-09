"""Test de la lógica pura de validez de promociones (sin BD)."""

from datetime import datetime, timedelta, timezone
from decimal import Decimal

from app.models.enums import TipoDescuento
from app.models.promocion import Promocion
from app.services.promocion import _motivo_invalidez


def _promo(**kwargs) -> Promocion:
    base = dict(
        codigo="TEST",
        tipo_descuento=TipoDescuento.porcentaje,
        valor=Decimal("10"),
        activo=True,
        valido_desde=None,
        valido_hasta=None,
        usos_maximos=None,
        usos_actuales=0,
    )
    base.update(kwargs)
    return Promocion(**base)


def test_promo_valida():
    assert _motivo_invalidez(_promo()) is None


def test_promo_inexistente():
    assert _motivo_invalidez(None) is not None


def test_promo_inactiva():
    assert _motivo_invalidez(_promo(activo=False)) is not None


def test_promo_vencida():
    ayer = datetime.now(timezone.utc) - timedelta(days=1)
    assert _motivo_invalidez(_promo(valido_hasta=ayer)) is not None


def test_promo_sin_usos_disponibles():
    assert _motivo_invalidez(_promo(usos_maximos=5, usos_actuales=5)) is not None
