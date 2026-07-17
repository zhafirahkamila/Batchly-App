/// Result of an HPP calculation — mirrors the JSON returned by
/// POST /api/recipes/:id/calculate. Also produced client-side by hpp_math.dart
/// for live preview + guest mode.
class HppBreakdown {
  final int recipeId;
  final double yieldQty;
  final String yieldUnit;
  final double targetMarginPercent;
  final List<IngredientBreakdownLine> ingredientBreakdown;
  final List<OverheadBreakdownLine> overheadBreakdown;
  final double ingredientCostTotal;
  final double ingredientCostPerUnit;
  final double totalOverheadPerUnit;
  final double hppPerUnit;
  final double priceBufferPercent;
  final double hppBeforeBuffer;
  final double suggestedPrice;
  final double profitPerUnit;
  final DateTime? calculatedAt;

  HppBreakdown({
    required this.recipeId,
    required this.yieldQty,
    required this.yieldUnit,
    required this.targetMarginPercent,
    required this.ingredientBreakdown,
    required this.overheadBreakdown,
    required this.ingredientCostTotal,
    required this.ingredientCostPerUnit,
    required this.totalOverheadPerUnit,
    required this.hppPerUnit,
    this.priceBufferPercent = 0,
    double? hppBeforeBuffer,
    required this.suggestedPrice,
    required this.profitPerUnit,
    this.calculatedAt,
  }) : hppBeforeBuffer = hppBeforeBuffer ?? hppPerUnit;

  double get marginPercent {
    if (suggestedPrice <= 0) return 0;
    return ((suggestedPrice - hppPerUnit) / suggestedPrice) * 100.0;
  }

  factory HppBreakdown.fromJson(Map<String, dynamic> json) {
    return HppBreakdown(
      recipeId: (json['recipe_id'] as num).toInt(),
      yieldQty: _num(json['yield_qty']),
      yieldUnit: (json['yield_unit'] ?? 'pcs') as String,
      targetMarginPercent: _num(json['target_margin_percent']),
      ingredientBreakdown: (json['ingredient_breakdown'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(IngredientBreakdownLine.fromJson)
          .toList(),
      overheadBreakdown: (json['overhead_breakdown'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .map(OverheadBreakdownLine.fromJson)
          .toList(),
      ingredientCostTotal: _num(json['ingredient_cost_total']),
      ingredientCostPerUnit: _num(json['ingredient_cost_per_unit']),
      totalOverheadPerUnit: _num(json['total_overhead_per_unit']),
      hppPerUnit: _num(json['hpp_per_unit']),
      priceBufferPercent: _num(json['price_buffer_percent']),
      hppBeforeBuffer: json['hpp_before_buffer'] == null
          ? _num(json['hpp_per_unit'])
          : _num(json['hpp_before_buffer']),
      suggestedPrice: _num(json['suggested_price']),
      profitPerUnit: _num(json['profit_per_unit']),
      calculatedAt: json['calculated_at'] == null
          ? null
          : DateTime.tryParse(json['calculated_at'].toString()),
    );
  }
}

class IngredientBreakdownLine {
  final int ingredientId;
  final String name;
  final double qtyUsed;
  final String unit;
  final double qtyInBaseUnit;
  final String purchaseUnit;
  final double pricePerBaseUnit;
  final double lineCost;

  IngredientBreakdownLine({
    required this.ingredientId,
    required this.name,
    required this.qtyUsed,
    required this.unit,
    required this.qtyInBaseUnit,
    required this.purchaseUnit,
    required this.pricePerBaseUnit,
    required this.lineCost,
  });

  factory IngredientBreakdownLine.fromJson(Map<String, dynamic> json) {
    return IngredientBreakdownLine(
      ingredientId: (json['ingredient_id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      qtyUsed: _num(json['qty_used']),
      unit: (json['unit'] ?? '') as String,
      qtyInBaseUnit: _num(json['qty_in_base_unit']),
      purchaseUnit: (json['purchase_unit'] ?? '') as String,
      pricePerBaseUnit: _num(json['price_per_base_unit']),
      lineCost: _num(json['line_cost']),
    );
  }
}

class OverheadBreakdownLine {
  final int overheadCostId;
  final String name;
  final double amount;
  final String period;
  final int estimatedMonthlyProduction;
  final double allocatedPerUnit;

  OverheadBreakdownLine({
    required this.overheadCostId,
    required this.name,
    required this.amount,
    required this.period,
    required this.estimatedMonthlyProduction,
    required this.allocatedPerUnit,
  });

  factory OverheadBreakdownLine.fromJson(Map<String, dynamic> json) {
    return OverheadBreakdownLine(
      overheadCostId: (json['overhead_cost_id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      amount: _num(json['amount']),
      period: (json['period'] ?? 'per_bulan') as String,
      estimatedMonthlyProduction:
          (json['estimated_monthly_production'] as num? ?? 1).toInt(),
      allocatedPerUnit: _num(json['allocated_per_unit']),
    );
  }
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
