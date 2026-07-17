import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/gradients.dart';

/// The signature "premium" surface: a purple→pink gradient card with the
/// brand's key numbers. In dark mode we layer a translucent frosted panel over
/// the gradient (glassmorphism); in light mode we render a solid white inner
/// card — glass reads as premium against dark canvases but muddy against
/// light ones, so we swap the treatment per brightness.
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

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: AppGradients.accent(c),
          borderRadius: radius,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative blurred blobs to give the card visual depth.
            Positioned(
              top: -40,
              right: -40,
              child: _Blob(color: Colors.white.withOpacity(0.18), size: 160),
            ),
            Positioned(
              bottom: -30,
              left: -20,
              child: _Blob(color: Colors.white.withOpacity(0.10), size: 120),
            ),
            if (c.useGlassBlur)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: const SizedBox(),
              ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(padding: padding, child: child),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
