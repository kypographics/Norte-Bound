import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthTokenStore {
  AuthTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'norte_bound.access_token';
  static const _roleKey = 'norte_bound.role';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<String?> readRole() => _storage.read(key: _roleKey);

  Future<void> saveSession({
    required String accessToken,
    required String role,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _roleKey, value: role);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _roleKey);
  }
}
