// Daily Tasks screen with "Congrats" overlay when all tasks are done.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../../core/utils/icon_mapper.dart'; // IconMapper für zentrale Icon-Verwaltung
import '../../../progress/presentation/screens/congrats_screen.dart';

/// ===============================================================
/// Model
/// ===============================================================

/// Repeat pattern for recurring tasks
enum TaskRepeatPattern {
  daily,
  every_2_days,
  every_3_days,
  weekly_days,
  every_7_days,
  biweekly,
  monthly,
  custom;

  String get label {
    switch (this) {
      case TaskRepeatPattern.daily:
        return 'Daily';
      case TaskRepeatPattern.every_2_days:
        return 'Every 2 days';
      case TaskRepeatPattern.every_3_days:
        return 'Every 3 days';
      case TaskRepeatPattern.weekly_days:
        return 'Weekly';
      case TaskRepeatPattern.every_7_days:
        return 'Every 7 days';
      case TaskRepeatPattern.biweekly:
        return 'Biweekly';
      case TaskRepeatPattern.monthly:
        return 'Monthly';
      case TaskRepeatPattern.custom:
        return 'Custom days...';
    }
  }

  int get intervalDays {
    switch (this) {
      case TaskRepeatPattern.daily:
        return 1;
      case TaskRepeatPattern.every_2_days:
        return 2;
      case TaskRepeatPattern.every_3_days:
        return 3;
      case TaskRepeatPattern.weekly_days:
        return 7;
      case TaskRepeatPattern.every_7_days:
        return 7;
      case TaskRepeatPattern.biweekly:
        return 14;
      case TaskRepeatPattern.monthly:
        return 30;
      case TaskRepeatPattern.custom:
        return 1; // fallback, use customDays instead
    }
  }

  static TaskRepeatPattern fromString(String? str) {
    if (str == null) return TaskRepeatPattern.daily;
    try {
      return TaskRepeatPattern.values.firstWhere((e) => e.name == str);
    } catch (_) {
      return TaskRepeatPattern.daily;
    }
  }

  String toStorageString() => name;
}

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

class TaskChecklistItem {
  final String text;
  bool done;

  TaskChecklistItem({
    required this.text,
    this.done = false,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'done': done,
  };

  factory TaskChecklistItem.fromMap(Map<String, dynamic> m) => TaskChecklistItem(
    text: (m['text'] ?? '').toString(),
    done: (m['done'] ?? false) as bool,
  );
}

/// View modes
enum DailyViewMode { today, byDate }

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

/// ===============================================================
/// Screen
/// ===============================================================
class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen>
    with WidgetsBindingObserver {
  // Storage Keys (keep tasks)
  static const _kDailyTasksKey = 'daily_tasks_v1';
  static const _kDailyRolloverKey = 'daily_last_rollover_v1';
  static const _kCongratsShownKey = 'daily_congrats_shown_v1';

  // Legacy orders (kept for compatibility / seeding)
  static const _kDailyOrderKey = 'daily_tasks_order_v1'; // keep tasks order
  static const _kOrderByDateKey =
      'daily_tasks_order_by_date_v1'; // Map<dateKey, List<id>>

  // NEW: combined order (keep + one-offs) per date
  static const _kOrderCombinedKey =
      'daily_order_combined_v1'; // Map<dateKey, List<id>>

  // Freeze
  static const _kFreezeTokensKey = 'daily_freeze_tokens_v1';
  static const _kFreezeDaysCounterKey = 'daily_freeze_days_counter_v1';
  static const _kFreezeUsageKey =
      'daily_freeze_usage_v1'; // Map<dateKey, List<taskId>>

  // NEW: one-off tasks per day (only keep=false live here)
  static const _kOneOffByDateKey =
      'daily_oneoff_by_date_v1'; // Map<dateKey, List<task>>

  // Task History: stores snapshots of all tasks (keep + one-offs) for last 7 days
  static const _kTasksHistoryKey =
      'daily_tasks_history_v1'; // Map<dateKey, List<task snapshots>>

  // Shared with gym_screen: creatine intake per date
  static const _kCreatineKey = 'gym_creatine_intake_v1';

  // Task Icons (standard and custom)
  static const _kTaskIconsKey = 'daily_task_icons_v1'; // Map<taskId, codePoint>
  static const _kTaskCustomIconsKey = 'daily_task_custom_icons_v1'; // Map<taskId, filePath>

  // State
  final List<DailyTask> _keepTasks = []; // keep=true
  final Map<String, List<DailyTask>> _oneOffByDate = {}; // keep=false by date
  
  // Task Icons
  final Map<String, int> _taskIcons = <String, int>{}; // standard icons by task id (codePoint)
  final Map<String, String> _taskCustomIcons = <String, String>{}; // custom icons by task id (file path)

  // Task History (last 7 days) - snapshots of all tasks per date
  final Map<String, List<DailyTask>> _tasksHistory = {};

  // legacy/local orders
  List<String> _orderKeep = [];
  final Map<String, List<String>> _orderByDate = {};

  // combined per date
  final Map<String, List<String>> _orderCombined = {};

  // Creatine intake cache (yyyy-MM-dd)
  final Set<String> _creatineDates = <String>{};

  int _todayPoints = 0;

  // Freeze-State
  int _freezeTokens = 0;
  int _freezeDaysCounter = 0;
  final Map<String, List<String>> _freezeUsageByDate = {};

  // View selection
  DailyViewMode _mode = DailyViewMode.today;
  DateTime _selectedDate = DateTime.now();

  // Helpers
  void _showFreezeHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 3),
        content: Text(
          'Freeze token: protects a keep-task streak for TODAY without checking it off. '
              'Long-press a keep-task and choose "Freeze for today". Costs 1 token.',
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(); // loads + applies rollover
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _dailyRolloverIfNeeded();
    }
  }

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _todayKey() => _dateKey(DateTime.now());
  String _selectedKey() => _dateKey(_selectedDate);

  bool _isDoneForDate(DailyTask t, String dateKey) {
    if (!t.keep) return t.done;
    // Past dates are rendered from immutable history snapshots.
    // For those entries, keep the stored done-state instead of forcing false.
    if (_isPastDate(dateKey, _todayKey())) return t.done;
    return dateKey == _todayKey() ? t.done : false;
  }

  // ---- Progress: save today’s points ----
  Future<void> _saveProgressToday() async {
    final key = _todayKey();
    final raw =
    await LocalStorage.loadJson('progress_history_v1', fallback: {});
    final hist = Map<String, dynamic>.from(raw as Map);
    hist[key] = _todayPoints;
    await LocalStorage.saveJson('progress_history_v1', hist);
  }

  // ===============================================================
  // Load & Save
  // ===============================================================
  Future<void> _load() async {
    _availableTaskIcons = await IconMapper.getTaskIcons();
    await _loadCreatine();
    await _loadTaskIcons();
    await _loadTaskCustomIcons();
    // Keep-tasks (legacy list)
    final rawKeep = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
    if (rawKeep is List) {
      _keepTasks
        ..clear()
        ..addAll(
          rawKeep.map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e))),
        );
    }

    await _normalizeRecurringAnchors();

    // MIGRATION: if any non-keep sneaked into old list, move them to TODAY bucket
    if (_keepTasks.any((t) => !t.keep)) {
      final today = _todayKey();
      final off = _keepTasks.where((t) => !t.keep).toList();
      _keepTasks.removeWhere((t) => !t.keep);
      final list = _oneOffByDate.putIfAbsent(today, () => <DailyTask>[]);
      list.addAll(off.map((t) => t..done = t.done));
      await LocalStorage.saveJson(
          _kDailyTasksKey, _keepTasks.map((t) => t.toMap()).toList());
    }

    // Legacy orders
    final orderKeepRaw =
    await LocalStorage.loadJson(_kDailyOrderKey, fallback: []);
    _orderKeep = (orderKeepRaw is List)
        ? orderKeepRaw.map((e) => e.toString()).toList()
        : <String>[];

    final orderByDateRaw =
    await LocalStorage.loadJson(_kOrderByDateKey, fallback: {});
    _orderByDate.clear();
    if (orderByDateRaw is Map) {
      orderByDateRaw.forEach((k, v) {
        if (v is List) {
          _orderByDate[k.toString()] =
              v.map((e) => e.toString()).toList(growable: true);
        }
      });
    }

    // One-offs by date
    final oneOffRaw =
    await LocalStorage.loadJson(_kOneOffByDateKey, fallback: {});
    _oneOffByDate.clear();
    if (oneOffRaw is Map) {
      oneOffRaw.forEach((k, v) {
        if (v is List) {
          final list = v
              .map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e)))
              .where((t) => !t.keep)
              .toList();
          _oneOffByDate[k.toString()] = list;
        }
      });
    }

    // Combined order
    final combinedRaw =
    await LocalStorage.loadJson(_kOrderCombinedKey, fallback: {});
    _orderCombined.clear();
    if (combinedRaw is Map) {
      combinedRaw.forEach((k, v) {
        if (v is List) {
          _orderCombined[k.toString()] =
              v.map((e) => e.toString()).toList(growable: true);
        }
      });
    }

    // Freeze state
    _freezeTokens =
        (await LocalStorage.loadJson(_kFreezeTokensKey, fallback: null))
        as int? ??
            2;
    _freezeDaysCounter =
        (await LocalStorage.loadJson(_kFreezeDaysCounterKey, fallback: 0))
        as int? ??
            0;

    final fuRaw = await LocalStorage.loadJson(_kFreezeUsageKey, fallback: {});
    _freezeUsageByDate.clear();
    if (fuRaw is Map) {
      fuRaw.forEach((k, v) {
        if (v is List) {
          _freezeUsageByDate[k.toString()] =
              v.map((e) => e.toString()).toList();
        }
      });
    }

    // Load task history (last 7 days)
    final historyRaw = await LocalStorage.loadJson(_kTasksHistoryKey, fallback: {});
    _tasksHistory.clear();
    if (historyRaw is Map) {
      historyRaw.forEach((k, v) {
        if (v is List) {
          final list = v
              .map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e)))
              .toList();
          _tasksHistory[k.toString()] = list;
        }
      });
    }

    await _dailyRolloverIfNeeded(); // apply rollover

    // Re-apply done-at-bottom sort after loading so the order is correct
    // even if the app restarted or the stored order got out of sync.
    final todayKey = _todayKey();
    _syncCombinedForDate(todayKey); // ensure _orderCombined[today] is initialised
    _sortCompletedToBottom(todayKey);

    _recalcTodayPoints();
    await _saveProgressToday();
    if (mounted) setState(() {});
  }

  Future<void> _saveKeepTasks() async {
    await LocalStorage.saveJson(
      _kDailyTasksKey,
      _keepTasks.map((t) => t.toMap()).toList(),
    );
  }

  Future<void> _saveOneOffMap() async {
    final map = <String, List<Map<String, dynamic>>>{};
    _oneOffByDate.forEach((k, v) {
      map[k] = v.map((t) => t.toMap()).toList();
    });
    await LocalStorage.saveJson(_kOneOffByDateKey, map);
  }

  Future<void> _saveOrderKeep() async =>
      LocalStorage.saveJson(_kDailyOrderKey, _orderKeep);

  Future<void> _saveOrderByDate() async =>
      LocalStorage.saveJson(_kOrderByDateKey, _orderByDate);

  Future<void> _saveOrderCombined() async =>
      LocalStorage.saveJson(_kOrderCombinedKey, _orderCombined);

  Future<void> _saveTasksHistory() async {
    final map = <String, List<Map<String, dynamic>>>{};
    _tasksHistory.forEach((k, v) {
      map[k] = v.map((t) => t.toMap()).toList();
    });
    await LocalStorage.saveJson(_kTasksHistoryKey, map);
  }

  Future<void> _saveFreezeState() async {
    await LocalStorage.saveJson(_kFreezeTokensKey, _freezeTokens);
    await LocalStorage.saveJson(_kFreezeDaysCounterKey, _freezeDaysCounter);
    await LocalStorage.saveJson(_kFreezeUsageKey, _freezeUsageByDate);
  }

  Future<void> _loadCreatine() async {
    final raw = await LocalStorage.loadJson(_kCreatineKey, fallback: []);
    _creatineDates
      ..clear()
      ..addAll((raw is List) ? raw.map((e) => e.toString()) : const <String>[]);
  }

  Future<void> _saveCreatine() async {
    await LocalStorage.saveJson(_kCreatineKey, _creatineDates.toList());
  }

  Future<void> _setCreatineForDate(String dateKey, bool value) async {
    if (value) {
      _creatineDates.add(dateKey);
    } else {
      _creatineDates.remove(dateKey);
    }
    await _saveCreatine();
  }

  Future<void> _loadTaskIcons() async {
    final raw = await LocalStorage.loadJson(_kTaskIconsKey, fallback: {});
    _taskIcons.clear();
    if (raw is Map) {
      raw.forEach((key, value) {
        _taskIcons[key.toString()] = (value as num?)?.toInt() ?? 0;
      });
    }
  }

  Future<void> _saveTaskIcons() async =>
      LocalStorage.saveJson(_kTaskIconsKey, _taskIcons);

  Future<void> _loadTaskCustomIcons() async {
    final raw = await LocalStorage.loadJson(_kTaskCustomIconsKey, fallback: {});
    _taskCustomIcons.clear();
    if (raw is Map) {
      raw.forEach((key, value) {
        _taskCustomIcons[key.toString()] = value.toString();
      });
    }
  }

  Future<void> _saveTaskCustomIcons() async =>
      LocalStorage.saveJson(_kTaskCustomIconsKey, _taskCustomIcons);

  Future<void> _normalizeRecurringAnchors() async {
    final todayKey = _todayKey();
    var changed = false;

    for (final task in _keepTasks) {
      if (!task.keep) continue;
      if ((task.repeatPattern == TaskRepeatPattern.weekly_days ||
              task.repeatPattern == TaskRepeatPattern.biweekly) &&
          task.weeklyDays.isEmpty) {
        final anchorDate = _tryParseDateKey(task.repeatStartKey ?? '') ?? DateTime.now();
        task.weeklyDays = <int>[anchorDate.weekday];
        changed = true;
      }
      final anchor = task.repeatStartKey;
      if (anchor == null || anchor.isEmpty) {
        task.repeatStartKey = (task.lastDoneKey != null && task.lastDoneKey!.isNotEmpty)
            ? task.lastDoneKey
            : todayKey;
        changed = true;
      }
    }

    if (changed) {
      await _saveKeepTasks();
    }
  }


  // Keep order sync (legacy - still used to seed combined)
  void _syncOrderKeepWithTasks() {
    final ids = _keepTasks.map((t) => t.id).toList();
    bool changed = false;
    for (final id in ids) {
      if (!_orderKeep.contains(id)) {
        _orderKeep.add(id);
        changed = true;
      }
    }
    final setIds = ids.toSet();
    final before = _orderKeep.length;
    _orderKeep.removeWhere((id) => !setIds.contains(id));
    if (before != _orderKeep.length) changed = true;
    if (changed) _saveOrderKeep();
  }

  // One-off order sync (legacy - seed combined)
  void _syncOrderForDate(String dateKey) {
    final ids =
    (_oneOffByDate[dateKey] ?? const <DailyTask>[]).map((t) => t.id).toList();
    final order = List<String>.from(_orderByDate[dateKey] ?? const []);
    bool changed = false;
    for (final id in ids) {
      if (!order.contains(id)) {
        order.add(id);
        changed = true;
      }
    }
    if (changed) {
      _orderByDate[dateKey] = order;
      _saveOrderByDate();
    }
  }

  // NEW: ensure combined order for date contains exactly the task ids present
  void _syncCombinedForDate(String dateKey) {
    _syncOrderKeepWithTasks();
    _syncOrderForDate(dateKey);

    final presentIds = <String>{
      ..._keepTasks.map((e) => e.id),
      ...(_oneOffByDate[dateKey] ?? const <DailyTask>[]).map((e) => e.id),
    };

    var combined = List<String>.from(_orderCombined[dateKey] ?? const []);

    // remove missing
    combined.removeWhere((id) => !presentIds.contains(id));

    // if empty (first time): seed with legacy orders (keeps in legacy order, then one-offs)
    if (combined.isEmpty) {
      final legacyKeepOrder = _orderKeep
          .where((id) => presentIds.contains(id))
          .toList(growable: true);
      final legacyOffOrder =
      (_orderByDate[dateKey] ?? const <String>[]).where(presentIds.contains).toList();
      combined = [...legacyKeepOrder, ...legacyOffOrder];
    }

    // append any new ids at end (stable)
    for (final id in presentIds) {
      if (!combined.contains(id)) combined.add(id);
    }

    _orderCombined[dateKey] = combined;
    _saveOrderCombined();
  }

  /// Visible list for current context:
  /// SINGLE combined order per date (keep + one-offs interleavable)
  /// For past dates: loads from history
  List<DailyTask> _orderedTasksFor(String dateKey) {
    final today = _todayKey();
    
    // For past dates: load from history
    if (_isPastDate(dateKey, today)) {
      final historyTasks = _tasksHistory[dateKey] ?? const <DailyTask>[];
      return List<DailyTask>.from(historyTasks);
    }
    
    // For today or future: normal logic
    _syncCombinedForDate(dateKey);

    // Build id -> task map of all tasks visible that day
    // Filter keep tasks by repeat pattern - only show if active on this date
    final map = <String, DailyTask>{
      for (final t in _keepTasks)
        if (_isTaskActiveOnDate(t, dateKey))
          t.id: t,
      for (final t in (_oneOffByDate[dateKey] ?? const <DailyTask>[])) t.id: t,
    };

    final ids = _orderCombined[dateKey] ?? const <String>[];
    final result = <DailyTask>[];

    // 1) add in combined order
    for (final id in ids) {
      final t = map[id];
      if (t != null) {
        result.add(t);
        map.remove(id);
      }
    }
    // 2) append any leftovers (shouldn't happen, but safe)
    result.addAll(map.values);

    return result;
  }

  /// Check if a recurring task should be active on a given date based on its repeat pattern
  bool _isTaskActiveOnDate(DailyTask task, String dateKey) {
    if (!task.keep) return true;

    if (task.isLimited) {
      // Cycle still has remaining completions → visible
      if (task.completedCount < task.targetCount!) return true;
      // Cycle done — permanent tasks vanish, recurring tasks hide until next cycle
      if (task.limitedCycleIntervalDays == null) return false;
      final cycleStart = _tryParseDateKey(task.limitedCycleStartKey ?? '');
      final checkDate = _tryParseDateKey(dateKey);
      if (cycleStart == null || checkDate == null) return false;
      final daysSince = checkDate.difference(cycleStart).inDays;
      return daysSince >= task.limitedCycleIntervalDays!;
    }

    return _isRecurringTaskScheduledOnDate(task, dateKey);
  }

  /// Check if dateKey is in the past (before today)
  bool _isPastDate(String dateKey, String todayKey) {
    try {
      final parts = dateKey.split('-').map(int.parse).toList();
      final date = DateTime(parts[0], parts[1], parts[2]);
      final todayParts = todayKey.split('-').map(int.parse).toList();
      final today = DateTime(todayParts[0], todayParts[1], todayParts[2]);
      return date.isBefore(today);
    } catch (e) {
      return false;
    }
  }

  DateTime? _tryParseDateKey(String dateKey) {
    try {
      final parts = dateKey.split('-').map(int.parse).toList();
      return DateTime(parts[0], parts[1], parts[2]);
    } catch (_) {
      return null;
    }
  }

  bool _isTaskDueOnDate(DailyTask task, String dateKey) {
    if (!task.keep) return false;
    return _isRecurringTaskScheduledOnDate(task, dateKey);
  }

  bool _isConsecutiveCompletion(DailyTask task, String completionDateKey) {
    final lastDoneKey = task.lastDoneKey;
    if (lastDoneKey == null || lastDoneKey.isEmpty) return false;

    final completionDate = _tryParseDateKey(completionDateKey);
    final previousCompletionDate = _tryParseDateKey(lastDoneKey);
    if (completionDate == null || previousCompletionDate == null) return false;

    final daysBetween = completionDate.difference(previousCompletionDate).inDays;
    return daysBetween == task.effectiveIntervalDays;
  }

  bool _isRecurringTaskScheduledOnDate(DailyTask task, String dateKey) {
    if (task.repeatPattern == TaskRepeatPattern.weekly_days) {
      if (task.weeklyDays.isEmpty) return true;
      final checkDate = _tryParseDateKey(dateKey);
      if (checkDate == null) return true;
      return task.weeklyDays.contains(checkDate.weekday);
    }

    if (task.repeatPattern == TaskRepeatPattern.biweekly) {
      final checkDate = _tryParseDateKey(dateKey);
      final anchorDate = _tryParseDateKey(task.repeatStartKey ?? '');
      if (checkDate == null || anchorDate == null) return true;
      if (checkDate.isBefore(anchorDate)) return false;

      final weekdays = task.weeklyDays.isEmpty
          ? <int>[anchorDate.weekday]
          : task.weeklyDays;
      if (!weekdays.contains(checkDate.weekday)) return false;

      final startOfAnchorWeek =
          DateTime(anchorDate.year, anchorDate.month, anchorDate.day)
              .subtract(Duration(days: anchorDate.weekday - 1));
      final startOfCheckWeek =
          DateTime(checkDate.year, checkDate.month, checkDate.day)
              .subtract(Duration(days: checkDate.weekday - 1));
      final weeksBetween =
          startOfCheckWeek.difference(startOfAnchorWeek).inDays ~/ 7;

      return weeksBetween % 2 == 0;
    }

    final anchorKey = task.repeatStartKey;
    if (anchorKey == null || anchorKey.isEmpty) {
      return true;
    }

    final checkDate = _tryParseDateKey(dateKey);
    final anchorDate = _tryParseDateKey(anchorKey);
    if (checkDate == null || anchorDate == null) return true;

    final daysSince = checkDate.difference(anchorDate).inDays;
    if (daysSince < 0) return false;

    return daysSince % task.effectiveIntervalDays == 0;
  }

  // ===============================================================
  // Daily rollover + streak/freeze logic (keep tasks)
  // ===============================================================
  Future<void> _markRolloverDoneForToday() async {
    await LocalStorage.saveJson(_kDailyRolloverKey, _todayKey());
  }

  bool _wasFrozenOn(String dateKey, String taskId) {
    final list = _freezeUsageByDate[dateKey];
    return list != null && list.contains(taskId);
  }

  void _clearFreezeForDate(String dateKey) {
    _freezeUsageByDate.remove(dateKey);
  }

  Future<void> _dailyRolloverIfNeeded() async {
    final rawLast =
        await LocalStorage.loadJson(_kDailyRolloverKey, fallback: '');
    final todayKey = _todayKey();
    if (rawLast == todayKey) return;

    final todayDate = DateTime.now();
    final today = DateTime(todayDate.year, todayDate.month, todayDate.day);

    // If no valid rollover exists, keep legacy behavior and process only 1 day.
    final parsedLast = _tryParseDateKey((rawLast ?? '').toString());
    var cursor = parsedLast ?? today.subtract(const Duration(days: 1));
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    bool changedKeep = false;
    bool changedOneOff = false;
    bool changedOrderByDate = false;
    bool changedOrderCombined = false;

    while (cursor.isBefore(today)) {
      final dayKey = _dateKey(cursor);
      final nextDay = cursor.add(const Duration(days: 1));
      final nextDayKey = _dateKey(nextDay);

      // --- SNAPSHOT: Save day's tasks to history BEFORE modifying them ---
      await _saveTaskSnapshotToHistory(dayKey);

      // --- Streak update (evaluate this day only if task was due) ---
      for (final t in _keepTasks) {
        if (!t.keep) continue;

        // Limited tasks: cycle reset + completion count, no streak tracking
        if (t.isLimited) {
          // Check if a new cycle starts on this day
          if (t.limitedCycleIntervalDays != null) {
            final cycleStart = _tryParseDateKey(t.limitedCycleStartKey ?? '');
            final dayDate = _tryParseDateKey(dayKey);
            if (cycleStart != null && dayDate != null) {
              final daysSince = dayDate.difference(cycleStart).inDays;
              if (daysSince > 0 && daysSince % t.limitedCycleIntervalDays! == 0) {
                t.completedCount = 0;
                t.limitedCycleStartKey = dayKey;
                changedKeep = true;
              }
            }
          }
          if (t.done) {
            t.completedCount += 1;
            changedKeep = true;
          }
          continue;
        }

        final wasDue = _isTaskDueOnDate(t, dayKey);
        if (!wasDue) continue;

        if (t.done) {
          if (_isConsecutiveCompletion(t, dayKey)) {
            t.streak += 1;
          } else {
            t.streak = 1;
          }
          t.lastDoneKey = dayKey;
          if (t.streak > t.bestStreak) t.bestStreak = t.streak;
        } else {
          // not done -> protect only if frozen that day
          if (!_wasFrozenOn(dayKey, t.id)) {
            t.streak = 0;
          }
        }
      }
      _clearFreezeForDate(dayKey);

      // --- Day change ---
      // 1) keep tasks: uncheck for the next day
      for (final t in _keepTasks) {
        if (t.keep && t.done) {
          t.done = false;
          changedKeep = true;
        }
      }

      // 2) one-offs: drop this day's bucket entirely (completed or not)
      // (They're now saved in history, so we can safely remove them)
      if (_oneOffByDate.containsKey(dayKey)) {
        _oneOffByDate.remove(dayKey);
        _orderByDate.remove(dayKey);
        _orderCombined.remove(dayKey);
        changedOneOff = true;
        changedOrderByDate = true;
        changedOrderCombined = true;
      }

      // --- Freeze tokens: +1 each 7 days ---
      _freezeDaysCounter += 1;
      if (_freezeDaysCounter % 7 == 0) {
        _freezeTokens += 1;
      }

      // --- Reset combined order to original state (active first) ---
      _resetCombinedOrderToOriginal(dayKey);
      _resetCombinedOrderToOriginal(nextDayKey);
      changedOrderCombined = true;

      cursor = nextDay;
    }

    // --- Remove permanent limited tasks that reached their target (recurring ones stay) ---
    final limitedDone = _keepTasks.any(
      (t) => t.isLimited && t.limitedCycleIntervalDays == null && t.completedCount >= t.targetCount!,
    );
    if (limitedDone) {
      _keepTasks.removeWhere(
        (t) => t.isLimited && t.limitedCycleIntervalDays == null && t.completedCount >= t.targetCount!,
      );
      changedKeep = true;
    }

    // --- Cleanup old history (older than 7 days) ---
    await _cleanupOldHistory();

    _recalcTodayPoints();
    await _markRolloverDoneForToday();
    await _saveProgressToday();
    await _saveFreezeState();
    if (changedKeep) {
      await _saveKeepTasks();
    }
    if (changedOneOff) {
      await _saveOneOffMap();
    }
    if (changedOrderByDate) {
      await _saveOrderByDate();
    }
    if (changedOrderCombined) {
      await _saveOrderCombined();
    }

    if (mounted) setState(() {});
  }

  /// Save a snapshot of all tasks (keep + one-offs) for a specific date to history
  Future<void> _saveTaskSnapshotToHistory(String dateKey) async {
    // Collect all tasks for this date
    final snapshot = <DailyTask>[];
    
    // Add keep tasks (with their current done state)
    // Filter by repeat pattern - only include if active on this date
    for (final t in _keepTasks) {
      if (!_isTaskActiveOnDate(t, dateKey)) continue;
      
      snapshot.add(DailyTask(
        id: t.id,
        title: t.title,
        description: t.description,
        category: t.category,
        points: t.points,
        keep: t.keep,
        repeatPattern: t.repeatPattern,
        customDays: t.customDays,
        repeatStartKey: t.repeatStartKey,
        done: t.done,
        streak: t.streak,
        bestStreak: t.bestStreak,
        lastDoneKey: t.lastDoneKey,
        checklist: t.checklist
            .map((c) => TaskChecklistItem(text: c.text, done: c.done))
            .toList(),
        targetCount: t.targetCount,
        completedCount: t.completedCount,
        limitedCycleIntervalDays: t.limitedCycleIntervalDays,
        limitedCycleStartKey: t.limitedCycleStartKey,
      ));
    }
    
    // Add one-off tasks for this date
    final oneOffs = _oneOffByDate[dateKey] ?? const <DailyTask>[];
    for (final t in oneOffs) {
      snapshot.add(DailyTask(
        id: t.id,
        title: t.title,
        description: t.description,
        category: t.category,
        points: t.points,
        keep: t.keep,
        done: t.done,
        checklist: t.checklist
            .map((c) => TaskChecklistItem(text: c.text, done: c.done))
            .toList(),
      ));
    }
    
    // Store in history
    _tasksHistory[dateKey] = snapshot;
    await _saveTasksHistory();
  }

  /// Remove history entries older than 7 days
  /// Keeps: today + 7 previous days = max 8 entries
  Future<void> _cleanupOldHistory() async {
    final today = DateTime.now();
    final cutoffDate = today.subtract(const Duration(days: 8));
    final cutoffKey = _dateKey(cutoffDate);
    
    final keysToRemove = <String>[];
    for (final key in _tasksHistory.keys) {
      if (_isPastDate(key, cutoffKey) || key == cutoffKey) {
        // This date is 8+ days old, remove it
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _tasksHistory.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      await _saveTasksHistory();
    }
  }

  /// Reset combined order by date to original structure (no completion-based sorting)
  void _resetCombinedOrderToOriginal(String dateKey) {
    final keepIds = _orderKeep.where((id) {
      return _keepTasks.any((x) => x.id == id);
    }).toList();

    final oneOffIds = _orderByDate[dateKey] ?? <String>[];

    // Rebuild: keep first, then one-offs
    _orderCombined[dateKey] = keepIds + oneOffIds;
  }

  // ===============================================================
  // Points (only keep & done today count toward "Today" points)
  // ===============================================================
  void _recalcTodayPoints() {
    _todayPoints = _keepTasks
        .where((t) => t.keep && t.done)
        .fold<int>(0, (s, t) => s + t.points);
  }

  // ===============================================================
  // Congrats: only for TODAY and only when everything (keep + today’s one-offs) is done
  // ===============================================================
  Future<void> _checkAndMaybeShowCongrats() async {
    final todayKey = _todayKey();
    final all = _orderedTasksFor(todayKey);
    if (all.isEmpty) return;

    final allDone = all.every(
      (t) => t.done || (t.keep && _wasFrozenOn(todayKey, t.id)),
    );
    if (!allDone) return;

    final lastShown =
    await LocalStorage.loadJson(_kCongratsShownKey, fallback: '');
    if (lastShown == todayKey) return;

    await LocalStorage.saveJson(_kCongratsShownKey, todayKey);
    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (_, _, _) => CongratsScreen(
          onSeeProgress: () {
            widget.onNavigateToTab?.call(0);
          },
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ===============================================================
  // Create / Toggle / Delete / Freeze / Reorder / Actions
  // ===============================================================
  Future<void> _openCreateTaskSheet({required String forDateKey}) async {
    // Block creating tasks for past dates
    if (_isPastDate(forDateKey, _todayKey())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Cannot create tasks for past dates.'),
        ),
      );
      return;
    }
    
    final created = await showModalBottomSheet<_CreateResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateDailyTaskSheet(
        defaultDateKey: forDateKey,
      ),
    );

    if (!mounted) return;
    if (created != null) {
      // Auto-assign default icon based on category
      final defaultIcon = _getDefaultIconForCategory(created.task.category);
      _taskIcons[created.task.id] = defaultIcon.codePoint;

      if (created.task.keep) {
        setState(() {
          _keepTasks.add(created.task..done = false);
          _orderKeep.add(created.task.id); // legacy
          _recalcTodayPoints();
        });
        await _saveKeepTasks();
        await _saveOrderKeep();
        await _saveProgressToday();
      } else {
        final key = created.dateKey ?? forDateKey;
        final list = _oneOffByDate.putIfAbsent(key, () => <DailyTask>[]);
        setState(() {
          list.add(created.task);
          final ord = _orderByDate.putIfAbsent(key, () => <String>[]); // legacy
          ord.add(created.task.id);
        });
        await _saveOneOffMap();
        await _saveOrderByDate();
      }

      // Save the task icon
      await _saveTaskIcons();

      // ensure new item is appended to combined order of that date
      final key = created.dateKey ?? forDateKey;
      _syncCombinedForDate(key);
      if (!_orderCombined[key]!.contains(created.task.id)) {
        _orderCombined[key]!.add(created.task.id);
        await _saveOrderCombined();
      }
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleDone(DailyTask t, {required String dateKey}) async {
    // Block changes to past dates (read-only history)
    if (_isPastDate(dateKey, _todayKey())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Cannot modify tasks from past dates.'),
        ),
      );
      return;
    }
    
    if (t.keep && dateKey != _todayKey()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Recurring tasks can only be checked for today.'),
        ),
      );
      return;
    }
    setState(() {
      t.done = !t.done;
      _recalcTodayPoints();
      _sortCompletedToBottom(dateKey);
    });

    await _maybeToggleCreatine(t, dateKey: dateKey);

    if (t.keep) {
      await _saveKeepTasks();
    } else {
      await _saveOneOffMap();
    }
    
    // Save the new combined order (completed moved to bottom)
    await _saveOrderCombined();
    
    if (dateKey == _todayKey()) {
      await _saveProgressToday();
      await _checkAndMaybeShowCongrats();
    }
  }

  Future<void> _maybeToggleCreatine(DailyTask t, {required String dateKey}) async {
    final cat = t.category?.toLowerCase().trim();
    if (cat != 'creatin' && cat != 'creatine') return;
    await _setCreatineForDate(dateKey, t.done);
  }

  /// Sort tasks in combined order: active/incomplete first, completed last
  void _sortCompletedToBottom(String dateKey) {
    final ids = _orderCombined[dateKey] ?? <String>[];
    final map = <String, DailyTask>{
      for (final t in _keepTasks) t.id: t,
      for (final t in (_oneOffByDate[dateKey] ?? const <DailyTask>[])) t.id: t,
    };

    final active = <String>[];
    final completed = <String>[];

    for (final id in ids) {
      final t = map[id];
      if (t != null) {
        if (t.done) {
          completed.add(id);
        } else {
          active.add(id);
        }
      }
    }

    _orderCombined[dateKey] = active + completed;
    _saveOrderCombined();
  }


  Future<void> _deleteAt(int indexInOrdered, {required String dateKey}) async {
    // Block deleting tasks from past dates
    if (_isPastDate(dateKey, _todayKey())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Cannot delete tasks from past dates.'),
        ),
      );
      return;
    }
    
    final list = _orderedTasksFor(dateKey);
    if (indexInOrdered < 0 || indexInOrdered >= list.length) return;
    final t = list[indexInOrdered];

    setState(() {
      if (t.keep) {
        _keepTasks.removeWhere((x) => x.id == t.id);
        _orderKeep.remove(t.id);
      } else {
        final dayList = _oneOffByDate[dateKey];
        dayList?.removeWhere((x) => x.id == t.id);
        _orderByDate[dateKey]?.remove(t.id);
        if (dayList != null && dayList.isEmpty) {
          _oneOffByDate.remove(dateKey);
          _orderByDate.remove(dateKey);
        }
      }
      _orderCombined[dateKey]?.remove(t.id); // remove from combined
      _recalcTodayPoints();
    });

    if (t.keep) {
      await _saveKeepTasks();
      await _saveOrderKeep();
    } else {
      await _saveOneOffMap();
      await _saveOrderByDate();
    }
    await _saveOrderCombined();
    if (dateKey == _todayKey()) await _saveProgressToday();
  }

  Future<void> _freezeToday(DailyTask t) async {
    final today = _todayKey();
    if (_freezeTokens <= 0) return;
    if (_wasFrozenOn(today, t.id)) return;

    setState(() {
      _freezeTokens -= 1;
      final list = _freezeUsageByDate.putIfAbsent(today, () => <String>[]);
      list.add(t.id);
    });
    _sortCompletedToBottom(today);
    await _saveFreezeState();
    await _checkAndMaybeShowCongrats();
  }

  Future<void> _openChecklistNoteEditor(DailyTask task) async {
    final draft = task.checklist
        .map((c) => TaskChecklistItem(text: c.text, done: c.done))
        .toList(growable: true);
    final inputController = TextEditingController();

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFF5F7FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEDE9FE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.checklist, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Checklist note',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D1F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (draft.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'No checklist items yet. Add one below.',
                          style: TextStyle(color: Color(0xFF6F7789)),
                        ),
                      ),
                    ...List.generate(draft.length, (index) {
                      final item = draft[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Checkbox(
                              value: item.done,
                              activeColor: const Color(0xFFE53935),
                              onChanged: (value) {
                                setSheetState(() => item.done = value ?? false);
                              },
                            ),
                            Expanded(
                              child: Text(
                                item.text,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: item.done
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFF1A1D1F),
                                  decoration:
                                      item.done ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Delete item',
                              onPressed: () => setSheetState(() => draft.removeAt(index)),
                              icon: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              final text = inputController.text.trim();
                              if (text.isEmpty) return;
                              setSheetState(() {
                                draft.add(TaskChecklistItem(text: text));
                                inputController.clear();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: 'Add checklist item...',
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final text = inputController.text.trim();
                            if (text.isEmpty) return;
                            setSheetState(() {
                              draft.add(TaskChecklistItem(text: text));
                              inputController.clear();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetCtx, false),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetCtx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Save checklist'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    inputController.dispose();
    if (saved != true) return;

    setState(() {
      task.checklist = draft;
    });

    if (task.keep) {
      await _saveKeepTasks();
    } else {
      await _saveOneOffMap();
    }
  }

  // NEW: single combined reorder across keep + one-off
  void _onReorder(int oldIndex, int newIndex, {required String dateKey}) {
    // Block reordering for past dates
    if (_isPastDate(dateKey, _todayKey())) {
      return;
    }
    
    _syncCombinedForDate(dateKey);
    if (newIndex > oldIndex) newIndex -= 1;
    final ids = _orderCombined[dateKey] ?? <String>[];
    if (oldIndex < 0 || oldIndex >= ids.length || newIndex < 0 || newIndex >= ids.length) {
      return;
    }
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    _orderCombined[dateKey] = ids;
    _saveOrderCombined();
    setState(() {});
  }

  Future<void> _openTaskActions(
      DailyTask t, int indexInOrdered, String dateKey) async {
    // For past dates, show read-only info
    if (_isPastDate(dateKey, _todayKey())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Tasks from past dates are read-only.'),
        ),
      );
      return;
    }
    
    final frozenToday = _wasFrozenOn(_todayKey(), t.id);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF5F7FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget actionTile({
          required IconData icon,
          required String title,
          String? subtitle,
          Color iconColor = const Color(0xFF1A1D1F),
          VoidCallback? onTap,
          bool danger = false,
          bool enabled = true,
        }) {
          final foreground = enabled
              ? (danger ? const Color(0xFFE53935) : iconColor)
              : const Color(0xFFBFC5D2);
          final textColor = enabled
              ? (danger ? const Color(0xFFE53935) : const Color(0xFF1A1D1F))
              : const Color(0xFFBFC5D2);
          final bgColor = danger
              ? const Color(0xFFFFEBEE)
              : iconColor.withOpacity(0.12);

          return Opacity(
            opacity: enabled ? 1 : 0.6,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: foreground, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: enabled
                                    ? const Color(0xFF6F7789)
                                    : const Color(0xFFBFC5D2),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      danger ? Icons.delete_outline : Icons.chevron_right,
                      color: danger ? const Color(0xFFE53935) : const Color(0xFFCDD2D8),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.settings, color: Color(0xFFE53935)),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Task actions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1D1F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                actionTile(
                  icon: Icons.edit,
                  title: 'Edit',
                  subtitle: 'Update title, description or category',
                  iconColor: const Color(0xFF3F51B5),
                  onTap: () async {
                    final data = await showModalBottomSheet<_TaskFormData>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: const Color(0xFFF5F7FA),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => _EditDailyTaskSheet(task: t),
                    );
                    if (data != null) {
                      if (t.keep) {
                        final idx = _keepTasks.indexWhere((x) => x.id == t.id);
                        if (idx >= 0) {
                          setState(() {
                            _keepTasks[idx] = DailyTask(
                              id: t.id,
                              title: data.title,
                              description: data.description,
                              category: data.category,
                              points: data.points,
                              keep: true,
                              repeatPattern: data.repeatPattern,
                              customDays: data.customDays,
                              repeatStartKey: _keepTasks[idx].repeatStartKey,
                              weeklyDays: data.weeklyDays,
                              streak: _keepTasks[idx].streak,
                              bestStreak: _keepTasks[idx].bestStreak,
                              lastDoneKey: _keepTasks[idx].lastDoneKey,
                              done: _keepTasks[idx].done,
                              checklist: _keepTasks[idx].checklist
                                  .map((c) => TaskChecklistItem(text: c.text, done: c.done))
                                  .toList(),
                              targetCount: data.targetCount,
                              completedCount: _keepTasks[idx].completedCount,
                              limitedCycleIntervalDays: data.limitedCycleIntervalDays,
                              limitedCycleStartKey: _keepTasks[idx].limitedCycleStartKey,
                            );
                          });
                          await _saveKeepTasks();
                        }
                      } else {
                        final list = _oneOffByDate[dateKey];
                        final idx = list?.indexWhere((x) => x.id == t.id) ?? -1;
                        if (list != null && idx >= 0) {
                          setState(() {
                            list[idx] = DailyTask(
                              id: t.id,
                              title: data.title,
                              description: data.description,
                              category: data.category,
                              points: data.points,
                              keep: false,
                              done: list[idx].done,
                              checklist: list[idx].checklist
                                  .map((c) => TaskChecklistItem(text: c.text, done: c.done))
                                  .toList(),
                            );
                          });
                          await _saveOneOffMap();
                        }
                      }
                    }
                    if (mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.emoji_emotions,
                  title: 'Change icon',
                  subtitle: 'Choose a custom or predefined icon',
                  iconColor: const Color(0xFFFF6F00),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _changeTaskIconDialog(t);
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.checklist,
                  title: 'Checklist note',
                  subtitle: t.hasChecklist
                      ? '${t.checklistDoneCount}/${t.checklistTotalCount} checked'
                      : 'Add checkbox items to this task',
                  iconColor: const Color(0xFF7C3AED),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _openChecklistNoteEditor(t);
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.copy_all,
                  title: 'Duplicate',
                  subtitle: 'Copy this task right below',
                  iconColor: const Color(0xFF009688),
                  onTap: () async {
                    String dateKeyForCopy = dateKey;
                    final copy = DailyTask(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      title: t.title,
                      description: t.description,
                      category: t.category,
                      points: t.points,
                      keep: t.keep,
                      repeatPattern: t.repeatPattern,
                      customDays: t.customDays,
                      repeatStartKey: t.keep ? dateKeyForCopy : null,
                      weeklyDays: List<int>.from(t.weeklyDays),
                      streak: 0,
                      bestStreak: 0,
                      lastDoneKey: null,
                      done: false,
                      checklist: t.checklist
                          .map((c) => TaskChecklistItem(text: c.text, done: c.done))
                          .toList(),
                      targetCount: t.targetCount,
                      completedCount: 0,
                      limitedCycleIntervalDays: t.limitedCycleIntervalDays,
                      limitedCycleStartKey: t.keep ? dateKeyForCopy : null,
                    );
                    if (t.keep) {
                      setState(() {
                        _keepTasks.add(copy);
                        _orderKeep.add(copy.id); // legacy
                      });
                      await _saveKeepTasks();
                      await _saveOrderKeep();
                    } else {
                      final list =
                      _oneOffByDate.putIfAbsent(dateKeyForCopy, () => <DailyTask>[]);
                      setState(() {
                        list.add(copy);
                        final ord =
                        _orderByDate.putIfAbsent(dateKeyForCopy, () => <String>[]);
                        ord.add(copy.id); // legacy
                      });
                      await _saveOneOffMap();
                      await _saveOrderByDate();
                    }
                    // add into combined next to original
                    _syncCombinedForDate(dateKeyForCopy);
                    final ids = _orderCombined[dateKeyForCopy]!;
                    final pos = ids.indexOf(t.id);
                    if (pos >= 0) {
                      ids.insert(pos + 1, copy.id);
                    } else {
                      ids.add(copy.id);
                    }
                    await _saveOrderCombined();
                    if (mounted) Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: 10),
                if (t.keep && !t.isLimited)
                  actionTile(
                    icon: Icons.ac_unit,
                    title: 'Freeze for today',
                    subtitle: frozenToday
                        ? 'Already frozen'
                        : (_freezeTokens > 0
                        ? 'Protect your streak'
                        : 'No tokens left'),
                    iconColor: const Color(0xFF2196F3),
                    enabled: !frozenToday && _freezeTokens > 0,
                    onTap: (!frozenToday && _freezeTokens > 0)
                        ? () async {
                      await _freezeToday(t);
                      if (mounted) Navigator.pop(ctx);
                    }
                        : null,
                  ),
                if (t.keep) const SizedBox(height: 10),
                if (t.keep)
                  actionTile(
                    icon: Icons.vertical_align_top,
                    title: 'Move to top',
                    subtitle: 'Pin this recurring task to the top',
                    iconColor: const Color(0xFF7B1FA2),
                    onTap: () async {
                      _syncCombinedForDate(dateKey);
                      setState(() {
                        _orderCombined[dateKey]!
                          ..remove(t.id)
                          ..insert(0, t.id);
                      });
                      await _saveOrderCombined();
                      if (mounted) Navigator.pop(ctx);
                    },
                  ),
                if (t.keep) const SizedBox(height: 10),
                if (t.keep)
                  actionTile(
                    icon: Icons.emoji_events,
                    title: 'Show highest streak',
                    subtitle: 'See your all-time best for this task',
                    iconColor: const Color(0xFF388E3C),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _showHighestStreak(t);
                    },
                  ),
                if (t.keep) const SizedBox(height: 10),
                if (t.keep)
                  actionTile(
                    icon: Icons.local_fire_department_outlined,
                    title: 'Reset current streak',
                    subtitle: 'Clear today’s streak progress',
                    iconColor: const Color(0xFFFF5722),
                    onTap: () async {
                      setState(() => t.streak = 0);
                      await _saveKeepTasks();
                      if (mounted) Navigator.pop(ctx);
                    },
                  ),
                if (t.keep) const SizedBox(height: 10),
                if (t.keep)
                  actionTile(
                    icon: Icons.emoji_events_outlined,
                    title: 'Reset best streak',
                    subtitle: 'Remove your all-time best streak',
                    iconColor: const Color(0xFF795548),
                    onTap: () async {
                      setState(() => t.bestStreak = 0);
                      await _saveKeepTasks();
                      if (mounted) Navigator.pop(ctx);
                    },
                  ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.delete_outline,
                  title: 'Delete',
                  subtitle: 'Remove this task permanently',
                  danger: true,
                  onTap: () async {
                    await _deleteAt(indexInOrdered, dateKey: dateKey);
                    if (mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  // ---- Icon Management for Tasks ----
  late List<IconData> _availableTaskIcons = [];

  IconData _getTaskIcon(String taskId) {
    final stored = _taskIcons[taskId];
    if (stored != null) {
      try {
        return _availableTaskIcons.firstWhere(
          (icon) => icon.codePoint == stored,
          orElse: () => Icons.check_circle_outline,
        );
      } catch (_) {
        return Icons.check_circle_outline;
      }
    }
    return Icons.check_circle_outline;
  }

  Future<void> _changeTaskIconDialog(DailyTask task) async {
    final selectedIcon = await showDialog<IconData>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.emoji_emotions,
                      color: Color(0xFFE53935),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Choose an Icon',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1F),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: Color(0xFF6F7789),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: _availableTaskIcons.length + 1,
                  itemBuilder: (_, index) {
                    // Plus button at the end
                    if (index == _availableTaskIcons.length) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _pickCustomTaskIcon(task.id, ctx),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE0E0E0),
                                width: 2.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Color(0xFFE53935),
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    }

                    final icon = _availableTaskIcons[index];
                    final isSelected = _getTaskIcon(task.id).codePoint == icon.codePoint;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, icon),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? const Color(0xFFFFEBEE) 
                                : const Color(0xFFF5F7FA),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected 
                                ? Border.all(color: const Color(0xFFE53935), width: 2.5)
                                : Border.all(color: const Color(0xFFE0E0E0), width: 1),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected 
                                ? const Color(0xFFE53935) 
                                : const Color(0xFF6F7789),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedIcon != null) {
      setState(() {
        _taskIcons[task.id] = selectedIcon.codePoint;
        // Remove custom icon when switching to predefined icon
        _taskCustomIcons.remove(task.id);
      });
      await _saveTaskIcons();
      await _saveTaskCustomIcons();
    }
  }

  Future<void> _pickCustomTaskIcon(String taskId, BuildContext dialogContext) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'task_icon_${taskId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${directory.path}/$fileName';
        
        final savedImage = await File(image.path).copy(filePath);
        
        setState(() {
          _taskCustomIcons[taskId] = savedImage.path;
          // Remove standard icon when custom image is set
          _taskIcons.remove(taskId);
        });
        
        await _saveTaskCustomIcons();
        await _saveTaskIcons();
        
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Custom icon saved!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving image: $e')),
          );
        }
      }
    }
  }

  Future<void> _showHighestStreak(DailyTask task) async {
    final best = task.bestStreak;
    final label = best == 1 ? '1 day' : '$best days';
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Color(0xFFE53935)),
            SizedBox(width: 8),
            Text('Highest streak'),
          ],
        ),
        content: Text(
          best > 0 ? 'Your best streak for this task is $label.' : 'No streak recorded yet.',
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ===============================================================
  // UI - Modern Design
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    final dateKey = _mode == DailyViewMode.today ? _todayKey() : _selectedKey();
    final ordered = _orderedTasksFor(dateKey);
    final now = DateTime.now();
    final isToday = _selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Calendar
            _buildModernHeader(context, isToday),
            
            // Task List
            Expanded(
              child: ordered.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: ordered.length,
                      onReorder: (old, newI) => _onReorder(old, newI, dateKey: dateKey),
                      buildDefaultDragHandles: false,
                      itemBuilder: (ctx, i) {
                        final task = ordered[i];
                        return _buildModernTaskCard(task, i, dateKey);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _isPastDate(dateKey, _todayKey()) 
          ? null 
          : _buildModernFAB(dateKey),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isToday) {
    final isPast = _isPastDate(_selectedKey(), _todayKey());
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title and Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isToday ? 'Today' : _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                  if (isPast) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.history, size: 14, color: Color(0xFF9CA3AF)),
                        SizedBox(width: 4),
                        Text(
                          'History (read-only)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  // Freeze Tokens
                  if (_freezeTokens > 0 && isToday) ...[
                    GestureDetector(
                      onTap: _showFreezeHelp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.ac_unit, size: 16, color: Color(0xFF2196F3)),
                            const SizedBox(width: 4),
                            Text(
                              '$_freezeTokens',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2196F3),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Points
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Color(0xFFFF9800)),
                          const SizedBox(width: 4),
                          Text(
                            '$_todayPoints',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF9800),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Menu
                  PopupMenuButton<int>(
                    icon: const Icon(Icons.more_horiz, color: Color(0xFF6F7789)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (val) {
                      if (val == 1) {
                        setState(() {
                          _mode = _mode == DailyViewMode.today
                              ? DailyViewMode.byDate
                              : DailyViewMode.today;
                          if (_mode == DailyViewMode.today) {
                            _selectedDate = DateTime.now();
                          }
                        });
                      } else if (val == 2) {
                        _pickDate();
                      } else if (val == 3) {
                        _resetAllToday();
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 1,
                        child: Text(_mode == DailyViewMode.today
                            ? 'View by date'
                            : 'Back to Today'),
                      ),
                      if (_mode == DailyViewMode.byDate)
                        const PopupMenuItem(
                          value: 2,
                          child: Text('Pick another date'),
                        ),
                      if (_mode == DailyViewMode.today)
                        const PopupMenuItem(
                          value: 3,
                          child: Text('Reset all'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mini Calendar Week View
          _buildWeekCalendar(),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final date = startOfWeek.add(Duration(days: index));
        final isSelected = date.day == _selectedDate.day &&
            date.month == _selectedDate.month &&
            date.year == _selectedDate.year;
        final isToday = date.day == now.day &&
            date.month == now.month &&
            date.year == now.year;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _mode = DailyViewMode.byDate;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFE53935)
                    : (isToday ? const Color(0xFFFFEBEE) : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _getWeekdayShort(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? const Color(0xFFE53935) : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isToday ? const Color(0xFFE53935) : const Color(0xFF1A1D1F)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  String _getWeekdayShort(int weekday) {
    const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
    return days[weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF0F4F8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a task to get started',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTaskCard(DailyTask task, int index, String dateKey) {
    final frozenToday = _wasFrozenOn(_todayKey(), task.id);
    final color = _getColorForCategory(task.category);
    final isDone = _isDoneForDate(task, dateKey);
    final isPastDate = _isPastDate(dateKey, _todayKey());

    return Container(
      key: ValueKey(task.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleDone(task, dateKey: dateKey),
          onLongPress: () => _openTaskActions(task, index, dateKey),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Drag Handle (only for today/future dates)
                if (!isPastDate)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_indicator,
                      color: Color(0xFFD1D5DB),
                      size: 20,
                    ),
                  ),
                if (!isPastDate) const SizedBox(width: 12),
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _taskCustomIcons[task.id] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_taskCustomIcons[task.id]!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          _getTaskIcon(task.id),
                          color: color,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDone
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1A1D1F),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDone
                                  ? const Color(0xFFBFC5D2)
                                  : const Color(0xFF6F7789),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (task.hasChecklist)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.checklist,
                                size: 13,
                                color: Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${task.checklistDoneCount}/${task.checklistTotalCount} checklist items done',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Task Type Badge
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: task.isLimited
                                ? const Color(0xFFFFEBEE)
                                : task.keep
                                    ? const Color(0xFFE3F2FD)
                                    : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.isLimited
                                    ? Icons.flag
                                    : task.keep ? Icons.repeat : Icons.event,
                                size: 12,
                                color: task.isLimited
                                    ? const Color(0xFFE53935)
                                    : task.keep
                                        ? const Color(0xFF2196F3)
                                        : const Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.isLimited
                                    ? '${task.completedCount}/${task.targetCount} days'
                                        '${task.isLimitedRecurring ? ' · ${task.limitedCycleLabel}' : ''}'
                                    : task.keep
                                        ? 'Recurring · ${task.repeatDisplayLabel}'
                                        : 'Daily',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: task.isLimited
                                      ? const Color(0xFFE53935)
                                      : task.keep
                                          ? const Color(0xFF2196F3)
                                          : const Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (task.keep && !task.isLimited && task.streak > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department,
                                  size: 14, color: Color(0xFFFF5722)),
                              const SizedBox(width: 4),
                              Text(
                                '${task.streak} day${task.streak > 1 ? 's' : ''} streak',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFFF5722),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (frozenToday)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.ac_unit,
                                  size: 14, color: Color(0xFF2196F3)),
                              const SizedBox(width: 4),
                              const Text(
                                'Frozen today',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Checkbox/Status
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? const Color(0xFFE53935) : Colors.transparent,
                    border: Border.all(
                      color: isDone ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getColorForCategory(String? category) {
    if (category == null) return const Color(0xFF9C27B0);
    switch (category.toLowerCase()) {
      case 'gym':
      case 'fitness':
      case 'workout':
      case 'exercise':
        return const Color(0xFFFF5722);
      case 'work':
        return const Color(0xFF2196F3);
      case 'leisure':
      case 'fun':
        return const Color(0xFFFF9800);
      case 'health':
      case 'water':
      case 'drink':
        return const Color(0xFF03A9F4);
      case 'morning':
      case 'routine':
        return const Color(0xFFFFC107);
      case 'read':
      case 'book':
        return const Color(0xFF795548);
      case 'study':
      case 'learning':
        return const Color(0xFF3F51B5);
      case 'food':
      case 'meal':
        return const Color(0xFF4CAF50);
      case 'chores':
      case 'chore':
        return const Color(0xFF607D8B);
      case 'creatin':
      case 'creatine':
        return const Color(0xFFE53935);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  /// Get default icon based on task category
  IconData _getDefaultIconForCategory(String? category) {
    if (category == null) return Icons.assignment;
    switch (category.toLowerCase()) {
      case 'gym':
      case 'fitness':
      case 'workout':
      case 'exercise':
        return Icons.fitness_center;
      case 'work':
        return Icons.work;
      case 'leisure':
      case 'fun':
        return Icons.sports;
      case 'health':
        return Icons.favorite;
      case 'water':
      case 'drink':
        return Icons.local_drink;
      case 'morning':
      case 'routine':
        return Icons.schedule;
      case 'read':
      case 'book':
        return Icons.book;
      case 'study':
      case 'learning':
        return Icons.school;
      case 'food':
      case 'meal':
        return Icons.restaurant;
      case 'chores':
      case 'chore':
        return Icons.home;
      case 'creatin':
      case 'creatine':
        return Icons.fitness_center;
      case 'skill':
        return Icons.lightbulb;
      default:
        return Icons.assignment;
    }
  }

  Widget _buildModernFAB(String dateKey) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _openCreateTaskSheet(forDateKey: dateKey),
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _ModernDatePickerDialog(
        initialDate: _selectedDate,
        onDateSelected: (picked) {
          setState(() => _selectedDate = picked);
          Navigator.of(dialogContext).pop();
        },
      ),
    );
  }

  // -- Reset all (only uncheck keep tasks today; one-offs stay untouched)
  Future<void> _resetAllToday() async {
    if (_keepTasks.isEmpty) return;
    setState(() {
      for (final t in _keepTasks) {
        t.done = false;
      }
      _recalcTodayPoints();
    });
    await _saveKeepTasks();
    await _saveProgressToday(); // 0 points
  }
}

/// ===============================================================
/// Create bottom sheet (supports scheduling date for one-offs)
/// ===============================================================
class _CreateResult {
  final DailyTask task;
  final String? dateKey; // only for keep=false
  const _CreateResult(this.task, this.dateKey);
}

class _CreateDailyTaskSheet extends StatefulWidget {
  final String defaultDateKey; // suggested date for one-offs
  const _CreateDailyTaskSheet({required this.defaultDateKey});

  @override
  State<_CreateDailyTaskSheet> createState() => _CreateDailyTaskSheetState();
}

class _CreateDailyTaskSheetState extends State<_CreateDailyTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _category;
  int _points = 1;
  bool _keep = false;
  bool _isLimited = false;
  int _targetCount = 2;
  int? _limitedCycleIntervalDays; // null = permanent; >0 = recurring cycle

  // Repeat pattern fields
  TaskRepeatPattern _repeatPattern = TaskRepeatPattern.daily;
  int _customDays = 1;
  Set<int> _weeklyDays = <int>{};

  late DateTime _scheduledDate;

  static const _suggestedCategories = [
    'Gym',
    'Work',
    'Study',
    'Leisure',
    'Skill',
    'Chores',
    'Creatine',
  ];

  @override
  void initState() {
    super.initState();
    // parse default dateKey
    final parts = widget.defaultDateKey.split('-').map(int.parse).toList();
    _scheduledDate = DateTime(parts[0], parts[1], parts[2]);
    _weeklyDays = <int>{_scheduledDate.weekday};
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isPastDate(DateTime dt) => _dateOnly(dt).isBefore(_dateOnly(DateTime.now()));

  Future<int?> _showCustomDaysDialog() async {
    final controller = TextEditingController(text: _customDays.toString());
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 40,
                  color: Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Custom Repeat Interval',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'How many days between each repeat?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6F7789),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Input Field
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  hintText: '7',
                  hintStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 16, top: 12),
                    child: Text(
                      'days',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6F7789),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
              const SizedBox(height: 28),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6F7789),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value > 0) {
                          Navigator.pop(context, value);
                        } else {
                          // Show error feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid number (1 or greater)'),
                              backgroundColor: Color(0xFFE53935),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  List<Widget> _buildLimitedCycleChips() {
    const fixedOptions = <(int?, String)>[
      (null, 'Never'),
      (7, 'Weekly'),
      (14, '2 Weeks'),
      (30, 'Monthly'),
    ];
    final fixedValues = fixedOptions.map((o) => o.$1).toList();
    final isCustom = _limitedCycleIntervalDays != null &&
        !fixedValues.contains(_limitedCycleIntervalDays);

    final chips = <Widget>[
      ...fixedOptions.map((opt) {
        final selected = _limitedCycleIntervalDays == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _limitedCycleIntervalDays = opt.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE53935) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF6F7789),
              ),
            ),
          ),
        );
      }),
      // Custom chip
      GestureDetector(
        onTap: () async {
          final days = await _showCustomDaysDialog();
          if (days != null && days > 0) {
            setState(() => _limitedCycleIntervalDays = days);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isCustom ? const Color(0xFFE53935) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustom ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Text(
            isCustom ? 'Every ${_limitedCycleIntervalDays}d' : 'Custom days...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCustom ? Colors.white : const Color(0xFF6F7789),
            ),
          ),
        ),
      ),
    ];
    return chips;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_keep && !_isLimited && _isPastDate(_scheduledDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Cannot create tasks for past dates.'),
        ),
      );
      return;
    }

    final effectiveKeep = _keep || _isLimited;
    final t = DailyTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: (_category?.trim().isEmpty ?? true) ? null : _category!.trim(),
      points: effectiveKeep && !_isLimited ? _points : 0,
      keep: effectiveKeep,
      repeatPattern: effectiveKeep && !_isLimited ? _repeatPattern : TaskRepeatPattern.daily,
      customDays: effectiveKeep && !_isLimited ? _customDays : 1,
      repeatStartKey: effectiveKeep ? widget.defaultDateKey : null,
      weeklyDays: effectiveKeep && !_isLimited
        ? ((_repeatPattern == TaskRepeatPattern.weekly_days ||
            _repeatPattern == TaskRepeatPattern.biweekly)
          ? (_weeklyDays.isEmpty ? <int>{_scheduledDate.weekday}.toList() : _weeklyDays.toList())
          : const <int>[])
        : const <int>[],
      targetCount: _isLimited ? _targetCount : null,
      completedCount: 0,
      limitedCycleIntervalDays: _isLimited ? _limitedCycleIntervalDays : null,
      limitedCycleStartKey: _isLimited ? widget.defaultDateKey : null,
    );

    Navigator.pop(context, _CreateResult(t, effectiveKeep ? null : _dateKey(_scheduledDate)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_task, color: Color(0xFFE53935), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF6F7789)),
                  )
                ],
              ),
              const SizedBox(height: 24),
              // Task Name
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g. Drink 2L water',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF6F7789)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF6F7789)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              // Category
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F7789),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedCategories.map((c) {
                  final selected = _category == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category = selected ? null : c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFE53935) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : const Color(0xFF6F7789),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Task Type Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _keep = false; _isLimited = false; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_keep && !_isLimited ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 18,
                                color: !_keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Daily',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: !_keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _keep = true; _isLimited = false; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _keep && !_isLimited ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.repeat,
                                size: 18,
                                color: _keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Recurring',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _keep = false; _isLimited = true; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLimited ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag,
                                size: 18,
                                color: _isLimited ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'X-Times',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isLimited ? Colors.white : const Color(0xFF6F7789),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLimited) ...[
                const SizedBox(height: 16),
                // Target count stepper
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Color(0xFFE53935), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'How many days?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1D1F),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _targetCount > 1
                            ? () => setState(() => _targetCount--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFFE53935),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_targetCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _targetCount++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Cycle / reset options
                const Text(
                  'Repeats after completion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7789),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildLimitedCycleChips(),
                ),
              ],
              if (_keep && !_isLimited) ...[
                const SizedBox(height: 16),
                // Points are only relevant for recurring tasks.
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Color(0xFFFF9800)),
                          const SizedBox(width: 8),
                          const Text(
                            'Points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D1F),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_points',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: 1.0 * _points,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: const Color(0xFFE53935),
                        inactiveColor: const Color(0xFFFFEBEE),
                        onChanged: (v) => setState(() => _points = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
              // Repeat pattern selector (only for recurring tasks)
              if (_keep) ...[
                const SizedBox(height: 20),
                const Text(
                  'Repeat Pattern',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7789),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskRepeatPattern.values.map((pattern) {
                    final selected = _repeatPattern == pattern;
                    return GestureDetector(
                      onTap: () async {
                        if (pattern == TaskRepeatPattern.weekly_days ||
                            pattern == TaskRepeatPattern.biweekly) {
                          setState(() {
                            _repeatPattern = pattern;
                            if (_weeklyDays.isEmpty) {
                              _weeklyDays = <int>{_scheduledDate.weekday};
                            }
                          });
                          return;
                        }
                        if (pattern == TaskRepeatPattern.custom) {
                          final customDays = await _showCustomDaysDialog();
                          if (customDays != null && customDays > 0) {
                            setState(() {
                              _repeatPattern = pattern;
                              _customDays = customDays;
                            });
                          }
                        } else {
                          setState(() => _repeatPattern = pattern);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE53935) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          pattern == TaskRepeatPattern.custom && _repeatPattern == TaskRepeatPattern.custom
                              ? 'Every $_customDays days'
                              : pattern.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : const Color(0xFF6F7789),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_repeatPattern == TaskRepeatPattern.weekly_days ||
                  _repeatPattern == TaskRepeatPattern.biweekly) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Choose weekdays',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6F7789),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _WeekdayPicker(
                    selectedDays: _weeklyDays,
                    onChanged: (days) => setState(() => _weeklyDays = days),
                  ),
                ],
              ],
              if (!_keep && !_isLimited) ...[
                const SizedBox(height: 16),
                // Date picker only for one-offs
                GestureDetector(
                  onTap: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => _ModernDatePickerDialog(
                        initialDate: _scheduledDate,
                        onDateSelected: (picked) {
                          if (_isPastDate(picked)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: Duration(seconds: 2),
                                content: Text('Cannot create tasks for past dates.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _scheduledDate = picked);
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFE53935)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scheduled Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6F7789),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1D1F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Create Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// Edit bottom sheet (keep flag not moved between models here)
/// ===============================================================
class _TaskFormData {
  final String title;
  final String? description;
  final String? category;
  final int points;
  final bool keep;
  final TaskRepeatPattern repeatPattern;
  final int customDays;
  final List<int> weeklyDays;
  final int? targetCount;
  final int? limitedCycleIntervalDays;

  const _TaskFormData({
    required this.title,
    this.description,
    this.category,
    required this.points,
    required this.keep,
    required this.repeatPattern,
    required this.customDays,
    required this.weeklyDays,
    this.targetCount,
    this.limitedCycleIntervalDays,
  });
}

class _EditDailyTaskSheet extends StatefulWidget {
  final DailyTask task;
  const _EditDailyTaskSheet({required this.task});

  @override
  State<_EditDailyTaskSheet> createState() => _EditDailyTaskSheetState();
}

class _EditDailyTaskSheetState extends State<_EditDailyTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  String? _category;
  int _points = 1;
  bool _keep = false;

  // Repeat pattern fields
  late TaskRepeatPattern _repeatPattern;
  late int _customDays;
  late Set<int> _weeklyDays;

  // Limited task fields
  int _targetCount = 2;
  int? _limitedCycleIntervalDays;

  static const _suggestedCategories = [
    'Gym',
    'Work',
    'Study',
    'Leisure',
    'Skill',
    'Chores',
    'Creatine',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    _category = widget.task.category;
    _points = widget.task.points;
    _keep = widget.task.keep;
    _repeatPattern = widget.task.repeatPattern;
    _customDays = widget.task.customDays;
    _weeklyDays = widget.task.weeklyDays.isNotEmpty
      ? widget.task.weeklyDays.toSet()
      : <int>{DateTime.now().weekday};
    _targetCount = widget.task.targetCount ?? 2;
    _limitedCycleIntervalDays = widget.task.limitedCycleIntervalDays;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<int?> _showCustomDaysDialog() async {
    final controller = TextEditingController(text: _customDays.toString());
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 40,
                  color: Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Custom Repeat Interval',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'How many days between each repeat?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6F7789),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Input Field
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  hintText: '7',
                  hintStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 16, top: 12),
                    child: Text(
                      'days',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6F7789),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
              const SizedBox(height: 28),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6F7789),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value > 0) {
                          Navigator.pop(context, value);
                        } else {
                          // Show error feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid number (1 or greater)'),
                              backgroundColor: Color(0xFFE53935),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isLimited = widget.task.isLimited;
    final weeklyDays = (!isLimited && (_repeatPattern == TaskRepeatPattern.weekly_days ||
        _repeatPattern == TaskRepeatPattern.biweekly))
        ? (_weeklyDays.isEmpty ? <int>{DateTime.now().weekday}.toList() : _weeklyDays.toList())
        : const <int>[];
    Navigator.pop(
      context,
      _TaskFormData(
        title: _titleCtrl.text.trim(),
        description:
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: (_category?.trim().isEmpty ?? true) ? null : _category!.trim(),
        points: _keep && !isLimited ? _points : 0,
        keep: _keep,
        repeatPattern: isLimited ? TaskRepeatPattern.daily : _repeatPattern,
        customDays: isLimited ? 1 : _customDays,
        weeklyDays: weeklyDays,
        targetCount: isLimited ? _targetCount : null,
        limitedCycleIntervalDays: isLimited ? _limitedCycleIntervalDays : null,
      ),
    );
  }

  List<Widget> _buildLimitedCycleChips() {
    const fixedOptions = <(int?, String)>[
      (null, 'Never'),
      (7, 'Weekly'),
      (14, '2 Weeks'),
      (30, 'Monthly'),
    ];
    final fixedValues = fixedOptions.map((o) => o.$1).toList();
    final isCustom = _limitedCycleIntervalDays != null &&
        !fixedValues.contains(_limitedCycleIntervalDays);

    return <Widget>[
      ...fixedOptions.map((opt) {
        final selected = _limitedCycleIntervalDays == opt.$1;
        return GestureDetector(
          onTap: () => setState(() => _limitedCycleIntervalDays = opt.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE53935) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF6F7789),
              ),
            ),
          ),
        );
      }),
      GestureDetector(
        onTap: () async {
          final days = await _showCustomDaysDialog();
          if (days != null && days > 0) {
            setState(() => _limitedCycleIntervalDays = days);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isCustom ? const Color(0xFFE53935) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustom ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Text(
            isCustom ? 'Every ${_limitedCycleIntervalDays}d' : 'Custom days...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCustom ? Colors.white : const Color(0xFF6F7789),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit, color: Color(0xFFE53935), size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Edit Task',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF6F7789)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF6F7789)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F7789),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _category,
                decoration: InputDecoration(
                  hintText: 'Category (optional)',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF6F7789)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                ),
                onChanged: (v) => _category = v,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedCategories.map((c) {
                  final selected = _category == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category = selected ? null : c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFE53935) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : const Color(0xFF6F7789),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (widget.task.isLimited) ...[
                // Limited task: show progress and target count editor
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag, size: 20, color: Color(0xFFE53935)),
                          const SizedBox(width: 8),
                          const Text(
                            'Target Days',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D1F),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _targetCount > 1
                                ? () => setState(() => _targetCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: const Color(0xFFE53935),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_targetCount',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE53935),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _targetCount++),
                            icon: const Icon(Icons.add_circle_outline),
                            color: const Color(0xFFE53935),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Already done: ${widget.task.completedCount}/${widget.task.targetCount} days this cycle',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6F7789),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Repeats after completion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7789),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildLimitedCycleChips(),
                ),
              ] else ...[
              if (_keep) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Color(0xFFFF9800)),
                          const SizedBox(width: 8),
                          const Text(
                            'Points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D1F),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_points',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: 1.0 * _points,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: const Color(0xFFE53935),
                        inactiveColor: const Color(0xFFFFEBEE),
                        onChanged: (v) => setState(() => _points = v.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Keep for future days'),
                  subtitle: const Text('Turn into a recurring task'),
                  activeColor: const Color(0xFFE53935),
                  value: _keep,
                  onChanged: (v) => setState(() => _keep = v),
                ),
              ),
              // Repeat pattern selector (only for recurring tasks)
              if (_keep) ...[
                const SizedBox(height: 16),
                const Text(
                  'Repeat Pattern',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7789),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskRepeatPattern.values.map((pattern) {
                    final selected = _repeatPattern == pattern;
                    return GestureDetector(
                      onTap: () async {
                        if (pattern == TaskRepeatPattern.weekly_days ||
                            pattern == TaskRepeatPattern.biweekly) {
                          setState(() {
                            _repeatPattern = pattern;
                            if (_weeklyDays.isEmpty) {
                              _weeklyDays = <int>{DateTime.now().weekday};
                            }
                          });
                          return;
                        }
                        if (pattern == TaskRepeatPattern.custom) {
                          final customDays = await _showCustomDaysDialog();
                          if (customDays != null && customDays > 0) {
                            setState(() {
                              _repeatPattern = pattern;
                              _customDays = customDays;
                            });
                          }
                        } else {
                          setState(() => _repeatPattern = pattern);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE53935) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          pattern == TaskRepeatPattern.custom && _repeatPattern == TaskRepeatPattern.custom
                              ? 'Every $_customDays days'
                              : pattern.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : const Color(0xFF6F7789),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_repeatPattern == TaskRepeatPattern.weekly_days ||
                  _repeatPattern == TaskRepeatPattern.biweekly) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Choose weekdays',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6F7789),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _WeekdayPicker(
                    selectedDays: _weeklyDays,
                    onChanged: (days) => setState(() => _weeklyDays = days),
                  ),
                ],
              ],
              ], // end else (non-limited) block
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekdayPicker extends StatelessWidget {
  const _WeekdayPicker({
    required this.selectedDays,
    required this.onChanged,
  });

  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final day = index + 1;
        final selected = selectedDays.contains(day);

        return GestureDetector(
          onTap: () {
            final next = Set<int>.from(selectedDays);
            if (selected) {
              next.remove(day);
            } else {
              next.add(day);
            }
            onChanged(next);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE53935) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Text(
              labels[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF6F7789),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ModernDatePickerDialog extends StatefulWidget {
  const _ModernDatePickerDialog({
    required this.initialDate,
    required this.onDateSelected,
  });

  final DateTime initialDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_ModernDatePickerDialog> createState() => _ModernDatePickerDialogState();
}

class _ModernDatePickerDialogState extends State<_ModernDatePickerDialog> {
  late DateTime _currentMonth;
  double? _dragStartX;
  bool _dragHandled = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(widget.initialDate.year, widget.initialDate.month, 1);
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  int _daysInMonth(DateTime month) {
    final next = DateTime(month.year, month.month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  Future<void> _jumpToMonthYear() async {
    final monthController = TextEditingController(text: _currentMonth.month.toString());
    final yearController = TextEditingController(text: _currentMonth.year.toString());

    final targetMonth = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final month = int.tryParse(monthController.text.trim());
              final year = int.tryParse(yearController.text.trim());

              if (month == null || month < 1 || month > 12) {
                setDialogState(() {
                  errorText = 'Month must be between 1 and 12';
                });
                return;
              }

              if (year == null || year < 1) {
                setDialogState(() {
                  errorText = 'Year must be greater than 0';
                });
                return;
              }

                Navigator.of(dialogContext).pop(DateTime(year, month, 1));
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Color(0xFFE53935),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Go to month',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1D1F),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: monthController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Month',
                          hintText: '1 - 12',
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE53935), width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Year',
                          hintText: 'e.g. 2026',
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE53935), width: 1.2),
                          ),
                        ),
                      ),
                      if (errorText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          errorText!,
                          style: const TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF6F7789)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Go',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    monthController.dispose();
    yearController.dispose();

    if (!mounted || targetMonth == null) return;

    setState(() {
      _currentMonth = targetMonth;
    });
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragHandled = false;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragHandled || _dragStartX == null) return;
    final delta = details.globalPosition.dx - _dragStartX!;
    const threshold = 60;
    if (delta.abs() > threshold) {
      if (delta > 0) {
        _prevMonth();
      } else {
        _nextMonth();
      }
      _dragHandled = true;
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _dragStartX = null;
    _dragHandled = false;
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final leadingEmpty = (firstWeekday + 6) % 7;
    final days = _daysInMonth(_currentMonth);
    final cells = leadingEmpty + days;
    final rows = (cells / 7).ceil();

    final localizations = MaterialLocalizations.of(context);
    final titleLabel = localizations.formatMonthYear(_currentMonth);
    final now = DateTime.now();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: _handleHorizontalDragStart,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(20),
          ),
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _jumpToMonthYear,
                            borderRadius: BorderRadius.circular(8),
                            child: Text(
                              titleLabel,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select a date or tap month to jump',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _MonthIconButton(icon: Icons.chevron_left, onTap: _prevMonth),
                    const SizedBox(width: 8),
                    _MonthIconButton(icon: Icons.chevron_right, onTap: _nextMonth, isPrimary: true),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: const [
                    _Dow('Mon'), _Dow('Tue'), _Dow('Wed'),
                    _Dow('Thu'), _Dow('Fri'), _Dow('Sat'), _Dow('Sun'),
                  ],
                ),
              ),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: rows * 7,
                  itemBuilder: (_, idx) {
                    if (idx < leadingEmpty || idx >= leadingEmpty + days) {
                      return const SizedBox.shrink();
                    }
                    final dayNum = idx - leadingEmpty + 1;
                    final date = DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                    final isToday = _dateKey(date) == _dateKey(now);
                    final isSelected = _dateKey(date) == _dateKey(widget.initialDate);

                    return GestureDetector(
                      onTap: () => widget.onDateSelected(date),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEF4444)
                              : isToday
                                  ? const Color(0xFFFEE2E2)
                                  : Colors.white,
                          border: isToday && !isSelected
                              ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
                              : null,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: isSelected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x33EF4444),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  )
                                ]
                              : const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  )
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          dayNum.toString(),
                          style: TextStyle(
                            fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.w500,
                            fontSize: 14,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? const Color(0xFFEF4444)
                                    : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// Month Button Components
/// ===============================================================
class _MonthIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _MonthIconButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFEF4444) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Icon(
          icon,
          color: isPrimary ? Colors.white : const Color(0xFF374151),
          size: 18,
        ),
      ),
    );
  }
}

class _Dow extends StatelessWidget {
  final String label;

  const _Dow(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6F7789),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
