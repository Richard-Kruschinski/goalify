import '../../../../core/utils/day_cycle.dart';
import '../../domain/repositories/weekly_review_repository.dart';
import '../datasources/weekly_review_local_data_source.dart';
import '../models/weekly_review_data.dart';

/// Default [WeeklyReviewRepository] implementation, backed by
/// [WeeklyReviewLocalDataSource]. Aggregates focus time (pomodoro), completed
/// tasks and workouts per calendar week (Monday-Sunday).
class WeeklyReviewRepositoryImpl implements WeeklyReviewRepository {
  WeeklyReviewRepositoryImpl([WeeklyReviewLocalDataSource? local])
      : _local = local ?? WeeklyReviewLocalDataSource();

  final WeeklyReviewLocalDataSource _local;

  @override
  Future<WeeklyReviewData> loadWeeklyReview() async {
    final today = DayCycle.today();
    final thisWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    final thisWeekKeys = _weekKeys(thisWeekStart);
    final lastWeekKeys = _weekKeys(lastWeekStart);
    final todayKey = _dateKey(today);

    final focusHistory = await _local.loadFocusHistory();
    final blockerHistory = await _local.loadBlockerHistory();
    final workoutCounts = await _local.loadWorkoutCountsByDate();
    final tasksHistory = await _local.loadTasksHistory();

    // Today's tasks are not snapshotted to history until the day rolls over,
    // so count them from the live task state instead.
    final todayTasksDone = await _countTodayTasksDone(todayKey);

    int tasksDoneFor(List<String> keys) {
      var count = 0;
      for (final key in keys) {
        if (key == todayKey) {
          count += todayTasksDone;
        } else {
          final snapshot = tasksHistory[key] ?? const [];
          count += snapshot.where((t) => (t['done'] ?? false) == true).length;
        }
      }
      return count;
    }

    int sumFor(Map<String, int> byDate, List<String> keys) =>
        keys.fold(0, (sum, key) => sum + (byDate[key] ?? 0));

    return WeeklyReviewData(
      focusMinutes: sumFor(focusHistory, thisWeekKeys),
      prevFocusMinutes: sumFor(focusHistory, lastWeekKeys),
      // Blocker history is stored in seconds; only finished sessions count.
      blockerMinutes: sumFor(blockerHistory, thisWeekKeys) ~/ 60,
      prevBlockerMinutes: sumFor(blockerHistory, lastWeekKeys) ~/ 60,
      tasksDone: tasksDoneFor(thisWeekKeys),
      prevTasksDone: tasksDoneFor(lastWeekKeys),
      workouts: sumFor(workoutCounts, thisWeekKeys),
      prevWorkouts: sumFor(workoutCounts, lastWeekKeys),
    );
  }

  Future<int> _countTodayTasksDone(String todayKey) async {
    final keepTasks = await _local.loadKeepTasks();
    final oneOffs = await _local.loadOneOffTasksFor(todayKey);
    bool isDone(Map<String, dynamic> t) => (t['done'] ?? false) == true;
    return keepTasks.where(isDone).length + oneOffs.where(isDone).length;
  }

  List<String> _weekKeys(DateTime weekStart) => List.generate(
        7,
        (i) => _dateKey(weekStart.add(Duration(days: i))),
      );

  String _dateKey(DateTime dt) => DayCycle.dateKey(dt);
}
