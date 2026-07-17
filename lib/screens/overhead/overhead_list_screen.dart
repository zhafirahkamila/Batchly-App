import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/rupiah_formatter.dart';
import '../../models/overhead.dart';
import '../../providers/overhead_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/section_header.dart';

class OverheadListScreen extends StatefulWidget {
  const OverheadListScreen({super.key});

  @override
  State<OverheadListScreen> createState() => _OverheadListScreenState();
}

class _OverheadListScreenState extends State<OverheadListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OverheadProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = context.watch<OverheadProvider>();
    final perBulan = p.items.where((o) => o.period == 'per_bulan').toList();
    final perBatch = p.items.where((o) => o.period == 'per_batch').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Overhead Costs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile/overhead/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refresh(),
        child: p.loading && p.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  Text(
                    'Recurring costs like electricity, gas, packaging, salaries. '
                    'Overhead is used when calculating COGS to allocate monthly costs to each product.',
                    style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  if (p.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: EmptyState(
                        icon: Icons.receipt_outlined,
                        title: 'No overhead yet',
                        subtitle: 'Add your first operating cost.',
                      ),
                    ),
                  if (perBulan.isNotEmpty) ...[
                    const SectionHeader(title: 'Per Month'),
                    for (final o in perBulan) ...[
                      _OverheadTile(overhead: o, colors: c),
                      const SizedBox(height: 10),
                    ],
                  ],
                  if (perBatch.isNotEmpty) ...[
                    const SectionHeader(title: 'Per Batch'),
                    for (final o in perBatch) ...[
                      _OverheadTile(overhead: o, colors: c),
                      const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
      ),
    );
  }
}

class _OverheadTile extends StatelessWidget {
  final Overhead overhead;
  final AppColors colors;
  const _OverheadTile({required this.overhead, required this.colors});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/profile/overhead/${overhead.id}/edit'),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.accentPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              overhead.period == 'per_bulan'
                  ? Icons.calendar_month_outlined
                  : Icons.inventory_2_outlined,
              color: colors.accentPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(overhead.name,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                Text(
                  overhead.period == 'per_bulan' ? 'per month' : 'per batch',
                  style: TextStyle(color: colors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            formatRupiah(overhead.amount),
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
