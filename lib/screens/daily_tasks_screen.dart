// Daily Tasks screen with "Congrats" overlay when all tasks are done.
// NOTE: add this to your pubspec.yaml dependencies:
//   confetti: ^0.7.0

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../storage/local_storage.dart';

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

  // State
  final List<DailyTask> _keepTasks = []; // keep=true
  final Map<String, List<DailyTask>> _oneOffByDate = {}; // keep=false by date

  // legacy/local orders
  List<String> _orderKeep = [];
  Map<String, List<String>> _orderByDate = {};

  // combined per date
  final Map<String, List<String>> _orderCombined = {};

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

    _recalcTodayPoints();
    await _markRolloverDoneForToday();
    await _saveProgressToday();
    await _saveFreezeState();

    if (changedKeep) {
      await _saveKeepTasks();
      if (mounted) setState(() {});
    }
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
        pageBuilder: (_, __, ___) => const CongratsScreen(),
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
    });
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
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            if (t.keep)
              ListTile(
                leading: const Icon(Icons.ac_unit),
                title: const Text('Freeze for today'),
                subtitle: Text(frozenToday
                    ? 'Already frozen'
                    : (_freezeTokens > 0
                    ? 'Protect your streak'
                    : 'No tokens left')),
                enabled: !frozenToday && _freezeTokens > 0,
                onTap: (!frozenToday && _freezeTokens > 0)
                    ? () async {
                  await _freezeToday(t);
                  if (mounted) Navigator.pop(ctx);
                }
                    : null,
              ),
            if (t.keep) const Divider(height: 0),

            // Edit (for simplicity, keep flag is not changed in edit here)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                final data = await showModalBottomSheet<_TaskFormData>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
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
            ListTile(
              leading: const Icon(Icons.copy_all),
              title: const Text('Duplicate'),
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
            if (t.keep)
              ListTile(
                leading: const Icon(Icons.vertical_align_top),
                title: const Text('Move to top'),
                onTap: () async {
                  // move to top in combined for this date
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
            if (t.keep) const Divider(height: 0),
            if (t.keep)
              ListTile(
                leading: const Icon(Icons.local_fire_department_outlined),
                title: const Text('Reset current streak'),
                onTap: () async {
                  setState(() => t.streak = 0);
                  await _saveKeepTasks();
                  if (mounted) Navigator.pop(ctx);
                },
              ),
            if (t.keep)
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Reset best streak'),
                onTap: () async {
                  setState(() => t.bestStreak = 0);
                  await _saveKeepTasks();
                  if (mounted) Navigator.pop(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _deleteAt(indexInOrdered, dateKey: dateKey);
                if (mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===============================================================
  // UI
  // ===============================================================
  @override
  Widget build(BuildContext context) {
    final dateKey = _mode == DailyViewMode.today ? _todayKey() : _selectedKey();
    final ordered = _orderedTasksFor(dateKey);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        actions: [
          // View switch
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ToggleButtons(
              isSelected: [
                _mode == DailyViewMode.today,
                _mode == DailyViewMode.byDate
              ],
              onPressed: (i) {
                setState(() {
                  _mode = i == 0 ? DailyViewMode.today : DailyViewMode.byDate;
                });
              },
              borderRadius: BorderRadius.circular(8),
              constraints:
              const BoxConstraints(minHeight: 36, minWidth: 64),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Today'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('By date'),
                ),
              ],
            ),
          ),

          if (_mode == DailyViewMode.byDate)
            IconButton(
              tooltip: 'Pick date',
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now()
                      .subtract(const Duration(days: 0)), // no past planning
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
              icon: const Icon(Icons.event),
            ),

          // Freeze tokens (keep at top)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onLongPress: _showFreezeHelp,
              child: Tooltip(
                message:
                'Prevents your keep-task streak from breaking today. You earn one token each week.',
                preferBelow: false,
                child: Row(
                  children: [
                    Icon(Icons.ac_unit,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 4),
                    Text('$_freezeTokens'),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ),

          // Today points (only in Today view)
          if (_mode == DailyViewMode.today)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  'Today: $_todayPoints pts',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Reset all (today)',
            onPressed: ordered.isEmpty || _mode != DailyViewMode.today
                ? null
                : _resetAllToday,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ordered.isEmpty
          ? Center(
        child: Text(_mode == DailyViewMode.today
            ? 'No tasks for today'
            : 'No tasks on ${_selectedKey()}'),
      )
          : ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 96, top: 8),
        itemCount: ordered.length,
        onReorder: (a, b) => _onReorder(a, b, dateKey: dateKey),
        buildDefaultDragHandles: false,
        itemBuilder: (_, i) {
          final t = ordered[i];
          final isKeep = t.keep;

          return _ReorderDailyTile(
            key: ValueKey('daily_${dateKey}_${t.id}'),
            index: i,
            leadingStripColor: Theme.of(context).colorScheme.primary,
            title: Text(
              t.title,
              style: t.done
                  ? const TextStyle(
                  decoration: TextDecoration.lineThrough)
                  : null,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (t.description != null && t.description!.isNotEmpty)
                  Text(t.description!),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    if (t.category != null && t.category!.isNotEmpty)
                      Chip(
                        label: Text(t.category!),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                      ),
                    Text('${t.points} pts'),
                    if (isKeep)
                      const Chip(
                        label: Text('keeps'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                      ),
                    if (!isKeep)
                      Chip(
                        label: Text(_mode == DailyViewMode.today
                            ? 'today only'
                            : dateKey),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
            leadingCheckboxValue: t.done,
            onLeadingCheckboxChanged: (_) =>
                _toggleDone(t, dateKey: dateKey),
            onLongPress: () =>
                _openTaskActions(t, i, dateKey), // actions sheet
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isKeep) ...[
                  _FlameBadge(streak: t.streak),
                  const SizedBox(width: 4),
                  _BestBadge(best: t.bestStreak),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteAt(i, dateKey: dateKey),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateTaskSheet(
          forDateKey:
          _mode == DailyViewMode.today ? _todayKey() : _selectedKey(),
        ),
        icon: const Icon(Icons.add),
        label: Text(
          _mode == DailyViewMode.today ? 'Add for today' : 'Add for date',
        ),
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

  static const _suggestedCategories = ['Gym', 'Work', 'Study', 'Leisure', 'Skill'];

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

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('New Daily Task',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g. Drink 2L water',
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  hintText: 'Gym, Work, …',
                ),
                onChanged: (v) => _category = v,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _suggestedCategories.map((c) {
                  final selected = _category == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Points'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: 1.0 * _points,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_points',
                      onChanged: (v) => setState(() => _points = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_points',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _keep,
                onChanged: (v) => setState(() => _keep = v ?? false),
                title: const Text('Keep for future days'),
                subtitle: const Text('If disabled: task is for a specific date'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              // Date picker only for one-offs
              Opacity(
                opacity: _keep ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: _keep,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Scheduled date'),
                    subtitle: Text(
                        '${_scheduledDate.year}-${_scheduledDate.month.toString().padLeft(2, '0')}-${_scheduledDate.day.toString().padLeft(2, '0')}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                        _scheduledDate.isBefore(today) ? today : _scheduledDate,
                        firstDate: today,
                        lastDate: today.add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _scheduledDate = picked);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Create'),
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

  static const _suggestedCategories = ['Gym', 'Work', 'Study', 'Leisure', 'Skill'];

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
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Edit Task',
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                ),
                onChanged: (v) => _category = v,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _suggestedCategories.map((c) {
                  final selected = _category == c;
                  return ChoiceChip(
                    label: Text(c),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Points'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: 1.0 * _points,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '$_points',
                      onChanged: (v) => setState(() => _points = v.round()),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_points',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _keep,
                onChanged: (v) => setState(() => _keep = v ?? false),
                title: const Text('Keep for future days'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Save'),
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
        alignment: Alignment.center,
        children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _scale, curve: Curves.easeOutBack),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(20),
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
                          widget.onSeeProgress?.call();
                        },
                        child: const Text('See progress'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
