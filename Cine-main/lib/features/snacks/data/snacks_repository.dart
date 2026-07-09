import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/models.dart';

class SnacksRepository {
  final ApiClient _api;
  SnacksRepository(this._api);

  Dio get _dio => _api.dio;

  Future<List<Producto>> productos() async {
    try {
      final res = await _dio.get('/productos');
      return (res.data as List)
          .map((e) => Producto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<Combo>> combos() async {
    try {
      final res = await _dio.get('/combos');
      return (res.data as List)
          .map((e) => Combo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
