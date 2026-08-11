import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// API'den dönen hata mesajını taşır (Laravel validation/mesaj formatını çözer).
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

/// Tüm API isteklerinin geçtiği tek nokta: base URL, token ekleme,
/// JSON encode/decode ve hata çözümleme burada.
class ApiClient {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  Future<String?> get token => _storage.read(key: _tokenKey);

  Future<void> saveToken(String value) => _storage.write(key: _tokenKey, value: value);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (auth) {
      final t = await token;
      if (t != null) headers['Authorization'] = 'Bearer $t';
    }

    return headers;
  }

  Future<dynamic> get(String path) async {
    final res = await http.get(_uri(path), headers: await _headers());
    return _handle(res);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final res = await http.post(
      _uri(path),
      headers: await _headers(auth: auth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final res = await http.patch(
      _uri(path),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handle(res);
  }

  dynamic _handle(http.Response res) {
    final decoded = res.body.isNotEmpty ? jsonDecode(res.body) : null;

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return decoded;
    }

    String message = 'Bir hata oluştu (${res.statusCode}).';

    if (decoded is Map) {
      if (decoded['errors'] != null) {
        // Laravel validation hatası: {"errors": {"alan": ["mesaj", ...]}}
        final errors = decoded['errors'] as Map;
        final firstList = errors.values.first;
        if (firstList is List && firstList.isNotEmpty) {
          message = firstList.first.toString();
        }
      } else if (decoded['message'] != null) {
        message = decoded['message'].toString();
      }
    }

    throw ApiException(res.statusCode, message);
  }
}
