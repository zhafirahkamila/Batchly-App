import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/rupiah_formatter.dart';
import '../../models/dashboard_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/animated_number.dart';
import '../../widgets/batchly_logo.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_hero_card.dart';
import '../../widgets/margin_badge.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_box.dart';

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
        : 'Guest';

    final items = p.items;
    final priced = items.where((i) => i.marginPercent != null).toList();
    final avgMargin = priced.isEmpty
        ? null
        : priced.map((i) => i.marginPercent!).reduce((a, b) => a + b) /
              priced.length;
    final warningCount = items.where((i) {
      final m = i.marginPercent;
      return m != null && m < 15;
    }).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          children: [
            const BatchlyLogo(size: 28),
            const SizedBox(width: 10),
            Text(
              'Batchly',
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            GradientHeroCard(
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $greetName 👋',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    auth.user?.businessName ?? 'Check your business margins.',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      _HeroStat.count(
                        label: 'Total Recipes',
                        value: items.length,
                      ),
                      const SizedBox(width: 28),
                      _HeroStat.percent(
                        label: 'Average margin',
                        value: avgMargin,
                      ),
                      const SizedBox(width: 28),
                      _HeroStat.count(
                        label: 'Needs attention',
                        value: warningCount,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Row(
                children: [
                  Text(
                    'Products',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  _SortMenu(current: p.sort, onChanged: p.setSort),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (p.loading && items.isEmpty)
              Column(
                children: const [
                  SkeletonCard(height: 92),
                  SizedBox(height: 12),
                  SkeletonCard(height: 82),
                  SizedBox(height: 12),
                  SkeletonCard(height: 82),
                ],
              )
            else if (items.isEmpty && p.error != null)
              _DashboardErrorCard(
                message: p.error!,
                onRetry: () => p.refresh(),
              )
            else if (items.isEmpty)
              _DashboardEmptyCard(
                onCreate: () => context.go('/recipes'),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 600;
                  if (wide) {
                    // Asymmetric tablet layout: the first (lowest-margin, most
                    // attention-worthy) card spans full width, subsequent
                    // cards fall into a 2-column grid.
                    final spotlight = items.first;
                    final rest = items.skip(1).toList();
                    return Column(
                      children: [
                        _DashboardCard(item: spotlight, featured: true),
                        if (rest.isNotEmpty) const SizedBox(height: 14),
                        if (rest.isNotEmpty)
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.9,
                            children: [
                              for (final item in rest)
                                _DashboardCard(item: item),
                            ],
                          ),
                      ],
                    );
                  }
                  // Mobile: single column with a slightly bolder first card
                  // and varied spacing so it doesn't read as a rigid grid.
                  const spacings = [14.0, 10.0, 12.0, 8.0];
                  return Column(
                    children: [
                      for (var idx = 0; idx < items.length; idx++) ...[
                        _DashboardCard(item: items[idx], featured: idx == 0),
                        if (idx < items.length - 1)
                          SizedBox(height: spacings[idx % spacings.length]),
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

  /// Numeric value to animate. Null renders "–" instead of tweening — used
  /// for "Average margin" when no recipe has been priced yet.
  final double? value;
  final String Function(double) formatter;

  const _HeroStat._({
    required this.label,
    required this.value,
    required this.formatter,
  });

  factory _HeroStat.count({required String label, required int value}) =>
      _HeroStat._(
        label: label,
        value: value.toDouble(),
        formatter: (v) => v.round().toString(),
      );

  factory _HeroStat.percent({required String label, required double? value}) =>
      _HeroStat._(
        label: label,
        value: value,
        formatter: (v) => '${v.toStringAsFixed(1)}%',
      );

  @override
  Widget build(BuildContext context) {
    const numberStyle = TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.2,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 4),
        if (value == null)
          const Text('–', style: numberStyle)
        else
          AnimatedNumber(
            value: value!,
            formatter: formatter,
            style: numberStyle,
          ),
      ],
    );
  }
}

/// Empty-state block that lives *inside* the products region — the hero card
/// and section header above it stay visible so the dashboard still feels
/// alive at zero data.
class _DashboardEmptyCard extends StatelessWidget {
  final VoidCallback onCreate;
  const _DashboardEmptyCard({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.accentPrimary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.calculate_rounded,
                color: c.accentPrimary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            'No products yet',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start by calculating the HPP for your first recipe. Once you do, its margin and suggested price appear here.',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Create Recipe',
            icon: Icons.add_rounded,
            onPressed: onCreate,
          ),
        ],
      ),
    );
  }
}

/// Inline error card shown when the summary fetch fails — replaces the
/// misleading "No products yet" empty state in that case.
class _DashboardErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _DashboardErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_rounded, color: c.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Couldn't load dashboard",
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: c.textSecondary, fontSize: 12.5),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  final DashboardSort current;
  final ValueChanged<DashboardSort> onChanged;
  const _SortMenu({required this.current, required this.onChanged});

  static const _labels = {
    DashboardSort.marginAsc: 'Margin ↑ (lowest)',
    DashboardSort.marginDesc: 'Margin ↓ (highest)',
    DashboardSort.nameAsc: 'Name A–Z',
    DashboardSort.newest: 'Newest',
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopupMenuButton<DashboardSort>(
      onSelected: onChanged,
      itemBuilder: (ctx) => [
        for (final s in DashboardSort.values)
          PopupMenuItem(value: s, child: Text(_labels[s] ?? s.name)),
      ],
      child: Row(
        children: [
          Icon(Icons.sort, color: c.textSecondary, size: 18),
          const SizedBox(width: 4),
          Text(
            _labels[current] ?? current.name,
            style: TextStyle(color: c.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final DashboardItem item;
  final bool featured;
  const _DashboardCard({required this.item, this.featured = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GlassCard(
      padding: featured
          ? const EdgeInsets.fromLTRB(18, 18, 18, 20)
          : const EdgeInsets.all(16),
      onTap: () => context.push('/recipes/${item.recipeId}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: featured ? 17 : 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              MarginBadge(
                marginPercent: item.marginPercent,
                compact: !featured,
              ),
            ],
          ),
          SizedBox(height: featured ? 12 : 8),
          Row(
            children: [
              _MiniCol(label: 'COGS', value: formatRupiah(item.hppPerUnit)),
              const SizedBox(width: 18),
              _MiniCol(
                label: 'Price',
                value: formatRupiah(item.suggestedPrice),
              ),
              const Spacer(),
              Text(
                'per ${item.yieldUnit}',
                style: TextStyle(color: c.textSecondary, fontSize: 11),
              ),
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
        Text(
          value,
          style: TextStyle(
            color: c.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
