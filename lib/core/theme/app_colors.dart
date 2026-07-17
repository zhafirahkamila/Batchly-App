import 'package:flutter/material.dart';

/// Semantic color tokens for Batchly. Never hardcode hex in widgets — pull from
/// `AppColors.of(context)` so the same widget renders correctly in both modes.
///
/// The "Batchly Dark" identity is the primary brand feel: dark charcoal-purple
/// canvas with a purple → pink gradient hero. Light mode keeps the same gradient
/// family (adjusted for contrast on a warm off-white) and drops glassmorphism.
class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final List<Color> accentGradient;
  final Color accentPrimary;
  final Color marginGoodBg;
  final Color marginGoodText;
  final Color marginWarningBg;
  final Color marginWarningText;
  final Color marginDangerBg;
  final Color marginDangerText;
  final bool useGlassBlur;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.accentGradient,
    required this.accentPrimary,
    required this.marginGoodBg,
    required this.marginGoodText,
    required this.marginWarningBg,
    required this.marginWarningText,
    required this.marginDangerBg,
    required this.marginDangerText,
    required this.useGlassBlur,
  });

  static const dark = AppColors(
    background: Color(0xFF121016),
    surface: Color(0xFF17151D),
    surfaceElevated: Color(0xFF1F1C26),
    textPrimary: Color(0xFFF5F3F8),
    textSecondary: Color(0xFF8F8A9C),
    border: Color(0x14FFFFFF),
    accentGradient: [Color(0xFF7B5CFF), Color(0xFFFF6FA5)],
    accentPrimary: Color(0xFF7B5CFF),
    marginGoodBg: Color(0x3D1D9E75),
    marginGoodText: Color(0xFF4FE0B0),
    marginWarningBg: Color(0x3DEF9F27),
    marginWarningText: Color(0xFFFFC271),
    marginDangerBg: Color(0x3DF0997B),
    marginDangerText: Color(0xFFFF8A8A),
    useGlassBlur: true,
  );

  static const light = AppColors(
    background: Color(0xFFFAF9FC),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF1C1B22),
    textSecondary: Color(0xFF6B6577),
    border: Color(0xFFECE9F2),
    accentGradient: [Color(0xFF6A4CFF), Color(0xFFFF5B96)],
    accentPrimary: Color(0xFF6A4CFF),
    marginGoodBg: Color(0xFFE1F5EE),
    marginGoodText: Color(0xFF0F6E56),
    marginWarningBg: Color(0xFFFAECE7),
    marginWarningText: Color(0xFF993C1D),
    marginDangerBg: Color(0xFFFDE2E2),
    marginDangerText: Color(0xFFB3261E),
    useGlassBlur: false,
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
