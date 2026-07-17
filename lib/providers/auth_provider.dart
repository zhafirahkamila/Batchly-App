import 'package:flutter/foundation.dart';

import '../core/api/api_client.dart';
import '../core/storage/secure_token_store.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Owns the authentication lifecycle:
///   - hydrates from secure storage on boot
///   - login / register (real backend) → persists token → hydrates user
///   - continueAsGuest → sets an in-memory guest user, no token, no API
///   - logout → clears everything
///
/// The router listens to this via `refreshListenable` to route users to
/// /login vs / based on [status].
enum AuthStatus { unknown, unauthenticated, authenticated, guest }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final ApiClient _api;
  final SecureTokenStore _tokenStore;

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _lastError;

  AuthProvider({
    required AuthService authService,
    required ApiClient api,
    required SecureTokenStore tokenStore,
  })  : _authService = authService,
        _api = api,
        _tokenStore = tokenStore;

  AuthStatus get status => _status;
  User? get user => _user;
  bool get isGuest => _status == AuthStatus.guest;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isReady => _status != AuthStatus.unknown;
  String? get lastError => _lastError;

  /// Called once at startup. Silently upgrades to authenticated if the stored
  /// token still validates; otherwise falls through to unauthenticated.
  Future<void> bootstrap() async {
    final token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _api.setToken(token);
    try {
      _user = await _authService.me();
      _status = AuthStatus.authenticated;
    } catch (_) {
      // Token expired or backend unreachable — treat as logged out. A user
      // still gets to see the login screen and try again.
      _api.setToken(null);
      await _tokenStore.clear();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _lastError = null;
    try {
      final r = await _authService.login(email, password);
      await _tokenStore.write(r.token);
      _api.setToken(r.token);
      _user = r.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? businessName,
  }) async {
    _lastError = null;
    try {
      final r = await _authService.register(
        name: name,
        email: email,
        password: password,
        businessName: businessName,
      );
      await _tokenStore.write(r.token);
      _api.setToken(r.token);
      _user = r.user;
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  void continueAsGuest() {
    _api.setToken(null);
    _user = User.guest();
    _status = AuthStatus.guest;
    _lastError = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _tokenStore.clear();
    _api.setToken(null);
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Updates the local user (called by profile update flow) so the header on
  /// the profile screen updates without a re-fetch.
  void updateLocalUser(User u) {
    _user = u;
    notifyListeners();
  }

  String _friendlyError(Object e) {
    final s = e.toString();
    if (s.contains('SocketException') || s.contains('Failed host')) {
      return 'Cannot connect to server. Make sure the backend is running.';
    }
    // ApiException.toString() already carries the backend message.
    return s.replaceFirst('ApiException', '').replaceFirst(RegExp(r'^\s*[(].*?[)]:\s*'), '');
  }
}
