import '../../../../core/utils/local_storage.dart';
import '../../data/models/daily_task.dart';

/// ===============================================================
/// Public Helper (for external calls from gym_screen, etc.)
/// ===============================================================
class DailyTasksHelper {
  static const _kDailyTasksKey = 'daily_tasks_v1';
  
  /// Mark gym category task as done for today
  /// Called from gym_screen when a workout day is marked as done
  static Future<void> markGymTaskDoneForToday() async {
    final today = _dateKey(DateTime.now());
    
    // Load keep tasks
    final rawKeep = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
    if (rawKeep is! List) return;
    
    final keepTasks = rawKeep.map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e))).toList();
    
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
    await LocalStorage.saveJson(_kDailyTasksKey, keepTasks.map((t) => t.toMap()).toList());
    
    // Update progress points for today
    final todayPoints = keepTasks
        .where((t) => t.keep && t.done)
        .fold<int>(0, (s, t) => s + t.points);
    
    final progressRaw = await LocalStorage.loadJson('progress_history_v1', fallback: {});
    final hist = Map<String, dynamic>.from(progressRaw as Map);
    hist[today] = todayPoints;
    await LocalStorage.saveJson('progress_history_v1', hist);
  }
  
  static String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
