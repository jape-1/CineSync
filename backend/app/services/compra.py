"""Lógica de compras: checkout, historial, detalle y cancelación."""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from decimal import ROUND_HALF_UP, Decimal

from fastapi import HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings
from app.models.compra import Compra, CompraAsiento, CompraProducto
from app.models.enums import EstadoAsientoFuncion, EstadoQR, RolUsuario, TipoDescuento
from app.repositories import compra as compra_repo
from app.repositories import dulceria as dulceria_repo
from app.repositories import funcion as funcion_repo
from app.repositories import promocion as promocion_repo
from app.realtime import notifications as rt_notif
from app.realtime import seats as rt_seats
from app.schemas.compra import (
    CompraAsientoRead,
    CompraCreate,
    CompraProductoRead,
    CompraRead,
    FuncionResumen,
)
from app.services import promocion as promocion_service
from app.services import qr as qr_service

_CERO = Decimal("0.00")


def _q(valor: Decimal) -> Decimal:
    return valor.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def _to_read(compra: Compra) -> CompraRead:
    funcion = compra.funcion
    asientos = [
        CompraAsientoRead(
            asiento_funcion_id=ca.asiento_funcion_id,
            fila=ca.asiento_funcion.asiento.fila,
            numero=ca.asiento_funcion.asiento.numero,
        )
        for ca in compra.asientos
    ]
    productos = [
        CompraProductoRead(
            id=cp.id,
            producto_id=cp.producto_id,
            combo_id=cp.combo_id,
            nombre=(cp.producto.nombre if cp.producto else cp.combo.nombre),
            cantidad=cp.cantidad,
            precio_unitario=cp.precio_unitario,
        )
        for cp in compra.productos
    ]
    return CompraRead(
        id=compra.id,
        funcion=FuncionResumen(
            id=funcion.id,
            inicio=funcion.inicio,
            fin=funcion.fin,
            pelicula_titulo=funcion.pelicula.titulo,
            sala_nombre=funcion.sala.nombre,
        ),
        asientos=asientos,
        productos=productos,
        subtotal=compra.subtotal,
        descuento=compra.descuento,
        total=compra.total,
        qr_codigo=compra.qr_codigo,
        qr_estado=compra.qr_estado,
        creado_en=compra.creado_en,
        usado_en=compra.usado_en,
    )


async def _resolver_dulceria(
    db: AsyncSession, items
) -> tuple[list[CompraProducto], Decimal]:
    filas: list[CompraProducto] = []
    total = _CERO
    for item in items:
        if item.producto_id is not None:
            producto = await dulceria_repo.get_producto(db, item.producto_id)
            if producto is None or not producto.activo:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Producto {item.producto_id} inválido",
                )
            precio = producto.precio
            filas.append(
                CompraProducto(
                    producto_id=producto.id,
                    cantidad=item.cantidad,
                    precio_unitario=precio,
                )
            )
        else:
            combo = await dulceria_repo.get_combo(db, item.combo_id)
            if combo is None or not combo.activo:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Combo {item.combo_id} inválido",
                )
            precio = combo.precio
            filas.append(
                CompraProducto(
                    combo_id=combo.id,
                    cantidad=item.cantidad,
                    precio_unitario=precio,
                )
            )
        total += precio * item.cantidad
    return filas, total


def _calcular_descuento(
    subtotal: Decimal, tipo: TipoDescuento, valor: Decimal
) -> Decimal:
    if tipo == TipoDescuento.porcentaje:
        return _q(subtotal * valor / Decimal("100"))
    return min(_q(valor), subtotal)


async def crear(db: AsyncSession, user_id: int, data: CompraCreate) -> CompraRead:
    funcion = await funcion_repo.get(db, data.funcion_id)
    if funcion is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Función no encontrada")

    # 1) Bloquea y valida los asientos elegidos (evita doble reserva concurrente).
    ids = list(dict.fromkeys(data.asientos))  # sin duplicados, preserva orden
    asiento_funciones = await compra_repo.lock_asiento_funciones(db, funcion.id, ids)
    if len(asiento_funciones) != len(ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uno o más asientos no pertenecen a la función",
        )
    for af in asiento_funciones:
        disponible = af.estado == EstadoAsientoFuncion.libre or (
            af.estado == EstadoAsientoFuncion.reservado_temporal
            and af.reservado_por == user_id
        )
        if not disponible:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Algún asiento ya no está disponible",
            )

    # 2) Dulcería.
    filas_productos, subtotal_dulceria = await _resolver_dulceria(db, data.productos)

    # 3) Subtotal = asientos (precio_base c/u) + dulcería.
    subtotal_asientos = funcion.precio_base * len(asiento_funciones)
    subtotal = _q(subtotal_asientos + subtotal_dulceria)

    # 4) Promoción opcional.
    descuento = _CERO
    promocion = None
    if data.promocion_codigo:
        resultado = await promocion_service.validar(db, data.promocion_codigo)
        if not resultado.valido:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Promoción inválida: {resultado.motivo}",
            )
        promocion = await promocion_repo.get_by_codigo(db, data.promocion_codigo)
        descuento = _calcular_descuento(
            subtotal, promocion.tipo_descuento, promocion.valor
        )
        promocion.usos_actuales += 1

    total = _q(subtotal - descuento)

    # 5) Crea la compra y confirma los asientos como ocupados.
    compra = Compra(
        usuario_id=user_id,
        funcion_id=funcion.id,
        promocion_id=promocion.id if promocion else None,
        subtotal=subtotal,
        descuento=descuento,
        total=total,
        qr_codigo=qr_service.generar_codigo(),
        qr_estado=EstadoQR.activo,
    )
    await compra_repo.add(db, compra)

    for af in asiento_funciones:
        af.estado = EstadoAsientoFuncion.ocupado
        af.reservado_por = None
        af.reservado_hasta = None
        db.add(CompraAsiento(compra_id=compra.id, asiento_funcion_id=af.id))

    for fila in filas_productos:
        fila.compra_id = compra.id
        db.add(fila)

    await db.commit()
    creada = await compra_repo.get(db, compra.id)

    # Tiempo real: los asientos pasaron a ocupados.
    await rt_seats.broadcast_seat_map(db, funcion.id)
    await rt_notif.broadcast_occupancy(db)
    return _to_read(creada)


async def historial(
    db: AsyncSession, user_id: int, estado: EstadoQR | None
) -> list[CompraRead]:
    compras = await compra_repo.list_by_user(db, user_id, estado)
    return [_to_read(c) for c in compras]


async def detalle(
    db: AsyncSession, compra_id: int, user_id: int, rol: RolUsuario
) -> CompraRead:
    compra = await compra_repo.get(db, compra_id)
    if compra is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Compra no encontrada")
    # El cliente solo ve las suyas; trabajador/admin ven cualquiera.
    if rol == RolUsuario.cliente and compra.usuario_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No autorizado")
    return _to_read(compra)


async def cancelar(db: AsyncSession, compra_id: int, user_id: int) -> CompraRead:
    compra = await compra_repo.get(db, compra_id)
    if compra is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Compra no encontrada")
    if compra.usuario_id != user_id:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No autorizado")
    if compra.qr_estado != EstadoQR.activo:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Solo se pueden cancelar compras activas",
        )
    limite = compra.funcion.inicio - timedelta(hours=settings.cancel_window_hours)
    if datetime.now(timezone.utc) >= limite:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Fuera de la ventana de cancelación",
        )

    compra.qr_estado = EstadoQR.cancelado
    for ca in compra.asientos:
        ca.asiento_funcion.estado = EstadoAsientoFuncion.libre
        ca.asiento_funcion.reservado_por = None
        ca.asiento_funcion.reservado_hasta = None
    if compra.promocion_id is not None:
        promocion = await promocion_repo.get(db, compra.promocion_id)
        if promocion and promocion.usos_actuales > 0:
            promocion.usos_actuales -= 1

    await db.commit()
    actualizada = await compra_repo.get(db, compra.id)

    # Tiempo real: los asientos se liberaron.
    await rt_seats.broadcast_seat_map(db, actualizada.funcion_id)
    await rt_notif.broadcast_occupancy(db)
    return _to_read(actualizada)
