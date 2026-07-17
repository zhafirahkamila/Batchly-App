import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Preset gradients derived from [AppColors.accentGradient]. Reuse these to
/// keep every accent surface pulling from a single source of truth.
class AppGradients {
  static LinearGradient accent(AppColors c) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: c.accentGradient,
    );
  }

  /// A softer, more washed version of the accent — for empty-state or CTA fills
  /// where a full-strength gradient would fight the surrounding chrome.
  static LinearGradient accentSoft(AppColors c) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        c.accentGradient.first.withOpacity(0.16),
        c.accentGradient.last.withOpacity(0.16),
      ],
    );
  }
}
