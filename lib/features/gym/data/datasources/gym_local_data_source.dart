import '../../../../core/utils/local_storage.dart';
import '../models/gym_models.dart';

/// Local (SharedPreferences-backed) data source for the gym feature.
///
/// Owns every gym storage key and all (de)serialization; the only place that
/// talks to [LocalStorage]. To move onto a database/server later, add a remote
/// data source with the same method signatures and swap it inside the
/// repository implementation — nothing above the data layer changes.
class GymLocalDataSource {
  // --- Gym-owned storage keys ---
  static const _kGymLogsKey = 'gym_logs_v1';
  static const _kGymViewKey = 'gym_view_mode_v1';
  static const _kOrderActiveKey = 'gym_order_by_exercise_v1';
  static const _kOrderByDayKey = 'gym_order_by_day_v1';
  static const _kAssignmentsKey = 'gym_assignments_by_day_v1';
  static const _kOrderDaysKey = 'gym_order_days_v1';
  static const _kExerciseNotesKey = 'gym_exercise_notes_v1';
  static const _kSplitsKey = 'gym_splits_v1';
  static const _kSplitOrderKey = 'gym_split_order_v1';
  static const _kCalendarKey = 'gym_calendar_v1';
  static const _kDayColorsKey = 'gym_day_colors_v1';
  static const _kDayIconsKey = 'gym_day_icons_v1';
  static const _kDayCustomIconsKey = 'gym_day_custom_icons_v1';
  static const _kCreatineKey = 'gym_creatine_intake_v1';
  static const _kBestSetCacheKey = 'gym_best_set_cache_v1';
  static const _kAlternativeIdsByDayKey = 'gym_alternative_ids_by_day_v1';

  // Cross-feature keys (owned by the tasks / progress features). Accessed here
  // only by the creatine sync; will move to those repositories once refactored.
  static const _kDailyTasksKey = 'daily_tasks_v1';
  static const _kDailyOneOffByDateKey = 'daily_oneoff_by_date_v1';
  static const _kProgressHistoryKey = 'progress_history_v1';

  // --- View mode ---
  Future<String> loadViewMode() async =>
      (await LocalStorage.loadJson(_kGymViewKey, fallback: 'byExercise'))
          .toString();

  Future<void> saveViewMode(String name) =>
      LocalStorage.saveJson(_kGymViewKey, name);

  // --- Logs ---
  Future<Map<String, List<WorkoutLog>>> loadLogs() async {
    final raw = await LocalStorage.loadJson(_kGymLogsKey, fallback: {});
    final result = <String, List<WorkoutLog>>{};
    if (raw is Map) {
      raw.forEach((key, value) {
        final List list = value as List? ?? [];
        final parsed = list
            .map((e) => WorkoutLog.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        result[key as String] = parsed;
      });
    }
    return result;
  }

  Future<void> saveLogs(Map<String, List<WorkoutLog>> logs) {
    final encoded =
        logs.map((k, v) => MapEntry(k, v.map((e) => e.toMap()).toList()));
    return LocalStorage.saveJson(_kGymLogsKey, encoded);
  }

  // --- Ordering / assignments / splits ---
  Future<List<String>> loadOrderActive() async {
    final raw = await LocalStorage.loadJson(_kOrderActiveKey, fallback: []);
    return (raw is List) ? raw.map((e) => e.toString()).toList() : <String>[];
  }

  Future<void> saveOrderActive(List<String> order) =>
      LocalStorage.saveJson(_kOrderActiveKey, order);

  Future<Map<String, List<String>>> loadOrderByDay() async =>
      _decodeStringListMap(
        await LocalStorage.loadJson(_kOrderByDayKey, fallback: {}),
      );

  Future<void> saveOrderByDay(Map<String, List<String>> order) =>
      LocalStorage.saveJson(_kOrderByDayKey, order);

  Future<Map<String, List<String>>> loadAssignments() async =>
      _decodeStringListMap(
        await LocalStorage.loadJson(_kAssignmentsKey, fallback: {}),
      );

  Future<void> saveAssignments(Map<String, List<String>> assignments) =>
      LocalStorage.saveJson(_kAssignmentsKey, assignments);

  Future<List<String>> loadOrderDays() async {
    final raw = await LocalStorage.loadJson(_kOrderDaysKey, fallback: []);
    return (raw is List) ? raw.map((e) => e.toString()).toList() : <String>[];
  }

  Future<void> saveOrderDays(List<String> order) =>
      LocalStorage.saveJson(_kOrderDaysKey, order);

  Future<Map<String, List<String>>> loadSplits() async =>
      _decodeStringListMap(
        await LocalStorage.loadJson(_kSplitsKey, fallback: {}),
      );

  Future<void> saveSplits(Map<String, List<String>> splits) =>
      LocalStorage.saveJson(_kSplitsKey, splits);

  Future<List<String>> loadSplitOrder() async {
    final raw = await LocalStorage.loadJson(_kSplitOrderKey, fallback: []);
    return (raw is List)
        ? raw.map((e) => e.toString()).toList(growable: true)
        : <String>[];
  }

  Future<void> saveSplitOrder(List<String> order) =>
      LocalStorage.saveJson(_kSplitOrderKey, order);

  // --- Exercise notes ---
  Future<Map<String, String>> loadExerciseNotes() async {
    final raw = await LocalStorage.loadJson(_kExerciseNotesKey, fallback: {});
    final result = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final note = v.toString().trim();
        if (note.isNotEmpty) result[k.toString()] = note;
      });
    }
    return result;
  }

  Future<void> saveExerciseNotes(Map<String, String> notes) =>
      LocalStorage.saveJson(_kExerciseNotesKey, notes);

  // --- Day colors / icons ---
  Future<Map<String, int>> loadDayColors() async =>
      _decodeIntMap(await LocalStorage.loadJson(_kDayColorsKey, fallback: {}));

  Future<void> saveDayColors(Map<String, int> colors) =>
      LocalStorage.saveJson(_kDayColorsKey, colors);

  Future<Map<String, int>> loadDayIcons() async =>
      _decodeIntMap(await LocalStorage.loadJson(_kDayIconsKey, fallback: {}));

  Future<void> saveDayIcons(Map<String, int> icons) =>
      LocalStorage.saveJson(_kDayIconsKey, icons);

  Future<Map<String, String>> loadDayCustomIcons() async {
    final raw = await LocalStorage.loadJson(_kDayCustomIconsKey, fallback: {});
    final result = <String, String>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        result[k.toString()] = v.toString();
      });
    }
    return result;
  }

  Future<void> saveDayCustomIcons(Map<String, String> icons) =>
      LocalStorage.saveJson(_kDayCustomIconsKey, icons);

  // --- Calendar (Map<dateKey, Set<dayName>>) ---
  Future<Map<String, Set<String>>> loadCalendar() async {
    final raw = await LocalStorage.loadJson(_kCalendarKey, fallback: {});
    final result = <String, Set<String>>{};
    if (raw is Map) {
      raw.forEach((dateStr, list) {
        final l =
            (list as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
        result[dateStr.toString()] = l;
      });
    }
    return result;
  }

  Future<void> saveCalendar(Map<String, Set<String>> calendar) {
    final enc = calendar.map((k, v) => MapEntry(k, v.toList()));
    return LocalStorage.saveJson(_kCalendarKey, enc);
  }

  // --- Creatine intake ---
  Future<Set<String>> loadCreatineDates() async {
    final raw = await LocalStorage.loadJson(_kCreatineKey, fallback: []);
    return (raw is List) ? raw.map((e) => e.toString()).toSet() : <String>{};
  }

  Future<void> saveCreatineDates(Set<String> dates) =>
      LocalStorage.saveJson(_kCreatineKey, dates.toList());

  // --- Best-set cache (raw map; parsed by BestSetCache) ---
  Future<Map<String, dynamic>> loadBestSetCacheMap() async {
    final raw = await LocalStorage.loadJson(_kBestSetCacheKey, fallback: {});
    return (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  Future<void> saveBestSetCacheMap(Map<String, dynamic> cache) =>
      LocalStorage.saveJson(_kBestSetCacheKey, cache);

  // --- Alternative exercise ids per day (Map<dayName, Set<id>>) ---
  Future<Map<String, Set<String>>> loadAlternativeIdsByDay() async {
    final raw =
        await LocalStorage.loadJson(_kAlternativeIdsByDayKey, fallback: {});
    final result = <String, Set<String>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List) {
          result[k.toString()] = v.map((e) => e.toString()).toSet();
        }
      });
    }
    return result;
  }

  Future<void> saveAlternativeIdsByDay(Map<String, Set<String>> byDay) =>
      LocalStorage.saveJson(
        _kAlternativeIdsByDayKey,
        byDay.map((k, v) => MapEntry(k, v.toList())),
      );

  // --- Cross-feature raw access (creatine ↔ daily tasks / progress sync) ---
  Future<dynamic> loadDailyTasksRaw() =>
      LocalStorage.loadJson(_kDailyTasksKey, fallback: []);

  Future<void> saveDailyTasksRaw(Object value) =>
      LocalStorage.saveJson(_kDailyTasksKey, value);

  Future<dynamic> loadDailyOneOffByDateRaw() =>
      LocalStorage.loadJson(_kDailyOneOffByDateKey, fallback: {});

  Future<void> saveDailyOneOffByDateRaw(Object value) =>
      LocalStorage.saveJson(_kDailyOneOffByDateKey, value);

  Future<Map<String, dynamic>> loadProgressHistory() async {
    final raw = await LocalStorage.loadJson(_kProgressHistoryKey, fallback: {});
    return (raw is Map) ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  Future<void> saveProgressHistory(Map<String, dynamic> history) =>
      LocalStorage.saveJson(_kProgressHistoryKey, history);

  // --- Helpers ---
  Map<String, List<String>> _decodeStringListMap(dynamic raw) {
    final result = <String, List<String>>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is List) {
          result[k.toString()] =
              v.map((e) => e.toString()).toList(growable: true);
        }
      });
    }
    return result;
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
