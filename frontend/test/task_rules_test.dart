import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/tasks/data/models/daily_task.dart';
import 'package:Goalify/features/tasks/domain/usecases/task_rules.dart';

DailyTask _task({
  String id = 't',
  bool keep = true,
  TaskRepeatPattern pattern = TaskRepeatPattern.daily,
  int? targetCount,
  int completedCount = 0,
  int? cycleDays,
  String? cycleStart,
  int streak = 0,
  int bestStreak = 0,
}) {
  return DailyTask(
    id: id,
    title: id,
    keep: keep,
    repeatPattern: pattern,
    targetCount: targetCount,
    completedCount: completedCount,
    limitedCycleIntervalDays: cycleDays,
    limitedCycleStartKey: cycleStart,
    streak: streak,
    bestStreak: bestStreak,
  );
}

void main() {
  group('taskTypeRank', () {
    test('groups in the order recurring, X-repeating, X-once, one-off', () {
      final daily = _task(id: 'daily');
      final weekly = _task(id: 'weekly', pattern: TaskRepeatPattern.weekly_days);
      final xWeekly =
          _task(id: 'xWeekly', targetCount: 4, cycleDays: 7, cycleStart: '2026-08-24');
      final xOnce = _task(id: 'xOnce', targetCount: 2);
      final oneOff = _task(id: 'oneOff', keep: false);

      final shuffled = [oneOff, xOnce, weekly, xWeekly, daily]
        ..sort((a, b) => taskTypeRank(a).compareTo(taskTypeRank(b)));

      expect(
        shuffled.map((t) => t.id).toList(),
        ['daily', 'weekly', 'xWeekly', 'xOnce', 'oneOff'],
      );
    });

    test('a repeating X-task never shares a rank with a one-shot X-task', () {
      final repeating =
          _task(targetCount: 3, cycleDays: 14, cycleStart: '2026-08-24');
      final once = _task(targetCount: 3);

      expect(taskTypeRank(repeating), isNot(taskTypeRank(once)));
      expect(taskTypeRank(repeating), lessThan(taskTypeRank(once)));
    });
  });

  group('applyFinishedLimitedCycle', () {
    test('reaching the target extends the streak and re-anchors the cycle', () {
      final t = _task(
        targetCount: 4,
        completedCount: 4,
        cycleDays: 7,
        cycleStart: '2026-08-17',
        streak: 2,
        bestStreak: 2,
      );

      applyFinishedLimitedCycle(t, cycleEndKey: '2026-08-24', frozen: false);

      expect(t.streak, 3);
      expect(t.bestStreak, 3);
      expect(t.completedCount, 0);
      expect(t.limitedCycleStartKey, '2026-08-24');
      expect(t.lastDoneKey, '2026-08-24');
    });

    test('overshooting the target still counts as one cycle', () {
      final t = _task(
        targetCount: 3,
        completedCount: 6,
        cycleDays: 7,
        cycleStart: '2026-08-17',
        streak: 1,
      );

      applyFinishedLimitedCycle(t, cycleEndKey: '2026-08-24', frozen: false);

      expect(t.streak, 2);
    });

    test('missing the target breaks the streak', () {
      final t = _task(
        targetCount: 4,
        completedCount: 3,
        cycleDays: 7,
        cycleStart: '2026-08-17',
        streak: 5,
        bestStreak: 5,
      );

      applyFinishedLimitedCycle(t, cycleEndKey: '2026-08-24', frozen: false);

      expect(t.streak, 0);
      expect(t.bestStreak, 5, reason: 'the all-time best must survive');
      expect(t.completedCount, 0);
    });

    test('a frozen cycle end protects the streak', () {
      final t = _task(
        targetCount: 4,
        completedCount: 1,
        cycleDays: 7,
        cycleStart: '2026-08-17',
        streak: 5,
      );

      applyFinishedLimitedCycle(t, cycleEndKey: '2026-08-24', frozen: true);

      expect(t.streak, 5);
      expect(t.completedCount, 0);
    });

    test('a one-shot X-task is left untouched', () {
      final t = _task(targetCount: 2, completedCount: 2, streak: 0);

      applyFinishedLimitedCycle(t, cycleEndKey: '2026-08-24', frozen: false);

      expect(t.streak, 0);
      expect(t.completedCount, 2);
      expect(t.limitedCycleStartKey, isNull);
    });

    test('consecutive cycles accumulate', () {
      final t = _task(
        targetCount: 2,
        cycleDays: 7,
        cycleStart: '2026-08-03',
      );

      for (final end in ['2026-08-10', '2026-08-17', '2026-08-24']) {
        t.completedCount = 2;
        applyFinishedLimitedCycle(t, cycleEndKey: end, frozen: false);
      }

      expect(t.streak, 3);
      expect(t.bestStreak, 3);
    });
  });
}
