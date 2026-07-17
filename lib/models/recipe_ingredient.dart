class RecipeIngredient {
  final int? id;
  final int ingredientId;
  final String? name;      // populated by joined detail endpoint
  final double qtyUsed;
  final String unit;
  final double? lineCost;  // present on detail response

  RecipeIngredient({
    this.id,
    required this.ingredientId,
    this.name,
    required this.qtyUsed,
    required this.unit,
    this.lineCost,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'] as int?,
      ingredientId: (json['ingredient_id'] as num).toInt(),
      name: json['name'] as String?,
      qtyUsed: _num(json['qty_used']),
      unit: (json['unit'] ?? '') as String,
      lineCost: json['line_cost'] == null ? null : _num(json['line_cost']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ingredient_id': ingredientId,
        'qty_used': qtyUsed,
        'unit': unit,
      };
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
