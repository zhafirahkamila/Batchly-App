import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/pricing.dart';
import '../../models/recipe.dart';
import '../../providers/auth_provider.dart';
import '../../providers/guest_data_store.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/margin_badge.dart';
import '../../widgets/skeleton_box.dart';

class RecipesListScreen extends StatefulWidget {
  const RecipesListScreen({super.key});

  @override
  State<RecipesListScreen> createState() => _RecipesListScreenState();
}

class _RecipesListScreenState extends State<RecipesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RecipesProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<RecipesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipes',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/recipes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refresh(),
        child: p.loading && p.items.isEmpty
            ? ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: const [
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonCard(height: 78),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonCard(height: 78),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonCard(height: 78),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: SkeletonCard(height: 78),
                  ),
                ],
              )
            : p.items.isEmpty
            ? ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No recipes yet',
                    subtitle:
                        'Add your first recipe to start calculating COGS.',
                  ),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: wide
                        ? (p.items.length / 2).ceil()
                        : p.items.length,
                    itemBuilder: (context, index) {
                      if (!wide) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _RecipeCard(recipe: p.items[index]),
                        );
                      }
                      final left = p.items[index * 2];
                      final rightIdx = index * 2 + 1;
                      final right = rightIdx < p.items.length
                          ? p.items[rightIdx]
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _RecipeCard(recipe: left)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: right == null
                                  ? const SizedBox()
                                  : _RecipeCard(recipe: right),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // In guest mode the pricing store is in-memory and can be read
    // synchronously — watch it so the badge updates when the user calculates
    // pricing elsewhere. Auth mode would need a per-recipe API fetch which we
    // skip in the list (the detail page shows the full pricing card).
    final Pricing? pricing = _lookupPricing(context, recipe.id);
    final double? marginPct = _marginPercent(pricing);

    return GlassCard(
      onTap: () => context.push('/recipes/${recipe.id}'),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.cookie_outlined, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Batch: ${_qty(recipe.yieldQty)} ${recipe.yieldUnit}',
                  style: TextStyle(color: c.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          if (marginPct != null) ...[
            MarginBadge(marginPercent: marginPct, compact: true),
            const SizedBox(width: 6),
          ],
          Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }

  Pricing? _lookupPricing(BuildContext context, int recipeId) {
    final isGuest = context.watch<AuthProvider>().isGuest;
    if (!isGuest) return null;
    return context.watch<GuestDataStore>().pricingFor(recipeId);
  }

  double? _marginPercent(Pricing? p) {
    if (p == null || p.suggestedPrice == null || p.suggestedPrice! <= 0) {
      return null;
    }
    return ((p.suggestedPrice! - p.hppPerUnit) / p.suggestedPrice!) * 100;
  }

  String _qty(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}
