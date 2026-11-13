import '../../domain/repositories/runs_repository.dart';
import '../datasources/runs_local_data_source.dart';
import '../models/run.dart';

class RunsRepositoryImpl implements RunsRepository {
  RunsRepositoryImpl([RunsLocalDataSource? dataSource])
    : _dataSource = dataSource ?? RunsLocalDataSource();

  final RunsLocalDataSource _dataSource;

  @override
  Future<List<Run>> loadRuns() => _dataSource.loadRuns();

  @override
  Future<void> saveRuns(List<Run> runs) => _dataSource.saveRuns(runs);
}
