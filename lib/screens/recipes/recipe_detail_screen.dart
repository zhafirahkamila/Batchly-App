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
import '../../widgets/animated_number.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/margin_badge.dart';
import '../../widgets/margin_warning.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';
import '../../widgets/skeleton_box.dart';

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  Recipe? _recipe;
  Pricing? _pricing;
  bool _pricingError = false;
  bool _pricingLoading = false;
  bool _loading = true;
  String? _error;
  // Bumped on every _load()/_refetchPricing() call so a slow response from an
  // earlier fetch can't clobber state after a fresher fetch has already
  // resolved (pull-to-refresh, retry, etc.).
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final startedAt = DateTime.now();
    final gen = ++_loadGeneration;
    debugPrint('[RecipeDetail] load() start id=${widget.recipeId} gen=$gen');
    setState(() {
      _loading = true;
      _error = null;
      _pricingError = false;
      _pricingLoading = true;
    });

    // Phase 1 — recipe. Render as soon as this resolves; do NOT wait on
    // pricing. Blocking on pricing was the original bug: a slow /pricing
    // response kept the whole page on the skeleton even though we already
    // had the recipe in hand.
    final Recipe recipe;
    try {
      recipe = await context.read<RecipesProvider>().detail(widget.recipeId);
    } catch (e, st) {
      debugPrint('[RecipeDetail] recipe fetch failed: $e\n$st');
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _pricingLoading = false;
      });
      return;
    }
    if (!mounted || gen != _loadGeneration) return;
    setState(() {
      _recipe = recipe;
      _loading = false;
    });
    final phase1Elapsed = DateTime.now().difference(startedAt).inMilliseconds;
    debugPrint(
        '[RecipeDetail] recipe rendered in ${phase1Elapsed}ms id=${widget.recipeId} ingredients=${recipe.ingredients.length}');

    // Phase 2 — pricing. Independent of recipe render. A 404 returns null
    // (recipe simply has no pricing yet); any other error flips the pricing
    // card to its "unavailable" state without disturbing the rest of the page.
    try {
      final pricing = await context.read<PricingProvider>().fetchForRecipe(
        widget.recipeId,
      );
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _pricing = pricing;
        _pricingError = false;
        _pricingLoading = false;
      });
    } catch (e) {
      debugPrint('[RecipeDetail] pricing fetch failed: $e');
      if (!mounted || gen != _loadGeneration) return;
      setState(() {
        _pricingError = true;
        _pricingLoading = false;
      });
    }
    final totalElapsed = DateTime.now().difference(startedAt).inMilliseconds;
    debugPrint(
        '[RecipeDetail] load() done in ${totalElapsed}ms id=${widget.recipeId} pricing=${_pricing != null}');
  }

  Future<void> _refetchPricing() async {
    final gen = ++_loadGeneration;
    try {
      final pricing = await context.read<PricingProvider>().fetchForRecipe(
        widget.recipeId,
      );
      if (!mounted || gen != _loadGeneration) return;
      if (pricing?.updatedAt != _pricing?.updatedAt ||
          pricing?.suggestedPrice != _pricing?.suggestedPrice) {
        setState(() {
          _pricing = pricing;
          _pricingError = false;
        });
      }
    } catch (e) {
      // Silent — the user has an explicit retry via pull-to-refresh. Don't
      // demote a good pricing card to the failure state on a transient blip.
      debugPrint('[RecipeDetail] pricing refetch failed: $e');
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
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await provider.delete(widget.recipeId);
      if (mounted) context.go('/recipes');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        '[RecipeDetail] build id=${widget.recipeId} loading=$_loading error=$_error recipe=${_recipe?.name}');
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recipe Details',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
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
    final c = AppColors.of(context);

    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonBox(height: 160, radius: 22),
          SizedBox(height: 20),
          SkeletonBox(width: 90, height: 22, radius: 8),
          SizedBox(height: 14),
          SkeletonBox(height: 120, radius: 22),
          SizedBox(height: 12),
          SkeletonBox(height: 52, radius: 16),
          SizedBox(height: 24),
          SkeletonBox(width: 110, height: 22, radius: 8),
          SizedBox(height: 12),
          SkeletonCard(height: 60),
          SizedBox(height: 8),
          SkeletonCard(height: 60),
          SizedBox(height: 8),
          SkeletonCard(height: 60),
        ],
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 40, color: c.textPrimary),
              const SizedBox(height: 12),
              Text(
                'Failed to load recipe: $_error',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.textPrimary),
              ),
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
      // Should not happen (either _loading, _error, or _recipe is set), but
      // never leave the body invisible — always render *something*.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.help_outline, size: 40, color: c.textPrimary),
              const SizedBox(height: 12),
              Text('Recipe #${widget.recipeId} could not be loaded.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.textPrimary)),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }

    final totalIngredientCost = r.ingredients.fold<double>(
      0,
      (sum, ri) => sum + (ri.lineCost ?? 0),
    );
    final costPerUnit = r.yieldQty > 0 ? totalIngredientCost / r.yieldQty : 0.0;
    final hasPricing = _pricing != null && _pricing!.suggestedPrice != null;

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
                Text(
                  r.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Batch: ${_fmt(r.yieldQty)} ${r.yieldUnit}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(
                        label: 'Total ingredients / batch',
                        value: totalIngredientCost,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _HeroStat(
                        label: 'Ingredients per ${r.yieldUnit}',
                        value: costPerUnit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Pricing'),
          // Only show the skeleton when pricing has NEVER loaded yet —
          // subsequent refreshes keep the last card visible instead of
          // flashing back to a placeholder.
          if (_pricingLoading && _pricing == null && !_pricingError)
            const SkeletonCard(height: 96)
          else
            _PricingCard(
              pricing: _pricing,
              yieldUnit: r.yieldUnit,
              ingredientCostPerUnit: costPerUnit,
              fetchFailed: _pricingError,
            ),
          if (hasPricing) ...[
            const SizedBox(height: 10),
            MarginWarning(margin: _marginOf(_pricing!)),
          ],
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
          if (r.ingredients.isEmpty)
            GlassCard(
              onTap: () => context.push('/recipes/${r.id}/edit'),
              child: Row(
                children: [
                  Icon(Icons.playlist_add_rounded, color: c.accentPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'This recipe has no ingredients yet.',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to edit and add ingredients so we can calculate cost.',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: c.textSecondary),
                ],
              ),
            )
          else
            for (final ri in r.ingredients) ...[
              GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ri.name ?? 'Ingredient #${ri.ingredientId}',
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_fmt(ri.qtyUsed)} ${ri.unit}',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
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

  double _marginOf(Pricing p) {
    if (p.suggestedPrice == null || p.suggestedPrice! <= 0) return 0;
    return ((p.suggestedPrice! - p.hppPerUnit) / p.suggestedPrice!) * 100;
  }

  String _fmt(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}

class _HeroStat extends StatelessWidget {
  final String label;
  final double value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        AnimatedNumber(
          value: value,
          formatter: formatRupiah,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// Three states:
///   - Pricing fetch failed: neutral card noting the failure, so the user
///     understands why no numbers are shown yet.
///   - No pricing yet: preview of ingredient cost per unit + hint to add
///     overhead + margin for full HPP.
///   - Pricing calculated: gradient card with the selling price + COGS +
///     margin so the user sees the outcome without leaving the detail page.
class _PricingCard extends StatelessWidget {
  final Pricing? pricing;
  final String yieldUnit;
  final double ingredientCostPerUnit;
  final bool fetchFailed;

  const _PricingCard({
    required this.pricing,
    required this.yieldUnit,
    required this.ingredientCostPerUnit,
    required this.fetchFailed,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = pricing;

    if (fetchFailed) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, color: c.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pricing unavailable — pull down to retry.',
                style: TextStyle(color: c.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    if (p == null || p.suggestedPrice == null) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calculate_outlined, color: c.accentPrimary),
                const SizedBox(width: 12),
                Text(
                  'No pricing yet',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
                children: [
                  const TextSpan(text: 'Ingredient cost only: '),
                  TextSpan(
                    text: '${formatRupiah(ingredientCostPerUnit)} / $yieldUnit',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add overhead + margin to see full HPP and selling price.',
              style: TextStyle(color: c.textSecondary, fontSize: 12.5),
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
                  const Text(
                    'Selling price per unit',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const Spacer(),
                  MarginBadge(marginPercent: margin, compact: true),
                ],
              ),
              const SizedBox(height: 6),
              AnimatedNumber(
                value: p.suggestedPrice!,
                formatter: formatRupiah,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      label: 'COGS / $yieldUnit',
                      value: p.hppPerUnit,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _MiniStat(
                      label: 'Profit / $yieldUnit',
                      value: profit,
                    ),
                  ),
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
  final double value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 2),
        AnimatedNumber(
          value: value,
          formatter: formatRupiah,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
