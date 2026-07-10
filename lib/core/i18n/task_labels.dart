import 'package:intl/intl.dart';
import '../../features/tasks/data/models/daily_task.dart';
import '../../features/gym/data/models/gym_models.dart';
import '../../l10n/generated/app_localizations.dart';

/// Builds localized workout unit labels from the current localization.
WorkoutUnits workoutUnitsOf(AppLocalizations l10n) => WorkoutUnits(
      kg: l10n.unitKg,
      reps: l10n.unitReps,
      minShort: l10n.unitMin,
      secShort: l10n.unitSec,
      sets: l10n.setsWord,
      dropset: l10n.dropsetLabel,
      noProgress: l10n.noProgressYet,
      update: l10n.updateLabel,
    );

/// Localized display labels for task repeat patterns.
/// Mirrors the English label logic in the models (DailyTask /
/// TaskRepeatPattern), which stays context-free for storage purposes.

/// Short weekday name (Mon/Mo./пн) for weekday 1 (Monday) .. 7 (Sunday).
String localizedWeekdayShort(int weekday, String localeName) {
  // 2024-01-01 was a Monday, so day N of that week has weekday N.
  return DateFormat.E(localeName).format(DateTime(2024, 1, weekday));
}

/// Localized version of TaskRepeatPattern.label
String localizedPatternLabel(
    AppLocalizations l10n, TaskRepeatPattern pattern, int customDays) {
  switch (pattern) {
    case TaskRepeatPattern.daily:
      return l10n.dailyLabel;
    case TaskRepeatPattern.every_2_days:
      return l10n.everyNDays(2);
    case TaskRepeatPattern.every_3_days:
      return l10n.everyNDays(3);
    case TaskRepeatPattern.weekly_days:
      return l10n.repeatWeekly;
    case TaskRepeatPattern.every_7_days:
      return l10n.everyNDays(7);
    case TaskRepeatPattern.biweekly:
      return l10n.repeatBiweekly;
    case TaskRepeatPattern.monthly:
      return l10n.repeatMonthly;
    case TaskRepeatPattern.custom:
      return l10n.everyNDays(customDays);
  }
}

String _weeklyDaysLabel(AppLocalizations l10n, String localeName, DailyTask task) {
  if (task.weeklyDays.isEmpty) return l10n.repeatWeekly;
  final sorted = task.weeklyDays.toSet().toList()..sort();
  return sorted.map((d) => localizedWeekdayShort(d, localeName)).join(', ');
}

/// Localized version of DailyTask.repeatDisplayLabel
String localizedRepeatLabel(
    AppLocalizations l10n, String localeName, DailyTask task) {
  if (task.repeatPattern == TaskRepeatPattern.weekly_days) {
    return _weeklyDaysLabel(l10n, localeName, task);
  }
  if (task.repeatPattern == TaskRepeatPattern.biweekly) {
    final days = task.weeklyDays.isEmpty
        ? localizedWeekdayShort(1, localeName)
        : _weeklyDaysLabel(l10n, localeName, task);
    return '${l10n.repeatBiweekly} · $days';
  }
  if (task.repeatPattern == TaskRepeatPattern.custom) {
    return l10n.everyNDays(task.customDays);
  }
  return localizedPatternLabel(l10n, task.repeatPattern, task.customDays);
}

/// Display name for a task category. The stored value stays canonical
/// (English) so category matching and old data keep working; only the
/// visible label is translated. Custom categories are shown as typed.
String localizedCategory(AppLocalizations l10n, String category) {
  switch (category) {
    case 'Gym':
      return l10n.categoryGym;
    case 'Work':
      return l10n.categoryWork;
    case 'Study':
      return l10n.categoryStudy;
    case 'Leisure':
      return l10n.categoryLeisure;
    case 'Skill':
      return l10n.categorySkill;
    case 'Chores':
      return l10n.categoryChores;
    case 'Creatine':
      return l10n.categoryCreatine;
    default:
      return category;
  }
}

/// Localized version of DailyTask.limitedCycleLabel
String localizedCycleLabel(AppLocalizations l10n, DailyTask task) {
  final days = task.limitedCycleIntervalDays;
  if (days == null) return '';
  if (days == 7) return l10n.repeatWeekly;
  if (days == 14) return l10n.repeatBiweekly;
  if (days == 30) return l10n.repeatMonthly;
  return l10n.everyNDaysShort(days);
}
