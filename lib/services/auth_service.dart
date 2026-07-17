import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _api;
  AuthService(this._api);

  Future<({String token, User user})> register({
    required String name,
    required String email,
    required String password,
    String? businessName,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      if (businessName != null && businessName.isNotEmpty) 'business_name': businessName,
    };
    final res = await _api.post(Endpoints.authRegister, body: body);
    return (
      token: res['token'] as String,
      user: User.fromJson(res['user'] as Map<String, dynamic>),
    );
  }

  Future<({String token, User user})> login(String email, String password) async {
    final res = await _api.post(Endpoints.authLogin, body: {
      'email': email,
      'password': password,
    });
    return (
      token: res['token'] as String,
      user: User.fromJson(res['user'] as Map<String, dynamic>),
    );
  }

  Future<User> me() async {
    final res = await _api.get(Endpoints.authMe);
    return User.fromJson(res as Map<String, dynamic>);
  }
}
