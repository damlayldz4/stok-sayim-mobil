import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'api_client.dart';

/// Uygulama genelinde kimlik doğrulama durumunu tutar. main.dart'ta
/// Provider ile tüm widget ağacına açılır; ekranlar context.watch /
/// context.read ile buna erişir.
class AuthService extends ChangeNotifier {
  final ApiClient _client;

  AppUser? _currentUser;
  bool _isLoading = true; // Uygulama açılışında kayıtlı token kontrolü sürüyor.

  AuthService(this._client) {
    _restoreSession();
  }

  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  /// Uygulama her açıldığında, daha önce kaydedilmiş bir token varsa
  /// /me endpoint'i ile hâlâ geçerli olup olmadığını kontrol eder.
  Future<void> _restoreSession() async {
    final token = await _client.token;

    if (token != null) {
      try {
        final json = await _client.get('/me');
        _currentUser = AppUser.fromJson(json as Map<String, dynamic>);
      } catch (_) {
        await _client.clearToken();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final json = await _client.post(
      '/login',
      body: {'username': username, 'password': password},
      auth: false,
    );

    await _client.saveToken(json['token'] as String);
    _currentUser = AppUser.fromJson(json['user'] as Map<String, dynamic>);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _client.post('/logout');
    } catch (_) {
      // Token zaten geçersizse önemli değil, yerel oturumu yine temizliyoruz.
    }

    await _client.clearToken();
    _currentUser = null;
    notifyListeners();
  }
}
