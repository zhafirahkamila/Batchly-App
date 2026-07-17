import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Thin JSON client on top of `package:http`. Handles:
///   - resolving a sensible base URL per platform (Android emulator needs
///     10.0.2.2 instead of localhost)
///   - injecting a Bearer token when one is set
///   - decoding JSON, and turning non-2xx responses into [ApiException]
///
/// Override the base URL at build time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.42:3000
class ApiClient {
  ApiClient({String? baseUrl, http.Client? httpClient})
      : _baseUrl = baseUrl ?? _defaultBaseUrl(),
        _http = httpClient ?? http.Client();

  static const _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String _defaultBaseUrl() {
    if (_envBaseUrl.isNotEmpty) return _envBaseUrl;
    if (kIsWeb) return 'http://localhost:3000';
    // Android emulator maps host localhost → 10.0.2.2. iOS Sim / desktop use
    // localhost directly.
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  final String _baseUrl;
  final http.Client _http;

  String? _token;
  void setToken(String? token) => _token = token;
  String get baseUrl => _baseUrl;

  Map<String, String> _headers({bool json = true}) {
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null && _token!.isNotEmpty) 'Authorization': 'Bearer $_token',
    };
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<dynamic> get(String path) async {
    final res = await _http.get(_uri(path), headers: _headers(json: false));
    return _decode(res);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final res = await _http.post(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final res = await _http.put(
      _uri(path),
      headers: _headers(),
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  Future<void> delete(String path) async {
    final res = await _http.delete(_uri(path), headers: _headers(json: false));
    if (res.statusCode == 204) return;
    _decode(res);
  }

  dynamic _decode(http.Response res) {
    dynamic body;
    if (res.body.isNotEmpty) {
      try {
        body = jsonDecode(res.body);
      } catch (_) {
        body = res.body;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    final msg = (body is Map && body['error'] is String)
        ? body['error'] as String
        : 'HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, msg, body);
  }
}
