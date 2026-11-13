import '../../data/models/run.dart';

abstract class RunsRepository {
  Future<List<Run>> loadRuns();
  Future<void> saveRuns(List<Run> runs);
}
