import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Material themes built from the AppColors ramp instead of a seed color,
/// so default widgets (dialogs, sheets, switches, snackbars, the bottom
/// navigation) pick up neutral surfaces and the one red accent.
class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        bg: AppColors.lightBg,
        card: AppColors.lightCard,
        raised: AppColors.lightCard,
        chip: AppColors.lightChip,
        ink: AppColors.lightInk,
        muted: AppColors.lightMuted,
        faint: AppColors.lightFaint,
        accent: AppColors.accentLight,
        border: Colors.black.withValues(alpha: 0.08),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        bg: AppColors.darkBg,
        card: AppColors.darkCard,
        raised: AppColors.darkRaised,
        chip: AppColors.darkChip,
        ink: AppColors.darkInk,
        muted: AppColors.darkMuted,
        faint: AppColors.darkFaint,
        accent: AppColors.accentDark,
        border: Colors.white.withValues(alpha: 0.08),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color card,
    required Color raised,
    required Color chip,
    required Color ink,
    required Color muted,
    required Color faint,
    required Color accent,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: Colors.white,
      primaryContainer: accent.withValues(alpha: isDark ? 0.14 : 0.10),
      onPrimaryContainer: accent,
      secondary: ink,
      onSecondary: bg,
      secondaryContainer: chip,
      onSecondaryContainer: ink,
      tertiary: muted,
      onTertiary: bg,
      error: isDark ? const Color(0xFFE5534B) : const Color(0xFFD32F2F),
      onError: Colors.white,
      surface: card,
      onSurface: ink,
      onSurfaceVariant: muted,
      surfaceDim: bg,
      surfaceBright: raised,
      surfaceContainerLowest: bg,
      surfaceContainerLow: card,
      surfaceContainer: card,
      surfaceContainerHigh: raised,
      surfaceContainerHighest: chip,
      outline: faint,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: ink,
      onInverseSurface: bg,
      inversePrimary: accent,
      surfaceTint: Colors.transparent,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border,
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isDark ? BorderSide(color: border) : BorderSide.none,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: card,
        modalBackgroundColor: card,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: faint,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark ? BorderSide(color: border) : BorderSide.none,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkChip : AppColors.lightInk,
        contentTextStyle: TextStyle(
          color: isDark ? AppColors.darkInk : Colors.white,
        ),
        actionTextColor: accent,
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: accent,
        unselectedItemColor: muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: isDark ? 0 : 2,
        highlightElevation: isDark ? 0 : 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : faint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : chip,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : border,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: chip,
        thumbColor: accent,
        overlayColor: accent.withValues(alpha: 0.12),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: chip,
        circularTrackColor: chip,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: faint, width: 1.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chip,
        selectedColor: accent.withValues(alpha: isDark ? 0.14 : 0.10),
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: ink),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: chip,
        hintStyle: TextStyle(color: faint),
        labelStyle: TextStyle(color: muted),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accent,
        selectionColor: accent.withValues(alpha: 0.3),
        selectionHandleColor: accent,
      ),
      listTileTheme: ListTileThemeData(iconColor: muted, textColor: ink),
      iconTheme: IconThemeData(color: muted),
    );
  }
}
