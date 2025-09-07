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
  final String? category; // z. B. Gym, Work, Leisure
  final int points;
  final bool keep; // true = bleibt über Tage, false = nur heute

  // --- Streaks ---
  int streak; // aktuelle Streak-Länge (Tage)
  int bestStreak; // Bestleistung
  String? lastDoneKey; // Datumsschlüssel des letzten erledigten Tages (yyyy-mm-dd)

  bool done; // "heute" abgehakt (wird beim Tageswechsel zurückgesetzt)

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
  // Storage Keys
  static const _kDailyTasksKey = 'daily_tasks_v1';
  static const _kDailyRolloverKey = 'daily_last_rollover_v1';

  // Reihenfolge, Freeze-Tokens & -Nutzung
  static const _kDailyOrderKey = 'daily_tasks_order_v1';
  static const _kFreezeTokensKey = 'daily_freeze_tokens_v1';
  static const _kFreezeDaysCounterKey = 'daily_freeze_days_counter_v1';
  static const _kFreezeUsageKey = 'daily_freeze_usage_v1'; // Map<dateKey, List<taskId>>

  // Congrats (einmal pro Tag)
  static const _kCongratsShownKey = 'daily_congrats_shown_v1';

  final List<DailyTask> _tasks = [];
  List<String> _order = [];

  int _todayPoints = 0;

  // Freeze-State
  int _freezeTokens = 0;
  int _freezeDaysCounter = 0;
  final Map<String, List<String>> _freezeUsageByDate = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load(); // lädt + prüft Tageswechsel
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _dailyRolloverIfNeeded(); // Prüfen, wenn App wieder im Vordergrund ist
    }
  }

  String _dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _todayKey() => _dateKey(DateTime.now());
  String _yesterdayKey() => _dateKey(DateTime.now().subtract(const Duration(days: 1)));

  // ---- Progress: Heutige Punkte persistieren ----
  Future<void> _saveProgressToday() async {
    final key = _todayKey();
    final raw = await LocalStorage.loadJson('progress_history_v1', fallback: {});
    final hist = Map<String, dynamic>.from(raw as Map);
    hist[key] = _todayPoints;
    await LocalStorage.saveJson('progress_history_v1', hist);
  }

  // ===============================================================
  // Laden & Speichern
  // ===============================================================
  Future<void> _load() async {
    // Tasks
    final raw = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
    if (raw is List) {
      _tasks
        ..clear()
        ..addAll(
          raw.map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e))),
        );
    }

    // Reihenfolge
    final orderRaw = await LocalStorage.loadJson(_kDailyOrderKey, fallback: []);
    _order =
    (orderRaw is List) ? orderRaw.map((e) => e.toString()).toList() : <String>[];
    _syncOrderWithTasks(); // ergänzt/aufräumt

    // Freeze-State
    _freezeTokens =
        (await LocalStorage.loadJson(_kFreezeTokensKey, fallback: null)) as int? ??
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

    await _dailyRolloverIfNeeded(); // Tageswechsel anwenden
    _recalcTodayPoints();
    await _saveProgressToday();
    if (mounted) setState(() {});
  }

  Future<void> _saveTasks() async {
    await LocalStorage.saveJson(
      _kDailyTasksKey,
      _tasks.map((t) => t.toMap()).toList(),
    );
  }

  Future<void> _saveOrder() async => LocalStorage.saveJson(_kDailyOrderKey, _order);

  Future<void> _saveFreezeState() async {
    await LocalStorage.saveJson(_kFreezeTokensKey, _freezeTokens);
    await LocalStorage.saveJson(_kFreezeDaysCounterKey, _freezeDaysCounter);
    await LocalStorage.saveJson(_kFreezeUsageKey, _freezeUsageByDate);
  }

  void _syncOrderWithTasks() {
    final ids = _tasks.map((t) => t.id).toList();
    bool changed = false;

    // fehlende anhängen
    for (final id in ids) {
      if (!_order.contains(id)) {
        _order.add(id);
        changed = true;
      }
    }
    // nicht mehr vorhandene entfernen
    final setIds = ids.toSet();
    final before = _order.length;
    _order.removeWhere((id) => !setIds.contains(id));
    if (before != _order.length) changed = true;

    if (changed) _saveOrder();
  }

  /// Sichtbar sortierte Liste:
  /// - Manuelle Reihenfolge aus `_order`
  /// - aber: offene Aufgaben zuerst, erledigte am Ende.
  /// `_order` selbst wird **nicht** verändert – so kann ein Task nach dem
  /// Ent-haken wieder an seine ursprüngliche Position springen.
  List<DailyTask> _orderedTasks() {
    _syncOrderWithTasks();

    final map = {for (final t in _tasks) t.id: t};
    final List<DailyTask> open = [];
    final List<DailyTask> done = [];

    for (final id in _order) {
      final t = map[id];
      if (t == null) continue;
      (t.done ? done : open).add(t);
    }
    return [...open, ...done];
  }

  // ===============================================================
  // Daily Rollover + Streak/Freeze-Logik
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
    final last = await LocalStorage.loadJson(_kDailyRolloverKey, fallback: '');
    final today = _todayKey();
    if (last == today) return; // schon erledigt

    final yesterday = _yesterdayKey();

    // --- Streak aktualisieren (gestern auswerten) ---
    for (final t in _tasks) {
      if (!t.keep) continue; // "nur heute" Aufgaben sind gleich weg
      if (t.done) {
        // erledigt am gestrigen Tag
        if (t.lastDoneKey == yesterday) {
          t.streak += 1;
        } else {
          t.streak = 1;
        }
        t.lastDoneKey = yesterday;
        if (t.streak > t.bestStreak) {
          t.bestStreak = t.streak;
        }
      } else {
        // nicht erledigt -> Streak schützen, wenn gefreezed; sonst reset
        if (!_wasFrozenOn(yesterday, t.id)) {
          t.streak = 0;
        }
      }
    }
    // Freeze-Verbrauch für gestern aufräumen
    _clearFreezeForDate(yesterday);

    // --- Tageswechsel: Aufgaben anpassen wie bisher ---
    bool changed = false;

    // 1) "Nur heute" -> löschen
    _tasks.removeWhere((t) {
      final remove = !t.keep;
      if (remove) {
        _order.remove(t.id);
        changed = true;
      }
      return remove;
    });

    // 2) "Bleibt" -> Haken entfernen
    for (final t in _tasks) {
      if (t.keep && t.done) {
        t.done = false;
        changed = true;
      }
    }

    // --- Freeze-Tokens: alle 7 Tage +1 ---
    _freezeDaysCounter += 1;
    if (_freezeDaysCounter % 7 == 0) {
      _freezeTokens += 1;
    }

    _recalcTodayPoints();
    await _markRolloverDoneForToday();
    await _saveProgressToday();
    await _saveFreezeState();

    if (changed) {
      await _saveTasks();
      await _saveOrder();
      if (mounted) setState(() {});
    }
  }

  // ===============================================================
  // Punkte
  // ===============================================================
  void _recalcTodayPoints() {
    _todayPoints = _tasks.where((t) => t.done).fold<int>(0, (sum, t) => sum + t.points);
  }

  // ===============================================================
  // Congrats: prüfen & ggf. anzeigen
  // ===============================================================
  Future<void> _checkAndMaybeShowCongrats() async {
    if (_tasks.isEmpty) return;

    final allDone = _tasks.every((t) => t.done);
    if (!allDone) return;

    final today = _todayKey();
    final lastShown =
    await LocalStorage.loadJson(_kCongratsShownKey, fallback: '');
    if (lastShown == today) return;

    await LocalStorage.saveJson(_kCongratsShownKey, today);
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
  Future<void> _openCreateTaskSheet() async {
    final created = await showModalBottomSheet<DailyTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreateDailyTaskSheet(),
    );

    if (!mounted) return;
    if (created != null) {
      setState(() {
        _tasks.add(created);
        _order.add(created.id);
        _recalcTodayPoints();
      });
      await _saveTasks();
      await _saveOrder();
      await _saveProgressToday();
    }
  }

  Future<void> _toggleDone(DailyTask t) async {
    setState(() {
      t.done = !t.done;
      _recalcTodayPoints();
    });
    await _saveTasks();
    await _saveProgressToday();

    // NEU: nach dem Abhaken prüfen
    await _checkAndMaybeShowCongrats();
  }

  Future<void> _deleteAt(int indexInOrdered) async {
    final list = _orderedTasks();
    if (indexInOrdered < 0 || indexInOrdered >= list.length) return;
    final t = list[indexInOrdered];

    setState(() {
      _tasks.removeWhere((x) => x.id == t.id);
      _order.remove(t.id);
      _recalcTodayPoints();
    });
    await _saveTasks();
    await _saveOrder();
    await _saveProgressToday();
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

  void _onReorder(int oldIndex, int newIndex) {
    final ordered = _orderedTasks();
    if (newIndex > oldIndex) newIndex -= 1;

    // Arbeite auf IDs der sichtbaren Reihenfolge
    final ids = ordered.map((e) => e.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);

    // Neue aktive Reihenfolge vorne einsortieren
    final set = ids.toSet();
    _order.removeWhere(set.contains);
    _order.insertAll(0, ids);

    _saveOrder();
    setState(() {});
  }

  Future<void> _openTaskActions(DailyTask t, int indexInOrdered) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
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
                  final idx = _tasks.indexWhere((x) => x.id == t.id);
                  if (idx >= 0) {
                    final updated = DailyTask(
                      id: t.id,
                      title: data.title,
                      description: data.description,
                      category: data.category,
                      points: data.points,
                      keep: data.keep,
                      streak: _tasks[idx].streak,
                      bestStreak: _tasks[idx].bestStreak,
                      lastDoneKey: _tasks[idx].lastDoneKey,
                      done: _tasks[idx].done,
                    );
                    setState(() => _tasks[idx] = updated);
                    await _saveTasks();
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
                  streak: 0,
                  bestStreak: 0,
                  lastDoneKey: null,
                  done: false,
                );
                setState(() {
                  _tasks.add(copy);
                  // hinter dem Original einfügen
                  _order.insert(indexInOrdered + 1, copy.id);
                });
                await _saveTasks();
                await _saveOrder();
                if (mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.vertical_align_top),
              title: const Text('Move to top'),
              onTap: () async {
                setState(() {
                  _order.remove(t.id);
                  _order.insert(0, t.id);
                });
                await _saveOrder();
                if (mounted) Navigator.pop(ctx);
              },
            ),
            const Divider(height: 0),
            ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: const Text('Reset current streak'),
              onTap: () async {
                setState(() => t.streak = 0);
                await _saveTasks();
                if (mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events_outlined),
              title: const Text('Reset best streak'),
              onTap: () async {
                setState(() => t.bestStreak = 0);
                await _saveTasks();
                if (mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await _deleteAt(indexInOrdered);
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
    final ordered = _orderedTasks();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        actions: [
          // Freeze-Token Anzeige
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Icon(Icons.ac_unit, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text('$_freezeTokens'),
                const SizedBox(width: 12),
              ],
            ),
          ),
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
            tooltip: 'Reset all (daily)',
            onPressed: ordered.isEmpty ? null : _resetAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ordered.isEmpty
          ? const Center(child: Text('No daily tasks yet'))
          : ReorderableListView.builder(
        padding: const EdgeInsets.only(bottom: 96, top: 8),
        itemCount: ordered.length,
        onReorder: _onReorder,
        buildDefaultDragHandles: false,
        itemBuilder: (_, i) {
          final t = ordered[i];
          final frozenToday = _wasFrozenOn(_todayKey(), t.id);

          return _ReorderDailyTile(
            key: ValueKey('daily_${t.id}'),
            index: i,
            leadingStripColor: Theme.of(context).colorScheme.primary,
            title: Text(
              t.title,
              style: t.done
                  ? const TextStyle(decoration: TextDecoration.lineThrough)
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
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    Text('${t.points} pts'),
                    if (t.keep)
                      const Chip(
                        label: Text('keeps'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
            leadingCheckboxValue: t.done,
            onLeadingCheckboxChanged: (_) => _toggleDone(t),
            onLongPress: () => _openTaskActions(t, i),
            // Trailing Actions: Streak 🔥, Best 🏆, Freeze, Delete
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FlameBadge(streak: t.streak),
                const SizedBox(width: 4),
                _BestBadge(best: t.bestStreak),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: frozenToday
                      ? 'Frozen for today'
                      : (_freezeTokens > 0
                      ? 'Freeze today (protect streak)'
                      : 'No freeze tokens left'),
                  onPressed:
                  (frozenToday || _freezeTokens <= 0) ? null : () => _freezeToday(t),
                  icon: Icon(
                    frozenToday ? Icons.ac_unit : Icons.ac_unit_outlined,
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _deleteAt(i),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTaskSheet,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  // -- Reset all (nur Haken weg, nichts löschen)
  Future<void> _resetAll() async {
    if (_tasks.isEmpty) return;
    setState(() {
      for (final t in _tasks) {
        t.done = false;
      }
      _recalcTodayPoints();
    });
    await _saveTasks();
    await _saveProgressToday(); // Tagespunkte -> 0 sichern
  }
}

/// ===============================================================
/// Reorder-Tile (mit Drag-Strip links wie im Gym-Screen)
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
/// 🔥-Badge (aktuelle Streak)
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
          Text(
            '$streak',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// 🏆-Badge (Best Streak)
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
          Text(
            '$best',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// ===============================================================
/// Bottom Sheet Formular (Create)
/// ===============================================================
class _CreateDailyTaskSheet extends StatefulWidget {
  const _CreateDailyTaskSheet();

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

  static const _suggestedCategories = ['Gym', 'Work', 'Study', 'Leisure', 'Skill'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

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

    Navigator.pop(context, t);
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
                  const Text('New Daily Task',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
                subtitle: const Text('If disabled: task is only for today'),
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
/// Bottom Sheet Formular (Edit)
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
    _keep = widget.task.keep;
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
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
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
/// Congrats Overlay (inline)
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
    _scale = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
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
