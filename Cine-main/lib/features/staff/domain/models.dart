import '../../../core/json.dart';

enum ResultadoValidacion {
  valido,
  usado,
  invalido;

  static ResultadoValidacion fromString(String v) =>
      ResultadoValidacion.values.firstWhere((e) => e.name == v,
          orElse: () => ResultadoValidacion.invalido);
}

class TicketInfo {
  final int compraId;
  final String peliculaTitulo;
  final String salaNombre;
  final DateTime inicio;
  final List<String> asientos;
  final String clienteNombre;

  const TicketInfo({
    required this.compraId,
    required this.peliculaTitulo,
    required this.salaNombre,
    required this.inicio,
    required this.asientos,
    required this.clienteNombre,
  });

  factory TicketInfo.fromJson(Map<String, dynamic> j) => TicketInfo(
        compraId: j['compra_id'] as int,
        peliculaTitulo: j['pelicula_titulo'] as String,
        salaNombre: j['sala_nombre'] as String,
        inicio: DateTime.parse(j['inicio'] as String),
        asientos:
            ((j['asientos'] as List?) ?? []).map((e) => e.toString()).toList(),
        clienteNombre: j['cliente_nombre'] as String,
      );

  String get asientosLabel => asientos.join(' · ');
}

class ValidacionResponse {
  final ResultadoValidacion resultado;
  final String? motivo;
  final TicketInfo? ticket;

  const ValidacionResponse({
    required this.resultado,
    this.motivo,
    this.ticket,
  });

  factory ValidacionResponse.fromJson(Map<String, dynamic> j) =>
      ValidacionResponse(
        resultado: ResultadoValidacion.fromString(j['resultado'] as String),
        motivo: j['motivo'] as String?,
        ticket: j['ticket'] != null
            ? TicketInfo.fromJson(j['ticket'] as Map<String, dynamic>)
            : null,
      );
}

/// Ocupación de una función para el dashboard en vivo.
class OccupancyFuncion {
  final int funcionId;
  final String peliculaTitulo;
  final String salaNombre;
  final DateTime inicio;
  final int totalAsientos;
  final int ocupados;
  final double porcentaje;

  const OccupancyFuncion({
    required this.funcionId,
    required this.peliculaTitulo,
    required this.salaNombre,
    required this.inicio,
    required this.totalAsientos,
    required this.ocupados,
    required this.porcentaje,
  });

  factory OccupancyFuncion.fromJson(Map<String, dynamic> j) => OccupancyFuncion(
        funcionId: j['funcion_id'] as int,
        peliculaTitulo: j['pelicula_titulo'] as String,
        salaNombre: j['sala_nombre'] as String,
        inicio: DateTime.parse(j['inicio'] as String),
        totalAsientos: j['total_asientos'] as int,
        ocupados: j['ocupados'] as int,
        porcentaje: asDouble(j['porcentaje']),
      );
}
