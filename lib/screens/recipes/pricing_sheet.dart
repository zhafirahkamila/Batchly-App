import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/hpp_math.dart';
import '../../core/utils/margin_health.dart';
import '../../core/utils/rupiah_formatter.dart';
import '../../models/hpp_breakdown.dart';
import '../../models/ingredient.dart';
import '../../models/overhead.dart';
import '../../models/recipe.dart';
import '../../models/recipe_ingredient.dart';
import '../../providers/ingredients_provider.dart';
import '../../providers/overhead_provider.dart';
import '../../providers/pricing_provider.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/margin_badge.dart';
import '../../widgets/margin_warning.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/section_header.dart';

/// The pricing "sheet" — actually a full screen route so it survives keyboard
/// pops, layout swaps between phone/tablet, and lets us push it via GoRouter.
///
/// UX flow:
///   1. Load recipe + list of overhead entries
///   2. User picks which overhead entries to include and sets
///      estimated_monthly_production per each
///   3. User sets target margin % with a slider (0..99)
///   4. Live preview (client-side, using hpp_math.dart) updates on every change
///   5. "Hitung" button POSTs to the backend (or guest emulation) and
///      displays the persisted breakdown
class PricingSheet extends StatefulWidget {
  final int recipeId;
  const PricingSheet({super.key, required this.recipeId});

  @override
  State<PricingSheet> createState() => _PricingSheetState();
}

class _AllocEdit {
  final Overhead overhead;
  bool included = false;
  int emp = 100;
  _AllocEdit({required this.overhead});
}

enum _PricingMode { margin, competitor }

class _PricingSheetState extends State<PricingSheet> {
  Recipe? _recipe;
  final List<_AllocEdit> _allocs = [];
  double _marginPercent = 30;
  double _bufferPercent = 0;
  _PricingMode _mode = _PricingMode.margin;
  final _competitorPriceCtrl = TextEditingController();
  double? _competitorPrice;
  bool _loading = true;

  @override
  void dispose() {
    _competitorPriceCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Ensure ingredients + overhead are loaded so the live preview can look
      // them up by id.
      await Future.wait([
        context.read<IngredientsProvider>().refresh(),
        context.read<OverheadProvider>().refresh(),
      ]);
      final r = await context.read<RecipesProvider>().detail(widget.recipeId);
      // Pre-fill target margin + buffer from the last saved pricing (if any)
      // so re-opening the sheet feels like editing, not starting over.
      final saved = await context.read<PricingProvider>().fetchForRecipe(
        widget.recipeId,
      );
      if (!mounted) return;
      final overheads = context.read<OverheadProvider>().items;
      setState(() {
        _recipe = r;
        _allocs
          ..clear()
          ..addAll(overheads.map((o) => _AllocEdit(overhead: o)));
        if (saved != null) {
          if (saved.targetMarginPercent != null) {
            _marginPercent = saved.targetMarginPercent!.clamp(0, 90).toDouble();
          }
          _bufferPercent = saved.priceBufferPercent.clamp(0, 50).toDouble();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Runs the same math the backend does, but locally, so the numbers update
  /// as the user drags the slider without a server round-trip.
  ///
  /// In competitor mode we derive the effective margin from the entered price
  /// and the current HPP, then feed that through the same computeHpp() —
  /// keeps the preview / persist paths identical.
  HppBreakdown? _computeLivePreview() {
    if (_recipe == null) return null;
    try {
      final ingProv = context.read<IngredientsProvider>();
      final ingredients = <({RecipeIngredient row, Ingredient ingredient})>[];
      // Skip preview cleanly if the recipe references a missing ingredient
      // (e.g. one that was deleted).
      for (final row in _recipe!.ingredients) {
        final ing = ingProv.byId(row.ingredientId);
        if (ing == null) return null;
        ingredients.add((row: row, ingredient: ing));
      }
      final allocs = _allocs
          .where((a) => a.included)
          .map((a) => (overhead: a.overhead, estimatedMonthlyProduction: a.emp))
          .toList();
      final effectiveMargin = _effectiveMarginPercent(
        recipe: _recipe!,
        ingredients: ingredients,
        allocs: allocs,
      );
      if (effectiveMargin == null) return null;
      return computeHpp(
        HppInputs(
          recipe: _recipe!,
          ingredients: ingredients,
          overheadAllocations: allocs,
          targetMarginPercent: effectiveMargin,
          priceBufferPercent: _bufferPercent,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns the target margin % to pass into computeHpp / the backend.
  ///
  /// - Margin mode: the slider value directly.
  /// - Competitor mode: derive from `(price - hpp) / price * 100`. Requires
  ///   a valid HPP and a positive price; returns null (skip preview) when
  ///   the user hasn't typed a price yet, or when hpp/price are non-positive.
  ///   Clamps to <99.9 to avoid divide-by-zero on the backend side.
  double? _effectiveMarginPercent({
    required Recipe recipe,
    required List<({RecipeIngredient row, Ingredient ingredient})> ingredients,
    required List<({Overhead overhead, int estimatedMonthlyProduction})> allocs,
  }) {
    if (_mode == _PricingMode.margin) return _marginPercent;
    final price = _competitorPrice;
    if (price == null || price <= 0) return null;
    // Compute HPP with a placeholder margin so we can read hppPerUnit back.
    // Buffer flows through here so the derived margin matches the same
    // buffered HPP the backend will price against.
    final hppOnly = computeHpp(
      HppInputs(
        recipe: recipe,
        ingredients: ingredients,
        overheadAllocations: allocs,
        targetMarginPercent: 0,
        priceBufferPercent: _bufferPercent,
      ),
    );
    final hpp = hppOnly.hppPerUnit;
    if (!hpp.isFinite) return null;
    final derived = ((price - hpp) / price) * 100;
    // Backend rejects >=100 (divide by zero on inverse). Clamp to a safe range.
    return derived.clamp(-9999, 99.9).toDouble();
  }

  Future<void> _submit() async {
    if (_recipe == null) return;
    final ingProv = context.read<IngredientsProvider>();
    final ingredients = <({RecipeIngredient row, Ingredient ingredient})>[];
    for (final row in _recipe!.ingredients) {
      final ing = ingProv.byId(row.ingredientId);
      if (ing == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An ingredient is missing — refresh Pantry and retry.',
            ),
          ),
        );
        return;
      }
      ingredients.add((row: row, ingredient: ing));
    }
    final allocs = _allocs
        .where((a) => a.included)
        .map((a) => (overhead: a.overhead, estimatedMonthlyProduction: a.emp))
        .toList();
    final marginToSubmit = _effectiveMarginPercent(
      recipe: _recipe!,
      ingredients: ingredients,
      allocs: allocs,
    );
    if (marginToSubmit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == _PricingMode.competitor
                ? 'Enter a competitor price first.'
                : 'Cannot calculate — check inputs.',
          ),
        ),
      );
      return;
    }
    final submitAllocs = _allocs
        .where((a) => a.included)
        .map(
          (a) => (
            overheadCostId: a.overhead.id,
            estimatedMonthlyProduction: a.emp,
          ),
        )
        .toList();
    final pricingProv = context.read<PricingProvider>();
    final result = await pricingProv.calculate(
      recipeId: _recipe!.id,
      targetMarginPercent: marginToSubmit,
      allocations: submitAllocs,
      priceBufferPercent: _bufferPercent,
    );
    if (!mounted) return;
    if (result != null) {
      // Clear so a subsequent open of the sheet starts fresh instead of
      // reusing this recipe's cached breakdown on top of the live preview.
      pricingProv.clear();
      final messenger = ScaffoldMessenger.of(context);
      context.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Pricing updated')));
    } else {
      final err = pricingProv.error ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calculate COGS')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_recipe == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Calculate COGS')),
        body: const Center(child: Text('Recipe not found')),
      );
    }

    final preview = _computeLivePreview();
    final pricingProv = context.watch<PricingProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Calculate COGS · ${_recipe!.name}')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 700;
            final left = _buildForm(c);
            final right = _buildResult(c, preview);
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: left,
                    ),
                  ),
                  Container(width: 1, height: double.infinity, color: c.border),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: right,
                    ),
                  ),
                ],
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  left,
                  const SizedBox(height: 20),
                  right,
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Calculate',
                    icon: Icons.calculate_rounded,
                    loading: pricingProv.calculating,
                    onPressed: pricingProv.calculating ? null : _submit,
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: MediaQuery.of(context).size.width >= 700
          ? FloatingActionButton.extended(
              onPressed: pricingProv.calculating ? null : _submit,
              icon: const Icon(Icons.calculate_rounded),
              label: pricingProv.calculating
                  ? const Text('Calculating…')
                  : const Text('Calculate'),
            )
          : null,
    );
  }

  Widget _buildForm(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Overhead Allocation'),
        if (_allocs.isEmpty)
          GlassCard(
            child: Row(
              children: [
                Icon(Icons.info_outline, color: c.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No overhead costs yet. COGS will only include ingredient costs.',
                  ),
                ),
              ],
            ),
          )
        else
          ..._allocs.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OverheadRow(edit: a, onChanged: () => setState(() {})),
            ),
          ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Overhead'),
          onPressed: () async {
            await context.push('/profile/overhead/new');
            if (!mounted) return;
            await context.read<OverheadProvider>().refresh();
            final overheads = context.read<OverheadProvider>().items;
            setState(() {
              final existingIds = _allocs.map((a) => a.overhead.id).toSet();
              for (final o in overheads) {
                if (!existingIds.contains(o.id)) {
                  _allocs.add(_AllocEdit(overhead: o));
                }
              }
            });
          },
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'Pricing Strategy'),
        SegmentedButton<_PricingMode>(
          segments: const [
            ButtonSegment(
              value: _PricingMode.margin,
              icon: Icon(Icons.percent),
              label: Text('Target margin'),
            ),
            ButtonSegment(
              value: _PricingMode.competitor,
              icon: Icon(Icons.storefront_outlined),
              label: Text('Competitor price'),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() => _mode = s.first),
          showSelectedIcon: false,
        ),
        const SizedBox(height: 10),
        if (_mode == _PricingMode.margin)
          _MarginSlider(
            marginPercent: _marginPercent,
            onChanged: (v) => setState(() => _marginPercent = v),
          )
        else
          _CompetitorPriceInput(
            controller: _competitorPriceCtrl,
            impliedMargin: _computeLivePreview()?.marginPercent,
            onChanged: (v) => setState(() => _competitorPrice = v),
          ),
        const SizedBox(height: 10),
        _BufferSlider(
          bufferPercent: _bufferPercent,
          onChanged: (v) => setState(() => _bufferPercent = v),
        ),
      ],
    );
  }

  Widget _buildResult(AppColors c, HppBreakdown? b) {
    if (b == null) {
      return GlassCard(
        child: Row(
          children: [
            Icon(Icons.calculate_outlined, color: c.textSecondary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Fill in recipe ingredients to see estimates.'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(title: 'Live Estimate'),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: DecoratedBox(
            decoration: BoxDecoration(),
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
                      MarginBadge(marginPercent: b.marginPercent),
                    ],
                  ),
                  const SizedBox(height: 6),
                  AnimatedNumber(
                    value: b.suggestedPrice,
                    formatter: formatRupiah,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _MiniStat(label: 'COGS', value: b.hppPerUnit),
                      const SizedBox(width: 20),
                      _MiniStat(label: 'Profit', value: b.profitPerUnit),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const SectionHeader(title: 'Ingredient Breakdown'),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            children: [
              for (final line in b.ingredientBreakdown)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.name,
                              style: TextStyle(color: c.textPrimary),
                            ),
                            Text(
                              '${_fmt(line.qtyUsed)} ${line.unit}',
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(line.lineCost),
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Total ingredients / batch',
                      style: TextStyle(color: c.textSecondary),
                    ),
                  ),
                  Text(
                    formatRupiah(b.ingredientCostTotal),
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ingredients per ${b.yieldUnit}',
                      style: TextStyle(color: c.textSecondary),
                    ),
                  ),
                  Text(
                    formatRupiah(b.ingredientCostPerUnit),
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (b.overheadBreakdown.isNotEmpty) ...[
          const SizedBox(height: 14),
          const SectionHeader(title: 'Overhead Breakdown'),
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                for (final o in b.overheadBreakdown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.name,
                                style: TextStyle(color: c.textPrimary),
                              ),
                              Text(
                                o.period == 'per_bulan'
                                    ? '${formatRupiah(o.amount)}/month ÷ ${o.estimatedMonthlyProduction} units'
                                    : '${formatRupiah(o.amount)}/batch ÷ ${_fmt(b.yieldQty)} ${b.yieldUnit}',
                                style: TextStyle(
                                  color: c.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(o.allocatedPerUnit),
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Overhead per ${b.yieldUnit}',

                        style: TextStyle(color: c.textSecondary),
                      ),
                    ),
                    Text(
                      formatRupiah(b.totalOverheadPerUnit),
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        if (marginHealth(b.marginPercent) != MarginHealth.good) ...[
          const SizedBox(height: 12),
          MarginWarning(margin: b.marginPercent),
        ],
      ],
    );
  }

  String _fmt(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toString();
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

class _MarginSlider extends StatelessWidget {
  final double marginPercent;
  final ValueChanged<double> onChanged;

  const _MarginSlider({required this.marginPercent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${marginPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              MarginBadge(marginPercent: marginPercent),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: marginPercent,
            min: 0,
            max: 90,
            divisions: 90,
            label: '${marginPercent.round()}%',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Optional buffer % — inflates HPP to price against anticipated ingredient
/// cost rises. 0 keeps behavior identical to pre-buffer calculations.
class _BufferSlider extends StatelessWidget {
  final double bufferPercent;
  final ValueChanged<double> onChanged;

  const _BufferSlider({required this.bufferPercent, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Buffer kenaikan harga bahan (opsional)',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${bufferPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: bufferPercent,
            min: 0,
            max: 50,
            divisions: 50,
            label: '${bufferPercent.round()}%',
            onChanged: onChanged,
          ),
          Text(
            'Antisipasi kenaikan harga bahan baku sebelum kamu hitung ulang HPP.',
            style: TextStyle(color: c.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Enter a competitor / target selling price; the implied margin is shown
/// live using the same MarginBadge as the slider — so the color band gives
/// instant feedback on whether the price is healthy.
class _CompetitorPriceInput extends StatelessWidget {
  final TextEditingController controller;
  final double? impliedMargin;
  final ValueChanged<double?> onChanged;

  const _CompetitorPriceInput({
    required this.controller,
    required this.impliedMargin,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Competitor / target price',
              prefixText: 'Rp ',
              helperText:
                  'App will match this price and back-calculate the margin.',
            ),
            onChanged: (v) {
              final cleaned = v.replaceAll(',', '').replaceAll('.', '');
              final n = double.tryParse(cleaned);
              onChanged((n != null && n > 0) ? n : null);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Implied margin',
                style: TextStyle(color: c.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              MarginBadge(marginPercent: impliedMargin),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverheadRow extends StatelessWidget {
  final _AllocEdit edit;
  final VoidCallback onChanged;
  const _OverheadRow({required this.edit, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: edit.included,
                onChanged: (v) {
                  edit.included = v ?? false;
                  onChanged();
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edit.overhead.name,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${formatRupiah(edit.overhead.amount)} · ${edit.overhead.period == 'per_bulan' ? 'per month' : 'per batch'}',
                      style: TextStyle(color: c.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (edit.included && edit.overhead.period == 'per_bulan')
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, bottom: 8),
              child: TextFormField(
                initialValue: edit.emp.toString(),
                decoration: const InputDecoration(
                  labelText: 'Estimated production per month',
                  helperText:
                      'Used to divide this monthly cost across each unit.',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  edit.emp = int.tryParse(v) ?? 1;
                  onChanged();
                },
              ),
            ),
        ],
      ),
    );
  }
}
