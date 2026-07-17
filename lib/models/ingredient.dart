class Ingredient {
  final int id;
  final String name;
  final double purchasePrice;
  final double purchaseQty;
  final String purchaseUnit;
  final double pricePerBaseUnit;
  final String? category;

  Ingredient({
    required this.id,
    required this.name,
    required this.purchasePrice,
    required this.purchaseQty,
    required this.purchaseUnit,
    required this.pricePerBaseUnit,
    this.category,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      purchasePrice: _num(json['purchase_price']),
      purchaseQty: _num(json['purchase_qty']),
      purchaseUnit: (json['purchase_unit'] ?? '') as String,
      pricePerBaseUnit: _num(json['price_per_base_unit']),
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'purchase_price': purchasePrice,
        'purchase_qty': purchaseQty,
        'purchase_unit': purchaseUnit,
        if (category != null && category!.isNotEmpty) 'category': category,
      };

  Ingredient copyWith({
    int? id,
    String? name,
    double? purchasePrice,
    double? purchaseQty,
    String? purchaseUnit,
    double? pricePerBaseUnit,
    String? category,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      purchaseQty: purchaseQty ?? this.purchaseQty,
      purchaseUnit: purchaseUnit ?? this.purchaseUnit,
      pricePerBaseUnit: pricePerBaseUnit ?? this.pricePerBaseUnit,
      category: category ?? this.category,
    );
  }
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}
