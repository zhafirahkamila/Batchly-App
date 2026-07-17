import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Banner that warns the user when the current margin isn't healthy. Two
/// severities:
///   - danger (margin <= 0): selling below COGS, losing money per unit
///   - warning (0 < margin < 15): thin margin, common F&B footgun
///
/// Renders nothing when [margin] is healthy — callers can drop this in
/// unconditionally and rely on `SizedBox.shrink` short-circuit behavior.
class MarginWarning extends StatelessWidget {
  final double margin;
  const MarginWarning({super.key, required this.margin});

  @override
  Widget build(BuildContext context) {
    if (margin >= 15) return const SizedBox.shrink();
    final c = AppColors.of(context);
    final isDanger = margin <= 0;
    final bg = isDanger ? c.marginDangerBg : c.marginWarningBg;
    final fg = isDanger ? c.marginDangerText : c.marginWarningText;
    final msg = isDanger
        ? 'Selling price is below COGS — you will lose money on each unit sold.'
        : 'Thin margin (<15%). Consider raising the price or lowering ingredient costs.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(isDanger ? Icons.error_outline : Icons.warning_amber_rounded, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(color: fg, fontSize: 13))),
        ],
      ),
    );
  }
}
