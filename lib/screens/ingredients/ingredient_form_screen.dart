import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/rupiah_formatter.dart';
import '../../core/utils/units.dart';
import '../../providers/ingredients_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rupiah_field.dart';
import '../../widgets/unit_dropdown.dart';

class IngredientFormScreen extends StatefulWidget {
  final int? ingredientId;
  const IngredientFormScreen({super.key, this.ingredientId});

  @override
  State<IngredientFormScreen> createState() => _IngredientFormScreenState();
}

class _IngredientFormScreenState extends State<IngredientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  int? _price;
  String _unit = 'gram';
  bool _busy = false;
  bool _hydrated = false;

  bool get _isEdit => widget.ingredientId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated || !_isEdit) return;
    final ing = context.read<IngredientsProvider>().byId(widget.ingredientId!);
    if (ing != null) {
      _nameCtrl.text = ing.name;
      _qtyCtrl.text = _fmtQty(ing.purchaseQty);
      _categoryCtrl.text = ing.category ?? '';
      _price = ing.purchasePrice.round();
      _unit = ing.purchaseUnit;
    }
    _hydrated = true;
  }

  String _fmtQty(double q) => q == q.roundToDouble() ? q.toInt().toString() : q.toString();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  double _perBase() {
    final qty = double.tryParse(_qtyCtrl.text.replaceAll(',', '.'));
    final price = _price?.toDouble();
    if (qty == null || qty <= 0 || price == null) return 0;
    final unit = findUnit(_unit) ?? kAppUnits.first;
    return price / (qty * unit.toBaseFactor);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final qty = double.parse(_qtyCtrl.text.replaceAll(',', '.'));
    setState(() => _busy = true);
    try {
      final p = context.read<IngredientsProvider>();
      if (_isEdit) {
        await p.update(
          widget.ingredientId!,
          name: _nameCtrl.text.trim(),
          purchasePrice: _price!.toDouble(),
          purchaseQty: qty,
          purchaseUnit: _unit,
          category: _categoryCtrl.text.trim(),
        );
      } else {
        await p.create(
          name: _nameCtrl.text.trim(),
          purchasePrice: _price!.toDouble(),
          purchaseQty: qty,
          purchaseUnit: _unit,
          category: _categoryCtrl.text.trim(),
        );
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete ingredient?'),
        content: const Text('This ingredient will be removed and can no longer be used in recipes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<IngredientsProvider>().delete(widget.ingredientId!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final unit = findUnit(_unit);
    final baseLabel = unit?.family.name == 'weight'
        ? '/gram'
        : unit?.family.name == 'volume'
            ? '/ml'
            : '/pcs';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Ingredient' : 'Add Ingredient'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {}),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Ingredient name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                RupiahField(
                  label: 'Purchase price',
                  initialValue: _price,
                  onChanged: (v) => setState(() => _price = v),
                  validator: (v) => (v == null || v <= 0) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCtrl,
                        decoration: const InputDecoration(labelText: 'Purchase quantity'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          final n = double.tryParse(v.replaceAll(',', '.'));
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: UnitDropdown(
                        value: _unit,
                        onChanged: (v) => setState(() => _unit = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    hintText: 'Dry, Wet, Fresh…',
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.calculate_outlined, color: c.accentPrimary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Price per base unit',
                                style: TextStyle(color: c.textSecondary, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              '${formatRupiah(_perBase(), decimalDigits: 2)} $baseLabel',
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isEdit ? 'Save Changes' : 'Save Ingredient',
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
