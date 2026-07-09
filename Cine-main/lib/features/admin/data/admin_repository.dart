import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../auth/domain/app_user.dart';
import '../../catalog/domain/models.dart';
import '../../snacks/domain/models.dart';
import '../domain/models.dart';

/// Acceso a todos los endpoints de administración.
class AdminRepository {
  final ApiClient _api;
  AdminRepository(this._api);

  Dio get _dio => _api.dio;

  Future<T> _wrap<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  List<X> _list<X>(Response res, X Function(Map<String, dynamic>) f) =>
      (res.data as List).map((e) => f(e as Map<String, dynamic>)).toList();

  // --- Películas ---
  Future<List<Pelicula>> peliculas() => _wrap(() async =>
      _list(await _dio.get('/peliculas'), Pelicula.fromJson));

  Future<Pelicula> importarTmdb({int? tmdbId, String? titulo}) =>
      _wrap(() async {
        final res = await _dio.post('/peliculas/importar-tmdb', data: {
          if (tmdbId != null) 'tmdb_id': tmdbId,
          if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
        });
        return Pelicula.fromJson(res.data as Map<String, dynamic>);
      });

  Future<Pelicula> crearPelicula({
    required String titulo,
    String? sinopsis,
    int? duracionMin,
    String? clasificacion,
  }) =>
      _wrap(() async {
        final res = await _dio.post('/peliculas', data: {
          'titulo': titulo,
          if (sinopsis != null) 'sinopsis': sinopsis,
          if (duracionMin != null) 'duracion_min': duracionMin,
          if (clasificacion != null) 'clasificacion': clasificacion,
        });
        return Pelicula.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> archivarPelicula(int id) =>
      _wrap(() => _dio.delete('/peliculas/$id'));

  // --- Salas ---
  Future<List<Sala>> salas() =>
      _wrap(() async => _list(await _dio.get('/salas'), Sala.fromJson));

  Future<Sala> crearSala({
    required String nombre,
    required String tipo,
    required int filas,
    required int columnas,
  }) =>
      _wrap(() async {
        final res = await _dio.post('/salas', data: {
          'nombre': nombre,
          'tipo': tipo,
          'filas': filas,
          'columnas': columnas,
        });
        return Sala.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> eliminarSala(int id) => _wrap(() => _dio.delete('/salas/$id'));

  // --- Funciones ---
  Future<List<Funcion>> funciones() =>
      _wrap(() async => _list(await _dio.get('/funciones'), Funcion.fromJson));

  Future<Funcion> crearFuncion({
    required int peliculaId,
    required int salaId,
    required DateTime inicio,
    required double precioBase,
    String? idioma,
    String? formato,
  }) =>
      _wrap(() async {
        final res = await _dio.post('/funciones', data: {
          'pelicula_id': peliculaId,
          'sala_id': salaId,
          'inicio': inicio.toUtc().toIso8601String(),
          'precio_base': precioBase,
          if (idioma != null) 'idioma': idioma,
          if (formato != null) 'formato': formato,
        });
        return Funcion.fromJson(res.data as Map<String, dynamic>);
      });

  Future<void> eliminarFuncion(int id) =>
      _wrap(() => _dio.delete('/funciones/$id'));

  // --- Productos ---
  Future<List<Producto>> productos() =>
      _wrap(() async => _list(await _dio.get('/productos'), Producto.fromJson));

  Future<Producto> crearProducto({
    required String nombre,
    String? descripcion,
    required double precio,
    String? categoria,
  }) =>
      _wrap(() async {
        final res = await _dio.post('/productos', data: {
          'nombre': nombre,
          if (descripcion != null) 'descripcion': descripcion,
          'precio': precio,
          if (categoria != null) 'categoria': categoria,
        });
        return Producto.fromJson(res.data as Map<String, dynamic>);
      });

  // --- Combos ---
  Future<List<Combo>> combos() =>
      _wrap(() async => _list(await _dio.get('/combos'), Combo.fromJson));

  Future<Combo> crearCombo({
    required String nombre,
    String? descripcion,
    required double precio,
    required List<Map<String, int>> items,
  }) =>
      _wrap(() async {
        final res = await _dio.post('/combos', data: {
          'nombre': nombre,
          if (descripcion != null) 'descripcion': descripcion,
          'precio': precio,
          'items': items,
        });
        return Combo.fromJson(res.data as Map<String, dynamic>);
      });

  // --- Promociones ---
  Future<List<Promocion>> promociones() => _wrap(
      () async => _list(await _dio.get('/promociones'), Promocion.fromJson));

  Future<Promocion> crearPromocion({
    required String codigo,
    String? descripcion,
    required String tipoDescuento,
    required double valor,
    int? usosMaximos,
  }) =>
      _wrap(() async {
        final res = await _dio.post('/promociones', data: {
          'codigo': codigo,
          if (descripcion != null) 'descripcion': descripcion,
          'tipo_descuento': tipoDescuento,
          'valor': valor,
          if (usosMaximos != null) 'usos_maximos': usosMaximos,
        });
        return Promocion.fromJson(res.data as Map<String, dynamic>);
      });

  // --- Usuarios ---
  Future<List<AppUser>> usuarios({String? rol}) => _wrap(() async => _list(
      await _dio.get('/usuarios', queryParameters: {if (rol != null) 'rol': rol}),
      AppUser.fromJson));

  Future<AppUser> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required String rol,
    String? turno,
  }) =>
      _wrap(() async {
        final res = await _dio.post('/usuarios', data: {
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol,
          if (turno != null) 'turno': turno,
        });
        return AppUser.fromJson(res.data as Map<String, dynamic>);
      });

  Future<AppUser> editarUsuario(int id, {bool? activo, String? rol, String? turno}) =>
      _wrap(() async {
        final res = await _dio.patch('/usuarios/$id', data: {
          if (activo != null) 'activo': activo,
          if (rol != null) 'rol': rol,
          if (turno != null) 'turno': turno,
        });
        return AppUser.fromJson(res.data as Map<String, dynamic>);
      });

  // --- Reportes ---
  Future<Map<String, dynamic>> reporteVentas() => _wrap(() async =>
      (await _dio.get('/reportes/ventas')).data as Map<String, dynamic>);

  Future<Map<String, dynamic>> reporteOcupacion() => _wrap(() async =>
      (await _dio.get('/reportes/ocupacion')).data as Map<String, dynamic>);
}
