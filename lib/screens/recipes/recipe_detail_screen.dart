import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/gradients.dart';
import '../../core/utils/rupiah_formatter.dart';
import '../../models/pricing.dart';
import '../../models/recipe.dart';
import '../../providers/pricing_provider.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/margin_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  Pricing? _pricing;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Load on the first frame so Provider lookups (via context.read) see a
    // fully-mounted widget tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipeFuture =
          context.read<RecipesProvider>().detail(widget.recipeId);
      final pricingFuture =
          context.read<PricingProvider>().fetchForRecipe(widget.recipeId);
      final recipe = await recipeFuture;
      final pricing = await pricingFuture;
      if (!mounted) return;
      setState(() {
        _recipe = recipe;
        _pricing = pricing;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refetchPricing() async {
    try {
      final pricing =
          await context.read<PricingProvider>().fetchForRecipe(widget.recipeId);
      if (!mounted) return;
      if (pricing?.updatedAt != _pricing?.updatedAt ||
          pricing?.suggestedPrice != _pricing?.suggestedPrice) {
        setState(() => _pricing = pricing);
      }
    } catch (_) {
      // Silent — the CTA lets the user retry manually.
    }
  }

  Future<void> _confirmDelete() async {
    final provider = context.read<RecipesProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: const Text('The recipe and its COGS results will be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.delete(widget.recipeId);
      if (mounted) context.go('/recipes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/recipes/${widget.recipeId}/edit'),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text('Failed to load recipe: $_error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final r = _recipe;
    if (r == null) {
      return const Center(child: Text('Recipe not found'));
    }

    final c = AppColors.of(context);
    final totalIngredientCost = r.ingredients.fold<double>(
      0,
      (sum, ri) => sum + (ri.lineCost ?? 0),
    );
    final costPerUnit = r.yieldQty > 0 ? totalIngredientCost / r.yieldQty : 0.0;
    final hasPricing = _pricing != null;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GradientHeroCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                Text('Batch: ${_fmt(r.yieldQty)} ${r.yieldUnit}',
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroStat(
                      label: 'Total ingredients / batch',
                      value: formatRupiah(totalIngredientCost),
                    ),
                    const SizedBox(width: 20),
                    _HeroStat(
                      label: 'Ingredients per ${r.yieldUnit}',
                      value: formatRupiah(costPerUnit),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Pricing'),
          _PricingCard(pricing: _pricing, yieldUnit: r.yieldUnit),
          const SizedBox(height: 12),
          PrimaryButton(
            label: hasPricing ? 'Update Pricing' : 'Calculate Pricing',
            icon: Icons.calculate_rounded,
            onPressed: () async {
              await context.push('/recipes/${r.id}/pricing');
              // Pricing sheet may have persisted a new result on its way out —
              // refresh so the detail card reflects it immediately.
              if (mounted) _refetchPricing();
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Ingredients'),
          for (final ri in r.ingredients) ...[
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ri.name ?? 'Ingredient #${ri.ingredientId}',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        Text('${_fmt(ri.qtyUsed)} ${ri.unit}',
                            style: TextStyle(color: c.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text(
                    ri.lineCost == null ? '-' : formatRupiah(ri.lineCost),
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _fmt(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}

/// Two states:
///   - No pricing yet: neutral glass card with a hint explaining what happens
///     when the user calculates pricing.
///   - Pricing calculated: gradient card with the selling price + COGS + margin
///     so the user sees the outcome without leaving the detail page.
class _PricingCard extends StatelessWidget {
  final Pricing? pricing;
  final String yieldUnit;

  const _PricingCard({required this.pricing, required this.yieldUnit});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = pricing;

    if (p == null || p.suggestedPrice == null) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.calculate_outlined, color: c.accentPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No pricing yet',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Calculate to see your selling price and profit margin.',
                    style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final margin = (p.suggestedPrice! > 0)
        ? ((p.suggestedPrice! - p.hppPerUnit) / p.suggestedPrice!) * 100
        : 0.0;
    final profit = p.suggestedPrice! - p.hppPerUnit;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: AppGradients.accent(c)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Selling price per unit',
                      style: TextStyle(color: Colors.white70)),
                  const Spacer(),
                  MarginBadge(marginPercent: margin, compact: true),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                formatRupiah(p.suggestedPrice),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniStat(label: 'COGS / $yieldUnit', value: formatRupiah(p.hppPerUnit)),
                  const SizedBox(width: 24),
                  _MiniStat(label: 'Profit / $yieldUnit', value: formatRupiah(profit)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
