import '../core/api/api_client.dart';
import '../core/api/api_exception.dart';
import '../core/api/endpoints.dart';
import '../models/hpp_breakdown.dart';
import '../models/pricing.dart';
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
    double priceBufferPercent = 0,
  }) async {
    if (_auth.isGuest) {
      return _guest.calculatePricing(
        recipeId: recipeId,
        targetMarginPercent: targetMarginPercent,
        allocations: allocations,
        priceBufferPercent: priceBufferPercent,
      );
    }
    final res = await _api.post(
      Endpoints.recipeCalculate(recipeId),
      body: {
        'target_margin_percent': targetMarginPercent,
        'price_buffer_percent': priceBufferPercent,
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

  /// Returns the persisted pricing summary for [recipeId], or null when the
  /// user hasn't calculated pricing for this recipe yet. Absence is a normal
  /// state — the detail page renders a "not calculated" placeholder for it.
  Future<Pricing?> fetchForRecipe(int recipeId) async {
    if (_auth.isGuest) return _guest.pricingFor(recipeId);
    try {
      final res = await _api.get(Endpoints.recipePricing(recipeId));
      if (res == null) return null;
      return Pricing.fromJson(res as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }
}
