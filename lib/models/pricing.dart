class Pricing {
  final int recipeId;
  final double hppPerUnit;
  final double ingredientCostPerUnit;
  final double packagingCostPerUnit;
  final double overheadCostPerUnit;
  final double priceBufferPercent;
  final double hppBeforeBuffer;
  final double? targetMarginPercent;
  final double? suggestedPrice;
  final DateTime? updatedAt;

  Pricing({
    required this.recipeId,
    required this.hppPerUnit,
    this.ingredientCostPerUnit = 0,
    this.packagingCostPerUnit = 0,
    this.overheadCostPerUnit = 0,
    this.priceBufferPercent = 0,
    this.hppBeforeBuffer = 0,
    this.targetMarginPercent,
    this.suggestedPrice,
    this.updatedAt,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    // Backend's GET /pricing endpoint returns the timestamp as `calculated_at`
    // (matches HppBreakdown). Older code paths and the guest store may send
    // `updated_at` — accept either.
    final tsRaw = json['calculated_at'] ?? json['updated_at'];
    return Pricing(
      recipeId: (json['recipe_id'] as num).toInt(),
      hppPerUnit: _num(json['hpp_per_unit']),
      ingredientCostPerUnit: _num(json['ingredient_cost_per_unit']),
      packagingCostPerUnit: _num(json['packaging_cost_per_unit']),
      overheadCostPerUnit: _num(json['overhead_cost_per_unit']),
      priceBufferPercent: _num(json['price_buffer_percent']),
      hppBeforeBuffer: _num(json['hpp_before_buffer']),
      targetMarginPercent: json['target_margin_percent'] == null
          ? null
          : _num(json['target_margin_percent']),
      suggestedPrice:
          json['suggested_price'] == null ? null : _num(json['suggested_price']),
      updatedAt: tsRaw == null ? null : DateTime.tryParse(tsRaw.toString()),
    );
  }
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
