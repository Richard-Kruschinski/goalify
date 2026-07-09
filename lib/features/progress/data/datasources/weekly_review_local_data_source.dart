import '../../../../core/utils/local_storage.dart';

/// Local (SharedPreferences-backed) data source for the weekly review.
///
/// Reads raw data recorded by other features (tasks, gym, pomodoro). The keys
/// are owned by those features; this data source only ever reads them, never
/// writes. Once cross-feature repositories exist, these reads can move there.
class WeeklyReviewLocalDataSource {
  // Cross-feature keys (owned by the tasks / gym / pomodoro features).
  static const _kTasksHistoryKey = 'daily_tasks_history_v1';
  static const _kDailyTasksKey = 'daily_tasks_v1';
  static const _kOneOffByDateKey = 'daily_oneoff_by_date_v1';
  static const _kGymCalendarKey = 'gym_calendar_v1';
  static const _kPomodoroFocusHistoryKey = 'pomodoro_focus_history_v1';
  static const _kBlockerHistoryKey = 'distraction_blocker_history_v1';

  /// `Map<dateKey, List<task map>>` - task snapshots per past date.
  Future<Map<String, List<Map<String, dynamic>>>> loadTasksHistory() async {
    final raw = await LocalStorage.loadJson(_kTasksHistoryKey, fallback: {});
    final result = <String, List<Map<String, dynamic>>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List) {
          result[k.toString()] = v
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      });
    }
    return result;
  }

  /// Today's keep tasks (live state, not yet snapshotted to history).
  Future<List<Map<String, dynamic>>> loadKeepTasks() async {
    final raw = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// One-off tasks for a specific date (live state).
  Future<List<Map<String, dynamic>>> loadOneOffTasksFor(String dateKey) async {
    final raw = await LocalStorage.loadJson(_kOneOffByDateKey, fallback: {});
    if (raw is! Map) return const [];
    final list = raw[dateKey];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// `Map<dateKey, number of workouts logged on that date>`.
  Future<Map<String, int>> loadWorkoutCountsByDate() async {
    final raw = await LocalStorage.loadJson(_kGymCalendarKey, fallback: {});
    final result = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List && v.isNotEmpty) result[k.toString()] = v.length;
      });
    }
    return result;
  }

  /// `Map<dateKey, focus minutes>` recorded by the pomodoro feature.
  Future<Map<String, int>> loadFocusHistory() async {
    final raw =
        await LocalStorage.loadJson(_kPomodoroFocusHistoryKey, fallback: {});
    return _decodeIntMap(raw);
  }

  /// `Map<dateKey, blocked seconds>` recorded by the distraction blocker.
  Future<Map<String, int>> loadBlockerHistory() async {
    final raw = await LocalStorage.loadJson(_kBlockerHistoryKey, fallback: {});
    return _decodeIntMap(raw);
  }

  Map<String, int> _decodeIntMap(dynamic raw) {
    final result = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) result[k.toString()] = v.toInt();
      });
    }
    return result;
  }
}
