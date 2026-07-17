import '../../models/hpp_breakdown.dart';
import '../../models/ingredient.dart';
import '../../models/overhead.dart';
import '../../models/recipe.dart';
import '../../models/recipe_ingredient.dart';
import 'units.dart';

/// Client-side HPP math — mirrors the backend logic in
/// `batchly_backend/src/controllers/pricing.controller.js`.
///
/// Used for:
///   (a) the live preview inside the pricing sheet (no server round-trip on
///       every slider drag)
///   (b) guest-mode calculation (there is no backend to hit)
///
/// If you change the backend formula, keep this file in lock-step or the
/// numbers users see before hitting "Hitung" will disagree with what gets
/// persisted afterwards.
///
/// Formula:
///   1. line_cost         = convertToBase(qty_used, unit) * price_per_base_unit
///   2. ingredient_total  = Σ line_cost
///   3. hpp_from_ing      = ingredient_total / yield_qty
///   4. for each overhead allocation:
///        per_bulan → allocated = amount / estimated_monthly_production
///        per_batch → allocated = amount / yield_qty
///      total_overhead     = Σ allocated
///   5. hpp_per_unit       = hpp_from_ing + total_overhead
///   6. suggested_price    = hpp_per_unit / (1 - margin/100)
///   7. profit_per_unit    = suggested_price - hpp_per_unit
class HppInputs {
  final Recipe recipe;
  final List<({RecipeIngredient row, Ingredient ingredient})> ingredients;
  final List<({Overhead overhead, int estimatedMonthlyProduction})> overheadAllocations;
  final double targetMarginPercent;

  HppInputs({
    required this.recipe,
    required this.ingredients,
    required this.overheadAllocations,
    required this.targetMarginPercent,
  });
}

HppBreakdown computeHpp(HppInputs inputs) {
  final yieldQty = inputs.recipe.yieldQty;
  if (yieldQty <= 0) {
    throw ArgumentError('yield_qty must be > 0');
  }

  final ingredientLines = <IngredientBreakdownLine>[];
  double ingredientTotal = 0;

  for (final entry in inputs.ingredients) {
    final row = entry.row;
    final ing = entry.ingredient;
    final fromUnit = findUnit(row.unit);
    final targetUnit = findUnit(ing.purchaseUnit);
    if (fromUnit == null || targetUnit == null) {
      throw ArgumentError('unknown unit "${row.unit}" or "${ing.purchaseUnit}"');
    }
    if (fromUnit.family != targetUnit.family) {
      throw ArgumentError(
        'unit family mismatch: "${row.unit}" (${fromUnit.family.name}) '
        'vs ingredient "${ing.purchaseUnit}" (${targetUnit.family.name})',
      );
    }
    // Convert to the ingredient's base unit family and multiply by the
    // per-base-unit price to get this ingredient line's contribution.
    final qtyInBase = row.qtyUsed * fromUnit.toBaseFactor;
    final lineCost = qtyInBase * ing.pricePerBaseUnit;
    ingredientTotal += lineCost;
    ingredientLines.add(
      IngredientBreakdownLine(
        ingredientId: ing.id,
        name: ing.name,
        qtyUsed: row.qtyUsed,
        unit: row.unit,
        qtyInBaseUnit: qtyInBase,
        purchaseUnit: ing.purchaseUnit,
        pricePerBaseUnit: ing.pricePerBaseUnit,
        lineCost: lineCost,
      ),
    );
  }

  final ingredientCostPerUnit = ingredientTotal / yieldQty;

  final overheadLines = <OverheadBreakdownLine>[];
  double totalOverheadPerUnit = 0;
  for (final alloc in inputs.overheadAllocations) {
    final oc = alloc.overhead;
    final double allocatedPerUnit;
    if (oc.period == 'per_bulan') {
      final emp = alloc.estimatedMonthlyProduction;
      if (emp <= 0) {
        throw ArgumentError('estimated_monthly_production must be > 0 for per_bulan');
      }
      allocatedPerUnit = oc.amount / emp;
    } else {
      // per_batch — spread the batch cost across the yield.
      allocatedPerUnit = oc.amount / yieldQty;
    }
    totalOverheadPerUnit += allocatedPerUnit;
    overheadLines.add(
      OverheadBreakdownLine(
        overheadCostId: oc.id,
        name: oc.name,
        amount: oc.amount,
        period: oc.period,
        estimatedMonthlyProduction: alloc.estimatedMonthlyProduction,
        allocatedPerUnit: allocatedPerUnit,
      ),
    );
  }

  final hppPerUnit = ingredientCostPerUnit + totalOverheadPerUnit;
  // Guard against margin=100 which would divide by zero. Backend validation
  // caps at 99.99 but the live preview slider is client-side.
  final marginFraction = (inputs.targetMarginPercent.clamp(0, 99.99)) / 100.0;
  final suggestedPrice = hppPerUnit / (1 - marginFraction);
  final profitPerUnit = suggestedPrice - hppPerUnit;

  return HppBreakdown(
    recipeId: inputs.recipe.id,
    yieldQty: yieldQty,
    yieldUnit: inputs.recipe.yieldUnit,
    targetMarginPercent: inputs.targetMarginPercent.toDouble(),
    ingredientBreakdown: ingredientLines,
    overheadBreakdown: overheadLines,
    ingredientCostTotal: ingredientTotal,
    ingredientCostPerUnit: ingredientCostPerUnit,
    totalOverheadPerUnit: totalOverheadPerUnit,
    hppPerUnit: hppPerUnit,
    suggestedPrice: suggestedPrice,
    profitPerUnit: profitPerUnit,
    calculatedAt: DateTime.now(),
  );
}
