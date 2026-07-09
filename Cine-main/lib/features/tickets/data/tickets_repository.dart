import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/models.dart';

class TicketsRepository {
  final ApiClient _api;
  TicketsRepository(this._api);

  Dio get _dio => _api.dio;

  Future<List<Compra>> historial({String? estado}) async {
    try {
      final res = await _dio.get('/compras', queryParameters: {
        if (estado != null) 'estado': estado,
      });
      return (res.data as List)
          .map((e) => Compra.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Compra> compra(int id) async {
    try {
      final res = await _dio.get('/compras/$id');
      return Compra.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
