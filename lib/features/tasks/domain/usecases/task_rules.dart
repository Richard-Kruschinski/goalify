import '../../data/models/daily_task.dart';

/// Grouping rank for [TaskSortMode.type] on the daily tasks screen.
///
/// Order: recurring tasks first (daily ahead of the other patterns), then the
/// X-times tasks with the repeating ones ahead of the one-shot ones, and the
/// one-off tasks of the day last.
int taskTypeRank(DailyTask t) {
  if (!t.keep) return 4; // one-off
  if (t.isLimitedRecurring) return 2; // X-mal, repeats every cycle
  if (t.isLimited) return 3; // X-mal, once
  if (t.repeatPattern == TaskRepeatPattern.daily) return 0; // daily
  return 1; // recurring (weekly, biweekly, custom, ...)
}

/// Parses a `yyyy-mm-dd` day key; null when it is malformed.
DateTime? parseTaskDateKey(String dateKey) {
  final parts = dateKey.split('-').map(int.tryParse).toList();
  if (parts.length != 3 || parts.contains(null)) return null;
  return DateTime(parts[0]!, parts[1]!, parts[2]!);
}

/// Whether a repeating X-task begins a new cycle on [dayKey] (a full interval
/// after its cycle anchor).
bool startsNewLimitedCycle(DailyTask task, String dayKey) {
  if (!task.isLimitedRecurring) return false;
  final cycleStart = parseTaskDateKey(task.limitedCycleStartKey ?? '');
  final day = parseTaskDateKey(dayKey);
  if (cycleStart == null || day == null) return false;
  final daysSince = day.difference(cycleStart).inDays;
  return daysSince > 0 && daysSince % task.limitedCycleIntervalDays! == 0;
}

/// Whether the task's checklist starts over when the day before [nextDayKey]
/// ends. Call it before the task's `done` is cleared for the new day.
///
/// Plain recurring tasks start every day fresh. An X-time task keeps its
/// progress across days until it is checked off, or until its next cycle
/// begins.
bool clearsChecklistAtDayEnd(DailyTask task, {required String nextDayKey}) =>
    !task.isLimited || task.done || startsNewLimitedCycle(task, nextDayKey);

/// Settles the streak of a repeating X-task whose cycle just ended.
///
/// Unlike a plain recurring task - whose streak counts days - an X-times task
/// is only judged once per cycle: reaching [DailyTask.targetCount] within the
/// cycle extends the streak, falling short breaks it unless the day was frozen.
///
/// Call this while [DailyTask.completedCount] still holds the finished cycle's
/// count; it resets the counter and re-anchors the cycle to [cycleEndKey].
void applyFinishedLimitedCycle(
  DailyTask task, {
  required String cycleEndKey,
  required bool frozen,
}) {
  if (!task.isLimitedRecurring) return;

  if (task.completedCount >= task.targetCount!) {
    task.streak += 1;
    task.lastDoneKey = cycleEndKey;
    if (task.streak > task.bestStreak) task.bestStreak = task.streak;
  } else if (!frozen) {
    task.streak = 0;
  }

  task.completedCount = 0;
  task.limitedCycleStartKey = cycleEndKey;
}
