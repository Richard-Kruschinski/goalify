import '../../l10n/generated/app_localizations.dart';

/// Renders a minute count as "45 Min." / "1 Std." / "2 Std. 15 Min.".
///
/// Shared so the pomodoro stats and the progress screen's weekly review -
/// which show the same focus minutes - cannot drift apart in formatting.
/// Clock style: "1:05" for 65 seconds, "1:02:05" past an hour.
/// Used by the gym rest timer (bar, settings, history).
String formatClockDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = (totalSeconds % 60).toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$s';
  return '$m:$s';
}

String formatFocusMinutes(AppLocalizations l10n, int minutes) {
  if (minutes < 60) return '$minutes ${l10n.unitMin}';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0
      ? '$h ${l10n.unitHour}'
      : '$h ${l10n.unitHour} $m ${l10n.unitMin}';
}
