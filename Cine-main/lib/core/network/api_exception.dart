import 'package:dio/dio.dart';

/// Excepción de dominio con un mensaje legible extraído de la respuesta del API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;

  /// Construye un mensaje amigable a partir de un [DioException].
  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    if (res != null) {
      final data = res.data;
      String? detail;
      if (data is Map && data['detail'] != null) {
        final d = data['detail'];
        if (d is String) {
          detail = d;
        } else if (d is List && d.isNotEmpty) {
          // Errores de validación de Pydantic: [{loc, msg, ...}]
          final first = d.first;
          if (first is Map && first['msg'] != null) {
            detail = first['msg'].toString();
          }
        }
      }
      return ApiException(
        detail ?? 'Error ${res.statusCode}',
        statusCode: res.statusCode,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException('No se pudo conectar con el servidor');
    }
    return ApiException('Error inesperado de red');
  }
}
