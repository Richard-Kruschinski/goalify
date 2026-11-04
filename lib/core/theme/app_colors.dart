import 'package:flutter/material.dart';

/// Central theme-aware colors.
///
/// Surfaces, borders and text come from one neutral graphite ramp. The only
/// hue in the chrome is the red accent, which marks "today / now": the
/// selected day, a running timer and the primary action. Semantic colors
/// (success, warning, info) carry meaning only and are toned down to sit
/// inside the palette.
///
/// Usage: replace hardcoded colors with these getters, e.g.
///   Colors.white            -> AppColors.card(context)
///   Color(0xFFF5F7FA)       -> AppColors.bg(context)
///   Color(0xFF1A1D1F)       -> AppColors.ink(context)
///   Color(0xFF6F7789)       -> AppColors.muted(context)
///   Color(0xFFE53935)       -> AppColors.accent(context)
///   Color(0xFFFFEBEE)       -> AppColors.accentSoft(context)
class AppColors {
  AppColors._();

  // Dark graphite ramp
  static const darkBg = Color(0xFF121213);
  static const darkCard = Color(0xFF1B1B1D);
  static const darkRaised = Color(0xFF222225);
  static const darkChip = Color(0xFF26262A);
  static const darkInk = Color(0xFFEDEDEE);
  static const darkMuted = Color(0xFFA1A1A6);
  static const darkFaint = Color(0xFF6E6E73);

  // Light ramp
  static const lightBg = Color(0xFFF5F5F7);
  static const lightCard = Colors.white;
  static const lightChip = Color(0xFFF0F0F2);
  static const lightInk = Color(0xFF1B1B1D);
  static const lightMuted = Color(0xFF6B6B70);
  static const lightFaint = Color(0xFF9E9EA3);

  // Accent
  static const accentLight = Color(0xFFE53935);
  static const accentDark = Color(0xFFE5534B);

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Screen background
  static Color bg(BuildContext context) => isDark(context) ? darkBg : lightBg;

  /// Card / sheet surfaces
  static Color card(BuildContext context) =>
      isDark(context) ? darkCard : lightCard;

  /// Raised surface on top of a card (dialogs, menus, active rows)
  static Color raised(BuildContext context) =>
      isDark(context) ? darkRaised : lightCard;

  /// Primary text
  static Color ink(BuildContext context) => isDark(context) ? darkInk : lightInk;

  /// Secondary text
  static Color muted(BuildContext context) =>
      isDark(context) ? darkMuted : lightMuted;

  /// Tertiary text / disabled labels (lighter than muted)
  static Color faint(BuildContext context) =>
      isDark(context) ? darkFaint : lightFaint;

  /// Strong icons (slightly softer than ink)
  static Color inkSoft(BuildContext context) =>
      isDark(context) ? const Color(0xFFD4D4D7) : const Color(0xFF3A3A3E);

  /// App accent (red)
  static Color accent(BuildContext context) =>
      isDark(context) ? accentDark : accentLight;

  /// Soft accent background (selected states)
  static Color accentSoft(BuildContext context) => isDark(context)
      ? accentDark.withValues(alpha: 0.14)
      : const Color(0xFFFDECEC);

  /// Neutral chip / inset background, also used for icon tiles
  static Color chip(BuildContext context) =>
      isDark(context) ? darkChip : lightChip;

  /// Hairline dividers and borders
  static Color border(BuildContext context) => isDark(context)
      ? Colors.white.withValues(alpha: 0.08)
      : Colors.black.withValues(alpha: 0.08);

  /// Good change, done, completed
  static Color success(BuildContext context) =>
      isDark(context) ? const Color(0xFF5BB57A) : const Color(0xFF2E7D4F);

  static Color successSoft(BuildContext context) => isDark(context)
      ? const Color(0xFF5BB57A).withValues(alpha: 0.14)
      : const Color(0xFFE6F4EA);

  /// Streaks, rewards, warnings
  static Color warning(BuildContext context) =>
      isDark(context) ? const Color(0xFFD9A045) : const Color(0xFFB7791F);

  static Color warningSoft(BuildContext context) => isDark(context)
      ? const Color(0xFFD9A045).withValues(alpha: 0.14)
      : const Color(0xFFFBF1E1);

  /// Breaks, freezes, informational states
  static Color info(BuildContext context) =>
      isDark(context) ? const Color(0xFF6A9FD8) : const Color(0xFF2F6DB5);

  static Color infoSoft(BuildContext context) => isDark(context)
      ? const Color(0xFF6A9FD8).withValues(alpha: 0.14)
      : const Color(0xFFE6EEF8);

  /// Card shadow: soft and neutral in light mode, none in dark mode where
  /// depth comes from surface steps and hairlines.
  static List<BoxShadow> cardShadow(BuildContext context) => isDark(context)
      ? const []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ];
}
