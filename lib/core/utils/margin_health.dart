import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Buckets a computed margin percentage into a visual health category. Used
/// by the MarginBadge and by the dashboard to flag problem products.
///
/// Bands are deliberately generous for F&B — a 15 % margin is thin for a
/// small food business (packaging + delivery eat into it), so we treat
/// <15 % as warning and <=0 % as danger.
enum MarginHealth { good, warning, danger, unknown }

MarginHealth marginHealth(num? marginPercent) {
  if (marginPercent == null || !marginPercent.isFinite) return MarginHealth.unknown;
  if (marginPercent <= 0) return MarginHealth.danger;
  if (marginPercent < 15) return MarginHealth.warning;
  return MarginHealth.good;
}

Color marginBg(MarginHealth h, AppColors c) {
  switch (h) {
    case MarginHealth.good:
      return c.marginGoodBg;
    case MarginHealth.warning:
      return c.marginWarningBg;
    case MarginHealth.danger:
      return c.marginDangerBg;
    case MarginHealth.unknown:
      return c.surfaceElevated;
  }
}

Color marginFg(MarginHealth h, AppColors c) {
  switch (h) {
    case MarginHealth.good:
      return c.marginGoodText;
    case MarginHealth.warning:
      return c.marginWarningText;
    case MarginHealth.danger:
      return c.marginDangerText;
    case MarginHealth.unknown:
      return c.textSecondary;
  }
}

String marginLabel(num? marginPercent) {
  if (marginPercent == null || !marginPercent.isFinite) return 'Belum dihitung';
  final sign = marginPercent >= 0 ? '' : '-';
  return '$sign${marginPercent.abs().toStringAsFixed(1)}%';
}
