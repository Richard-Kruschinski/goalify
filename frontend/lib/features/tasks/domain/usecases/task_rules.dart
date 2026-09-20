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
