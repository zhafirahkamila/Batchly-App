class DashboardItem {
  final int recipeId;
  final String name;
  final double yieldQty;
  final String yieldUnit;
  final double? hppPerUnit;
  final double? suggestedPrice;
  final double? targetMarginPercent;
  final double? marginPercent;
  final DateTime? calculatedAt;

  DashboardItem({
    required this.recipeId,
    required this.name,
    required this.yieldQty,
    required this.yieldUnit,
    this.hppPerUnit,
    this.suggestedPrice,
    this.targetMarginPercent,
    this.marginPercent,
    this.calculatedAt,
  });

  factory DashboardItem.fromJson(Map<String, dynamic> json) {
    return DashboardItem(
      recipeId: (json['recipe_id'] as num).toInt(),
      name: (json['name'] ?? '') as String,
      yieldQty: _num(json['yield_qty']),
      yieldUnit: (json['yield_unit'] ?? 'pcs') as String,
      hppPerUnit: _optNum(json['hpp_per_unit']),
      suggestedPrice: _optNum(json['suggested_price']),
      targetMarginPercent: _optNum(json['target_margin_percent']),
      marginPercent: _optNum(json['margin_percent']),
      calculatedAt: json['calculated_at'] == null
          ? null
          : DateTime.tryParse(json['calculated_at'].toString()),
    );
  }
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

double? _optNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
