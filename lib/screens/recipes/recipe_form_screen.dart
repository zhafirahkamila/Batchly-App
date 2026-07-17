import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/units.dart';
import '../../models/ingredient.dart';
import '../../models/recipe.dart';
import '../../models/recipe_ingredient.dart';
import '../../providers/ingredients_provider.dart';
import '../../providers/recipes_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/unit_dropdown.dart';

class RecipeFormScreen extends StatefulWidget {
  final int? recipeId;
  const RecipeFormScreen({super.key, this.recipeId});

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RowEdit {
  int? ingredientId;
  final TextEditingController qtyCtrl;
  String? unit;
  _RowEdit({this.ingredientId, String? qty, this.unit})
      : qtyCtrl = TextEditingController(text: qty ?? '');
  void dispose() => qtyCtrl.dispose();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _yieldQtyCtrl = TextEditingController(text: '1');
  String _yieldUnit = 'pcs';
  final List<_RowEdit> _rows = [_RowEdit()];
  bool _busy = false;
  bool _hydrated = false;

  bool get _isEdit => widget.recipeId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    if (_isEdit) {
      _loadRecipe();
    } else {
      // For a new recipe, ensure ingredients are loaded so the dropdown is populated.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<IngredientsProvider>().refresh();
      });
    }
  }

  Future<void> _loadRecipe() async {
    await context.read<IngredientsProvider>().refresh();
    if (!mounted) return;
    try {
      final r = await context.read<RecipesProvider>().detail(widget.recipeId!);
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = r.name;
        _yieldQtyCtrl.text = _fmt(r.yieldQty);
        _yieldUnit = r.yieldUnit;
        for (final row in _rows) {
          row.dispose();
        }
        _rows
          ..clear()
          ..addAll(r.ingredients.map((ri) => _RowEdit(
                ingredientId: ri.ingredientId,
                qty: _fmt(ri.qtyUsed),
                unit: ri.unit,
              )));
        if (_rows.isEmpty) _rows.add(_RowEdit());
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat: $e')));
      }
    }
  }

  String _fmt(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _yieldQtyCtrl.dispose();
    for (final r in _rows) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final validRows = _rows.where((r) => r.ingredientId != null).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 bahan')),
      );
      return;
    }
    final items = <RecipeIngredient>[];
    for (final r in validRows) {
      final qty = double.tryParse(r.qtyCtrl.text.replaceAll(',', '.'));
      if (qty == null || qty <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Semua qty bahan harus > 0')),
        );
        return;
      }
      items.add(RecipeIngredient(
        ingredientId: r.ingredientId!,
        qtyUsed: qty,
        unit: r.unit ?? 'gram',
      ));
    }

    setState(() => _busy = true);
    try {
      final p = context.read<RecipesProvider>();
      final Recipe saved;
      if (_isEdit) {
        saved = await p.update(
          widget.recipeId!,
          name: _nameCtrl.text.trim(),
          yieldQty: double.parse(_yieldQtyCtrl.text.replaceAll(',', '.')),
          yieldUnit: _yieldUnit,
          ingredients: items,
        );
      } else {
        saved = await p.create(
          name: _nameCtrl.text.trim(),
          yieldQty: double.parse(_yieldQtyCtrl.text.replaceAll(',', '.')),
          yieldUnit: _yieldUnit,
          ingredients: items,
        );
      }
      if (mounted) context.go('/recipes/${saved.id}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ingredients = context.watch<IngredientsProvider>().items;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Resep' : 'Tambah Resep')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama resep'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yieldQtyCtrl,
                        decoration: const InputDecoration(labelText: 'Hasil per batch'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Angka > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: UnitDropdown(
                        label: 'Satuan hasil',
                        value: _yieldUnit,
                        onChanged: (v) => setState(() => _yieldUnit = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('Bahan-bahan',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 8),
                if (ingredients.isEmpty)
                  GlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: c.accentPrimary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Belum ada bahan. Tambahkan bahan dulu di tab Bahan Baku.'),
                        ),
                      ],
                    ),
                  )
                else
                  ..._rows.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final row = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _IngredientRow(
                        row: row,
                        allIngredients: ingredients,
                        onRemove: _rows.length == 1 ? null : () {
                          setState(() {
                            _rows.removeAt(idx).dispose();
                          });
                        },
                        onChanged: () => setState(() {}),
                      ),
                    );
                  }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _rows.add(_RowEdit())),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Bahan'),
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: _isEdit ? 'Simpan Perubahan' : 'Simpan Resep',
                  loading: _busy,
                  onPressed: _busy ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final _RowEdit row;
  final List<Ingredient> allIngredients;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;

  const _IngredientRow({
    required this.row,
    required this.allIngredients,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selected = allIngredients.firstWhere(
      (i) => i.id == row.ingredientId,
      orElse: () => allIngredients.first,
    );
    // Constrain the unit dropdown to units in the same family as the selected
    // ingredient — otherwise the backend will reject at save time.
    final selectedFamily = findUnit(selected.purchaseUnit)?.family;
    final resolvedUnit = () {
      if (row.unit != null && findUnit(row.unit)?.family == selectedFamily) {
        return row.unit!;
      }
      // Default to the ingredient's own purchase unit if compatible; otherwise
      // the first unit in the family.
      final def = findUnit(selected.purchaseUnit)?.code;
      return def ?? 'gram';
    }();
    if (row.unit == null || findUnit(row.unit)?.family != selectedFamily) {
      row.unit = resolvedUnit;
    }
    if (row.ingredientId == null) {
      row.ingredientId = selected.id;
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        children: [
          DropdownButtonFormField<int>(
            value: row.ingredientId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Bahan'),
            items: [
              for (final i in allIngredients)
                DropdownMenuItem(value: i.id, child: Text(i.name)),
            ],
            onChanged: (v) {
              row.ingredientId = v;
              // Reset unit when ingredient changes so the family check reapplies.
              row.unit = null;
              onChanged();
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Qty'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: UnitDropdown(
                  label: 'Satuan',
                  value: row.unit,
                  restrictToFamily: selectedFamily,
                  onChanged: (v) {
                    row.unit = v;
                    onChanged();
                  },
                ),
              ),
              if (onRemove != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                  tooltip: 'Hapus bahan',
                ),
            ],
          ),
        ],
      ),
    );
  }
}
