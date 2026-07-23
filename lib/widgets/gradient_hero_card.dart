import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// The signature hero surface: a flat accent card for the key summary area.
class GradientHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;

  const GradientHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = BorderRadius.circular(22);

    return Container(
      height: height,
      decoration: BoxDecoration(color: c.primary, borderRadius: radius),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
