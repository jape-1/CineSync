import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/app_user.dart';

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _tokens;

  AuthRepository(this._api, this._tokens);

  Dio get _dio => _api.dio;

  Future<void> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      final data = res.data as Map<String, dynamic>;
      await _tokens.save(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser> register(String nombre, String email, String password) async {
    try {
      final res = await _dio.post('/auth/registro', data: {
        'nombre': nombre,
        'email': email,
        'password': password,
      });
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AppUser> me() async {
    try {
      final res = await _dio.get('/usuarios/me');
      return AppUser.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    final refresh = await _tokens.refreshToken;
    try {
      if (refresh != null) {
        await _dio.post('/auth/logout', data: {'refresh_token': refresh});
      }
    } on DioException {
      // Da igual si falla en el servidor: localmente cerramos sesión.
    } finally {
      await _tokens.clear();
    }
  }

  /// Devuelve el reset_token (en dev el backend lo retorna en la respuesta).
  Future<String> forgotPassword(String email) async {
    try {
      final res = await _dio.post('/auth/olvide-password', data: {'email': email});
      return (res.data as Map<String, dynamic>)['reset_token'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'reset_token': resetToken,
        'nueva_password': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
