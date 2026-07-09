"""Lógica de validación de QR por el trabajador.

Reglas (PRD §8): el código debe existir, tener firma válida, no estar vencido y no
haber sido usado. Si es válido, marca la compra como usada. El broadcast del evento
por WebSocket (`ticket_status_changed`, `validation_count_update`) se conecta en la
Fase 4 — aquí queda el punto de extensión.
"""

from __future__ import annotations

from datetime import date, datetime, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.compra import Compra
from app.models.enums import EstadoQR, ResultadoValidacion
from app.models.validacion import ValidacionQR
from app.realtime import notifications as rt_notif
from app.repositories import validacion as validacion_repo
from app.repositories import compra as compra_repo
from app.schemas.validacion import (
    TicketInfo,
    ValidacionHistorialItem,
    ValidacionResponse,
)
from app.services import qr as qr_service


def _ticket(compra: Compra) -> TicketInfo:
    asientos = sorted(
        f"{ca.asiento_funcion.asiento.fila}{ca.asiento_funcion.asiento.numero}"
        for ca in compra.asientos
    )
    return TicketInfo(
        compra_id=compra.id,
        pelicula_titulo=compra.funcion.pelicula.titulo,
        sala_nombre=compra.funcion.sala.nombre,
        inicio=compra.funcion.inicio,
        asientos=asientos,
        cliente_nombre=compra.usuario.nombre,
    )


async def _registrar(
    db: AsyncSession,
    trabajador_id: int,
    codigo: str,
    resultado: ResultadoValidacion,
    compra_id: int | None,
) -> None:
    await validacion_repo.add(
        db,
        ValidacionQR(
            compra_id=compra_id,
            trabajador_id=trabajador_id,
            codigo_escaneado=codigo,
            resultado=resultado,
        ),
    )


async def validar(
    db: AsyncSession, trabajador_id: int, codigo: str
) -> ValidacionResponse:
    invalido = ResultadoValidacion.invalido

    if not qr_service.firma_valida(codigo):
        await _registrar(db, trabajador_id, codigo, invalido, None)
        await db.commit()
        return ValidacionResponse(resultado=invalido, motivo="Código no válido")

    compra = await compra_repo.get_by_qr(db, codigo)
    if compra is None:
        await _registrar(db, trabajador_id, codigo, invalido, None)
        await db.commit()
        return ValidacionResponse(resultado=invalido, motivo="Código no reconocido")

    ticket = _ticket(compra)

    if compra.qr_estado == EstadoQR.usado:
        await _registrar(db, trabajador_id, codigo, ResultadoValidacion.usado, compra.id)
        await db.commit()
        return ValidacionResponse(
            resultado=ResultadoValidacion.usado,
            motivo="La entrada ya fue usada",
            ticket=ticket,
        )

    if compra.qr_estado == EstadoQR.cancelado:
        await _registrar(db, trabajador_id, codigo, invalido, compra.id)
        await db.commit()
        return ValidacionResponse(
            resultado=invalido, motivo="La compra fue cancelada", ticket=ticket
        )

    if compra.funcion.fin < datetime.now(timezone.utc):
        await _registrar(db, trabajador_id, codigo, invalido, compra.id)
        await db.commit()
        return ValidacionResponse(
            resultado=invalido, motivo="La entrada está vencida", ticket=ticket
        )

    # Válida: marca la compra como usada.
    compra.qr_estado = EstadoQR.usado
    compra.usado_en = datetime.now(timezone.utc)
    await _registrar(db, trabajador_id, codigo, ResultadoValidacion.valido, compra.id)
    await db.commit()

    # Tiempo real: avisa al cliente y actualiza el contador del dashboard.
    await rt_notif.notify_ticket_validated(compra.usuario_id, compra.id)
    await rt_notif.broadcast_validation_count(db)
    return ValidacionResponse(resultado=ResultadoValidacion.valido, ticket=ticket)


async def historial(
    db: AsyncSession, funcion_id: int | None, fecha: date | None
) -> list[ValidacionHistorialItem]:
    filas = await validacion_repo.list_historial(db, funcion_id=funcion_id, fecha=fecha)
    return [
        ValidacionHistorialItem(
            id=v.id,
            compra_id=v.compra_id,
            resultado=v.resultado,
            codigo_escaneado=v.codigo_escaneado,
            escaneado_en=v.escaneado_en,
            trabajador_id=v.trabajador_id,
        )
        for v in filas
    ]
