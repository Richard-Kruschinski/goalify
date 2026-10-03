import '../../l10n/generated/app_localizations.dart';

/// Renders a minute count as "45 Min." / "1 Std." / "2 Std. 15 Min.".
///
/// Shared so the pomodoro stats and the progress screen's weekly review -
/// which show the same focus minutes - cannot drift apart in formatting.
String formatFocusMinutes(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return '$minutes ${l10n.unitMin}';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0
      ? '$h ${l10n.unitHour}'
      : '$h ${l10n.unitHour} $m ${l10n.unitMin}';
}
