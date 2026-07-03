import '../../data/models/daily_task.dart';

/// Contract for persisting and retrieving the tasks feature's data.
///
/// The presentation layer depends only on this abstraction, never on a
/// concrete storage mechanism. Today it is backed by local storage
/// (SharedPreferences); to move onto a database or server later, provide a new
/// implementation (or swap the data source inside [TasksRepositoryImpl]) — the
/// UI does not change.
abstract class TasksRepository {
  // Keep tasks (persist across days).
  Future<List<DailyTask>> loadKeepTasks();
  Future<void> saveKeepTasks(List<DailyTask> tasks);

  // One-off tasks bucketed per date (keep == false).
  Future<Map<String, List<DailyTask>>> loadOneOffByDate();
  Future<void> saveOneOffByDate(Map<String, List<DailyTask>> byDate);

  // Immutable task snapshots per date (history).
  Future<Map<String, List<DailyTask>>> loadTasksHistory();
  Future<void> saveTasksHistory(Map<String, List<DailyTask>> history);

  // Ordering.
  Future<List<String>> loadOrderKeep();
  Future<void> saveOrderKeep(List<String> order);
  Future<Map<String, List<String>>> loadOrderByDate();
  Future<void> saveOrderByDate(Map<String, List<String>> order);
  Future<Map<String, List<String>>> loadOrderCombined();
  Future<void> saveOrderCombined(Map<String, List<String>> order);

  // Freeze tokens / usage.
  Future<int?> loadFreezeTokens();
  Future<int?> loadFreezeDaysCounter();
  Future<Map<String, List<String>>> loadFreezeUsage();
  Future<void> saveFreezeState({
    required int tokens,
    required int daysCounter,
    required Map<String, List<String>> usage,
  });

  // Task icons (standard code points and custom file paths).
  Future<Map<String, int>> loadTaskIcons();
  Future<void> saveTaskIcons(Map<String, int> icons);
  Future<Map<String, String>> loadTaskCustomIcons();
  Future<void> saveTaskCustomIcons(Map<String, String> icons);

  // Daily rollover / congrats markers.
  Future<String> loadLastRollover();
  Future<void> saveLastRollover(String dateKey);
  Future<String> loadCongratsShown();
  Future<void> saveCongratsShown(String dateKey);

  // Cross-feature data the tasks screen also reads/writes. These will migrate
  // to the gym / progress repositories once those features are refactored.
  Future<Set<String>> loadCreatineDates();
  Future<void> saveCreatineDates(Set<String> dates);
  Future<Map<String, dynamic>> loadProgressHistory();
  Future<void> saveProgressHistory(Map<String, dynamic> history);
}
