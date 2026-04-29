import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/api_client.dart';
import '../api/auth_api.dart';
import '../models/user.dart';

const _kAccessTokenKey = 'access_token';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = true; // true while checking persisted token on startup

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  /// Called once at startup. Tries to restore a saved token.
  Future<void> tryRestoreSession() async {
    final token = await _storage.read(key: _kAccessTokenKey);
    if (token != null) {
      apiClient.setToken(token);
      try {
        _user = await authApi.me();
      } catch (_) {
        // Token is stale or invalid — clear it.
        await _storage.delete(key: _kAccessTokenKey);
        apiClient.clearToken();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final tokens = await authApi.login(username, password);
    final accessToken = tokens['access'] as String;

    await _storage.write(key: _kAccessTokenKey, value: accessToken);
    apiClient.setToken(accessToken);

    _user = await authApi.me();
    notifyListeners();
  }

  Future<void> register(
    String username,
    String email,
    String password,
  ) async {
    await authApi.register(username, email, password);
    // After registration, log them in immediately.
    await login(username, password);
  }

  Future<void> logout() async {
    await _storage.delete(key: _kAccessTokenKey);
    apiClient.clearToken();
    _user = null;
    notifyListeners();
  }
}
