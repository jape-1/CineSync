import 'package:dio/dio.dart';

import '../config.dart';
import '../session.dart';
import '../storage/token_storage.dart';

/// Cliente HTTP central (Dio) con:
///  - baseUrl del API v1
///  - interceptor que adjunta el access token
///  - refresh automático del access token ante un 401 (una sola vez)
class ApiClient {
  final TokenStorage _tokens;
  late final Dio dio;

  ApiClient(this._tokens) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  bool _isAuthPublicPath(String path) =>
      path.contains('/auth/login') ||
      path.contains('/auth/registro') ||
      path.contains('/auth/refresh') ||
      path.contains('/auth/olvide-password') ||
      path.contains('/auth/reset-password');

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthPublicPath(options.path)) {
      final token = await _tokens.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final path = err.requestOptions.path;
    final alreadyRetried = err.requestOptions.extra['__retried__'] == true;

    if (response?.statusCode == 401 &&
        !alreadyRetried &&
        !_isAuthPublicPath(path)) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        try {
          final opts = err.requestOptions;
          opts.extra['__retried__'] = true;
          final newToken = await _tokens.accessToken;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final clone = await dio.fetch(opts);
          return handler.resolve(clone);
        } catch (_) {
          // cae al reject de abajo
        }
      } else {
        await _tokens.clear();
        notifySessionExpired();
      }
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await _tokens.refreshToken;
    if (refresh == null) return false;
    try {
      // Dio limpio, sin interceptores, para no recursar.
      final bare = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final res = await bare.post(
        '/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final data = res.data as Map<String, dynamic>;
      await _tokens.save(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
