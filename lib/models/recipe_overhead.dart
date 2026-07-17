class RecipeOverhead {
  final int overheadCostId;
  final int estimatedMonthlyProduction;

  RecipeOverhead({
    required this.overheadCostId,
    required this.estimatedMonthlyProduction,
  });

  Map<String, dynamic> toJson() => {
        'overhead_cost_id': overheadCostId,
        'estimated_monthly_production': estimatedMonthlyProduction,
      };
}
