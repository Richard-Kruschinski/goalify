import '../../data/models/pomodoro_profile.dart';
import '../../data/models/pomodoro_stats.dart';

/// Contract for persisting and retrieving the pomodoro feature's data.
///
/// The controller depends only on this abstraction; local storage backs it
/// today and a database/server backend can be added later without changes here.
abstract class PomodoroRepository {
  Future<PomodoroProfile?> loadProfile();
  Future<void> saveProfile(PomodoroProfile profile);
  Future<List<PomodoroProfile>?> loadCustomProfiles();
  Future<void> saveCustomProfiles(List<PomodoroProfile> profiles);
  Future<PomodoroStats?> loadStats();
  Future<void> saveStats(PomodoroStats stats);

  /// Focus minutes per day (dateKey yyyy-mm-dd -> minutes). Feeds the
  /// weekly review on the progress screen.
  Future<Map<String, int>> loadFocusHistory();
  Future<void> saveFocusHistory(Map<String, int> history);
}
