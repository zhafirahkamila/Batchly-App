import 'package:flutter/foundation.dart';

import '../models/hpp_breakdown.dart';
import '../models/pricing.dart';
import '../services/pricing_service.dart';

class PricingProvider extends ChangeNotifier {
  final PricingService _service;
  PricingProvider(this._service);

  bool _calculating = false;
  HppBreakdown? _last;
  String? _error;

  bool get calculating => _calculating;
  HppBreakdown? get last => _last;
  String? get error => _error;

  Future<HppBreakdown?> calculate({
    required int recipeId,
    required double targetMarginPercent,
    required List<({int overheadCostId, int estimatedMonthlyProduction})> allocations,
  }) async {
    _calculating = true;
    _error = null;
    notifyListeners();
    try {
      _last = await _service.calculate(
        recipeId: recipeId,
        targetMarginPercent: targetMarginPercent,
        allocations: allocations,
      );
      return _last;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _calculating = false;
      notifyListeners();
    }
  }

  Future<Pricing?> fetchForRecipe(int recipeId) =>
      _service.fetchForRecipe(recipeId);

  void clear() {
    _last = null;
    _error = null;
    notifyListeners();
  }
}
