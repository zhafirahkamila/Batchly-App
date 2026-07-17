import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A rounded card. In dark mode it renders as a subtle glass panel (backdrop
/// blur + translucent fill) so it feels layered over the dark canvas; in
/// light mode it's a plain white card with a hairline border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Padding(padding: padding, child: child);

    if (c.useGlassBlur) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: borderRadius,
              border: Border.all(color: c.border, width: 1),
            ),
            child: content,
          ),
        ),
      );
    } else {
      content = Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: borderRadius,
          border: Border.all(color: c.border, width: 1),
        ),
        child: content,
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }
    return content;
  }
}
