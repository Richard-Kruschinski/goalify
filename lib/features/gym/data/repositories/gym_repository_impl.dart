import '../../domain/repositories/gym_repository.dart';
import '../../data/models/gym_models.dart';
import '../datasources/gym_local_data_source.dart';

/// Default [GymRepository] implementation, backed by [GymLocalDataSource].
///
/// When a remote (database/server) data source is introduced, this is the only
/// place that needs to change; the presentation layer keeps calling the same
/// [GymRepository] methods.
class GymRepositoryImpl implements GymRepository {
  GymRepositoryImpl([GymLocalDataSource? local])
      : _local = local ?? GymLocalDataSource();

  final GymLocalDataSource _local;

  @override
  Future<String> loadViewMode() => _local.loadViewMode();

  @override
  Future<void> saveViewMode(String name) => _local.saveViewMode(name);

  @override
  Future<Map<String, List<WorkoutLog>>> loadLogs() => _local.loadLogs();

  @override
  Future<void> saveLogs(Map<String, List<WorkoutLog>> logs) =>
      _local.saveLogs(logs);

  @override
  Future<List<String>> loadOrderActive() => _local.loadOrderActive();

  @override
  Future<void> saveOrderActive(List<String> order) =>
      _local.saveOrderActive(order);

  @override
  Future<Map<String, List<String>>> loadOrderByDay() => _local.loadOrderByDay();

  @override
  Future<void> saveOrderByDay(Map<String, List<String>> order) =>
      _local.saveOrderByDay(order);

  @override
  Future<Map<String, List<String>>> loadAssignments() =>
      _local.loadAssignments();

  @override
  Future<void> saveAssignments(Map<String, List<String>> assignments) =>
      _local.saveAssignments(assignments);

  @override
  Future<List<String>> loadOrderDays() => _local.loadOrderDays();

  @override
  Future<void> saveOrderDays(List<String> order) =>
      _local.saveOrderDays(order);

  @override
  Future<Map<String, List<String>>> loadSplits() => _local.loadSplits();

  @override
  Future<void> saveSplits(Map<String, List<String>> splits) =>
      _local.saveSplits(splits);

  @override
  Future<List<String>> loadSplitOrder() => _local.loadSplitOrder();

  @override
  Future<void> saveSplitOrder(List<String> order) =>
      _local.saveSplitOrder(order);

  @override
  Future<Map<String, String>> loadExerciseNotes() =>
      _local.loadExerciseNotes();

  @override
  Future<void> saveExerciseNotes(Map<String, String> notes) =>
      _local.saveExerciseNotes(notes);

  @override
  Future<Map<String, ExerciseWeightSettings>> loadWeightSettings() =>
      _local.loadWeightSettings();

  @override
  Future<void> saveWeightSettings(Map<String, ExerciseWeightSettings> settings) =>
      _local.saveWeightSettings(settings);

  @override
  Future<Map<String, int>> loadDayColors() => _local.loadDayColors();

  @override
  Future<void> saveDayColors(Map<String, int> colors) =>
      _local.saveDayColors(colors);

  @override
  Future<Map<String, int>> loadDayIcons() => _local.loadDayIcons();

  @override
  Future<void> saveDayIcons(Map<String, int> icons) =>
      _local.saveDayIcons(icons);

  @override
  Future<Map<String, String>> loadDayCustomIcons() =>
      _local.loadDayCustomIcons();

  @override
  Future<void> saveDayCustomIcons(Map<String, String> icons) =>
      _local.saveDayCustomIcons(icons);

  @override
  Future<Map<String, Set<String>>> loadCalendar() => _local.loadCalendar();

  @override
  Future<void> saveCalendar(Map<String, Set<String>> calendar) =>
      _local.saveCalendar(calendar);

  @override
  Future<Set<String>> loadCreatineDates() => _local.loadCreatineDates();

  @override
  Future<void> saveCreatineDates(Set<String> dates) =>
      _local.saveCreatineDates(dates);

  @override
  Future<Map<String, dynamic>> loadBestSetCacheMap() =>
      _local.loadBestSetCacheMap();

  @override
  Future<void> saveBestSetCacheMap(Map<String, dynamic> cache) =>
      _local.saveBestSetCacheMap(cache);

  @override
  Future<Map<String, Set<String>>> loadAlternativeIdsByDay() =>
      _local.loadAlternativeIdsByDay();

  @override
  Future<void> saveAlternativeIdsByDay(Map<String, Set<String>> byDay) =>
      _local.saveAlternativeIdsByDay(byDay);

  @override
  Future<dynamic> loadDailyTasksRaw() => _local.loadDailyTasksRaw();

  @override
  Future<void> saveDailyTasksRaw(Object value) =>
      _local.saveDailyTasksRaw(value);

  @override
  Future<dynamic> loadDailyOneOffByDateRaw() =>
      _local.loadDailyOneOffByDateRaw();

  @override
  Future<void> saveDailyOneOffByDateRaw(Object value) =>
      _local.saveDailyOneOffByDateRaw(value);

  @override
  Future<Map<String, dynamic>> loadProgressHistory() =>
      _local.loadProgressHistory();

  @override
  Future<void> saveProgressHistory(Map<String, dynamic> history) =>
      _local.saveProgressHistory(history);
}
