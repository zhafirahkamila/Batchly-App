class Pricing {
  final int recipeId;
  final double hppPerUnit;
  final double? targetMarginPercent;
  final double? suggestedPrice;
  final DateTime? updatedAt;

  Pricing({
    required this.recipeId,
    required this.hppPerUnit,
    this.targetMarginPercent,
    this.suggestedPrice,
    this.updatedAt,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      recipeId: (json['recipe_id'] as num).toInt(),
      hppPerUnit: _num(json['hpp_per_unit']),
      targetMarginPercent: json['target_margin_percent'] == null
          ? null
          : _num(json['target_margin_percent']),
      suggestedPrice:
          json['suggested_price'] == null ? null : _num(json['suggested_price']),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse(json['updated_at'].toString()),
    );
  }
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
