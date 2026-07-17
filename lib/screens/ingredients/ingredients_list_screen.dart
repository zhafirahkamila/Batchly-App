import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/rupiah_formatter.dart';
import '../../core/utils/units.dart';
import '../../models/ingredient.dart';
import '../../providers/ingredients_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';

class IngredientsListScreen extends StatefulWidget {
  const IngredientsListScreen({super.key});

  @override
  State<IngredientsListScreen> createState() => _IngredientsListScreenState();
}

class _IngredientsListScreenState extends State<IngredientsListScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IngredientsProvider>().refresh();
    });
  }

  Future<bool> _confirmDelete(Ingredient ing) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus bahan?'),
        content: Text(
          '"${ing.name}" akan dihapus dari daftar dan tidak lagi dapat dipakai di resep.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(ctx).marginDangerText,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _performDelete(Ingredient ing) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<IngredientsProvider>().delete(ing.id);
      messenger.showSnackBar(
        SnackBar(content: Text('${ing.name} dihapus')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Gagal menghapus: $e')),
      );
    }
  }

  Future<void> _showTabletDeleteSheet(Ingredient ing) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_outlined, color: c.textPrimary),
                title: const Text('Edit'),
                onTap: () => Navigator.of(ctx).pop('edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: c.marginDangerText),
                title: Text('Hapus', style: TextStyle(color: c.marginDangerText)),
                onTap: () => Navigator.of(ctx).pop('delete'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (!mounted) return;
    if (choice == 'edit') {
      context.push('/ingredients/${ing.id}/edit');
    } else if (choice == 'delete') {
      if (await _confirmDelete(ing)) {
        if (!mounted) return;
        await _performDelete(ing);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = context.watch<IngredientsProvider>();
    final filtered = p.items
        .where((i) => i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Bahan Baku')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/ingredients/new'),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refresh(),
        child: p.loading && p.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari bahan…',
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 14),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: EmptyState(
                        icon: Icons.egg_alt_outlined,
                        title: _query.isEmpty ? 'Belum ada bahan baku' : 'Tidak ditemukan',
                        subtitle: _query.isEmpty
                            ? 'Tambahkan bahan pertama Anda untuk mulai menghitung HPP.'
                            : 'Coba kata kunci lain.',
                      ),
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Responsive: two columns at tablet width.
                        if (constraints.maxWidth >= 600) {
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.6,
                            children: [
                              for (final i in filtered)
                                _IngredientTile(
                                  ingredient: i,
                                  colors: c,
                                  onLongPress: () => _showTabletDeleteSheet(i),
                                ),
                            ],
                          );
                        }
                        // Mobile: swipe-left to delete. Slightly varied vertical
                        // rhythm so the list doesn't read as a rigid grid.
                        const gaps = [10.0, 12.0, 8.0, 11.0];
                        return Column(
                          children: [
                            for (var idx = 0; idx < filtered.length; idx++) ...[
                              _DismissibleTile(
                                ingredient: filtered[idx],
                                colors: c,
                                onConfirm: () => _confirmDelete(filtered[idx]),
                                onDismissed: () => _performDelete(filtered[idx]),
                              ),
                              if (idx < filtered.length - 1)
                                SizedBox(height: gaps[idx % gaps.length]),
                            ],
                          ],
                        );
                      },
                    ),
                ],
              ),
      ),
    );
  }
}

class _DismissibleTile extends StatelessWidget {
  final Ingredient ingredient;
  final AppColors colors;
  final Future<bool> Function() onConfirm;
  final Future<void> Function() onDismissed;

  const _DismissibleTile({
    required this.ingredient,
    required this.colors,
    required this.onConfirm,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Dismissible(
      key: ValueKey('ingredient-${ingredient.id}'),
      direction: DismissDirection.endToStart,
      background: const SizedBox.shrink(),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          color: colors.marginDangerText,
          borderRadius: radius,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text('Hapus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
      confirmDismiss: (_) => onConfirm(),
      onDismissed: (_) => onDismissed(),
      child: _IngredientTile(ingredient: ingredient, colors: colors),
    );
  }
}

class _IngredientTile extends StatelessWidget {
  final Ingredient ingredient;
  final AppColors colors;
  final VoidCallback? onLongPress;
  const _IngredientTile({
    required this.ingredient,
    required this.colors,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final unit = findUnit(ingredient.purchaseUnit);
    // Show the "per base unit" price honestly (per gram for weight, per ml
    // for volume, per pcs for count) — that's what the calculation uses.
    final baseLabel = unit?.family.name == 'weight'
        ? '/g'
        : unit?.family.name == 'volume'
            ? '/ml'
            : '/pcs';
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push('/ingredients/${ingredient.id}/edit'),
      onLongPress: onLongPress,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.egg_alt_outlined, color: colors.accentPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ingredient.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 2),
                Text(
                  '${_qtyDisplay(ingredient.purchaseQty)} ${ingredient.purchaseUnit} · '
                  '${formatRupiah(ingredient.purchasePrice)}',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatRupiah(ingredient.pricePerBaseUnit, decimalDigits: 2),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  )),
              Text(baseLabel,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  String _qtyDisplay(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();
}
