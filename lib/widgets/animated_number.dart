import 'package:flutter/material.dart';

/// A text widget whose numeric value tweens smoothly between updates. Formats
/// via the supplied [formatter] each frame so it can render prices, margins,
/// counts, etc. with the same primitive.
///
/// Retains the previously-shown value across rebuilds so refreshes tween from
/// the last painted number instead of jumping back to zero.
class AnimatedNumber extends StatefulWidget {
  final double value;
  final String Function(double) formatter;
  final Duration duration;
  final TextStyle? style;
  final TextAlign? textAlign;
  final Curve curve;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.formatter,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
    this.style,
    this.textAlign,
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber> {
  late double _from = widget.value;

  @override
  void didUpdateWidget(covariant AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _from = oldWidget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _from, end: widget.value),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, v, _) => Text(
        widget.formatter(v),
        style: widget.style,
        textAlign: widget.textAlign,
      ),
    );
  }
}
