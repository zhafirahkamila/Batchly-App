import 'recipe_ingredient.dart';

class Recipe {
  final int id;
  final String name;
  final double yieldQty;
  final String yieldUnit;
  final List<RecipeIngredient> ingredients;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Recipe({
    required this.id,
    required this.name,
    required this.yieldQty,
    required this.yieldUnit,
    this.ingredients = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    final ing = json['ingredients'];
    return Recipe(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      yieldQty: _num(json['yield_qty']),
      yieldUnit: (json['yield_unit'] ?? 'pcs') as String,
      ingredients: ing is List
          ? ing
              .cast<Map<String, dynamic>>()
              .map(RecipeIngredient.fromJson)
              .toList()
          : const [],
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  Map<String, dynamic> toCreateJson() => {
        'name': name,
        'yield_qty': yieldQty,
        'yield_unit': yieldUnit,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
      };
}

double _num(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}
