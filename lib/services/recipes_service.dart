import '../core/api/api_client.dart';
import '../core/api/endpoints.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../providers/auth_provider.dart';
import '../providers/guest_data_store.dart';

class RecipesService {
  final ApiClient _api;
  final AuthProvider _auth;
  final GuestDataStore _guest;

  RecipesService(this._api, this._auth, this._guest);

  Future<List<Recipe>> list() async {
    if (_auth.isGuest) return _guest.recipes;
    final res = await _api.get(Endpoints.recipes) as List;
    return res.cast<Map<String, dynamic>>().map(Recipe.fromJson).toList();
  }

  Future<Recipe> detail(int id) async {
    if (_auth.isGuest) {
      final r = _guest.findRecipe(id);
      if (r == null) throw StateError('recipe not found');
      // Enrich ingredient rows with names + line_cost for the detail screen.
      final enriched = r.ingredients.map((ri) {
        final ing = _guest.findIngredient(ri.ingredientId);
        double? line;
        if (ing != null) {
          final qtyBase = ri.qtyUsed *
              _factor(ri.unit) /
              1; // qty in base of the row's unit family
          line = qtyBase * ing.pricePerBaseUnit;
        }
        return RecipeIngredient(
          id: ri.id,
          ingredientId: ri.ingredientId,
          name: ing?.name,
          qtyUsed: ri.qtyUsed,
          unit: ri.unit,
          lineCost: line,
        );
      }).toList();
      return Recipe(
        id: r.id,
        name: r.name,
        yieldQty: r.yieldQty,
        yieldUnit: r.yieldUnit,
        ingredients: enriched,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );
    }
    final res = await _api.get(Endpoints.recipeById(id));
    return Recipe.fromJson(res as Map<String, dynamic>);
  }

  Future<Recipe> create({
    required String name,
    required double yieldQty,
    required String yieldUnit,
    required List<RecipeIngredient> ingredients,
  }) async {
    if (_auth.isGuest) {
      return _guest.addRecipe(
        name: name,
        yieldQty: yieldQty,
        yieldUnit: yieldUnit,
        ingredients: ingredients,
      );
    }
    final res = await _api.post(Endpoints.recipes, body: {
      'name': name,
      'yield_qty': yieldQty,
      'yield_unit': yieldUnit,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
    });
    return Recipe.fromJson(res as Map<String, dynamic>);
  }

  Future<Recipe> update(int id, {
    required String name,
    required double yieldQty,
    required String yieldUnit,
    required List<RecipeIngredient> ingredients,
  }) async {
    if (_auth.isGuest) {
      return _guest.updateRecipe(
        id,
        name: name,
        yieldQty: yieldQty,
        yieldUnit: yieldUnit,
        ingredients: ingredients,
      );
    }
    final res = await _api.put(Endpoints.recipeById(id), body: {
      'name': name,
      'yield_qty': yieldQty,
      'yield_unit': yieldUnit,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
    });
    return Recipe.fromJson(res as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    if (_auth.isGuest) {
      _guest.deleteRecipe(id);
      return;
    }
    await _api.delete(Endpoints.recipeById(id));
  }

  // Tiny helper so we don't need to import units.dart just for a factor.
  double _factor(String unit) {
    switch (unit) {
      case 'kg':
      case 'liter':
        return 1000;
      default:
        return 1;
    }
  }
}
