import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/margin_health.dart';

/// A pill showing "+18.5%" (green), "9.2%" (amber), or "-4.1%" (red) — colored
/// by the margin_health bucket. Used on dashboard cards and pricing results.
class MarginBadge extends StatelessWidget {
  final num? marginPercent;
  final bool compact;

  const MarginBadge({super.key, required this.marginPercent, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final health = marginHealth(marginPercent);
    final bg = marginBg(health, c);
    final fg = marginFg(health, c);
    final label = marginLabel(marginPercent);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            health == MarginHealth.good
                ? Icons.trending_up
                : health == MarginHealth.warning
                    ? Icons.warning_amber_rounded
                    : health == MarginHealth.danger
                        ? Icons.trending_down
                        : Icons.help_outline,
            size: compact ? 12 : 14,
            color: fg,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}
