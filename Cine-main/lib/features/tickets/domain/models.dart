import '../../../core/json.dart';

class CompraFuncion {
  final int id;
  final DateTime inicio;
  final DateTime fin;
  final String peliculaTitulo;
  final String salaNombre;

  const CompraFuncion({
    required this.id,
    required this.inicio,
    required this.fin,
    required this.peliculaTitulo,
    required this.salaNombre,
  });

  factory CompraFuncion.fromJson(Map<String, dynamic> j) => CompraFuncion(
        id: j['id'] as int,
        inicio: DateTime.parse(j['inicio'] as String),
        fin: DateTime.parse(j['fin'] as String),
        peliculaTitulo: j['pelicula_titulo'] as String,
        salaNombre: j['sala_nombre'] as String,
      );
}

class CompraAsiento {
  final int asientoFuncionId;
  final String fila;
  final int numero;

  const CompraAsiento({
    required this.asientoFuncionId,
    required this.fila,
    required this.numero,
  });

  factory CompraAsiento.fromJson(Map<String, dynamic> j) => CompraAsiento(
        asientoFuncionId: j['asiento_funcion_id'] as int,
        fila: j['fila'] as String,
        numero: j['numero'] as int,
      );

  String get label => '$fila$numero';
}

class CompraProducto {
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  const CompraProducto({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  factory CompraProducto.fromJson(Map<String, dynamic> j) => CompraProducto(
        nombre: j['nombre'] as String,
        cantidad: j['cantidad'] as int,
        precioUnitario: asDouble(j['precio_unitario']),
      );
}

class Compra {
  final int id;
  final CompraFuncion funcion;
  final List<CompraAsiento> asientos;
  final List<CompraProducto> productos;
  final double subtotal;
  final double descuento;
  final double total;
  final String qrCodigo;
  final String qrEstado; // activo | usado | cancelado
  final DateTime creadoEn;
  final DateTime? usadoEn;

  const Compra({
    required this.id,
    required this.funcion,
    required this.asientos,
    required this.productos,
    required this.subtotal,
    required this.descuento,
    required this.total,
    required this.qrCodigo,
    required this.qrEstado,
    required this.creadoEn,
    this.usadoEn,
  });

  factory Compra.fromJson(Map<String, dynamic> j) => Compra(
        id: j['id'] as int,
        funcion: CompraFuncion.fromJson(j['funcion'] as Map<String, dynamic>),
        asientos: ((j['asientos'] as List?) ?? [])
            .map((e) => CompraAsiento.fromJson(e as Map<String, dynamic>))
            .toList(),
        productos: ((j['productos'] as List?) ?? [])
            .map((e) => CompraProducto.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: asDouble(j['subtotal']),
        descuento: asDouble(j['descuento']),
        total: asDouble(j['total']),
        qrCodigo: j['qr_codigo'] as String,
        qrEstado: j['qr_estado'] as String,
        creadoEn: DateTime.parse(j['creado_en'] as String),
        usadoEn: asDateOrNull(j['usado_en']),
      );

  String get asientosLabel => asientos.map((a) => a.label).join(' · ');
}
