// Daily Tasks screen with "Congrats" overlay when all tasks are done.
// NOTE: add this to your pubspec.yaml dependencies:
//   confetti: ^0.7.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../storage/local_storage.dart';
import 'progress_screen.dart';

/// ===============================================================
/// Model
/// ===============================================================
class DailyTask {
  final String id;
  final String title;
  final String? description;
  final String? category; // e.g. Gym, Work, Leisure
  final int points;
  final bool keep; // true = persists across days, false = one-off for a date

  // --- Streaks (for keep tasks only) ---
  int streak; // current streak length (days)
  int bestStreak; // best ever
  String? lastDoneKey; // dateKey (yyyy-mm-dd) when last completed

  bool done; // "today" checked (resets on rollover for keep; per-date for one-offs)

  DailyTask({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.points = 1,
    this.keep = false,
    this.streak = 0,
    this.bestStreak = 0,
    this.lastDoneKey,
    this.done = false,
  });

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
  };

  factory DailyTask.fromMap(Map<String, dynamic> m) => DailyTask(
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
  );
}

/// View modes
enum DailyViewMode { today, byDate }

/// ===============================================================
/// Screen
/// ===============================================================
class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});
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

  // Shared with gym_screen: creatine intake per date
  static const _kCreatineKey = 'gym_creatine_intake_v1';

  // State
  final List<DailyTask> _keepTasks = []; // keep=true
  final Map<String, List<DailyTask>> _oneOffByDate = {}; // keep=false by date

  // legacy/local orders
  List<String> _orderKeep = [];
  Map<String, List<String>> _orderByDate = {};

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
  String _yesterdayKey() =>
      _dateKey(DateTime.now().subtract(const Duration(days: 1)));
  String _selectedKey() => _dateKey(_selectedDate);

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
    await _loadCreatine();
    // Keep-tasks (legacy list)
    final rawKeep = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
    if (rawKeep is List) {
      _keepTasks
        ..clear()
        ..addAll(
          rawKeep.map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e))),
        );
    }

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

    await _dailyRolloverIfNeeded(); // apply rollover
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
  List<DailyTask> _orderedTasksFor(String dateKey) {
    _syncCombinedForDate(dateKey);

    // Build id -> task map of all tasks visible that day
    final map = <String, DailyTask>{
      for (final t in _keepTasks) t.id: t,
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
    final last =
    await LocalStorage.loadJson(_kDailyRolloverKey, fallback: '');
    final today = _todayKey();
    if (last == today) return;

    final yesterday = _yesterdayKey();

    // --- Streak update (evaluate yesterday) ---
    for (final t in _keepTasks) {
      if (!t.keep) continue;
      if (t.done) {
        // completed yesterday
        if (t.lastDoneKey == yesterday) {
          t.streak += 1;
        } else {
          t.streak = 1;
        }
        t.lastDoneKey = yesterday;
        if (t.streak > t.bestStreak) t.bestStreak = t.streak;
      } else {
        // not done -> protect only if frozen yesterday
        if (!_wasFrozenOn(yesterday, t.id)) {
          t.streak = 0;
        }
      }
    }
    _clearFreezeForDate(yesterday);

    // --- Day change ---
    bool changedKeep = false;

    // 1) keep tasks: uncheck for a new day
    for (final t in _keepTasks) {
      if (t.keep && t.done) {
        t.done = false;
        changedKeep = true;
      }
    }

    // 2) one-offs: drop yesterday's bucket entirely (completed or not)
    if (_oneOffByDate.containsKey(yesterday)) {
      _oneOffByDate.remove(yesterday);
      _orderByDate.remove(yesterday);
      _orderCombined.remove(yesterday);
      await _saveOneOffMap();
      await _saveOrderByDate();
      await _saveOrderCombined();
    }

    // --- Freeze tokens: +1 each 7 days ---
    _freezeDaysCounter += 1;
    if (_freezeDaysCounter % 7 == 0) {
      _freezeTokens += 1;
    }

    // --- Reset combined order to original state (active first) ---
    _resetCombinedOrderToOriginal(yesterday);
    _resetCombinedOrderToOriginal(today);

    _recalcTodayPoints();
    await _markRolloverDoneForToday();
    await _saveProgressToday();
    await _saveFreezeState();
    await _saveOrderCombined();

    if (changedKeep) {
      await _saveKeepTasks();
      if (mounted) setState(() {});
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

    final allDone = all.every((t) => t.done);
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
        pageBuilder: (_, __, ___) => CongratsScreen(
          onSeeProgress: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProgressScreen()),
            );
          },
        ),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  // ===============================================================
  // Create / Toggle / Delete / Freeze / Reorder / Actions
  // ===============================================================
  Future<void> _openCreateTaskSheet({required String forDateKey}) async {
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
  }

  // NEW: single combined reorder across keep + one-off
  void _onReorder(int oldIndex, int newIndex, {required String dateKey}) {
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
          final effectiveIconColor = enabled
              ? (danger ? const Color(0xFFE53935) : iconColor)
              : const Color(0xFFBFC5D2);
          final effectiveTextColor = enabled
              ? (danger ? const Color(0xFFE53935) : const Color(0xFF1A1D1F))
              : const Color(0xFFBFC5D2);
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (danger
                                ? const Color(0xFFFFEBEE)
                                : iconColor.withOpacity(0.12))
                            .withOpacity(enabled ? 1 : 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: effectiveIconColor),
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
                              color: effectiveTextColor,
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
                    if (danger)
                      const Icon(Icons.delete_outline, color: Color(0xFFE53935))
                    else
                      const Icon(Icons.chevron_right, color: Color(0xFFCDD2D8)),
                  ],
                ),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                              streak: _keepTasks[idx].streak,
                              bestStreak: _keepTasks[idx].bestStreak,
                              lastDoneKey: _keepTasks[idx].lastDoneKey,
                              done: _keepTasks[idx].done,
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
                  icon: Icons.copy_all,
                  title: 'Duplicate',
                  subtitle: 'Copy this task right below',
                  iconColor: const Color(0xFF009688),
                  onTap: () async {
                    final copy = DailyTask(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      title: t.title,
                      description: t.description,
                      category: t.category,
                      points: t.points,
                      keep: t.keep,
                      streak: t.keep ? 0 : 0,
                      bestStreak: t.keep ? 0 : 0,
                      lastDoneKey: null,
                      done: false,
                    );
                    String dateKeyForCopy = dateKey;
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
                if (t.keep)
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
        );
      },
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
      floatingActionButton: _buildModernFAB(dateKey),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModernHeader(BuildContext context, bool isToday) {
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
              Text(
                isToday ? 'Today' : _formatDate(_selectedDate),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1F),
                ),
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
    final iconData = _getIconForCategory(task.category);
    final color = _getColorForCategory(task.category);

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
                // Drag Handle
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Color(0xFFD1D5DB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    iconData,
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
                          color: task.done
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF1A1D1F),
                          decoration: task.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (task.description != null && task.description!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            task.description!,
                            style: TextStyle(
                              fontSize: 13,
                              color: task.done
                                  ? const Color(0xFFBFC5D2)
                                  : const Color(0xFF6F7789),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      // Task Type Badge
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: task.keep
                                ? const Color(0xFFE3F2FD)
                                : const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                task.keep ? Icons.repeat : Icons.event,
                                size: 12,
                                color: task.keep
                                    ? const Color(0xFF2196F3)
                                    : const Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.keep ? 'Recurring' : 'Daily',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: task.keep
                                      ? const Color(0xFF2196F3)
                                      : const Color(0xFFFF9800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (task.keep && task.streak > 0)
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
                    color: task.done ? const Color(0xFFE53935) : Colors.transparent,
                    border: Border.all(
                      color: task.done ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                      width: 2,
                    ),
                  ),
                  child: task.done
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

  IconData _getIconForCategory(String? category) {
    if (category == null) return Icons.task_alt;
    switch (category.toLowerCase()) {
      case 'gym':
      case 'fitness':
      case 'workout':
      case 'exercise':
        return Icons.fitness_center;
      case 'work':
        return Icons.work_outline;
      case 'leisure':
      case 'fun':
        return Icons.celebration;
      case 'health':
      case 'water':
      case 'drink':
        return Icons.water_drop;
      case 'morning':
      case 'routine':
        return Icons.wb_sunny;
      case 'read':
      case 'book':
        return Icons.menu_book;
      case 'study':
      case 'learning':
        return Icons.school;
      case 'food':
      case 'meal':
        return Icons.restaurant;
      case 'chores':
      case 'chore':
        return Icons.cleaning_services;
      case 'creatin':
      case 'creatine':
        return Icons.medication_liquid;
      default:
        return Icons.task_alt;
    }
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
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
/// Reorder-Tile (with left drag strip)
/// ===============================================================
class _ReorderDailyTile extends StatelessWidget {
  final int index;
  final Color leadingStripColor;
  final Widget title;
  final Widget? subtitle;
  final bool leadingCheckboxValue;
  final ValueChanged<bool?> onLeadingCheckboxChanged;
  final VoidCallback? onLongPress;
  final Widget trailing;

  const _ReorderDailyTile({
    super.key,
    required this.index,
    required this.leadingStripColor,
    required this.title,
    this.subtitle,
    required this.leadingCheckboxValue,
    required this.onLeadingCheckboxChanged,
    this.onLongPress,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: key,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(width: 0.5, color: Color(0x1F000000))),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            ReorderableDelayedDragStartListener(
              index: index,
              child: Container(
                width: 16,
                height: 54,
                color: leadingStripColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ListTile(
                onLongPress: onLongPress,
                leading: Checkbox(
                  value: leadingCheckboxValue,
                  onChanged: onLeadingCheckboxChanged,
                ),
                dense: true,
                title: title,
                subtitle: subtitle,
                trailing: trailing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact pill-style tag used for small status labels like "keep"/"today".
class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

/// ===============================================================
/// 🔥-Badge (current streak) with black outline on number
/// ===============================================================
class _FlameBadge extends StatelessWidget {
  final int streak;
  const _FlameBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.local_fire_department, size: 26, color: cs.error),
          // Outline
          Text(
            '$streak',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black,
            ),
          ),
          // Fill
          const SizedBox.shrink(),
          Text(
            '$streak',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// 🏆-Badge (best streak) with black outline on number
/// ===============================================================
class _BestBadge extends StatelessWidget {
  final int best;
  const _BestBadge({required this.best});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.emoji_events, size: 22, color: cs.secondary),
          // Outline
          Text(
            '$best',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2
                ..color = Colors.black,
            ),
          ),
          // Fill
          Text(
            '$best',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
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
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final t = DailyTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: (_category?.trim().isEmpty ?? true) ? null : _category!.trim(),
      points: _points,
      keep: _keep,
    );

    Navigator.pop(context, _CreateResult(t, _keep ? null : _dateKey(_scheduledDate)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final today = DateTime.now();

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
              const SizedBox(height: 20),
              // Points
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
                        onTap: () => setState(() => _keep = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_keep ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 18,
                                color: !_keep ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Daily',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: !_keep ? Colors.white : const Color(0xFF6F7789),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _keep = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _keep ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.repeat,
                                size: 18,
                                color: _keep ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Recurring',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _keep ? Colors.white : const Color(0xFF6F7789),
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
              if (!_keep) ...[
                const SizedBox(height: 16),
                // Date picker only for one-offs
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _scheduledDate.isBefore(today) ? today : _scheduledDate,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _scheduledDate = picked);
                    }
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
  const _TaskFormData({
    required this.title,
    this.description,
    this.category,
    required this.points,
    required this.keep,
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
    _keep = widget.task.keep; // kept for completeness; not used to migrate
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _TaskFormData(
        title: _titleCtrl.text.trim(),
        description:
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: (_category?.trim().isEmpty ?? true) ? null : _category!.trim(),
        points: _points,
        keep: _keep,
      ),
    );
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

/// ===============================================================
/// Congrats overlay
/// ===============================================================
class CongratsScreen extends StatefulWidget {
  const CongratsScreen({
    super.key,
    this.title = 'CONGRATS!',
    this.subtitle = 'You finished all tasks for today',
    this.detail = 'Well done — keep up the streaks!',
    this.onSeeProgress,
  });

  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback? onSeeProgress;

  @override
  State<CongratsScreen> createState() => _CongratsScreenState();
}

class _CongratsScreenState extends State<CongratsScreen>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scale;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))..play();
    _scale =
    AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
      ..forward();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Stack(
        children: [
          // Centered card
          Positioned.fill(
            child: Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _scale, curve: Curves.easeOutBack),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, size: 72, color: cs.primary),
                      const SizedBox(height: 10),
                      Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          widget.title,
                          style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(widget.detail, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(context);
                              if (widget.onSeeProgress != null) {
                                widget.onSeeProgress!.call();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProgressScreen(),
                                  ),
                                );
                              }
                            },
                            child: const Text('See progress'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Confetti overlay
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                numberOfParticles: 20,
                emissionFrequency: 0.06,
                gravity: 0.35,
                minBlastForce: 6,
                maxBlastForce: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
