import '../../../../core/utils/day_cycle.dart';
import '../../data/repositories/tasks_repository_impl.dart';
import '../repositories/tasks_repository.dart';

/// ===============================================================
/// Public Helper (for external calls from gym_screen, etc.)
/// ===============================================================
class DailyTasksHelper {
  static final TasksRepository _repo = TasksRepositoryImpl();

  /// Mark gym category task as done for today
  /// Called from gym_screen when a workout day is marked as done
  static Future<void> markGymTaskDoneForToday() async {
    final today = _dateKey(DayCycle.today());

    // Load keep tasks
    final keepTasks = await _repo.loadKeepTasks();

    // Find gym task (keep tasks with category 'gym' or 'Gym')
    bool changed = false;
    for (final t in keepTasks) {
      if (t.keep && !t.done) {
        final cat = t.category?.toLowerCase().trim();
        if (cat == 'gym') {
          t.done = true;
          changed = true;
          break; // Mark only the first gym task
        }
      }
    }

    if (!changed) return;

    // Save updated tasks
    await _repo.saveKeepTasks(keepTasks);

    // Update progress points for today
    final todayPoints = keepTasks
        .where((t) => t.keep && t.done)
        .fold<int>(0, (s, t) => s + t.points);

    final hist = await _repo.loadProgressHistory();
    hist[today] = todayPoints;
    await _repo.saveProgressHistory(hist);
  }

  static String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
