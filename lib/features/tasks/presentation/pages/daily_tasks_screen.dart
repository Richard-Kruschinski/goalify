// Daily Tasks screen with "Congrats" overlay when all tasks are done.

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/sounds/sound_controller.dart';
import '../../../../core/utils/day_cycle.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/icon_mapper.dart'; // IconMapper für zentrale Icon-Verwaltung
import '../../data/repositories/tasks_repository_impl.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../../domain/usecases/task_rules.dart';
import '../../../progress/presentation/pages/congrats_screen.dart';
import '../../data/models/daily_task.dart';
import '../description_preview.dart';
import '../widgets/create_daily_task_sheet.dart';
import '../widgets/edit_daily_task_sheet.dart';
import '../widgets/freeze_widgets.dart';
import '../widgets/checklist_editor.dart';
import '../../../../core/widgets/modern_date_picker_dialog.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/i18n/task_labels.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// View modes
enum DailyViewMode { today, byDate }

/// Sort modes for the daily task list.
/// Completed tasks always stay at the bottom regardless of mode.
enum TaskSortMode { manual, alphabetical, streak, points, type }

extension TaskSortModeStorage on TaskSortMode {
  String toStorageString() => name;

  static TaskSortMode fromString(String? raw) => TaskSortMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => TaskSortMode.manual,
      );

  /// Which way this mode sorts when it is not reversed. Modes disagree:
  /// alphabetical reads best A-Z, while streak and points are only useful
  /// with the biggest value on top. The reverse flag flips this, so the
  /// arrow shown in the UI follows from both.
  bool get isDescendingByNature => switch (this) {
        TaskSortMode.streak || TaskSortMode.points => true,
        TaskSortMode.manual ||
        TaskSortMode.alphabetical ||
        TaskSortMode.type =>
          false,
      };

  /// Reversing a hand-made order has no meaning, so [manual] is excluded.
  bool get supportsReverse => this != TaskSortMode.manual;
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

  // Task History (last 14 days) - snapshots of all tasks per date
  final Map<String, List<DailyTask>> _tasksHistory = {};

  // legacy/local orders
  List<String> _orderKeep = [];
  final Map<String, List<String>> _orderByDate = {};

  // combined per date
  final Map<String, List<String>> _orderCombined = {};

  // Creatine intake cache (yyyy-MM-dd)
  final Set<String> _creatineDates = <String>{};

  /// Task ids whose checklist is unfolded on the card (view state only).
  final Set<String> _expandedChecklists = <String>{};

  /// Task ids whose unfolded checklist also shows the done steps, or every
  /// open step past the preview count.
  final Set<String> _checklistShowDone = <String>{};
  final Set<String> _checklistShowAll = <String>{};

  int _todayPoints = 0;
  int _todayDoneCount = 0;

  // Freeze-State
  /// Tokens stop accruing at this cap. A balance above it (saved before the
  /// cap existed) is kept, it just earns nothing until it drops below.
  static const int _maxFreezeTokens = 5;
  int _freezeTokens = 0;
  int _freezeDaysCounter = 0;
  final Map<String, List<String>> _freezeUsageByDate = {};

  // View selection
  DailyViewMode _mode = DailyViewMode.today;
  DateTime _selectedDate = DayCycle.today();

  /// Fires the rollover exactly at the configured day boundary while the app
  /// stays in the foreground (e.g. someone still using the app at 2 a.m.).
  Timer? _rolloverTimer;

  // Sort mode (persisted)
  TaskSortMode _sortMode = TaskSortMode.manual;

  /// Flips the active mode's natural direction (see [TaskSortMode.isDescendingByNature]).
  /// Persisted, but reset whenever the mode changes.
  bool _sortReversed = false;

  // Helpers
  Future<void> _openFreezeSheet() async {
    final todayKey = _todayKey();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => FreezeSheet(
        frozen: _isDayFrozen(todayKey),
        tokens: _freezeTokens,
        maxTokens: _maxFreezeTokens,
        onFreeze: () async {
          await _freezeDay(todayKey);
          if (ctx.mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showPointsHelp() {
    ScaffoldMessenger.of(context).showSingleSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Text(AppLocalizations.of(context).pointsHelp),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DayCycle.revision.addListener(_onDayCycleChanged);
    _load(); // loads + applies rollover
    _scheduleRolloverTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DayCycle.revision.removeListener(_onDayCycleChanged);
    _rolloverTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _dailyRolloverIfNeeded();
      _scheduleRolloverTimer();
    }
  }

  /// The user changed the day start hour in the settings: "today" may now be a
  /// different date, so re-run the rollover and re-arm the timer.
  void _onDayCycleChanged() {
    if (!mounted) return;
    setState(() {
      if (_mode == DailyViewMode.today) _selectedDate = DayCycle.today();
    });
    _dailyRolloverIfNeeded();
    _scheduleRolloverTimer();
  }

  void _scheduleRolloverTimer() {
    _rolloverTimer?.cancel();
    // One second of slack so the timer never fires a hair before the boundary.
    final delay = DayCycle.untilNextBoundary() + const Duration(seconds: 1);
    _rolloverTimer = Timer(delay, () async {
      await _dailyRolloverIfNeeded();
      if (mounted) _scheduleRolloverTimer();
    });
  }

  String _dateKey(DateTime dt) => DayCycle.dateKey(dt);

  String _todayKey() => DayCycle.todayKey();
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

    // Sort mode
    _sortMode = TaskSortModeStorage.fromString(await _repo.loadSortMode());
    _sortReversed =
        _sortMode.supportsReverse && (await _repo.loadSortReversed() ?? false);

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
        final anchorDate = _tryParseDateKey(task.repeatStartKey ?? '') ?? DayCycle.today();
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
      // A task turned into a repeating X-task by editing has no cycle anchor
      // yet - without one its cycle never rolls over and no streak can build.
      final cycleAnchor = task.limitedCycleStartKey;
      if (task.isLimitedRecurring && (cycleAnchor == null || cycleAnchor.isEmpty)) {
        task.limitedCycleStartKey = todayKey;
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
      return _applySortMode(List<DailyTask>.from(historyTasks), dateKey);
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

    return _applySortMode(result, dateKey);
  }

  /// Apply the active sort mode to [list] (display-only, does not touch the
  /// stored manual order). Completed tasks always end up at the bottom.
  List<DailyTask> _applySortMode(List<DailyTask> list, String dateKey) {
    if (_sortMode == TaskSortMode.manual) return list;

    int byTitle(DailyTask a, DailyTask b) =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase());

    int compare(DailyTask a, DailyTask b) {
      switch (_sortMode) {
        case TaskSortMode.alphabetical:
          return byTitle(a, b);
        case TaskSortMode.streak:
          final c = b.streak.compareTo(a.streak); // descending
          return c != 0 ? c : byTitle(a, b);
        case TaskSortMode.points:
          final c = b.points.compareTo(a.points); // descending
          return c != 0 ? c : byTitle(a, b);
        case TaskSortMode.type:
          final c = taskTypeRank(a).compareTo(taskTypeRank(b));
          return c != 0 ? c : byTitle(a, b);
        case TaskSortMode.manual:
          return 0;
      }
    }

    // Reverse inside the comparator, not on the result: the completed-at-the
    // -bottom partition below has to stay the last word on the order.
    final effective = _sortReversed
        ? (DailyTask a, DailyTask b) => compare(b, a)
        : compare;
    final sorted = List<DailyTask>.from(list)..sort(effective);

    // Completed tasks always at the bottom (stable partition).
    final active = <DailyTask>[];
    final completed = <DailyTask>[];
    for (final t in sorted) {
      (_isDoneForDate(t, dateKey) ? completed : active).add(t);
    }
    return active + completed;
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

  bool _isFutureDate(String dateKey, String todayKey) {
    try {
      final parts = dateKey.split('-').map(int.parse).toList();
      final date = DateTime(parts[0], parts[1], parts[2]);
      final todayParts = todayKey.split('-').map(int.parse).toList();
      final today = DateTime(todayParts[0], todayParts[1], todayParts[2]);
      return date.isAfter(today);
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

  /// Marker in [_freezeUsageByDate] for a day frozen as a whole. Older saves
  /// hold task ids instead (one freeze per task), which still count.
  static const String _kDayFreeze = '*';

  /// Frozen days stay on record this long so past days can show them and a
  /// long X-task cycle can still see a freeze from its first days.
  static const int _freezeRecordDays = 90;

  bool _isDayFrozen(String dateKey) =>
      _freezeUsageByDate[dateKey]?.contains(_kDayFreeze) ?? false;

  bool _wasFrozenOn(String dateKey, String taskId) {
    final list = _freezeUsageByDate[dateKey];
    return list != null && (list.contains(_kDayFreeze) || list.contains(taskId));
  }

  /// Whether a freeze covered any day of [task]'s cycle that ends before
  /// [cycleEndKey] (exclusive). Used to protect a repeating X-task streak.
  bool _wasFrozenInCycle(DailyTask task, String cycleEndKey) {
    final end = _tryParseDateKey(cycleEndKey);
    if (end == null) return false;
    var day = _tryParseDateKey(task.limitedCycleStartKey ?? '') ??
        end.subtract(Duration(days: task.limitedCycleIntervalDays ?? 1));
    while (day.isBefore(end)) {
      if (_wasFrozenOn(_dateKey(day), task.id)) return true;
      day = day.add(const Duration(days: 1));
    }
    return false;
  }

  void _pruneFreezeRecords() {
    final cutoff = _dateKey(
      DayCycle.today().subtract(const Duration(days: _freezeRecordDays)),
    );
    _freezeUsageByDate.removeWhere((key, _) => _isPastDate(key, cutoff));
  }

  /// Streak-bearing tasks: plain recurring ones and repeating X-tasks.
  bool _hasStreak(DailyTask t) =>
      t.keep && (!t.isLimited || t.isLimitedRecurring);

  Future<void> _freezeDay(String dateKey) async {
    if (_freezeTokens <= 0 || _isDayFrozen(dateKey)) return;
    setState(() {
      _freezeTokens -= 1;
      _freezeUsageByDate
          .putIfAbsent(dateKey, () => <String>[])
          .add(_kDayFreeze);
    });
    _sortCompletedToBottom(dateKey);
    await _saveFreezeState();
  }

  /// Streak tasks that would lose their streak when [dayKey] is settled, i.e.
  /// what a freeze on that day would save. [nextDayKey] is the day after it.
  List<DailyTask> _streaksAtRiskOn(String dayKey, String nextDayKey) {
    final next = _tryParseDateKey(nextDayKey);
    if (next == null) return const [];
    final result = <DailyTask>[];
    for (final t in _keepTasks) {
      if (!_hasStreak(t) || t.streak <= 0 || _wasFrozenOn(dayKey, t.id)) {
        continue;
      }
      if (t.isLimitedRecurring) {
        // Only a cycle that ended with [dayKey] can still be saved by it.
        final start = _tryParseDateKey(t.limitedCycleStartKey ?? '');
        final interval = t.limitedCycleIntervalDays;
        if (start == null || interval == null) continue;
        final sinceStart = next.difference(start).inDays;
        final cycleEnded = sinceStart > 0 && sinceStart % interval == 0;
        final count = t.completedCount + (t.done ? 1 : 0);
        if (cycleEnded && count < t.targetCount!) result.add(t);
      } else if (!t.done && _isTaskDueOnDate(t, dayKey)) {
        result.add(t);
      }
    }
    return result;
  }

  /// Asks whether to spend a token on [dayKey] (yesterday) before its streaks
  /// are settled, when at least one of them would break.
  Future<void> _maybeOfferRetroFreeze(String dayKey, String nextDayKey) async {
    if (_freezeTokens <= 0 || _isDayFrozen(dayKey) || !mounted) return;
    final atRisk = _streaksAtRiskOn(dayKey, nextDayKey);
    if (atRisk.isEmpty) return;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final freeze = await showDialog<bool>(
      context: context,
      builder: (ctx) => RetroFreezeDialog(
        tasks: atRisk,
        tokens: _freezeTokens,
        maxTokens: _maxFreezeTokens,
      ),
    );
    if (freeze == true) await _freezeDay(dayKey);
  }

  /// Rollover may be triggered from several places (load, resume, timer);
  /// while one runs - possibly waiting on the retro-freeze dialog - the others
  /// join it instead of settling the same days twice.
  Future<void>? _rolloverInFlight;

  Future<void> _dailyRolloverIfNeeded() {
    return _rolloverInFlight ??=
        _runDailyRollover().whenComplete(() => _rolloverInFlight = null);
  }

  Future<void> _runDailyRollover() async {
    final rawLast = await _repo.loadLastRollover();
    final todayKey = _todayKey();
    if (rawLast == todayKey) return;

    final today = DayCycle.today();

    // If no valid rollover exists, keep legacy behavior and process only 1 day.
    final parsedLast = _tryParseDateKey(rawLast);
    var cursor = parsedLast ?? today.subtract(const Duration(days: 1));
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    // Only yesterday can still be frozen after the fact; older missed days
    // settle as they are.
    final yesterdayKey = _dateKey(today.subtract(const Duration(days: 1)));
    if (_dateKey(cursor) == yesterdayKey) {
      await _maybeOfferRetroFreeze(yesterdayKey, todayKey);
    }

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

        // Limited tasks: cycle reset + completion count. Their streak counts
        // completed *cycles*, not days, so it is only evaluated when one ends.
        if (t.isLimited) {
          // Check if a new cycle starts on this day
          if (t.limitedCycleIntervalDays != null) {
            final cycleStart = _tryParseDateKey(t.limitedCycleStartKey ?? '');
            final dayDate = _tryParseDateKey(dayKey);
            if (cycleStart != null && dayDate != null) {
              final daysSince = dayDate.difference(cycleStart).inDays;
              if (daysSince > 0 && daysSince % t.limitedCycleIntervalDays! == 0) {
                applyFinishedLimitedCycle(
                  t,
                  cycleEndKey: dayKey,
                  frozen: _wasFrozenInCycle(t, dayKey),
                );
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
          } else if (t.streak > 0) {
            // The frozen day bridges the streak, so the next completion still
            // counts as consecutive instead of starting over at 1.
            t.lastDoneKey = dayKey;
          }
        }
      }

      // --- Day change ---
      // 1) keep tasks: uncheck for the next day
      for (final t in _keepTasks) {
        if (t.keep && t.done) {
          t.done = false;
          changedKeep = true;
        }
        // Steps start fresh with the task; the history snapshot above keeps
        // what was checked on the day.
        if (t.keep && t.checklist.any((c) => c.done)) {
          for (final c in t.checklist) {
            c.done = false;
          }
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

      // --- Freeze tokens: +1 each 7 days, up to the cap ---
      // The counter keeps running at the cap so the weekly rhythm holds;
      // that week's token is simply forfeited.
      _freezeDaysCounter += 1;
      if (_freezeDaysCounter % 7 == 0 && _freezeTokens < _maxFreezeTokens) {
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
    _pruneFreezeRecords();

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

  /// Remove history entries older than 14 days
  /// Keeps: today + 14 previous days, so the weekly review can always compare
  /// the current week against the full previous week (Mon-Sun).
  Future<void> _cleanupOldHistory() async {
    final today = DayCycle.today();
    final cutoffDate = today.subtract(const Duration(days: 15));
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

    // A frozen day protects streaks but is not a finished day, so only real
    // check-offs count here.
    final allDone = all.every((t) => t.done);
    if (!allDone) return;

    final lastShown = await _repo.loadCongratsShown();
    if (lastShown == todayKey) return;

    await _repo.saveCongratsShown(todayKey);
    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        // The screen dims the page itself; a grey barrier would wash out the colors.
        barrierColor: Colors.transparent,
        pageBuilder: (_, _, _) => CongratsScreen(
          tasksDone: all.length,
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
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).cannotCreatePastTasks),
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
      }
      // keep the new task below existing active tasks but above completed ones
      _sortCompletedToBottom(key);
      await _saveOrderCombined();
      if (mounted) setState(() {});
    }
  }

  Future<void> _toggleDone(DailyTask t, {required String dateKey}) async {
    // Block changes to past dates (read-only history)
    if (_isPastDate(dateKey, _todayKey())) {
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).cannotModifyPastTasks),
        ),
      );
      return;
    }
    
    // Block changes to future dates (read-only preview)
    if (_isFutureDate(dateKey, _todayKey())) {
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).cannotModifyFutureTasks),
        ),
      );
      return;
    }

    if (t.keep && dateKey != _todayKey()) {
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).recurringOnlyToday),
        ),
      );
      return;
    }
    final wasChecked = t.done;
    if (!wasChecked) {
      // Checking off a task: play the completion sound (respects settings)
      context.read<SoundController>().playEvent(SoundEvent.dailyTaskCompleted);
    }
    setState(() {
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
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).cannotDeletePastTasks),
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

  Future<void> _saveTaskList(DailyTask task) async {
    if (task.keep) {
      await _saveKeepTasks();
    } else {
      await _saveOneOffMap();
    }
  }

  /// Edits the steps of [task]. Every change saves right away; checking steps
  /// off happens on the task card.
  Future<void> _openChecklistNoteEditor(DailyTask task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.bg(context),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final l10n = AppLocalizations.of(ctx);
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.checklistNote,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink(ctx),
                          ),
                        ),
                      ),
                      if (task.hasChecklist)
                        Text(
                          l10n.checklistProgress(
                            task.checklistDoneCount,
                            task.checklistTotalCount,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted(ctx),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: AppColors.muted(ctx)),
                  ),
                  const SizedBox(height: 16),
                  if (!task.hasChecklist) ...[
                    Text(
                      l10n.checklistEmpty,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.muted(ctx),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ChecklistEditor(
                    items: task.checklist,
                    autofocus: !task.hasChecklist,
                    onChanged: () {
                      setSheetState(() {});
                      if (mounted) setState(() {});
                      _saveTaskList(task);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.chip(ctx),
                        foregroundColor: AppColors.ink(ctx),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.done),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Ticks one step on the card. Finishing the last step completes the task,
  /// unticking a step of a completed task reopens it.
  Future<void> _toggleChecklistItem(
    DailyTask task,
    TaskChecklistItem item,
    String dateKey,
  ) async {
    final todayKey = _todayKey();
    if (dateKey != todayKey) {
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            _isPastDate(dateKey, todayKey)
                ? AppLocalizations.of(context).cannotModifyPastTasks
                : AppLocalizations.of(context).cannotModifyFutureTasks,
          ),
        ),
      );
      return;
    }

    setState(() => item.done = !item.done);
    await _saveTaskList(task);

    final allDone = task.checklist.every((c) => c.done);
    if (allDone != task.done) {
      await _toggleDone(task, dateKey: dateKey);
    }
  }

  // NEW: single combined reorder across keep + one-off
  void _onReorder(int oldIndex, int newIndex, {required String dateKey}) {
    if (_isPastDate(dateKey, _todayKey())) return;
    // Manual reordering only makes sense in manual sort mode.
    if (_sortMode != TaskSortMode.manual) return;
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
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          duration: Duration(seconds: 2),
          content: Text(AppLocalizations.of(context).pastTasksReadOnly),
        ),
      );
      return;
    }
    
    final frozenToday = _isDayFrozen(_todayKey());

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget actionTile({
          required IconData icon,
          required String title,
          String? subtitle,
          Color? iconColor,
          VoidCallback? onTap,
          bool danger = false,
          bool enabled = true,
        }) {
          final foreground = enabled
              ? (danger ? AppColors.accent(context) : iconColor ?? AppColors.ink(context))
              : AppColors.faint(context);
          final textColor = enabled
              ? (danger ? AppColors.accent(context) : AppColors.ink(context))
              : AppColors.faint(context);
          final bgColor = danger
              ? AppColors.accentSoft(context)
              : (iconColor ?? AppColors.ink(context)).withOpacity(0.12);

          return Opacity(
            opacity: enabled ? 1 : 0.6,
            child: InkWell(
              onTap: enabled ? onTap : null,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow(context),
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
                                    ? AppColors.muted(context)
                                    : AppColors.faint(context),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      danger ? Icons.delete_outline : Icons.chevron_right,
                      color: danger ? AppColors.accent(context) : Color(0xFFCDD2D8),
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
                          color: AppColors.accentSoft(context),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.settings, color: AppColors.accent(context)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context).taskActions,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                actionTile(
                  icon: Icons.edit,
                  title: AppLocalizations.of(context).edit,
                  subtitle: AppLocalizations.of(context).editTaskSubtitle,
                  iconColor: const Color(0xFF3F51B5),
                  onTap: () async {
                    final data = await showModalBottomSheet<TaskFormData>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: AppColors.bg(context),
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
                              checklist: data.checklist,
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
                              checklist: data.checklist,
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
                  title: AppLocalizations.of(context).changeIcon,
                  subtitle: AppLocalizations.of(context).changeIconSubtitle,
                  iconColor: const Color(0xFFFF6F00),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _changeTaskIconDialog(t);
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.checklist,
                  title: AppLocalizations.of(context).checklistNote,
                  subtitle: t.hasChecklist
                      ? AppLocalizations.of(context).checklistProgress(t.checklistDoneCount, t.checklistTotalCount)
                      : AppLocalizations.of(context).checklistNoteSubtitle,
                  iconColor: AppColors.inkSoft(context),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _openChecklistNoteEditor(t);
                  },
                ),
                const SizedBox(height: 10),
                actionTile(
                  icon: Icons.copy_all,
                  title: AppLocalizations.of(context).duplicate,
                  subtitle: AppLocalizations.of(context).duplicateSubtitle,
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
                if (_hasStreak(t))
                  actionTile(
                    icon: Icons.ac_unit,
                    title: AppLocalizations.of(context).freezeForToday,
                    subtitle: frozenToday
                        ? AppLocalizations.of(context).alreadyFrozen
                        : (_freezeTokens > 0
                        ? AppLocalizations.of(context).protectYourStreak
                        : AppLocalizations.of(context).noTokensLeft),
                    iconColor: AppColors.info(context),
                    enabled: !frozenToday && _freezeTokens > 0,
                    onTap: (!frozenToday && _freezeTokens > 0)
                        ? () async {
                      await _freezeDay(_todayKey());
                      if (mounted) Navigator.pop(ctx);
                    }
                        : null,
                  ),
                if (t.keep) const SizedBox(height: 10),
                if (t.keep)
                  actionTile(
                    icon: Icons.vertical_align_top,
                    title: AppLocalizations.of(context).moveToTop,
                    subtitle: AppLocalizations.of(context).moveToTopSubtitle,
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
                    title: AppLocalizations.of(context).showHighestStreak,
                    subtitle: AppLocalizations.of(context).showHighestStreakSubtitle,
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
                    title: AppLocalizations.of(context).resetCurrentStreak,
                    subtitle: AppLocalizations.of(context).resetCurrentStreakSubtitle,
                    iconColor: AppColors.warning(context),
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
                    title: AppLocalizations.of(context).resetBestStreak,
                    subtitle: AppLocalizations.of(context).resetBestStreakSubtitle,
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
                  title: AppLocalizations.of(context).delete,
                  subtitle: AppLocalizations.of(context).deleteTaskSubtitle,
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
            color: AppColors.card(context),
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
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.emoji_emotions,
                      color: AppColors.accent(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).chooseAnIcon,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink(context),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: AppColors.muted(context),
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
                              color: AppColors.bg(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border(context),
                                width: 2.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppColors.accent(context),
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
                                ? AppColors.accentSoft(context) 
                                : AppColors.bg(context),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected 
                                ? Border.all(color: AppColors.accent(context), width: 2.5)
                                : Border.all(color: AppColors.border(context), width: 1),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected 
                                ? AppColors.accent(context) 
                                : AppColors.muted(context),
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
          ScaffoldMessenger.of(context).showSingleSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).customIconSaved)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSingleSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).errorSavingImage(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showHighestStreak(DailyTask task) async {
    final best = task.bestStreak;
    final label = task.isLimitedRecurring
        ? AppLocalizations.of(context).streakCycleUnitCount(best)
        : AppLocalizations.of(context).streakDayCount(best);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: AppColors.accent(context)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context).highestStreak),
          ],
        ),
        content: Text(
          best > 0
              ? AppLocalizations.of(context).bestStreakIs(label)
              : AppLocalizations.of(context).noStreakYet,
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).close),
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
    final now = DayCycle.today();
    final isToday = _selectedDate.day == now.day &&
        _selectedDate.month == now.month &&
        _selectedDate.year == now.year;

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header with Calendar
            _buildModernHeader(context, isToday),

            if (_isDayFrozen(dateKey))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: FrostBanner(
                  subtitle: _isPastDate(dateKey, _todayKey())
                      ? AppLocalizations.of(context).dayFrozenPastSubtitle
                      : AppLocalizations.of(context).dayFrozenTodaySubtitle,
                ),
              ),

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
        color: AppColors.card(context),
        boxShadow: AppColors.cardShadow(context),
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
                    isToday
                        ? AppLocalizations.of(context).todayTitle
                        : _formatDate(_selectedDate),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(context),
                    ),
                  ),
                  if (isPast) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.history, size: 14, color: AppColors.faint(context)),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).historyReadOnly,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.faint(context),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ] else if (!isToday) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.update, size: 14, color: AppColors.faint(context)),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context).futureReadOnly,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.faint(context),
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
                  if (isToday &&
                      (_freezeTokens > 0 || _isDayFrozen(_todayKey()))) ...[
                    GestureDetector(
                      onTap: _openFreezeSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isDayFrozen(_todayKey())
                                ? AppColors.info(context).withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.ac_unit, size: 16, color: AppColors.info(context)),
                            const SizedBox(width: 4),
                            Text(
                              '$_freezeTokens',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.info(context),
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
                    GestureDetector(
                      onTap: _showPointsHelp,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft(context),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, size: 16, color: AppColors.warning(context)),
                            const SizedBox(width: 4),
                            Text(
                              '$_todayDoneCount',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Sort menu
                  PopupMenuButton<TaskSortMode>(
                    icon: Icon(
                      _sortDirectionIcon,
                      color: _sortMode == TaskSortMode.manual
                          ? AppColors.muted(context)
                          : AppColors.accent(context),
                    ),
                    tooltip: AppLocalizations.of(context).sortTasks,
                    color: AppColors.card(context),
                    surfaceTintColor: AppColors.card(context),
                    elevation: AppColors.isDark(context) ? 0 : 10,
                    shadowColor: const Color(0x29000000),
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: _setSortMode,
                    itemBuilder: (_) => [
                      _buildSortMenuItem(
                        mode: TaskSortMode.manual,
                        icon: Icons.drag_indicator,
                        label: AppLocalizations.of(context).sortManual,
                      ),
                      _buildSortMenuItem(
                        mode: TaskSortMode.alphabetical,
                        icon: Icons.sort_by_alpha,
                        label: AppLocalizations.of(context).sortAlphabetical,
                      ),
                      _buildSortMenuItem(
                        mode: TaskSortMode.streak,
                        icon: Icons.local_fire_department,
                        label: AppLocalizations.of(context).sortByStreak,
                      ),
                      _buildSortMenuItem(
                        mode: TaskSortMode.points,
                        icon: Icons.star_outline,
                        label: AppLocalizations.of(context).sortByPoints,
                      ),
                      _buildSortMenuItem(
                        mode: TaskSortMode.type,
                        icon: Icons.category_outlined,
                        label: AppLocalizations.of(context).sortByType,
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Menu
                  PopupMenuButton<int>(
                    icon: Icon(Icons.more_horiz, color: AppColors.muted(context)),
                    color: AppColors.card(context),
                    surfaceTintColor: AppColors.card(context),
                    elevation: AppColors.isDark(context) ? 0 : 10,
                    shadowColor: const Color(0x29000000),
                    offset: const Offset(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (val) {
                      if (val == 1) {
                        if (_mode == DailyViewMode.today) {
                          _pickDate();
                        } else {
                          setState(() {
                            _mode = DailyViewMode.today;
                            _selectedDate = DayCycle.today();
                          });
                        }
                      } else if (val == 2) {
                        _pickDate();
                      } else if (val == 3) {
                        _resetAllToday();
                      }
                    },
                    itemBuilder: (_) => [
                      _buildHeaderMenuItem(
                        value: 1,
                        icon: _mode == DailyViewMode.today
                            ? Icons.calendar_month
                            : Icons.today,
                        label: _mode == DailyViewMode.today
                            ? AppLocalizations.of(context).viewByDate
                            : AppLocalizations.of(context).backToToday,
                      ),
                      if (_mode == DailyViewMode.byDate)
                        _buildHeaderMenuItem(
                          value: 2,
                          icon: Icons.event,
                          label: AppLocalizations.of(context).pickAnotherDate,
                        ),
                      if (_mode == DailyViewMode.today)
                        _buildHeaderMenuItem(
                          value: 3,
                          icon: Icons.restart_alt,
                          label: AppLocalizations.of(context).resetAll,
                          destructive: true,
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

  /// Whether the list currently runs biggest/last value first.
  bool get _sortIsDescending =>
      _sortMode.isDescendingByNature != _sortReversed;

  /// Arrow for the active sort direction. Direction rides on the icon shape,
  /// not on colour: colour already distinguishes "sorting active" (accent)
  /// from "custom order" (muted), and the app's blue belongs to freeze tokens.
  IconData get _sortDirectionIcon => !_sortMode.supportsReverse
      ? Icons.swap_vert
      : (_sortIsDescending ? Icons.arrow_downward : Icons.arrow_upward);

  /// Picking the mode that is already active flips its direction; picking a
  /// different one starts from that mode's natural direction again, so
  /// "reversed" never carries over into a mode where it would mean something
  /// else.
  Future<void> _setSortMode(TaskSortMode mode) async {
    final reversed = mode == _sortMode
        ? (mode.supportsReverse && !_sortReversed)
        : false;
    if (mode == _sortMode && reversed == _sortReversed) return;

    setState(() {
      _sortMode = mode;
      _sortReversed = reversed;
    });
    await _repo.saveSortMode(mode.toStorageString());
    await _repo.saveSortReversed(reversed);
  }

  PopupMenuItem<TaskSortMode> _buildSortMenuItem({
    required TaskSortMode mode,
    required IconData icon,
    required String label,
  }) {
    final selected = _sortMode == mode;
    final color = selected ? AppColors.accent(context) : AppColors.inkSoft(context);
    return PopupMenuItem<TaskSortMode>(
      value: mode,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected ? AppColors.accentSoft(context) : AppColors.chip(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.accent(context) : AppColors.ink(context),
              ),
            ),
          ),
          // The arrow doubles as the hint that tapping again flips it.
          if (selected)
            Icon(
              mode.supportsReverse ? _sortDirectionIcon : Icons.check,
              size: 18,
              color: AppColors.accent(context),
            ),
        ],
      ),
    );
  }

  PopupMenuItem<int> _buildHeaderMenuItem({
    required int value,
    required IconData icon,
    required String label,
    bool destructive = false,
  }) {
    final accent = destructive ? AppColors.accent(context) : AppColors.inkSoft(context);
    return PopupMenuItem<int>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: destructive ? AppColors.accentSoft(context) : AppColors.chip(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: destructive ? AppColors.accent(context) : AppColors.ink(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCalendar() {
    final now = DayCycle.today();
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
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent(context)
                    : (isToday ? AppColors.accentSoft(context) : Colors.transparent),
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
                          : (isToday ? AppColors.accent(context) : AppColors.faint(context)),
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
                          : (isToday ? AppColors.accent(context) : AppColors.ink(context)),
                    ),
                  ),
                  // Fixed slot so frozen and plain days keep the same height.
                  SizedBox(
                    height: 14,
                    child: _isDayFrozen(_dateKey(date))
                        ? Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.ac_unit,
                              size: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.info(context),
                            ),
                          )
                        : null,
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
    return localizedWeekdayShort(
        weekday, Localizations.localeOf(context).toString());
  }

  String _formatDate(DateTime date) {
    return DateFormat.MMMMd(Localizations.localeOf(context).toString())
        .format(date);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.chip(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.faint(context),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noTasksYet,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.ink(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).addTaskToStart,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.faint(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Progress strip (one segment per step) that unfolds into the steps, so
  /// they can be checked off right on the card.
  Widget _buildChecklistOnCard(DailyTask task, String dateKey) {
    final expanded = _expandedChecklists.contains(task.id);
    final accent = AppColors.accent(context);
    final done = task.checklistDoneCount;
    final total = task.checklistTotalCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            if (!_expandedChecklists.remove(task.id)) {
              _expandedChecklists.add(task.id);
            }
          }),
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < total; i++) ...[
                        if (i > 0) const SizedBox(width: 3),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 4,
                            decoration: BoxDecoration(
                              color: task.checklist[i].done
                                  ? accent
                                  : AppColors.border(context),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$done/$total',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted(context),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.expand_more,
                    size: 18,
                    color: AppColors.muted(context),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded) ..._buildChecklistRows(task, dateKey),
      ],
    );
  }

  /// Open steps come first and at most [_checklistPreviewCount] of them show
  /// until "n more" is tapped; done steps stay folded behind "n done". A
  /// footer row collapses everything again, so long-term lists stay short.
  static const int _checklistPreviewCount = 5;

  List<Widget> _buildChecklistRows(DailyTask task, String dateKey) {
    final l10n = AppLocalizations.of(context);
    final open = task.checklist.where((c) => !c.done).toList();
    final done = task.checklist.where((c) => c.done).toList();
    final showAll = _checklistShowAll.contains(task.id);
    final showDone = _checklistShowDone.contains(task.id);
    final visibleOpen = showAll || open.length <= _checklistPreviewCount
        ? open
        : open.take(_checklistPreviewCount).toList();
    final hiddenOpen = open.length - visibleOpen.length;

    void toggle(Set<String> set) => setState(() {
      if (!set.remove(task.id)) set.add(task.id);
    });

    Widget footerLink(String label, IconData icon, VoidCallback onTap) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted(context),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 2),
              Icon(icon, size: 16, color: AppColors.muted(context)),
            ],
          ),
        ),
      );
    }

    return [
      for (final item in visibleOpen) _buildChecklistRow(task, item, dateKey),
      if (showDone)
        for (final item in done) _buildChecklistRow(task, item, dateKey),
      Row(
        children: [
          if (hiddenOpen > 0)
            footerLink(
              l10n.checklistMore(hiddenOpen),
              Icons.expand_more,
              () => toggle(_checklistShowAll),
            ),
          if (hiddenOpen > 0 && done.isNotEmpty) const SizedBox(width: 16),
          if (done.isNotEmpty)
            footerLink(
              l10n.checklistShowDone(done.length),
              showDone ? Icons.expand_less : Icons.expand_more,
              () => toggle(_checklistShowDone),
            ),
          const Spacer(),
          footerLink(
            l10n.checklistCollapse,
            Icons.expand_less,
            () => setState(() => _expandedChecklists.remove(task.id)),
          ),
        ],
      ),
    ];
  }

  Widget _buildChecklistRow(
    DailyTask task,
    TaskChecklistItem item,
    String dateKey,
  ) {
    final accent = AppColors.accent(context);
    return GestureDetector(
      key: ObjectKey(item),
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleChecklistItem(task, item, dateKey),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.done ? accent : Colors.transparent,
                border: Border.all(
                  color: item.done ? accent : AppColors.faint(context),
                  width: 1.5,
                ),
              ),
              child: item.done
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: item.done
                      ? AppColors.faint(context)
                      : AppColors.ink(context),
                  decoration: item.done ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTaskCard(DailyTask task, int index, String dateKey) {
    final dayFrozen = _isDayFrozen(dateKey);
    final streakFrozen = _hasStreak(task) && _wasFrozenOn(dateKey, task.id);
    final color = _getColorForCategory(task.category);
    final isDone = _isDoneForDate(task, dateKey);
    final isPastDate = _isPastDate(dateKey, _todayKey());

    return Container(
      key: ValueKey(task.id),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        // A frozen day lays the same thin frost edge on every card.
        border: Border.all(
          color: dayFrozen
              ? AppColors.info(context).withValues(alpha: 0.35)
              : Colors.transparent,
        ),
        boxShadow: AppColors.cardShadow(context),
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
                // Drag Handle (only for today/future dates and manual sort)
                if (!isPastDate && _sortMode == TaskSortMode.manual) ...[
                  ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_indicator,
                      color: AppColors.border(context),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
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
                              ? AppColors.faint(context)
                              : AppColors.ink(context),
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            descriptionPreview(task.description!),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDone
                                  ? AppColors.faint(context)
                                  : AppColors.muted(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (task.hasChecklist)
                        _buildChecklistOnCard(task, dateKey),
                      // Task Type Badge
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: task.isLimited
                                ? AppColors.accentSoft(context)
                                : task.keep
                                    ? AppColors.chip(context)
                                    : AppColors.warningSoft(context),
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
                                    ? AppColors.accent(context)
                                    : task.keep
                                        ? AppColors.muted(context)
                                        : AppColors.warning(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.isLimited
                                    ? AppLocalizations.of(context).limitedDays(
                                            '${task.completedCount + (task.done ? 1 : 0)}',
                                            '${task.targetCount}')
                                        .toString() +
                                        (task.isLimitedRecurring
                                            ? ' · ${localizedCycleLabel(AppLocalizations.of(context), task)}'
                                            : '')
                                    : task.keep
                                        ? AppLocalizations.of(context).recurringDot(
                                            localizedRepeatLabel(
                                                AppLocalizations.of(context),
                                                Localizations.localeOf(context).toString(),
                                                task))
                                        : AppLocalizations.of(context).dailyLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: task.isLimited
                                      ? AppColors.accent(context)
                                      : task.keep
                                          ? AppColors.muted(context)
                                          : AppColors.warning(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Repeating X-tasks count completed cycles, plain
                      // recurring ones count days - hence the two labels.
                      if (task.keep &&
                          (!task.isLimited || task.isLimitedRecurring) &&
                          task.streak > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Builder(builder: (context) {
                            final l10n = AppLocalizations.of(context);
                            final label = task.isLimitedRecurring
                                ? l10n.streakCycleCount(task.streak)
                                : l10n.streakCount(task.streak);
                            // On a frozen day the flame turns to frost: the
                            // streak is held, not growing.
                            final tone = streakFrozen
                                ? AppColors.info(context)
                                : AppColors.warning(context);
                            return Row(
                              children: [
                                Icon(
                                  streakFrozen
                                      ? Icons.ac_unit
                                      : Icons.local_fire_department,
                                  size: 14,
                                  color: tone,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  streakFrozen
                                      ? l10n.streakProtected(label)
                                      : label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: tone,
                                  ),
                                ),
                              ],
                            );
                          }),
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
                    color: isDone ? AppColors.accent(context) : Colors.transparent,
                    border: Border.all(
                      color: isDone ? AppColors.accent(context) : AppColors.border(context),
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
        return AppColors.accent(context);
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
        color: AppColors.accent(context),
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppColors.cardShadow(context),
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
          setState(() {
            _selectedDate = picked;
            _mode = DailyViewMode.byDate;
          });
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