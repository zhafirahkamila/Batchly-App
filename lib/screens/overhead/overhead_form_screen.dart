import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/overhead_provider.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/rupiah_field.dart';

class OverheadFormScreen extends StatefulWidget {
  final int? overheadId;
  const OverheadFormScreen({super.key, this.overheadId});

  @override
  State<OverheadFormScreen> createState() => _OverheadFormScreenState();
}

class _OverheadFormScreenState extends State<OverheadFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  int? _amount;
  String _period = 'per_bulan';
  bool _busy = false;
  bool _hydrated = false;

  bool get _isEdit => widget.overheadId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated || !_isEdit) return;
    final o = context.read<OverheadProvider>().byId(widget.overheadId!);
    if (o != null) {
      _nameCtrl.text = o.name;
      _amount = o.amount.round();
      _period = o.period;
    }
    _hydrated = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final p = context.read<OverheadProvider>();
      if (_isEdit) {
        await p.update(widget.overheadId!,
            name: _nameCtrl.text.trim(), amount: _amount!.toDouble(), period: _period);
      } else {
        await p.create(
            name: _nameCtrl.text.trim(), amount: _amount!.toDouble(), period: _period);
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus overhead?'),
        content: const Text('Overhead ini akan dihapus dan tidak lagi tersedia untuk alokasi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await context.read<OverheadProvider>().delete(widget.overheadId!);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Overhead' : 'Tambah Overhead'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Hapus',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama biaya'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                RupiahField(
                  label: 'Nominal',
                  initialValue: _amount,
                  onChanged: (v) => _amount = v,
                  validator: (v) => (v == null || v <= 0) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'per_bulan', label: Text('Per Bulan'), icon: Icon(Icons.calendar_month)),
                    ButtonSegment(value: 'per_batch', label: Text('Per Batch'), icon: Icon(Icons.inventory_2)),
                  ],
                  selected: {_period},
                  onSelectionChanged: (s) => setState(() => _period = s.first),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isEdit ? 'Simpan Perubahan' : 'Simpan Overhead',
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
