import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/overhead.dart';
import '../providers/auth_provider.dart';
import '../providers/guest_data_store.dart';

class OverheadService {
  final ApiClient _api;
  final AuthProvider _auth;
  final GuestDataStore _guest;

  OverheadService(this._api, this._auth, this._guest);

  Future<List<Overhead>> list() async {
    if (_auth.isGuest) return _guest.overheads;
    final res = await _api.get(Endpoints.overhead) as List;
    return res.cast<Map<String, dynamic>>().map(Overhead.fromJson).toList();
  }

  Future<Overhead> create({
    required String name,
    required double amount,
    required String period,
  }) async {
    if (_auth.isGuest) {
      return _guest.addOverhead(name: name, amount: amount, period: period);
    }
    final res = await _api.post(Endpoints.overhead, body: {
      'name': name,
      'amount': amount,
      'period': period,
    });
    return Overhead.fromJson(res as Map<String, dynamic>);
  }

  Future<Overhead> update(int id, {
    required String name,
    required double amount,
    required String period,
  }) async {
    if (_auth.isGuest) {
      return _guest.updateOverhead(id, name: name, amount: amount, period: period);
    }
    final res = await _api.put(Endpoints.overheadById(id), body: {
      'name': name,
      'amount': amount,
      'period': period,
    });
    return Overhead.fromJson(res as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    if (_auth.isGuest) {
      _guest.deleteOverhead(id);
      return;
    }
    await _api.delete(Endpoints.overheadById(id));
  }
}
