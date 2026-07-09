import '../../../core/json.dart';

class Producto {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final String? categoria;
  final bool activo;

  const Producto({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    this.categoria,
    this.activo = true,
  });

  factory Producto.fromJson(Map<String, dynamic> j) => Producto(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        precio: asDouble(j['precio']),
        imagenUrl: j['imagen_url'] as String?,
        categoria: j['categoria'] as String?,
        activo: j['activo'] as bool? ?? true,
      );
}

class Combo {
  final int id;
  final String nombre;
  final String? descripcion;
  final double precio;
  final String? imagenUrl;
  final bool activo;

  const Combo({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.precio,
    this.imagenUrl,
    this.activo = true,
  });

  factory Combo.fromJson(Map<String, dynamic> j) => Combo(
        id: j['id'] as int,
        nombre: j['nombre'] as String,
        descripcion: j['descripcion'] as String?,
        precio: asDouble(j['precio']),
        imagenUrl: j['imagen_url'] as String?,
        activo: j['activo'] as bool? ?? true,
      );
}

/// Un ítem seleccionable en la dulcería (producto o combo) unificado para la UI.
class SnackItem {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? imagenUrl;
  final bool esCombo;

  const SnackItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.imagenUrl,
    required this.esCombo,
  });

  factory SnackItem.fromProducto(Producto p) => SnackItem(
        id: p.id,
        nombre: p.nombre,
        descripcion: p.descripcion ?? (p.categoria ?? ''),
        precio: p.precio,
        imagenUrl: p.imagenUrl,
        esCombo: false,
      );

  factory SnackItem.fromCombo(Combo c) => SnackItem(
        id: c.id,
        nombre: c.nombre,
        descripcion: c.descripcion ?? 'Combo',
        precio: c.precio,
        imagenUrl: c.imagenUrl,
        esCombo: true,
      );
}
