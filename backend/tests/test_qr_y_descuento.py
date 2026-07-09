"""Tests sin BD: firma del QR y cálculo de descuentos."""

from decimal import Decimal

from app.models.enums import TipoDescuento
from app.services import qr as qr_service
from app.services.compra import _calcular_descuento


def test_qr_firma_valida_roundtrip():
    codigo = qr_service.generar_codigo()
    assert qr_service.firma_valida(codigo)


def test_qr_codigos_unicos():
    assert qr_service.generar_codigo() != qr_service.generar_codigo()


def test_qr_codigo_manipulado_invalido():
    codigo = qr_service.generar_codigo()
    assert not qr_service.firma_valida(codigo + "x")
    assert not qr_service.firma_valida("basura.no.jwt")


def test_descuento_porcentaje():
    assert _calcular_descuento(Decimal("100.00"), TipoDescuento.porcentaje, Decimal("10")) == Decimal("10.00")


def test_descuento_monto_no_supera_subtotal():
    assert _calcular_descuento(Decimal("15.00"), TipoDescuento.monto, Decimal("20")) == Decimal("15.00")
    assert _calcular_descuento(Decimal("50.00"), TipoDescuento.monto, Decimal("20")) == Decimal("20.00")
