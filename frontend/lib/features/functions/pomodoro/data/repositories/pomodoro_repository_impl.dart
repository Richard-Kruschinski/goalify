import '../../domain/repositories/pomodoro_repository.dart';
import '../../data/models/pomodoro_profile.dart';
import '../../data/models/pomodoro_stats.dart';
import '../datasources/pomodoro_local_data_source.dart';

/// Default [PomodoroRepository] implementation, backed by
/// [PomodoroLocalDataSource]. Swap point for a remote data source later.
class PomodoroRepositoryImpl implements PomodoroRepository {
  PomodoroRepositoryImpl([PomodoroLocalDataSource? local])
      : _local = local ?? PomodoroLocalDataSource();

  final PomodoroLocalDataSource _local;

  @override
  Future<PomodoroProfile?> loadProfile() => _local.loadProfile();

  @override
  Future<void> saveProfile(PomodoroProfile profile) =>
      _local.saveProfile(profile);

  @override
  Future<List<PomodoroProfile>?> loadCustomProfiles() =>
      _local.loadCustomProfiles();

  @override
  Future<void> saveCustomProfiles(List<PomodoroProfile> profiles) =>
      _local.saveCustomProfiles(profiles);

  @override
  Future<PomodoroStats?> loadStats() => _local.loadStats();

  @override
  Future<void> saveStats(PomodoroStats stats) => _local.saveStats(stats);

  @override
  Future<Map<String, int>> loadFocusHistory() => _local.loadFocusHistory();

  @override
  Future<void> saveFocusHistory(Map<String, int> history) =>
      _local.saveFocusHistory(history);
}
