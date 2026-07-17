import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Shimmering placeholder that fades between two neutral tones of the palette.
/// Use in place of a `CircularProgressIndicator` while a screen's real content
/// is being fetched — the moving box hints at the final layout instead of
/// covering it with a spinner.
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_ac.value);
        final color = Color.lerp(c.surface, c.surfaceElevated, t);
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(widget.radius),
            border: Border.all(color: c.border, width: 1),
          ),
        );
      },
    );
  }
}

/// Card-shaped skeleton whose stroke and radius match [GlassCard] so it lines
/// up perfectly with the real cards that will replace it.
class SkeletonCard extends StatelessWidget {
  final double height;
  final double radius;

  const SkeletonCard({super.key, required this.height, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(height: height, radius: radius);
  }
}
