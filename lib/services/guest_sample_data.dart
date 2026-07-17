import '../models/recipe_ingredient.dart';
import '../providers/guest_data_store.dart';

/// Sample dataset used ONLY by [GuestDataStore] to populate the demo calculator
/// shown behind the "Continue as Guest" flow.
///
/// This file is guest-only. NEVER import it from an authenticated screen or
/// service — authenticated users must always see live data (or an empty state)
/// from the real API, not these literals.
///
/// The seed is expressed as a function rather than raw `const` lists because
/// recipes reference the IDs of ingredients created earlier in the same seed,
/// and pricing references the IDs of both recipes and overheads. Routing seed
/// entries through the store's add* methods keeps ID assignment, price-per-
/// base-unit derivation, and pricing calculation in one place.
void seedGuestData(GuestDataStore store) {
  // Ingredients (realistic Indonesian home-baker basics)
  final tepung = store.addIngredient(
      name: 'Tepung Terigu', purchasePrice: 12000, purchaseQty: 1, purchaseUnit: 'kg', category: 'Kering');
  final gula = store.addIngredient(
      name: 'Gula Pasir', purchasePrice: 15000, purchaseQty: 1, purchaseUnit: 'kg', category: 'Kering');
  final mentega = store.addIngredient(
      name: 'Mentega', purchasePrice: 45000, purchaseQty: 500, purchaseUnit: 'gram', category: 'Kering');
  final telur = store.addIngredient(
      name: 'Telur', purchasePrice: 28000, purchaseQty: 10, purchaseUnit: 'pcs', category: 'Segar');
  final coklat = store.addIngredient(
      name: 'Coklat Bubuk', purchasePrice: 35000, purchaseQty: 250, purchaseUnit: 'gram', category: 'Kering');
  store.addIngredient(
      name: 'Susu UHT', purchasePrice: 18000, purchaseQty: 1, purchaseUnit: 'liter', category: 'Segar');

  // Overhead
  final gas = store.addOverhead(name: 'Gas LPG 3kg', amount: 150000, period: 'per_bulan');
  final listrik = store.addOverhead(name: 'Listrik Dapur', amount: 200000, period: 'per_bulan');
  final kemasan = store.addOverhead(name: 'Kemasan', amount: 500, period: 'per_batch');

  // Recipes
  final brownies = store.addRecipe(
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

  final cookies = store.addRecipe(
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
  store.calculatePricing(
    recipeId: brownies.id,
    targetMarginPercent: 40,
    allocations: [
      (overheadCostId: gas.id, estimatedMonthlyProduction: 60),
      (overheadCostId: listrik.id, estimatedMonthlyProduction: 60),
      (overheadCostId: kemasan.id, estimatedMonthlyProduction: 60),
    ],
  );
  store.calculatePricing(
    recipeId: cookies.id,
    targetMarginPercent: 35,
    allocations: [
      (overheadCostId: gas.id, estimatedMonthlyProduction: 80),
      (overheadCostId: kemasan.id, estimatedMonthlyProduction: 80),
    ],
  );
}
