import '../../domain/repositories/tasks_repository.dart';
import '../../data/models/daily_task.dart';
import '../datasources/tasks_local_data_source.dart';

/// Default [TasksRepository] implementation.
///
/// Currently backed entirely by [TasksLocalDataSource]. When a remote
/// (database/server) data source is introduced, this is the only place that
/// needs to change — e.g. read from remote with a local cache fallback — while
/// the presentation layer keeps calling the same [TasksRepository] methods.
class TasksRepositoryImpl implements TasksRepository {
  TasksRepositoryImpl([TasksLocalDataSource? local])
      : _local = local ?? TasksLocalDataSource();

  final TasksLocalDataSource _local;

  @override
  Future<List<DailyTask>> loadKeepTasks() => _local.loadKeepTasks();

  @override
  Future<void> saveKeepTasks(List<DailyTask> tasks) =>
      _local.saveKeepTasks(tasks);

  @override
  Future<Map<String, List<DailyTask>>> loadOneOffByDate() =>
      _local.loadOneOffByDate();

  @override
  Future<void> saveOneOffByDate(Map<String, List<DailyTask>> byDate) =>
      _local.saveOneOffByDate(byDate);

  @override
  Future<Map<String, List<DailyTask>>> loadTasksHistory() =>
      _local.loadTasksHistory();

  @override
  Future<void> saveTasksHistory(Map<String, List<DailyTask>> history) =>
      _local.saveTasksHistory(history);

  @override
  Future<List<String>> loadOrderKeep() => _local.loadOrderKeep();

  @override
  Future<void> saveOrderKeep(List<String> order) => _local.saveOrderKeep(order);

  @override
  Future<Map<String, List<String>>> loadOrderByDate() =>
      _local.loadOrderByDate();

  @override
  Future<void> saveOrderByDate(Map<String, List<String>> order) =>
      _local.saveOrderByDate(order);

  @override
  Future<Map<String, List<String>>> loadOrderCombined() =>
      _local.loadOrderCombined();

  @override
  Future<void> saveOrderCombined(Map<String, List<String>> order) =>
      _local.saveOrderCombined(order);

  @override
  Future<int?> loadFreezeTokens() => _local.loadFreezeTokens();

  @override
  Future<int?> loadFreezeDaysCounter() => _local.loadFreezeDaysCounter();

  @override
  Future<Map<String, List<String>>> loadFreezeUsage() =>
      _local.loadFreezeUsage();

  @override
  Future<void> saveFreezeState({
    required int tokens,
    required int daysCounter,
    required Map<String, List<String>> usage,
  }) =>
      _local.saveFreezeState(
        tokens: tokens,
        daysCounter: daysCounter,
        usage: usage,
      );

  @override
  Future<Map<String, int>> loadTaskIcons() => _local.loadTaskIcons();

  @override
  Future<void> saveTaskIcons(Map<String, int> icons) =>
      _local.saveTaskIcons(icons);

  @override
  Future<Map<String, String>> loadTaskCustomIcons() =>
      _local.loadTaskCustomIcons();

  @override
  Future<void> saveTaskCustomIcons(Map<String, String> icons) =>
      _local.saveTaskCustomIcons(icons);

  @override
  Future<String> loadLastRollover() => _local.loadLastRollover();

  @override
  Future<void> saveLastRollover(String dateKey) =>
      _local.saveLastRollover(dateKey);

  @override
  Future<String> loadCongratsShown() => _local.loadCongratsShown();

  @override
  Future<void> saveCongratsShown(String dateKey) =>
      _local.saveCongratsShown(dateKey);

  @override
  Future<Set<String>> loadCreatineDates() => _local.loadCreatineDates();

  @override
  Future<void> saveCreatineDates(Set<String> dates) =>
      _local.saveCreatineDates(dates);

  @override
  Future<Map<String, dynamic>> loadProgressHistory() =>
      _local.loadProgressHistory();

  @override
  Future<void> saveProgressHistory(Map<String, dynamic> history) =>
      _local.saveProgressHistory(history);
}
