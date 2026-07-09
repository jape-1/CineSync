import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/models.dart';

class CatalogRepository {
  final ApiClient _api;
  CatalogRepository(this._api);

  Dio get _dio => _api.dio;

  Future<List<Pelicula>> peliculas({String? genero}) async {
    try {
      final res = await _dio.get('/peliculas', queryParameters: {
        'activa': true,
        if (genero != null) 'genero': genero,
      });
      return (res.data as List)
          .map((e) => Pelicula.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Pelicula> pelicula(int id) async {
    try {
      final res = await _dio.get('/peliculas/$id');
      return Pelicula.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Genero>> generos() async {
    try {
      final res = await _dio.get('/generos');
      return (res.data as List)
          .map((e) => Genero.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Funcion>> funciones({int? peliculaId}) async {
    try {
      final res = await _dio.get('/funciones', queryParameters: {
        if (peliculaId != null) 'pelicula_id': peliculaId,
      });
      return (res.data as List)
          .map((e) => Funcion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Funcion> funcion(int id) async {
    try {
      final res = await _dio.get('/funciones/$id');
      return Funcion.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
