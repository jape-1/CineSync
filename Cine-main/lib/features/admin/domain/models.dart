import '../../../core/json.dart';

class Sala {
  final int id;
  final String nombre;
  final String tipo; // 2D | 3D | VIP
  final int filas;
  final int columnas;
  final bool activa;

  const Sala({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.filas,
    required this.columnas,
    required this.activa,
  });

  factory Sala.fromJson(Map<String, dynamic> j) => Sala(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        tipo: j['tipo'] as String,
        filas: j['filas'] as int,
        columnas: j['columnas'] as int,
        activa: j['activa'] as bool? ?? true,
      );

  int get capacidad => filas * columnas;
}

class Promocion {
  final int id;
  final String codigo;
  final String? descripcion;
  final String tipoDescuento; // porcentaje | monto
  final double valor;
  final bool activo;
  final int? usosMaximos;
  final int usosActuales;

  const Promocion({
    required this.id,
    required this.codigo,
    this.descripcion,
    required this.tipoDescuento,
    required this.valor,
    required this.activo,
    this.usosMaximos,
    required this.usosActuales,
  });

  factory Promocion.fromJson(Map<String, dynamic> j) => Promocion(
        id: j['id'] as int,
        codigo: j['codigo'] as String,
        descripcion: j['descripcion'] as String?,
        tipoDescuento: j['tipo_descuento'] as String,
        valor: asDouble(j['valor']),
        activo: j['activo'] as bool? ?? true,
        usosMaximos: j['usos_maximos'] as int?,
        usosActuales: j['usos_actuales'] as int? ?? 0,
      );

  String get valorLegible =>
      tipoDescuento == 'porcentaje' ? '${valor.toStringAsFixed(0)}%' : 'S/${valor.toStringAsFixed(2)}';
}
