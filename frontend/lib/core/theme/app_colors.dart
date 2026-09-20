import 'package:flutter/material.dart';

/// Central theme-aware colors for migrating screens to dark mode.
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

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Screen background
  static Color bg(BuildContext context) =>
      isDark(context) ? const Color(0xFF141619) : const Color(0xFFF5F6FA);

  /// Card / sheet surfaces
  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E2126) : Colors.white;

  /// Primary text
  static Color ink(BuildContext context) =>
      isDark(context) ? const Color(0xFFF2F3F5) : const Color(0xFF1A1D1F);

  /// Secondary text
  static Color muted(BuildContext context) =>
      isDark(context) ? const Color(0xFF9AA3AF) : const Color(0xFF6F7789);

  /// Tertiary text / disabled labels (lighter than muted)
  static Color faint(BuildContext context) =>
      isDark(context) ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

  /// Strong icons (slightly softer than ink)
  static Color inkSoft(BuildContext context) =>
      isDark(context) ? const Color(0xFFD5D8DD) : const Color(0xFF374151);

  /// App accent (red)
  static Color accent(BuildContext context) =>
      isDark(context) ? const Color(0xFFEF5350) : const Color(0xFFE53935);

  /// Soft accent background (icon chips, selected states)
  static Color accentSoft(BuildContext context) => isDark(context)
      ? const Color(0xFFEF5350).withValues(alpha: 0.15)
      : const Color(0xFFFFEBEE);

  /// Neutral chip / inset background
  static Color chip(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A2E34) : const Color(0xFFF0F4F8);

  /// Hairline dividers and borders
  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF2E3238) : const Color(0xFFE9ECF0);
}
