import '../../../core/json.dart';

/// Estado en vivo de un asiento dentro de una función.
class Seat {
  final int asientoFuncionId;
  final int asientoId;
  final String fila;
  final int numero;
  final String tipo; // normal | vip | discapacitado
  final String estado; // libre | reservado_temporal | ocupado
  final int? reservadoPor;
  final DateTime? reservadoHasta;

  const Seat({
    required this.asientoFuncionId,
    required this.asientoId,
    required this.fila,
    required this.numero,
    required this.tipo,
    required this.estado,
    this.reservadoPor,
    this.reservadoHasta,
  });

  factory Seat.fromJson(Map<String, dynamic> j) => Seat(
        asientoFuncionId: j['asiento_funcion_id'] as int,
        asientoId: j['asiento_id'] as int,
        fila: j['fila'] as String,
        numero: j['numero'] as int,
        tipo: j['tipo'] as String,
        estado: j['estado'] as String,
        reservadoPor: j['reservado_por'] as int?,
        reservadoHasta: asDateOrNull(j['reservado_hasta']),
      );

  String get label => '$fila$numero';
  bool get esVip => tipo == 'vip';
}
