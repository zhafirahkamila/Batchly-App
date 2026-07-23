import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A rounded card with a flat fill and subtle border.
///
/// When [onTap] is provided, the card gains a soft press micro-interaction
/// (scale 0.97 on pointer-down, ~150ms ease).
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.radius = 18,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  bool get _interactive => widget.onTap != null || widget.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final borderRadius = BorderRadius.circular(widget.radius);

    Widget content = Padding(padding: widget.padding, child: widget.child);

    content = Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: borderRadius,
        border: Border.all(color: c.border, width: 1),
      ),
      child: content,
    );

    if (_interactive) {
      content = Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged: (v) {
            if (v != _pressed) setState(() => _pressed = v);
          },
          child: content,
        ),
      );
      content = AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: content,
      );
    }
    return content;
  }
}
