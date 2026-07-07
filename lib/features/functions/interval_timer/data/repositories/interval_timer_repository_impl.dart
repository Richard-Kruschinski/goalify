import '../../domain/repositories/interval_timer_repository.dart';
import '../../data/models/interval_timer_state.dart';
import '../datasources/interval_timer_local_data_source.dart';

/// Default [IntervalTimerRepository] implementation, backed by
/// [IntervalTimerLocalDataSource]. Swap point for a remote data source later.
class IntervalTimerRepositoryImpl implements IntervalTimerRepository {
  IntervalTimerRepositoryImpl([IntervalTimerLocalDataSource? local])
      : _local = local ?? IntervalTimerLocalDataSource();

  final IntervalTimerLocalDataSource _local;

  @override
  Future<List<IntervalTimerProfile>> loadProfiles() => _local.loadProfiles();

  @override
  Future<void> saveProfiles(List<IntervalTimerProfile> profiles) =>
      _local.saveProfiles(profiles);

  @override
  Future<String?> loadSelectedProfileId() => _local.loadSelectedProfileId();

  @override
  Future<void> saveSelectedProfileId(String? id) =>
      _local.saveSelectedProfileId(id);
}
