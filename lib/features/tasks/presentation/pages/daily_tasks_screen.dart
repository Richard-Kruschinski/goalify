// Daily Tasks screen with "Congrats" overlay when all tasks are done.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/icon_mapper.dart'; // IconMapper für zentrale Icon-Verwaltung
import '../../data/repositories/tasks_repository_impl.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../../../progress/presentation/screens/congrats_screen.dart';
import '../../data/models/daily_task.dart';
import '../widgets/create_daily_task_sheet.dart';
import '../widgets/edit_daily_task_sheet.dart';
import '../../../../core/widgets/modern_date_picker_dialog.dart';

/// View modes
enum DailyViewMode { today, byDate }

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
  // All persistence goes through the repository abstraction so the storage
  // backend (local today, database/server later) can be swapped without
  // touching this screen.
  final TasksRepository _repo = TasksRepositoryImpl();

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
  int _todayDoneCount = 0;

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
    final hist = await _repo.loadProgressHistory();
    hist[key] = _todayPoints;
    await _repo.saveProgressHistory(hist);
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
    _keepTasks
      ..clear()
      ..addAll(await _repo.loadKeepTasks());

    await _normalizeRecurringAnchors();

    // MIGRATION: if any non-keep sneaked into old list, move them to TODAY bucket
    if (_keepTasks.any((t) => !t.keep)) {
      final today = _todayKey();
      final off = _keepTasks.where((t) => !t.keep).toList();
      _keepTasks.removeWhere((t) => !t.keep);
      final list = _oneOffByDate.putIfAbsent(today, () => <DailyTask>[]);
      list.addAll(off.map((t) => t..done = t.done));
      await _repo.saveKeepTasks(_keepTasks);
    }

    // Legacy orders
    _orderKeep = await _repo.loadOrderKeep();

    _orderByDate
      ..clear()
      ..addAll(await _repo.loadOrderByDate());

    // One-offs by date
    _oneOffByDate
      ..clear()
      ..addAll(await _repo.loadOneOffByDate());

    // Combined order
    _orderCombined
      ..clear()
      ..addAll(await _repo.loadOrderCombined());

    // Freeze state
    _freezeTokens = (await _repo.loadFreezeTokens()) ?? 2;
    _freezeDaysCounter = (await _repo.loadFreezeDaysCounter()) ?? 0;

    _freezeUsageByDate
      ..clear()
      ..addAll(await _repo.loadFreezeUsage());

    // Load task history (last 7 days)
    _tasksHistory
      ..clear()
      ..addAll(await _repo.loadTasksHistory());

    await _dailyRolloverIfNeeded(); // apply rollover

    // Re-apply done-at-bottom sort after loading so the order is correct
    // even if the app restarted or the stored order got out of sync.
    final todayKey = _todayKey();
    _syncCombinedForDate(todayKey); // ensure _orderCombined[today] is initialised
    _sortCompletedToBottom(todayKey);

    _recalcTodayPoints();
    _recalcTodayDoneCount();
    await _saveProgressToday();
    if (mounted) setState(() {});
  }

  Future<void> _saveKeepTasks() async {
    await _repo.saveKeepTasks(_keepTasks);
  }

  Future<void> _saveOneOffMap() async {
    await _repo.saveOneOffByDate(_oneOffByDate);
  }

  Future<void> _saveOrderKeep() async => _repo.saveOrderKeep(_orderKeep);

  Future<void> _saveOrderByDate() async => _repo.saveOrderByDate(_orderByDate);

  Future<void> _saveOrderCombined() async =>
      _repo.saveOrderCombined(_orderCombined);

  Future<void> _saveTasksHistory() async {
    await _repo.saveTasksHistory(_tasksHistory);
  }

  Future<void> _saveFreezeState() async {
    await _repo.saveFreezeState(
      tokens: _freezeTokens,
      daysCounter: _freezeDaysCounter,
      usage: _freezeUsageByDate,
    );
  }

  Future<void> _loadCreatine() async {
    _creatineDates
      ..clear()
      ..addAll(await _repo.loadCreatineDates());
  }

  Future<void> _saveCreatine() async {
    await _repo.saveCreatineDates(_creatineDates);
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
    _taskIcons
      ..clear()
      ..addAll(await _repo.loadTaskIcons());
  }

  Future<void> _saveTaskIcons() async => _repo.saveTaskIcons(_taskIcons);

  Future<void> _loadTaskCustomIcons() async {
    _taskCustomIcons
      ..clear()
      ..addAll(await _repo.loadTaskCustomIcons());
  }

  Future<void> _saveTaskCustomIcons() async =>
      _repo.saveTaskCustomIcons(_taskCustomIcons);

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
      final checkDate = _tryParseDateKey(dateKey);
      final todayDate = _tryParseDateKey(_todayKey());
      // For future dates, factor in today's check-off before the daily rollover runs
      final isFutureDate = checkDate != null && todayDate != null && checkDate.isAfter(todayDate);
      final effectiveCount = task.completedCount + (isFutureDate && task.done ? 1 : 0);

      // Cycle still has remaining completions → visible (optionally filtered by weekday)
      if (effectiveCount < task.targetCount!) {
        if (task.weeklyDays.isNotEmpty &&
            checkDate != null &&
            !task.weeklyDays.contains(checkDate.weekday)) {
          return false;
        }
        return true;
      }
      // Cycle done — permanent tasks vanish, recurring tasks hide until next cycle
      if (task.limitedCycleIntervalDays == null) return false;
      final cycleStart = _tryParseDateKey(task.limitedCycleStartKey ?? '');
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
    await _repo.saveLastRollover(_todayKey());
  }

  bool _wasFrozenOn(String dateKey, String taskId) {
    final list = _freezeUsageByDate[dateKey];
    return list != null && list.contains(taskId);
  }

  void _clearFreezeForDate(String dateKey) {
    _freezeUsageByDate.remove(dateKey);
  }

  Future<void> _dailyRolloverIfNeeded() async {
    final rawLast = await _repo.loadLastRollover();
    final todayKey = _todayKey();
    if (rawLast == todayKey) return;

    final todayDate = DateTime.now();
    final today = DateTime(todayDate.year, todayDate.month, todayDate.day);

    // If no valid rollover exists, keep legacy behavior and process only 1 day.
    final parsedLast = _tryParseDateKey(rawLast);
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
    _recalcTodayDoneCount();
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

  void _recalcTodayDoneCount() {
    _todayDoneCount = _orderedTasksFor(_todayKey()).where((t) => t.done).length;
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

    final lastShown = await _repo.loadCongratsShown();
    if (lastShown == todayKey) return;

    await _repo.saveCongratsShown(todayKey);
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
    
    final created = await showModalBottomSheet<CreateResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CreateDailyTaskSheet(
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
          _recalcTodayDoneCount();
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
      final wasChecked = t.done;
      t.done = !t.done;
      _recalcTodayPoints();
      _recalcTodayDoneCount();
      if (wasChecked) {
        // Uncheck: move task back to top so it's easily reachable
        final ids = List<String>.from(_orderCombined[dateKey] ?? const <String>[]);
        ids.remove(t.id);
        ids.insert(0, t.id);
        _orderCombined[dateKey] = ids;
        _saveOrderCombined();
      } else {
        // Check: sort completed tasks to bottom
        _sortCompletedToBottom(dateKey);
      }
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
      _recalcTodayDoneCount();
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
    if (_isPastDate(dateKey, _todayKey())) return;
    if (newIndex > oldIndex) newIndex -= 1;

    // Use visual IDs to avoid index mismatch with non-visible tasks in _orderCombined
    // (e.g. weekly/biweekly tasks not scheduled for today are in _orderCombined but hidden)
    final visibleIds = _orderedTasksFor(dateKey).map((t) => t.id).toList();
    if (oldIndex < 0 || oldIndex >= visibleIds.length || newIndex < 0 || newIndex >= visibleIds.length) return;

    final movedId = visibleIds.removeAt(oldIndex);
    visibleIds.insert(newIndex, movedId);

    // Rebuild combined order: slot in reordered visible IDs, leave non-visible IDs in place
    final combined = List<String>.from(_orderCombined[dateKey] ?? const <String>[]);
    final visibleSet = visibleIds.toSet();
    int vIdx = 0;
    for (int i = 0; i < combined.length; i++) {
      if (visibleSet.contains(combined[i])) {
        combined[i] = visibleIds[vIdx++];
      }
    }

    _orderCombined[dateKey] = combined;
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
                    final data = await showModalBottomSheet<TaskFormData>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: const Color(0xFFF5F7FA),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => EditDailyTaskSheet(task: t),
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
                            '$_todayDoneCount',
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
                                    ? '${task.completedCount + (task.done ? 1 : 0)}/${task.targetCount} days'
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
      builder: (dialogContext) => ModernDatePickerDialog(
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
      _recalcTodayDoneCount();
    });
    await _saveKeepTasks();
    await _saveProgressToday(); // 0 points
  }
}

/// ===============================================================
/// Create bottom sheet (supports scheduling date for one-offs)
/// ===============================================================
