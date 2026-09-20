import '../../../../core/utils/local_storage.dart';
import '../models/daily_task.dart';

/// Local (SharedPreferences-backed) data source for the tasks feature.
///
/// This is the single place that owns the storage keys and performs all
/// (de)serialization. To move the feature onto a database or server later, add
/// a matching remote data source with the same method signatures and swap it
/// inside the repository implementation — nothing above this layer changes.
class TasksLocalDataSource {
  // --- Storage keys ---
  static const _kDailyTasksKey = 'daily_tasks_v1';
  static const _kDailyRolloverKey = 'daily_last_rollover_v1';
  static const _kCongratsShownKey = 'daily_congrats_shown_v1';
  static const _kDailyOrderKey = 'daily_tasks_order_v1';
  static const _kOrderByDateKey = 'daily_tasks_order_by_date_v1';
  static const _kOrderCombinedKey = 'daily_order_combined_v1';
  static const _kSortModeKey = 'daily_sort_mode_v1';
  static const _kFreezeTokensKey = 'daily_freeze_tokens_v1';
  static const _kFreezeDaysCounterKey = 'daily_freeze_days_counter_v1';
  static const _kFreezeUsageKey = 'daily_freeze_usage_v1';
  static const _kOneOffByDateKey = 'daily_oneoff_by_date_v1';
  static const _kTasksHistoryKey = 'daily_tasks_history_v1';
  static const _kTaskIconsKey = 'daily_task_icons_v1';
  static const _kTaskCustomIconsKey = 'daily_task_custom_icons_v1';

  // Shared with other features (owned elsewhere for now).
  static const _kCreatineKey = 'gym_creatine_intake_v1';
  static const _kProgressHistoryKey = 'progress_history_v1';

  // --- Keep tasks ---
  Future<List<DailyTask>> loadKeepTasks() async {
    final raw = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
    if (raw is! List) return <DailyTask>[];
    return raw
        .map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> saveKeepTasks(List<DailyTask> tasks) => LocalStorage.saveJson(
        _kDailyTasksKey,
        tasks.map((t) => t.toMap()).toList(),
      );

  // --- One-off tasks per date (keep == false) ---
  Future<Map<String, List<DailyTask>>> loadOneOffByDate() async {
    final raw = await LocalStorage.loadJson(_kOneOffByDateKey, fallback: {});
    final result = <String, List<DailyTask>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List) {
          result[k.toString()] = v
              .map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e)))
              .where((t) => !t.keep)
              .toList();
        }
      });
    }
    return result;
  }

  Future<void> saveOneOffByDate(Map<String, List<DailyTask>> byDate) {
    final map = <String, List<Map<String, dynamic>>>{};
    byDate.forEach((k, v) {
      map[k] = v.map((t) => t.toMap()).toList();
    });
    return LocalStorage.saveJson(_kOneOffByDateKey, map);
  }

  // --- Task history snapshots per date ---
  Future<Map<String, List<DailyTask>>> loadTasksHistory() async {
    final raw = await LocalStorage.loadJson(_kTasksHistoryKey, fallback: {});
    final result = <String, List<DailyTask>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List) {
          result[k.toString()] = v
              .map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e)))
              .toList();
        }
      });
    }
    return result;
  }

  Future<void> saveTasksHistory(Map<String, List<DailyTask>> history) {
    final map = <String, List<Map<String, dynamic>>>{};
    history.forEach((k, v) {
      map[k] = v.map((t) => t.toMap()).toList();
    });
    return LocalStorage.saveJson(_kTasksHistoryKey, map);
  }

  // --- Ordering ---
  Future<List<String>> loadOrderKeep() async {
    final raw = await LocalStorage.loadJson(_kDailyOrderKey, fallback: []);
    return (raw is List) ? raw.map((e) => e.toString()).toList() : <String>[];
  }

  Future<void> saveOrderKeep(List<String> order) =>
      LocalStorage.saveJson(_kDailyOrderKey, order);

  Future<Map<String, List<String>>> loadOrderByDate() async =>
      _decodeStringListMap(
        await LocalStorage.loadJson(_kOrderByDateKey, fallback: {}),
      );

  Future<void> saveOrderByDate(Map<String, List<String>> order) =>
      LocalStorage.saveJson(_kOrderByDateKey, order);

  Future<Map<String, List<String>>> loadOrderCombined() async =>
      _decodeStringListMap(
        await LocalStorage.loadJson(_kOrderCombinedKey, fallback: {}),
      );

  Future<void> saveOrderCombined(Map<String, List<String>> order) =>
      LocalStorage.saveJson(_kOrderCombinedKey, order);

  Future<String?> loadSortMode() async =>
      (await LocalStorage.loadJson(_kSortModeKey, fallback: null)) as String?;

  Future<void> saveSortMode(String mode) =>
      LocalStorage.saveJson(_kSortModeKey, mode);

  // --- Freeze ---
  Future<int?> loadFreezeTokens() async =>
      (await LocalStorage.loadJson(_kFreezeTokensKey, fallback: null)) as int?;

  Future<int?> loadFreezeDaysCounter() async =>
      (await LocalStorage.loadJson(_kFreezeDaysCounterKey, fallback: 0)) as int?;

  Future<Map<String, List<String>>> loadFreezeUsage() async =>
      _decodeStringListMap(
        await LocalStorage.loadJson(_kFreezeUsageKey, fallback: {}),
      );

  Future<void> saveFreezeState({
    required int tokens,
    required int daysCounter,
    required Map<String, List<String>> usage,
  }) async {
    await LocalStorage.saveJson(_kFreezeTokensKey, tokens);
    await LocalStorage.saveJson(_kFreezeDaysCounterKey, daysCounter);
    await LocalStorage.saveJson(_kFreezeUsageKey, usage);
  }

  // --- Task icons ---
  Future<Map<String, int>> loadTaskIcons() async {
    final raw = await LocalStorage.loadJson(_kTaskIconsKey, fallback: {});
    final result = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        result[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }
    return result;
  }

  Future<void> saveTaskIcons(Map<String, int> icons) =>
      LocalStorage.saveJson(_kTaskIconsKey, icons);

  Future<Map<String, String>> loadTaskCustomIcons() async {
    final raw = await LocalStorage.loadJson(_kTaskCustomIconsKey, fallback: {});
    final result = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        result[k.toString()] = v.toString();
      });
    }
    return result;
  }

  Future<void> saveTaskCustomIcons(Map<String, String> icons) =>
      LocalStorage.saveJson(_kTaskCustomIconsKey, icons);

  // --- Rollover / congrats markers ---
  Future<String> loadLastRollover() async =>
      (await LocalStorage.loadJson(_kDailyRolloverKey, fallback: '')).toString();

  Future<void> saveLastRollover(String dateKey) =>
      LocalStorage.saveJson(_kDailyRolloverKey, dateKey);

  Future<String> loadCongratsShown() async =>
      (await LocalStorage.loadJson(_kCongratsShownKey, fallback: '')).toString();

  Future<void> saveCongratsShown(String dateKey) =>
      LocalStorage.saveJson(_kCongratsShownKey, dateKey);

  // --- Shared: creatine intake (owned by gym today) ---
  Future<Set<String>> loadCreatineDates() async {
    final raw = await LocalStorage.loadJson(_kCreatineKey, fallback: []);
    return (raw is List) ? raw.map((e) => e.toString()).toSet() : <String>{};
  }

  Future<void> saveCreatineDates(Set<String> dates) =>
      LocalStorage.saveJson(_kCreatineKey, dates.toList());

  // --- Shared: progress history (owned by progress feature) ---
  Future<Map<String, dynamic>> loadProgressHistory() async {
    final raw = await LocalStorage.loadJson(_kProgressHistoryKey, fallback: {});
    return Map<String, dynamic>.from(raw as Map);
  }

  Future<void> saveProgressHistory(Map<String, dynamic> history) =>
      LocalStorage.saveJson(_kProgressHistoryKey, history);

  Map<String, List<String>> _decodeStringListMap(dynamic raw) {
    final result = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List) {
          result[k.toString()] = v.map((e) => e.toString()).toList();
        }
      });
    }
    return result;
  }
}
