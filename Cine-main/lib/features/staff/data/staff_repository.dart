import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/models.dart';

class StaffRepository {
  final ApiClient _api;
  StaffRepository(this._api);

  Dio get _dio => _api.dio;

  Future<ValidacionResponse> validar(String codigo) async {
    try {
      final res = await _dio.post('/validaciones', data: {
        'codigo_escaneado': codigo,
      });
      return ValidacionResponse.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
