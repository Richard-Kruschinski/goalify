import '../../../../core/utils/local_storage.dart';
import '../models/run.dart';

/// Single place that owns the storage key of the runs feature.
class RunsLocalDataSource {
  static const _kRunsKey = 'runs_v1';

  Future<List<Run>> loadRuns() async {
    final raw = await LocalStorage.loadJson(_kRunsKey, fallback: []);
    if (raw is! List) return <Run>[];
    return raw.map((e) => Run.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> saveRuns(List<Run> runs) =>
      LocalStorage.saveJson(_kRunsKey, runs.map((r) => r.toMap()).toList());
}
