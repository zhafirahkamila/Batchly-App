import 'package:flutter/material.dart';

/// Semantic color tokens for Batchly. Never hardcode hex in widgets — pull from
/// `AppColors.of(context)` so the same widget renders correctly in both modes.
///
/// The Batchly identity is a flat teal-forward palette with warm neutrals and
/// no gradient or glassmorphism surfaces.
class AppColors {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color primary;
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
    required this.primary,
    required this.marginGoodBg,
    required this.marginGoodText,
    required this.marginWarningBg,
    required this.marginWarningText,
    required this.marginDangerBg,
    required this.marginDangerText,
    required this.useGlassBlur,
  });

  static const dark = AppColors(
    background: Color(0xFF0E1116),
    surface: Color(0xFF161A21),
    surfaceElevated: Color(0xFF1F242D),
    textPrimary: Color(0xFFF2F3F5),
    textSecondary: Color(0xFF8B93A1),
    border: Color(0x14FFFFFF),
    primary: Color(0xFF12805F),
    marginGoodBg: Color(0x262E9D6E),
    marginGoodText: Color(0xFF4ADE9A),
    marginWarningBg: Color(0x26C27832),
    marginWarningText: Color(0xFFF0A868),
    marginDangerBg: Color(0x26F97066),
    marginDangerText: Color(0xFFFF8A80),
    useGlassBlur: false,
  );

  static const light = AppColors(
    background: Color(0xFFF7F8FA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF667085),
    border: Color(0xFFE4E7EC),
    primary: Color(0xFF0E6B52),
    marginGoodBg: Color(0xFFECFDF3),
    marginGoodText: Color(0xFF027A48),
    marginWarningBg: Color(0xFFFFFAEB),
    marginWarningText: Color(0xFFB54708),
    marginDangerBg: Color(0xFFFEF3F2),
    marginDangerText: Color(0xFFB42318),
    useGlassBlur: false,
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}
