import '../../domain/repositories/progress_repository.dart';
import '../datasources/progress_local_data_source.dart';

/// Default [ProgressRepository] implementation, backed by
/// [ProgressLocalDataSource]. Swap point for a remote data source later.
class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl([ProgressLocalDataSource? local])
      : _local = local ?? ProgressLocalDataSource();

  final ProgressLocalDataSource _local;

  @override
  Future<String> loadRange() => _local.loadRange();

  @override
  Future<void> saveRange(String name) => _local.saveRange(name);

  @override
  Future<String> loadDisplayMode() => _local.loadDisplayMode();

  @override
  Future<void> saveDisplayMode(String name) => _local.saveDisplayMode(name);

  @override
  Future<Map<DateTime, int>> loadHistory() => _local.loadHistory();

  @override
  Future<void> saveHistory(Map<DateTime, int> history) =>
      _local.saveHistory(history);

  @override
  Future<Map<DateTime, int>> loadRatioHistory() => _local.loadRatioHistory();

  @override
  Future<void> saveRatioHistory(Map<DateTime, int> history) =>
      _local.saveRatioHistory(history);

  @override
  Future<dynamic> loadDailyTasksRaw() => _local.loadDailyTasksRaw();
}
