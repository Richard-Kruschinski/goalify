import 'task_repeat_pattern.dart';
import 'task_checklist_item.dart';

export 'task_repeat_pattern.dart';
export 'task_checklist_item.dart';

class DailyTask {
  final String id;
  final String title;
  final String? description;
  final String? category; // e.g. Gym, Work, Leisure
  final int points;
  final bool keep; // true = persists across days, false = one-off for a date

  // --- Repeat pattern (for keep tasks only) ---
  final TaskRepeatPattern repeatPattern;
  final int customDays; // used when repeatPattern == custom
  String? repeatStartKey; // anchor date (yyyy-mm-dd) for recurring schedule
  List<int> weeklyDays; // 1=Mon ... 7=Sun

  // --- Streaks (for keep tasks only) ---
  int streak; // current streak length (days)
  int bestStreak; // best ever
  String? lastDoneKey; // dateKey (yyyy-mm-dd) when last completed

  bool done; // "today" checked (resets on rollover for keep; per-date for one-offs)
  List<TaskChecklistItem> checklist; // checklist-style note entries

  // --- Limited tasks (X-mal): appear daily until completedCount >= targetCount ---
  final int? targetCount;         // null = not limited; >0 = must be done this many days per cycle
  int completedCount;             // how many days checked off in the current cycle
  final int? limitedCycleIntervalDays; // null = disappear permanently; >0 = reset every N days
  String? limitedCycleStartKey;  // anchor date for the current cycle (yyyy-mm-dd)

  bool get isLimited => targetCount != null && targetCount! > 0;
  bool get isLimitedRecurring => isLimited && limitedCycleIntervalDays != null;

  String get limitedCycleLabel {
    if (limitedCycleIntervalDays == null) return '';
    if (limitedCycleIntervalDays == 7) return 'Weekly';
    if (limitedCycleIntervalDays == 14) return 'Biweekly';
    if (limitedCycleIntervalDays == 30) return 'Monthly';
    return 'Every ${limitedCycleIntervalDays}d';
  }

  DailyTask({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.points = 1,
    this.keep = false,
    this.repeatPattern = TaskRepeatPattern.daily,
    this.customDays = 1,
    this.repeatStartKey,
    List<int>? weeklyDays,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastDoneKey,
    this.done = false,
    List<TaskChecklistItem>? checklist,
    this.targetCount,
    this.completedCount = 0,
    this.limitedCycleIntervalDays,
    this.limitedCycleStartKey,
  })  : weeklyDays = (weeklyDays ?? <int>[]).where((day) => day >= 1 && day <= 7).toSet().toList(),
        checklist = checklist ?? <TaskChecklistItem>[];

  bool get hasChecklist => checklist.isNotEmpty;
  int get checklistTotalCount => checklist.length;
  int get checklistDoneCount => checklist.where((c) => c.done).length;

  /// Get the effective interval in days for this task
  int get effectiveIntervalDays {
    if (repeatPattern == TaskRepeatPattern.custom) {
      return customDays;
    }
    return repeatPattern.intervalDays;
  }

  String get repeatDisplayLabel {
    if (repeatPattern == TaskRepeatPattern.weekly_days) {
      return weeklyDaysLabel;
    }
    if (repeatPattern == TaskRepeatPattern.biweekly) {
      return 'Biweekly · ${weeklyDaysLabel == 'Weekly' ? 'Mon' : weeklyDaysLabel}';
    }
    if (repeatPattern == TaskRepeatPattern.custom) {
      return 'Every $customDays days';
    }
    return repeatPattern.label;
  }

  String get weeklyDaysLabel {
    if (weeklyDays.isEmpty) return 'Weekly';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final sorted = weeklyDays.toSet().toList()..sort();
    return sorted.map((day) => names[day - 1]).join(', ');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'points': points,
    'keep': keep,
    'done': done,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastDoneKey': lastDoneKey,
    'repeatStartKey': repeatStartKey,
    'repeatPattern': repeatPattern.toStorageString(),
    'customDays': customDays,
    'weeklyDays': weeklyDays,
    'checklist': checklist.map((c) => c.toMap()).toList(),
    'targetCount': targetCount,
    'completedCount': completedCount,
    'limitedCycleIntervalDays': limitedCycleIntervalDays,
    'limitedCycleStartKey': limitedCycleStartKey,
  };

  factory DailyTask.fromMap(Map<String, dynamic> m) {
    final repeatPattern = TaskRepeatPattern.fromString(m['repeatPattern'] as String?);
    final weeklyDays = ((m['weeklyDays'] as List?) ?? const <dynamic>[])
        .map((e) => (e as num).toInt())
        .where((day) => day >= 1 && day <= 7)
        .toList();

    return DailyTask(
      id: m['id'] as String,
      title: m['title'] as String,
      description: m['description'] as String?,
      category: m['category'] as String?,
      points: (m['points'] ?? 1) as int,
      keep: (m['keep'] ?? false) as bool,
      done: (m['done'] ?? false) as bool,
      streak: (m['streak'] ?? 0) as int,
      bestStreak: (m['bestStreak'] ?? 0) as int,
      lastDoneKey: m['lastDoneKey'] as String?,
      repeatStartKey: (m['repeatStartKey'] as String?) ?? (m['lastDoneKey'] as String?),
      repeatPattern: repeatPattern,
      customDays: (m['customDays'] ?? 1) as int,
      weeklyDays: weeklyDays,
      checklist: ((m['checklist'] as List?) ?? const <dynamic>[])
          .map((e) => TaskChecklistItem.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      targetCount: m['targetCount'] as int?,
      completedCount: (m['completedCount'] ?? 0) as int,
      limitedCycleIntervalDays: m['limitedCycleIntervalDays'] as int?,
      limitedCycleStartKey: m['limitedCycleStartKey'] as String?,
    );
  }
}
