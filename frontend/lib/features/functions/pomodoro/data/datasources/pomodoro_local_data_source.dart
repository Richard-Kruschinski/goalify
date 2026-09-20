import '../../../../../core/utils/local_storage.dart';
import '../models/pomodoro_profile.dart';
import '../models/pomodoro_stats.dart';

/// Local (SharedPreferences-backed) data source for the pomodoro feature.
///
/// Owns the pomodoro storage keys and all (de)serialization; the only place
/// that talks to [LocalStorage]. To move onto a database/server later, add a
/// remote data source with the same signatures and swap it in the repository
/// implementation.
class PomodoroLocalDataSource {
  static const _kProfileKey = 'pomodoro_profile';
  static const _kCustomProfilesKey = 'pomodoro_custom_profiles';
  static const _kStatsKey = 'pomodoro_stats';
  static const _kFocusHistoryKey = 'pomodoro_focus_history_v1';

  Future<PomodoroProfile?> loadProfile() async {
    final data = await LocalStorage.loadJson(_kProfileKey, fallback: null);
    return data != null ? PomodoroProfile.fromJson(data) : null;
  }

  Future<void> saveProfile(PomodoroProfile profile) =>
      LocalStorage.saveJson(_kProfileKey, profile.toJson());

  Future<List<PomodoroProfile>?> loadCustomProfiles() async {
    final data =
        await LocalStorage.loadJson(_kCustomProfilesKey, fallback: null);
    if (data != null && data is List) {
      return data.map((item) => PomodoroProfile.fromJson(item)).toList();
    }
    return null;
  }

  Future<void> saveCustomProfiles(List<PomodoroProfile> profiles) =>
      LocalStorage.saveJson(
        _kCustomProfilesKey,
        profiles.map((p) => p.toJson()).toList(),
      );

  Future<PomodoroStats?> loadStats() async {
    final data = await LocalStorage.loadJson(_kStatsKey, fallback: null);
    return data != null ? PomodoroStats.fromJson(data) : null;
  }

  Future<void> saveStats(PomodoroStats stats) =>
      LocalStorage.saveJson(_kStatsKey, stats.toJson());

  // --- Focus history (Map<dateKey yyyy-mm-dd, focus minutes>) ---
  Future<Map<String, int>> loadFocusHistory() async {
    final raw = await LocalStorage.loadJson(_kFocusHistoryKey, fallback: {});
    final result = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) result[k.toString()] = v.toInt();
      });
    }
    return result;
  }

  Future<void> saveFocusHistory(Map<String, int> history) =>
      LocalStorage.saveJson(_kFocusHistoryKey, history);
}
