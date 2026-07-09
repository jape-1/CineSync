import 'package:flutter_test/flutter_test.dart';

import 'package:cinesync/features/admin/domain/models.dart';

void main() {
  test('Sala.fromJson calcula capacidad', () {
    final s = Sala.fromJson({
      'id': 1,
      'nombre': 'Sala 1',
      'tipo': '2D',
      'filas': 5,
      'columnas': 8,
      'activa': true,
    });
    expect(s.capacidad, 40);
    expect(s.tipo, '2D');
  });

  test('Promocion.valorLegible según tipo', () {
    final pct = Promocion.fromJson({
      'id': 1,
      'codigo': 'CINE10',
      'descripcion': null,
      'tipo_descuento': 'porcentaje',
      'valor': '10.00',
      'activo': true,
      'usos_maximos': null,
      'usos_actuales': 0,
    });
    expect(pct.valorLegible, '10%');

    final monto = Promocion.fromJson({
      'id': 2,
      'codigo': 'FIJO5',
      'descripcion': null,
      'tipo_descuento': 'monto',
      'valor': '5.00',
      'activo': true,
      'usos_maximos': 100,
      'usos_actuales': 3,
    });
    expect(monto.valorLegible, 'S/5.00');
  });
}
