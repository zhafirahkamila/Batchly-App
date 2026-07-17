import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Batchly wordmark/logo used across splash, auth screens, and the app bar.
/// `size` is the height of the mark in logical pixels; the image scales
/// proportionally. `showWordmark` appends the "Batchly" text next to the mark
/// for larger contexts (splash, login).
class BatchlyLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;

  const BatchlyLogo({
    super.key,
    this.size = 48,
    this.showWordmark = false,
  });

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset(
      'assets/images/batchly-logo.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (!showWordmark) return mark;

    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.18),
        Text(
          'Batchly',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: size * 0.44,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
