import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Each tool on the functions screen keeps one toned hue, used on its card
/// there and inside its own screen, so a tool is recognisable everywhere:
/// tomato for Pomodoro, violet for the blocker, amber for music, green for
/// intervals.
enum ToolHue {
  focus(Color(0xFFE53935), Color(0xFFE5534B)),
  blocker(Color(0xFF6A4BC4), Color(0xFF9D86E3)),
  music(Color(0xFFB7791F), Color(0xFFD9A045)),
  interval(Color(0xFF2E7D4F), Color(0xFF5BB57A));

  const ToolHue(this.light, this.dark);

  final Color light;
  final Color dark;

  Color of(BuildContext context) => AppColors.isDark(context) ? dark : light;

  /// Tinted surface for tiles and soft states.
  Color soft(BuildContext context) =>
      of(context).withValues(alpha: AppColors.isDark(context) ? 0.16 : 0.12);

  /// Text and icons placed on a solid [of] fill. The dark-mode hues are light,
  /// so they take dark ink; the light-mode hues take white.
  Color onFill(BuildContext context) =>
      AppColors.isDark(context) ? AppColors.darkBg : Colors.white;
}
