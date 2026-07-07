import '../../data/models/gym_models.dart';

/// Contract for persisting and retrieving the gym feature's data.
///
/// The presentation layer depends only on this abstraction. Local storage
/// backs it today; a database/server backend can be added later by providing a
/// new implementation (or swapping the data source in [GymRepositoryImpl])
/// without changing the UI.
abstract class GymRepository {
  // View mode (raw stored name).
  Future<String> loadViewMode();
  Future<void> saveViewMode(String name);

  // Logs per exercise id.
  Future<Map<String, List<WorkoutLog>>> loadLogs();
  Future<void> saveLogs(Map<String, List<WorkoutLog>> logs);

  // Ordering / assignments / splits.
  Future<List<String>> loadOrderActive();
  Future<void> saveOrderActive(List<String> order);
  Future<Map<String, List<String>>> loadOrderByDay();
  Future<void> saveOrderByDay(Map<String, List<String>> order);
  Future<Map<String, List<String>>> loadAssignments();
  Future<void> saveAssignments(Map<String, List<String>> assignments);
  Future<List<String>> loadOrderDays();
  Future<void> saveOrderDays(List<String> order);
  Future<Map<String, List<String>>> loadSplits();
  Future<void> saveSplits(Map<String, List<String>> splits);
  Future<List<String>> loadSplitOrder();
  Future<void> saveSplitOrder(List<String> order);

  // Exercise notes.
  Future<Map<String, String>> loadExerciseNotes();
  Future<void> saveExerciseNotes(Map<String, String> notes);

  // Day colors / icons.
  Future<Map<String, int>> loadDayColors();
  Future<void> saveDayColors(Map<String, int> colors);
  Future<Map<String, int>> loadDayIcons();
  Future<void> saveDayIcons(Map<String, int> icons);
  Future<Map<String, String>> loadDayCustomIcons();
  Future<void> saveDayCustomIcons(Map<String, String> icons);

  // Calendar (Map<dateKey, Set<dayName>>).
  Future<Map<String, Set<String>>> loadCalendar();
  Future<void> saveCalendar(Map<String, Set<String>> calendar);

  // Creatine intake dates.
  Future<Set<String>> loadCreatineDates();
  Future<void> saveCreatineDates(Set<String> dates);

  // Best-set cache (raw map, parsed by BestSetCache).
  Future<Map<String, dynamic>> loadBestSetCacheMap();
  Future<void> saveBestSetCacheMap(Map<String, dynamic> cache);

  // Alternative exercise ids per day.
  Future<Map<String, Set<String>>> loadAlternativeIdsByDay();
  Future<void> saveAlternativeIdsByDay(Map<String, Set<String>> byDay);

  // Cross-feature raw access used by the creatine ↔ daily-tasks sync. Will move
  // to the tasks / progress repositories once those features are refactored.
  Future<dynamic> loadDailyTasksRaw();
  Future<void> saveDailyTasksRaw(Object value);
  Future<dynamic> loadDailyOneOffByDateRaw();
  Future<void> saveDailyOneOffByDateRaw(Object value);
  Future<Map<String, dynamic>> loadProgressHistory();
  Future<void> saveProgressHistory(Map<String, dynamic> history);
}
