import 'package:flutter_test/flutter_test.dart';

import 'package:cinesync/features/auth/domain/app_user.dart';
import 'package:cinesync/features/tickets/domain/models.dart';

void main() {
  test('UserRole.fromString mapea el rol del JWT', () {
    expect(UserRole.fromString('administrador'), UserRole.administrador);
    expect(UserRole.fromString('trabajador'), UserRole.trabajador);
    expect(UserRole.fromString('desconocido'), UserRole.cliente);
  });

  test('Compra.fromJson parsea montos (Decimal como string) y asientos', () {
    final compra = Compra.fromJson({
      'id': 1,
      'funcion': {
        'id': 3,
        'inicio': '2026-08-01T18:00:00Z',
        'fin': '2026-08-01T20:00:00Z',
        'pelicula_titulo': 'Origen',
        'sala_nombre': 'Sala 1',
      },
      'asientos': [
        {'asiento_funcion_id': 1, 'fila': 'A', 'numero': 1},
        {'asiento_funcion_id': 2, 'fila': 'A', 'numero': 2},
      ],
      'productos': [],
      'subtotal': '86.00',
      'descuento': '8.60',
      'total': '77.40',
      'qr_codigo': 'abc.def.ghi',
      'qr_estado': 'activo',
      'creado_en': '2026-07-09T10:00:00Z',
      'usado_en': null,
    });
    expect(compra.total, 77.40);
    expect(compra.asientosLabel, 'A1 · A2');
    expect(compra.qrEstado, 'activo');
  });
}
