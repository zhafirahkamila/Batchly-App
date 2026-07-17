import 'package:flutter/foundation.dart';

import '../core/utils/hpp_math.dart';
import '../core/utils/units.dart';
import '../models/dashboard_item.dart';
import '../models/hpp_breakdown.dart';
import '../models/ingredient.dart';
import '../models/overhead.dart';
import '../models/pricing.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';

/// In-memory dataset used when the user chose "Lanjut sebagai Tamu". Mirrors
/// the backend's data model closely enough that services can swap between
/// this and the real API by branching on `AuthProvider.isGuest`.
///
/// Guest-mode "save" is a silent memory mutation (spec: "read-only save"),
/// not a modal — a persistent banner in RootShell nudges the user to register
/// if they want durability.
class GuestDataStore extends ChangeNotifier {
  GuestDataStore() {
    _seed();
  }

  final List<Ingredient> _ingredients = [];
  final List<Overhead> _overheads = [];
  final List<Recipe> _recipes = [];
  // recipeId → allocations picked in the pricing sheet
  final Map<int, List<({int overheadCostId, int estimatedMonthlyProduction})>>
      _recipeOverheadAllocs = {};
  final Map<int, Pricing> _pricing = {};
  final Map<int, HppBreakdown> _lastBreakdown = {};

  int _nextId = 1000;
  int _newId() => _nextId++;

  List<Ingredient> get ingredients => List.unmodifiable(_ingredients);
  List<Overhead> get overheads => List.unmodifiable(_overheads);
  List<Recipe> get recipes => List.unmodifiable(_recipes);

  // ---- Ingredients CRUD ----------------------------------------------------
  Ingredient addIngredient({
    required String name,
    required double purchasePrice,
    required double purchaseQty,
    required String purchaseUnit,
    String? category,
  }) {
    final unit = findUnit(purchaseUnit) ?? kAppUnits.first;
    final pricePerBase = purchasePrice / (purchaseQty * unit.toBaseFactor);
    final ing = Ingredient(
      id: _newId(),
      name: name,
      purchasePrice: purchasePrice,
      purchaseQty: purchaseQty,
      purchaseUnit: unit.code,
      pricePerBaseUnit: pricePerBase,
      category: category,
    );
    _ingredients.add(ing);
    notifyListeners();
    return ing;
  }

  Ingredient updateIngredient(int id, {
    required String name,
    required double purchasePrice,
    required double purchaseQty,
    required String purchaseUnit,
    String? category,
  }) {
    final idx = _ingredients.indexWhere((i) => i.id == id);
    if (idx < 0) throw StateError('ingredient not found');
    final unit = findUnit(purchaseUnit) ?? kAppUnits.first;
    final pricePerBase = purchasePrice / (purchaseQty * unit.toBaseFactor);
    _ingredients[idx] = Ingredient(
      id: id,
      name: name,
      purchasePrice: purchasePrice,
      purchaseQty: purchaseQty,
      purchaseUnit: unit.code,
      pricePerBaseUnit: pricePerBase,
      category: category,
    );
    notifyListeners();
    return _ingredients[idx];
  }

  void deleteIngredient(int id) {
    _ingredients.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  // ---- Overhead CRUD -------------------------------------------------------
  Overhead addOverhead({
    required String name,
    required double amount,
    required String period,
  }) {
    final o = Overhead(id: _newId(), name: name, amount: amount, period: period);
    _overheads.add(o);
    notifyListeners();
    return o;
  }

  Overhead updateOverhead(int id, {
    required String name,
    required double amount,
    required String period,
  }) {
    final idx = _overheads.indexWhere((o) => o.id == id);
    if (idx < 0) throw StateError('overhead not found');
    _overheads[idx] = Overhead(id: id, name: name, amount: amount, period: period);
    notifyListeners();
    return _overheads[idx];
  }

  void deleteOverhead(int id) {
    _overheads.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  // ---- Recipes CRUD --------------------------------------------------------
  Recipe addRecipe({
    required String name,
    required double yieldQty,
    required String yieldUnit,
    required List<RecipeIngredient> ingredients,
  }) {
    final r = Recipe(
      id: _newId(),
      name: name,
      yieldQty: yieldQty,
      yieldUnit: yieldUnit,
      ingredients: ingredients,
      createdAt: DateTime.now(),
    );
    _recipes.add(r);
    notifyListeners();
    return r;
  }

  Recipe updateRecipe(int id, {
    required String name,
    required double yieldQty,
    required String yieldUnit,
    required List<RecipeIngredient> ingredients,
  }) {
    final idx = _recipes.indexWhere((r) => r.id == id);
    if (idx < 0) throw StateError('recipe not found');
    _recipes[idx] = Recipe(
      id: id,
      name: name,
      yieldQty: yieldQty,
      yieldUnit: yieldUnit,
      ingredients: ingredients,
      createdAt: _recipes[idx].createdAt,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return _recipes[idx];
  }

  Recipe? findRecipe(int id) {
    for (final r in _recipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  void deleteRecipe(int id) {
    _recipes.removeWhere((r) => r.id == id);
    _pricing.remove(id);
    _lastBreakdown.remove(id);
    _recipeOverheadAllocs.remove(id);
    notifyListeners();
  }

  Ingredient? findIngredient(int id) {
    for (final i in _ingredients) {
      if (i.id == id) return i;
    }
    return null;
  }

  // ---- Pricing / HPP -------------------------------------------------------
  Pricing? pricingFor(int recipeId) => _pricing[recipeId];
  HppBreakdown? lastBreakdownFor(int recipeId) => _lastBreakdown[recipeId];
  List<({int overheadCostId, int estimatedMonthlyProduction})>
      allocationsFor(int recipeId) => _recipeOverheadAllocs[recipeId] ?? const [];

  HppBreakdown calculatePricing({
    required int recipeId,
    required double targetMarginPercent,
    required List<({int overheadCostId, int estimatedMonthlyProduction})> allocations,
  }) {
    final recipe = findRecipe(recipeId);
    if (recipe == null) throw StateError('recipe not found');

    // Match backend behavior: reject duplicate overhead ids.
    final seen = <int>{};
    for (final a in allocations) {
      if (!seen.add(a.overheadCostId)) {
        throw ArgumentError('duplicate overhead_cost_id in allocations');
      }
    }

    final inputIngredients = recipe.ingredients.map((row) {
      final ing = findIngredient(row.ingredientId);
      if (ing == null) {
        throw StateError('recipe references missing ingredient ${row.ingredientId}');
      }
      return (row: row, ingredient: ing);
    }).toList();

    final overheadPairs = allocations.map((a) {
      final oc = _overheads.firstWhere(
        (o) => o.id == a.overheadCostId,
        orElse: () => throw ArgumentError('unknown overhead_cost_id ${a.overheadCostId}'),
      );
      return (overhead: oc, estimatedMonthlyProduction: a.estimatedMonthlyProduction);
    }).toList();

    final breakdown = computeHpp(HppInputs(
      recipe: recipe,
      ingredients: inputIngredients,
      overheadAllocations: overheadPairs,
      targetMarginPercent: targetMarginPercent,
    ));

    _pricing[recipeId] = Pricing(
      recipeId: recipeId,
      hppPerUnit: breakdown.hppPerUnit,
      targetMarginPercent: targetMarginPercent,
      suggestedPrice: breakdown.suggestedPrice,
      updatedAt: DateTime.now(),
    );
    _lastBreakdown[recipeId] = breakdown;
    _recipeOverheadAllocs[recipeId] = allocations;
    notifyListeners();
    return breakdown;
  }

  // ---- Dashboard -----------------------------------------------------------
  List<DashboardItem> dashboardItems() {
    final items = _recipes.map((r) {
      final p = _pricing[r.id];
      double? margin;
      if (p != null && p.suggestedPrice != null && p.suggestedPrice! > 0) {
        margin = ((p.suggestedPrice! - p.hppPerUnit) / p.suggestedPrice!) * 100;
      }
      return DashboardItem(
        recipeId: r.id,
        name: r.name,
        yieldQty: r.yieldQty,
        yieldUnit: r.yieldUnit,
        hppPerUnit: p?.hppPerUnit,
        suggestedPrice: p?.suggestedPrice,
        targetMarginPercent: p?.targetMarginPercent,
        marginPercent: margin,
        calculatedAt: p?.updatedAt,
      );
    }).toList();
    // Same sort the backend applies: ascending margin, nulls last.
    items.sort((a, b) {
      if (a.marginPercent == null && b.marginPercent == null) return 0;
      if (a.marginPercent == null) return 1;
      if (b.marginPercent == null) return -1;
      return a.marginPercent!.compareTo(b.marginPercent!);
    });
    return items;
  }

  // ---- Seed ----------------------------------------------------------------
  void _seed() {
    // Ingredients (realistic Indonesian home-baker basics)
    final tepung = addIngredient(
        name: 'Tepung Terigu', purchasePrice: 12000, purchaseQty: 1, purchaseUnit: 'kg', category: 'Kering');
    final gula = addIngredient(
        name: 'Gula Pasir', purchasePrice: 15000, purchaseQty: 1, purchaseUnit: 'kg', category: 'Kering');
    final mentega = addIngredient(
        name: 'Mentega', purchasePrice: 45000, purchaseQty: 500, purchaseUnit: 'gram', category: 'Kering');
    final telur = addIngredient(
        name: 'Telur', purchasePrice: 28000, purchaseQty: 10, purchaseUnit: 'pcs', category: 'Segar');
    final coklat = addIngredient(
        name: 'Coklat Bubuk', purchasePrice: 35000, purchaseQty: 250, purchaseUnit: 'gram', category: 'Kering');
    addIngredient(
        name: 'Susu UHT', purchasePrice: 18000, purchaseQty: 1, purchaseUnit: 'liter', category: 'Segar');

    // Overhead
    final gas = addOverhead(name: 'Gas LPG 3kg', amount: 150000, period: 'per_bulan');
    final listrik = addOverhead(name: 'Listrik Dapur', amount: 200000, period: 'per_bulan');
    final kemasan = addOverhead(name: 'Kemasan', amount: 500, period: 'per_batch');

    // Recipes
    final brownies = addRecipe(
      name: 'Brownies Panggang',
      yieldQty: 12,
      yieldUnit: 'pcs',
      ingredients: [
        RecipeIngredient(ingredientId: tepung.id, qtyUsed: 250, unit: 'gram'),
        RecipeIngredient(ingredientId: gula.id, qtyUsed: 200, unit: 'gram'),
        RecipeIngredient(ingredientId: mentega.id, qtyUsed: 200, unit: 'gram'),
        RecipeIngredient(ingredientId: telur.id, qtyUsed: 3, unit: 'pcs'),
        RecipeIngredient(ingredientId: coklat.id, qtyUsed: 80, unit: 'gram'),
      ],
    );

    final cookies = addRecipe(
      name: 'Chocochip Cookies',
      yieldQty: 20,
      yieldUnit: 'pcs',
      ingredients: [
        RecipeIngredient(ingredientId: tepung.id, qtyUsed: 300, unit: 'gram'),
        RecipeIngredient(ingredientId: gula.id, qtyUsed: 180, unit: 'gram'),
        RecipeIngredient(ingredientId: mentega.id, qtyUsed: 150, unit: 'gram'),
        RecipeIngredient(ingredientId: telur.id, qtyUsed: 2, unit: 'pcs'),
        RecipeIngredient(ingredientId: coklat.id, qtyUsed: 60, unit: 'gram'),
      ],
    );

    // Pre-computed pricing so the guest sees a populated dashboard immediately.
    calculatePricing(
      recipeId: brownies.id,
      targetMarginPercent: 40,
      allocations: [
        (overheadCostId: gas.id, estimatedMonthlyProduction: 60),
        (overheadCostId: listrik.id, estimatedMonthlyProduction: 60),
        (overheadCostId: kemasan.id, estimatedMonthlyProduction: 60),
      ],
    );
    calculatePricing(
      recipeId: cookies.id,
      targetMarginPercent: 35,
      allocations: [
        (overheadCostId: gas.id, estimatedMonthlyProduction: 80),
        (overheadCostId: kemasan.id, estimatedMonthlyProduction: 80),
      ],
    );
  }
}
