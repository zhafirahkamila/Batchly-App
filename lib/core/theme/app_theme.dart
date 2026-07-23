import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Builds [ThemeData] for both light and dark modes. Every visual token
/// (surface colors, radii, input decoration, text weights) is driven by
/// [AppColors] so widgets can stay palette-agnostic. Every commonly-used
/// Material component (Slider, Checkbox, Switch, SegmentedButton, Progress,
/// FilledButton, Dialog) is explicitly themed to prevent the default seed
/// color from leaking through.
class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness b) {
    final base = b == Brightness.dark ? ThemeData.dark() : ThemeData.light();
    final baseText = GoogleFonts.plusJakartaSansTextTheme(
      base.textTheme,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    // Explicit type scale — hero numbers get to breathe, section headers stay
    // tight, meta text is comfortably small. Applied on top of Plus Jakarta
    // Sans so weights and letter-spacing survive the .apply() above.
    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: baseText.displayMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 13.5),
      labelSmall: baseText.labelSmall?.copyWith(
        fontSize: 11.5,
        letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      brightness: b,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      colorScheme:
          (b == Brightness.dark
                  ? const ColorScheme.dark()
                  : const ColorScheme.light())
              .copyWith(
                primary: c.primary,
                surface: c.surface,
                onPrimary: Colors.white,
                onSurface: c.textPrimary,
              ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: c.textPrimary),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.textSecondary),
        labelStyle: TextStyle(color: c.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.marginDangerText),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          elevation: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceElevated,
        contentTextStyle: TextStyle(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textSecondary,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: c.textSecondary, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? Colors.white : c.textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.primary : c.border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: c.primary,
        inactiveTrackColor: c.border,
        thumbColor: c.primary,
        overlayColor: c.primary.withOpacity(0.12),
        valueIndicatorColor: c.primary,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.primary,
        linearTrackColor: c.border,
        circularTrackColor: c.border,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected)
                ? c.primary.withOpacity(0.14)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) =>
                s.contains(WidgetState.selected) ? c.primary : c.textSecondary,
          ),
          side: WidgetStateProperty.all(BorderSide(color: c.border)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: c.border),
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: c.textSecondary,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border),
        ),
        textStyle: textTheme.bodyLarge,
      ),
    );
  }
}
