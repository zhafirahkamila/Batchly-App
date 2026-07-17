import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/dashboard_item.dart';
import '../providers/auth_provider.dart';
import '../providers/guest_data_store.dart';

class DashboardService {
  final ApiClient _api;
  final AuthProvider _auth;
  final GuestDataStore _guest;

  DashboardService(this._api, this._auth, this._guest);

  Future<List<DashboardItem>> summary() async {
    if (_auth.isGuest) return _guest.dashboardItems();
    final res = await _api.get(Endpoints.dashboardSummary) as List;
    return res.cast<Map<String, dynamic>>().map(DashboardItem.fromJson).toList();
  }
}
