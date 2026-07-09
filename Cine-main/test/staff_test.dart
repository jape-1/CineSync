import 'package:flutter_test/flutter_test.dart';

import 'package:cinesync/features/staff/domain/models.dart';

void main() {
  test('ValidacionResponse.fromJson parsea resultado y ticket', () {
    final r = ValidacionResponse.fromJson({
      'resultado': 'valido',
      'motivo': null,
      'ticket': {
        'compra_id': 7,
        'pelicula_titulo': 'Origen',
        'sala_nombre': 'Sala 1',
        'inicio': '2026-08-01T18:00:00Z',
        'asientos': ['A1', 'A2'],
        'cliente_nombre': 'Ana',
      },
    });
    expect(r.resultado, ResultadoValidacion.valido);
    expect(r.ticket!.compraId, 7);
    expect(r.ticket!.asientosLabel, 'A1 · A2');
  });

  test('ValidacionResponse sin ticket (código inválido)', () {
    final r = ValidacionResponse.fromJson({
      'resultado': 'invalido',
      'motivo': 'Código no válido',
      'ticket': null,
    });
    expect(r.resultado, ResultadoValidacion.invalido);
    expect(r.ticket, isNull);
    expect(r.motivo, 'Código no válido');
  });

  test('OccupancyFuncion.fromJson parsea porcentaje', () {
    final f = OccupancyFuncion.fromJson({
      'funcion_id': 1,
      'pelicula_titulo': 'Origen',
      'sala_nombre': 'S1',
      'inicio': '2026-09-01T18:00:00Z',
      'total_asientos': 6,
      'ocupados': 1,
      'porcentaje': 16.7,
    });
    expect(f.ocupados, 1);
    expect(f.porcentaje, 16.7);
  });
}
