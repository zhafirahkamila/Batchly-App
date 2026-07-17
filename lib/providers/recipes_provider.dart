import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../services/recipes_service.dart';

class RecipesProvider extends ChangeNotifier {
  final RecipesService _service;
  RecipesProvider(this._service);

  List<Recipe> _items = [];
  bool _loading = false;
  String? _error;

  List<Recipe> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.list();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Recipe> detail(int id) => _service.detail(id);

  Future<Recipe> create({
    required String name,
    required double yieldQty,
    required String yieldUnit,
    required List<RecipeIngredient> ingredients,
  }) async {
    final r = await _service.create(
      name: name,
      yieldQty: yieldQty,
      yieldUnit: yieldUnit,
      ingredients: ingredients,
    );
    _items = [..._items, r];
    notifyListeners();
    return r;
  }

  Future<Recipe> update(int id, {
    required String name,
    required double yieldQty,
    required String yieldUnit,
    required List<RecipeIngredient> ingredients,
  }) async {
    final r = await _service.update(
      id,
      name: name,
      yieldQty: yieldQty,
      yieldUnit: yieldUnit,
      ingredients: ingredients,
    );
    _items = _items.map((i) => i.id == id ? r : i).toList();
    notifyListeners();
    return r;
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    _items = _items.where((i) => i.id != id).toList();
    notifyListeners();
  }
}
