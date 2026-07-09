import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda los tokens JWT de forma segura (Keychain/Keystore).
class TokenStorage {
  static const _accessKey = 'cs_access_token';
  static const _refreshKey = 'cs_refresh_token';

  final FlutterSecureStorage _storage;

  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: _accessKey, value: access);
    await _storage.write(key: _refreshKey, value: refresh);
  }

  Future<void> saveAccess(String access) =>
      _storage.write(key: _accessKey, value: access);

  Future<String?> get accessToken => _storage.read(key: _accessKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshKey);

  Future<bool> get hasTokens async => (await accessToken) != null;

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
