import '../../../../core/utils/local_storage.dart';

/// Local (SharedPreferences-backed) data source for the progress feature.
///
/// Owns the progress storage keys and all (de)serialization; the only place
/// that talks to [LocalStorage]. To move onto a database/server later, add a
/// remote data source with the same signatures and swap it in the repository
/// implementation — the UI stays unchanged.
class ProgressLocalDataSource {
  static const _kHistoryKey = 'progress_history_v1';
  static const _kRatioHistoryKey = 'progress_ratio_history_v1';
  static const _kRangeKey = 'progress_range_v1';
  static const _kDisplayModeKey = 'progress_display_mode_v1';

  // Cross-feature key (owned by the tasks feature). Read here to derive today's
  // fallback points/ratio; will move to the tasks repository once refactored.
  static const _kDailyTasksKey = 'daily_tasks_v1';

  // --- Selected range / display mode (raw stored name) ---
  Future<String> loadRange() async =>
      (await LocalStorage.loadJson(_kRangeKey, fallback: 'week')).toString();

  Future<void> saveRange(String name) =>
      LocalStorage.saveJson(_kRangeKey, name);

  Future<String> loadDisplayMode() async =>
      (await LocalStorage.loadJson(_kDisplayModeKey, fallback: 'ratio'))
          .toString();

  Future<void> saveDisplayMode(String name) =>
      LocalStorage.saveJson(_kDisplayModeKey, name);

  // --- Points history (date -> points) ---
  Future<Map<DateTime, int>> loadHistory() async =>
      _decodeDateIntMap(await LocalStorage.loadJson(_kHistoryKey, fallback: {}));

  Future<void> saveHistory(Map<DateTime, int> history) =>
      LocalStorage.saveJson(_kHistoryKey, _encodeDateIntMap(history));

  // --- Ratio history (date -> percentage) ---
  Future<Map<DateTime, int>> loadRatioHistory() async => _decodeDateIntMap(
        await LocalStorage.loadJson(_kRatioHistoryKey, fallback: {}),
      );

  Future<void> saveRatioHistory(Map<DateTime, int> history) =>
      LocalStorage.saveJson(_kRatioHistoryKey, _encodeDateIntMap(history));

  // --- Cross-feature raw access (today's fallback from daily tasks) ---
  Future<dynamic> loadDailyTasksRaw() =>
      LocalStorage.loadJson(_kDailyTasksKey, fallback: []);

  // --- Helpers ---
  Map<DateTime, int> _decodeDateIntMap(dynamic raw) {
    final map = <DateTime, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String) {
          final parts = k.split('-');
          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              map[DateTime(y, m, d)] = (v as num).toInt();
            }
          }
        }
      });
    }
    return map;
  }

  Map<String, int> _encodeDateIntMap(Map<DateTime, int> map) => {
        for (final entry in map.entries)
          '${entry.key.year.toString().padLeft(4, '0')}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}':
              entry.value,
      };
}
