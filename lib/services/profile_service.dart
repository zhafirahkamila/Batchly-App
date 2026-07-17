import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/user.dart';

class ProfileService {
  final ApiClient _api;
  ProfileService(this._api);

  Future<User> get() async {
    final res = await _api.get(Endpoints.profile);
    return User.fromJson(res as Map<String, dynamic>);
  }

  Future<User> update({required String name, String? businessName}) async {
    final res = await _api.put(Endpoints.profile, body: {
      'name': name,
      if (businessName != null) 'business_name': businessName,
    });
    return User.fromJson(res as Map<String, dynamic>);
  }
}
