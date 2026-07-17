import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/hpp_breakdown.dart';
import '../providers/auth_provider.dart';
import '../providers/guest_data_store.dart';

class PricingService {
  final ApiClient _api;
  final AuthProvider _auth;
  final GuestDataStore _guest;

  PricingService(this._api, this._auth, this._guest);

  Future<HppBreakdown> calculate({
    required int recipeId,
    required double targetMarginPercent,
    required List<({int overheadCostId, int estimatedMonthlyProduction})> allocations,
  }) async {
    if (_auth.isGuest) {
      return _guest.calculatePricing(
        recipeId: recipeId,
        targetMarginPercent: targetMarginPercent,
        allocations: allocations,
      );
    }
    final res = await _api.post(
      Endpoints.recipeCalculate(recipeId),
      body: {
        'target_margin_percent': targetMarginPercent,
        'overhead_allocations': allocations
            .map((a) => {
                  'overhead_cost_id': a.overheadCostId,
                  'estimated_monthly_production': a.estimatedMonthlyProduction,
                })
            .toList(),
      },
    );
    return HppBreakdown.fromJson(res as Map<String, dynamic>);
  }
}
