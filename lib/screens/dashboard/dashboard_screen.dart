import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/rupiah_formatter.dart';
import '../../models/dashboard_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/margin_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final p = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();
    final greetName = (auth.user?.name.isNotEmpty ?? false)
        ? auth.user!.name.split(' ').first
        : 'Tamu';

    final items = p.items;
    final priced = items.where((i) => i.marginPercent != null).toList();
    final avgMargin = priced.isEmpty
        ? null
        : priced.map((i) => i.marginPercent!).reduce((a, b) => a + b) / priced.length;
    final warningCount = items.where((i) {
      final m = i.marginPercent;
      return m != null && m < 15;
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => p.refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => p.refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            GradientHeroCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $greetName 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(auth.user?.businessName ?? 'Yuk cek margin usaha kamu.',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      _HeroStat(label: 'Total Resep', value: '${items.length}'),
                      const SizedBox(width: 24),
                      _HeroStat(
                        label: 'Rata-rata margin',
                        value: avgMargin == null
                            ? '-'
                            : '${avgMargin.toStringAsFixed(1)}%',
                      ),
                      const SizedBox(width: 24),
                      _HeroStat(label: 'Perlu perhatian', value: '$warningCount'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text('Produk',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    )),
                const Spacer(),
                _SortMenu(current: p.sort, onChanged: p.setSort),
              ],
            ),
            const SizedBox(height: 10),
            if (p.loading && items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.receipt_long,
                  title: 'Belum ada produk',
                  subtitle: 'Tambahkan resep pertama untuk melihat margin di sini.',
                  action: FilledButton(
                    onPressed: () => context.go('/recipes'),
                    child: const Text('Buat Resep'),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  if (wide) {
                    return GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.9,
                      children: [
                        for (final item in items) _DashboardCard(item: item),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      for (final item in items) ...[
                        _DashboardCard(item: item),
                        const SizedBox(height: 10),
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

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}

class _SortMenu extends StatelessWidget {
  final DashboardSort current;
  final ValueChanged<DashboardSort> onChanged;
  const _SortMenu({required this.current, required this.onChanged});

  static const _labels = {
    DashboardSort.marginAsc: 'Margin ↑ (terendah)',
    DashboardSort.marginDesc: 'Margin ↓ (tertinggi)',
    DashboardSort.nameAsc: 'Nama A–Z',
    DashboardSort.newest: 'Terbaru',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopupMenuButton<DashboardSort>(
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        for (final s in DashboardSort.values)
          PopupMenuItem(value: s, child: Text(_labels[s]!)),
      ],
      child: Row(
        children: [
          Icon(Icons.sort, color: c.textSecondary, size: 18),
          const SizedBox(width: 4),
          Text(_labels[current]!,
              style: TextStyle(color: c.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final DashboardItem item;
  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      onTap: () => context.push('/recipes/${item.recipeId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    )),
              ),
              MarginBadge(marginPercent: item.marginPercent, compact: true),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _MiniCol(label: 'HPP', value: formatRupiah(item.hppPerUnit)),
              const SizedBox(width: 18),
              _MiniCol(label: 'Harga', value: formatRupiah(item.suggestedPrice)),
              const Spacer(),
              Text('per ${item.yieldUnit}',
                  style: TextStyle(color: c.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniCol extends StatelessWidget {
  final String label;
  final String value;
  const _MiniCol({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: c.textSecondary, fontSize: 11)),
        Text(value,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            )),
      ],
    );
  }
}
