import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Full-width solid button used for hero CTAs (Sign in, Calculate, Save).
/// Presses run a short scale-down micro-interaction that matches [GlassCard]'s
/// tactile press feedback.
class PrimaryButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final disabled = widget.onPressed == null || widget.loading;
    final radius = BorderRadius.circular(16);

    return AnimatedScale(
      scale: _pressed && !disabled ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Opacity(
        opacity: disabled ? 0.6 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.primary, borderRadius: radius),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: disabled ? null : widget.onPressed,
              onHighlightChanged: (v) {
                if (v != _pressed) setState(() => _pressed = v);
              },
              child: SizedBox(
                height: 52,
                child: Center(
                  child: widget.loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
