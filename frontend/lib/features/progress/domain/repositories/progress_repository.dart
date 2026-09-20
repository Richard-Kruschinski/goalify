/// Contract for persisting and retrieving the progress feature's data.
///
/// The presentation layer depends only on this abstraction. Local storage backs
/// it today; a database/server backend can be added later without changing the
/// UI.
abstract class ProgressRepository {
  Future<String> loadRange();
  Future<void> saveRange(String name);
  Future<String> loadDisplayMode();
  Future<void> saveDisplayMode(String name);

  Future<Map<DateTime, int>> loadHistory();
  Future<void> saveHistory(Map<DateTime, int> history);
  Future<Map<DateTime, int>> loadRatioHistory();
  Future<void> saveRatioHistory(Map<DateTime, int> history);

  // Cross-feature raw access used to derive today's fallback from daily tasks.
  // Will move to the tasks repository once that feature is refactored.
  Future<dynamic> loadDailyTasksRaw();
}
