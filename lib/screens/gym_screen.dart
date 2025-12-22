import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // rootBundle, SystemChrome, DeviceOrientation
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../storage/local_storage.dart'; // saveJson/loadJson

enum ViewMode { byExercise, byDay }

const List<String> kSuggestedWorkdays = <String>[
  'Push', 'Pull', 'Leg', 'Arm', 'Upper Body', 'Lower Body',
];

IconData _iconFromString(String? name) {
  switch (name) {
    case 'upload':
      return Icons.upload;
    case 'accessibility':
      return Icons.accessibility;
    case 'accessibility_new':
      return Icons.accessibility_new;
    case 'align_vertical_bottom':
      return Icons.align_vertical_bottom;
    case 'fitness_center':
    default:
      return Icons.fitness_center;
  }
}

class Workout {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final List<String> muscles;

  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.muscles = const [],
  });

  factory Workout.fromJson(Map<String, dynamic> m) => Workout(
    id: m['id'] as String,
    name: m['name'] as String,
    description: m['description'] as String,
    icon: _iconFromString(m['icon'] as String),
    muscles: (m['muscles'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

class WorkoutLog {
  final DateTime dateTime;
  final double weightKg;
  final int sets;
  final String day;
  final bool isDropset;
  final List<double> extraSetWeights;

  const WorkoutLog({
    required this.dateTime,
    required this.weightKg,
    required this.sets,
    required this.day,
    this.isDropset = false,
    this.extraSetWeights = const [],
  });

  Map<String, dynamic> toMap() => {
    'dateTime': dateTime.toIso8601String(),
    'weightKg': weightKg,
    'sets': sets,
    'day': day,
    'isDropset': isDropset,
    'extraSetWeights': extraSetWeights,
  };

  factory WorkoutLog.fromMap(Map<String, dynamic> m) => WorkoutLog(
    dateTime: DateTime.parse(m['dateTime'] as String),
    weightKg: (m['weightKg'] as num).toDouble(),
    sets: (m['sets'] as num).toInt(),
    day: m['day'] as String,
    isDropset: (m['isDropset'] as bool?) ?? false,
    extraSetWeights: ((m['extraSetWeights'] as List?)?.map((e) => (e as num).toDouble()).toList()) ?? const [],
  );
}

/// Rückgabewert des Dialogs:
/// - log != null  -> tracken
/// - assignDay != null -> nur Plan-Zuweisung (ohne History)
class LogOutcome {
  final WorkoutLog? log;
  final String? assignDay;
  const LogOutcome({this.log, this.assignDay});
}

/// ===============================================================
/// Gym Screen
/// ===============================================================
class GymScreen extends StatefulWidget {
  const GymScreen({super.key});
  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  // Storage Keys
  static const _kGymLogsKey = 'gym_logs_v1';
  static const _kGymViewKey = 'gym_view_mode_v1';
  static const _kOrderActiveKey = 'gym_order_by_exercise_v1';
  static const _kOrderByDayKey = 'gym_order_by_day_v1';
  static const _kAssignmentsKey = 'gym_assignments_by_day_v1';
  static const _kOrderDaysKey = 'gym_order_days_v1';

  // Kalender-Storage (Map<yyyy-MM-dd, Set<DayName>>)
  static const _kCalendarKey = 'gym_calendar_v1';
  static const _kDayColorsKey = 'gym_day_colors_v1';

  ViewMode _mode = ViewMode.byExercise;

  // Workouts from JSON
  final List<Workout> _workouts = <Workout>[];

  // Logs & Order
  final Map<String, List<WorkoutLog>> _logs = <String, List<WorkoutLog>>{};
  List<String> _orderActive = <String>[];
  Map<String, List<String>> _orderByDay = <String, List<String>>{};

  // Zuweisungen „Übung gehört zu Day“, auch ohne History
  final Map<String, List<String>> _assignmentsByDay = <String, List<String>>{};

  // Reihenfolge der Workout-Days
  List<String> _orderDays = <String>[];

  // Kalender – pro Datum (yyyy-MM-dd) Liste der erledigten Workout-Days
  final Map<String, Set<String>> _calendarByDate = <String, Set<String>>{};
  // Farbe je Workout-Tag
  final Map<String, int> _dayColors = <String, int>{};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _loadWorkoutsFromAsset();
    await _loadState();
    await _loadCalendar();
    if (mounted) setState(() {});
  }

  // ----------------------------- Workouts (Asset) -----------------------------
  Future<void> _loadWorkoutsFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/workouts.json');
      final list = (jsonDecode(jsonStr) as List)
          .map((e) => Workout.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _workouts
        ..clear()
        ..addAll(list);
    } catch (_) {
      // ignore
    }
  }

  // ----------------------------- Persistenter State -----------------------------
  Future<void> _loadState() async {
    // View mode
    final vm =
    await LocalStorage.loadJson(_kGymViewKey, fallback: 'byExercise');
    _mode = (vm == 'byDay') ? ViewMode.byDay : ViewMode.byExercise;

    // Logs
    final raw = await LocalStorage.loadJson(_kGymLogsKey, fallback: {});
    _logs.clear();
    if (raw is Map) {
      raw.forEach((key, value) {
        final List list = value as List? ?? [];
        final parsed = list
            .map((e) => WorkoutLog.fromMap(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        _logs[key as String] = parsed;
      });
    }

    // Order exercise
    final orderActiveRaw =
    await LocalStorage.loadJson(_kOrderActiveKey, fallback: []);
    _orderActive = (orderActiveRaw is List)
        ? orderActiveRaw.map((e) => e.toString()).toList()
        : <String>[];

    // Order per day
    final orderByDayRaw =
    await LocalStorage.loadJson(_kOrderByDayKey, fallback: {});
    _orderByDay.clear();
    if (orderByDayRaw is Map) {
      orderByDayRaw.forEach((k, v) {
        if (v is List) {
          _orderByDay[k.toString()] =
              v.map((e) => e.toString()).toList(growable: true);
        }
      });
    }

    // Assignments
    final assignmentsRaw =
    await LocalStorage.loadJson(_kAssignmentsKey, fallback: {});
    _assignmentsByDay.clear();
    if (assignmentsRaw is Map) {
      assignmentsRaw.forEach((k, v) {
        if (v is List) {
          _assignmentsByDay[k.toString()] =
              v.map((e) => e.toString()).toList(growable: true);
        }
      });
    }

    // Day colors
    final colorsRaw = await LocalStorage.loadJson(_kDayColorsKey, fallback: {});
    _dayColors.clear();
    if (colorsRaw is Map) {
      colorsRaw.forEach((k, v) {
        if (v is num) _dayColors[k.toString()] = v.toInt();
      });
    }

    // Order der Days
    final orderDaysRaw =
    await LocalStorage.loadJson(_kOrderDaysKey, fallback: []);
    _orderDays = (orderDaysRaw is List)
        ? orderDaysRaw.map((e) => e.toString()).toList()
        : <String>[];

    _syncOrderDaysWithAssignments();
  }

  Future<void> _saveLogs() async {
    final encoded =
    _logs.map((k, v) => MapEntry(k, v.map((e) => e.toMap()).toList()));
    await LocalStorage.saveJson(_kGymLogsKey, encoded);
  }

  Future<void> _saveViewMode() async =>
      LocalStorage.saveJson(_kGymViewKey, _mode.name);
  Future<void> _saveOrderActive() async =>
      LocalStorage.saveJson(_kOrderActiveKey, _orderActive);
  Future<void> _saveOrderByDay() async =>
      LocalStorage.saveJson(_kOrderByDayKey, _orderByDay);
  Future<void> _saveAssignments() async =>
      LocalStorage.saveJson(_kAssignmentsKey, _assignmentsByDay);
  Future<void> _saveOrderDays() async =>
      LocalStorage.saveJson(_kOrderDaysKey, _orderDays);
    Future<void> _saveDayColors() async =>
      LocalStorage.saveJson(_kDayColorsKey, _dayColors);

  // ----------------------------- Kalender: Load/Save -----------------------------
  Future<void> _loadCalendar() async {
    final raw = await LocalStorage.loadJson(_kCalendarKey, fallback: {});
    _calendarByDate.clear();
    if (raw is Map) {
      raw.forEach((dateStr, list) {
        final l =
            (list as List?)?.map((e) => e.toString()).toSet() ?? <String>{};
        _calendarByDate[dateStr.toString()] = l;
      });
    }
  }

  Future<void> _saveCalendar() async {
    final enc = _calendarByDate.map((k, v) => MapEntry(k, v.toList()));
    await LocalStorage.saveJson(_kCalendarKey, enc);
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool _isDayMarkedOn(DateTime date, String dayName) {
    final key = _dateKey(date);
    final set = _calendarByDate[key];
    return set != null && set.contains(dayName);
  }

  Future<void> _setDayMarkedToday(String dayName, bool value) async {
    final now = DateTime.now();
    final key = _dateKey(now);
    final set = _calendarByDate.putIfAbsent(key, () => <String>{});
    if (value) {
      set.add(dayName);
      // Ensure the day has a color for calendar display
      if (!_dayColors.containsKey(dayName)) {
        final cs = Theme.of(context).colorScheme;
        _dayColors[dayName] = _resolveDayColor(dayName, cs).value;
        await _saveDayColors();
      }
    } else {
      set.remove(dayName);
      if (set.isEmpty) _calendarByDate.remove(key);
    }
    await _saveCalendar();
    if (mounted) setState(() {});
  }

  Color _resolveDayColor(String day, ColorScheme cs) {
    final stored = _dayColors[day];
    if (stored != null) return Color(stored);
    final palette = Colors.primaries;
    final base = palette[day.hashCode.abs() % palette.length];
    return base.shade400;
  }

  Future<void> _setDayColor(String day, Color color) async {
    _dayColors[day] = color.value;
    await _saveDayColors();
    if (mounted) setState(() {});
  }

  Future<Color?> _pickColorForDay(String day) async {
    final cs = Theme.of(context).colorScheme;
    final selected = await showDialog<Color>(
      context: context,
      builder: (_) {
        const List<MaterialColor> options = <MaterialColor>[
          Colors.blue,
          Colors.green,
          Colors.pink,
          Colors.orange,
          Colors.purple,
          Colors.teal,
          Colors.amber,
          Colors.red,
          Colors.indigo,
          Colors.cyan,
        ];

        return AlertDialog(
          title: Text('Farbe für "$day"'),
          content: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options
                .map((c) => GestureDetector(
              onTap: () => Navigator.pop(context, c.shade400),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.shade400,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.onSurface.withValues(alpha: 0.1)),
                ),
              ),
            ))
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
          ],
        );
      },
    );

    if (selected != null) {
      await _setDayColor(day, selected);
    }
    return selected;
  }

  // ----------------------------- Helpers: Assignments -----------------------------
  void _ensureAssigned(String day, String workoutId) {
    final list = _assignmentsByDay.putIfAbsent(day, () => <String>[]);
    bool changed = false;
    if (!list.contains(workoutId)) {
      list.add(workoutId);
      changed = true;
      _saveAssignments();
    }
    final order = _orderByDay.putIfAbsent(day, () => <String>[]);
    if (!order.contains(workoutId)) {
      order.add(workoutId);
      _saveOrderByDay();
    }
    if (!_orderDays.contains(day)) {
      _orderDays.add(day);
      _saveOrderDays();
    }
    if (changed) setState(() {});
  }

  void _removeAssignmentForDay(String day, String workoutId) {
    final list = _assignmentsByDay[day];
    if (list == null) return;
    list.remove(workoutId);
    if (list.isEmpty) {
      _assignmentsByDay.remove(day);
      _orderDays.remove(day);
      _saveOrderDays();
    }
    _saveAssignments();

    final order = _orderByDay[day];
    if (order != null) {
      order.remove(workoutId);
      if (order.isEmpty) _orderByDay.remove(day);
      _saveOrderByDay();
    }
    setState(() {});
  }

  Set<String> _assignedDaysForWorkout(String workoutId) {
    final out = <String>{};
    _assignmentsByDay.forEach((day, ids) {
      if (ids.contains(workoutId)) out.add(day);
    });
    return out;
  }

  // ----------------------------- Logik -----------------------------
  WorkoutLog? _getLatestLogFor(String workoutId) {
    final list = _logs[workoutId];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  Set<String> _daysForWorkout(String workoutId) {
    final out = <String>{};
    final list = _logs[workoutId];
    if (list != null) {
      for (final l in list) out.add(l.day);
    }
    _assignmentsByDay.forEach((day, ids) {
      if (ids.contains(workoutId)) out.add(day);
    });
    return out;
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  void _addLog(String workoutId, WorkoutLog result) {
    setState(() {
      final list = _logs.putIfAbsent(workoutId, () => <WorkoutLog>[]);
      list.add(WorkoutLog(
        dateTime: result.dateTime,
        weightKg: result.weightKg,
        sets: result.sets,
        day: result.day,
        isDropset: result.isDropset,
      ));
      _ensureAssigned(result.day, workoutId);
      
      // Aktualisiere Kalender mit dem Log-Datum
      final key = _dateKey(result.dateTime);
      final set = _calendarByDate.putIfAbsent(key, () => <String>{});
      set.add(result.day);
      // Ensure the day has a color for calendar display
      if (!_dayColors.containsKey(result.day)) {
        final cs = Theme.of(context).colorScheme;
        _dayColors[result.day] = _resolveDayColor(result.day, cs).value;
        _saveDayColors();
      }
      _saveCalendar();
    });
    _saveLogs();
  }

  WorkoutLog? _latestForDay(String workoutId, String day) {
    final list = _logs[workoutId];
    if (list == null || list.isEmpty) return null;
    WorkoutLog? latest;
    for (final log in list) {
      if (log.day == day) {
        if (latest == null || log.dateTime.isAfter(latest.dateTime)) {
          latest = log;
        }
      }
    }
    return latest;
  }

  // ---------- Reihenfolge: Übungs-Ansicht ----------
  List<Workout> _getActiveWorkouts() {
    final idsWithLogs = _logs.keys.toSet();
    final idsWithAssign = <String>{
      for (final entry in _assignmentsByDay.entries) ...entry.value
    };
    final activeIds = {...idsWithLogs, ...idsWithAssign}.toList();

    final active =
    _workouts.where((w) => activeIds.contains(w.id)).toList(growable: false);

    bool changed = false;
    for (final id in activeIds) {
      if (!_orderActive.contains(id)) {
        _orderActive.add(id);
        changed = true;
      }
    }
    if (changed) _saveOrderActive();

    active.sort((a, b) =>
        _orderActive.indexOf(a.id).compareTo(_orderActive.indexOf(b.id)));
    return active;
  }

  void _reorderActive(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final active = _getActiveWorkouts();
    if (active.isEmpty) return;

    final ids = active.map((w) => w.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);

    final setActive = ids.toSet();
    _orderActive.removeWhere(setActive.contains);
    _orderActive.insertAll(0, ids);

    _saveOrderActive();
    setState(() {});
  }

  // ---------- Reihenfolge: pro Day ----------
  List<Workout> _getWorkoutsForDayOrdered(String day) {
    final idsFromLogs = <String>{};
    _logs.forEach((wid, list) {
      if (list.any((l) => l.day == day)) idsFromLogs.add(wid);
    });
    final idsFromAssign = _assignmentsByDay[day]?.toSet() ?? <String>{};

    final ids = {...idsFromLogs, ...idsFromAssign}.toList();

    final order = List<String>.from(_orderByDay[day] ?? const []);
    bool changed = false;
    for (final id in ids) {
      if (!order.contains(id)) {
        order.add(id);
        changed = true;
      }
    }
    if (changed) {
      _orderByDay[day] = order;
      _saveOrderByDay();
    }

    final filtered =
    _workouts.where((w) => ids.contains(w.id)).toList(growable: false);
    filtered.sort(
            (a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    return filtered;
  }

  // ---------- Nur zugewiesene Übungen für Day ----------
  List<Workout> _getAssignedWorkoutsForDayOrdered(String day) {
    final ids = _assignmentsByDay[day]?.toList() ?? <String>[];

    final order = List<String>.from(_orderByDay[day] ?? const []);
    bool changed = false;
    for (final id in ids) {
      if (!order.contains(id)) {
        order.add(id);
        changed = true;
      }
    }
    if (changed) {
      _orderByDay[day] = order;
      _saveOrderByDay();
    }

    final filtered =
    _workouts.where((w) => ids.contains(w.id)).toList(growable: false);
    filtered.sort(
            (a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    return filtered;
  }

  void _reorderDay(String day, List<String> newOrder) {
    _orderByDay[day] = newOrder;
    _saveOrderByDay();
    setState(() {});
  }

  // ---------- Day-Order (Gruppen-Reihenfolge) ----------
  void _syncOrderDaysWithAssignments() {
    final activeDays = _assignmentsByDay.keys.toList();

    bool changed = false;
    for (final d in activeDays) {
      if (!_orderDays.contains(d)) {
        _orderDays.add(d);
        changed = true;
      }
    }
    final activeSet = activeDays.toSet();
    final beforeLen = _orderDays.length;
    _orderDays.removeWhere((d) => !activeSet.contains(d));
    if (_orderDays.length != beforeLen) changed = true;

    if (changed) _saveOrderDays();
  }

  List<String> _getOrderedDays() {
    _syncOrderDaysWithAssignments();
    return List<String>.from(_orderDays);
  }

  void _reorderDays(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final days = _getOrderedDays();
    if (days.isEmpty) return;

    final moved = days.removeAt(oldIndex);
    days.insert(newIndex, moved);

    final setDays = days.toSet();
    _orderDays.removeWhere(setDays.contains);
    _orderDays.insertAll(0, days);

    _saveOrderDays();
    setState(() {});
  }

  // ----------------------------- Delete + Dialoge -----------------------------
  void _deleteWorkoutLogsAll(String workoutId) {
    setState(() => _logs.remove(workoutId));
    _saveLogs();
  }

  void _deleteExerciseEverywhere(String workoutId) {
    _logs.remove(workoutId);

    _assignmentsByDay.forEach((day, list) => list.remove(workoutId));
    _assignmentsByDay.removeWhere((_, list) => list.isEmpty);

    _orderActive.remove(workoutId);
    _orderByDay.forEach((day, list) => list.remove(workoutId));
    _orderByDay.removeWhere((_, list) => list.isEmpty);

    _orderDays.removeWhere((d) => !_assignmentsByDay.containsKey(d));

    _saveLogs();
    _saveAssignments();
    _saveOrderActive();
    _saveOrderByDay();
    _saveOrderDays();

    setState(() {});
  }

  void _confirmClearHistoryAll(Workout w) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete all logs for "${w.name}"?'),
        content: const Text(
          'This will remove the complete history for this exercise. '
              'Assignments in your workout plan remain.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkoutLogsAll(w.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteExercise(Workout w) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove "${w.name}" everywhere?'),
        content: const Text(
          'This will delete all logs and remove the exercise from every workout plan. '
              'This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExerciseEverywhere(w.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteWorkoutLogsForDay(String workoutId, String day) {
    final list = _logs[workoutId];
    if (list == null) return;
    setState(() {
      list.removeWhere((log) => log.day == day);
      if (list.isEmpty) _logs.remove(workoutId);
    });
    _saveLogs();
  }

  void _confirmDeleteForDay(Workout w, String day) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Clear history for "${w.name}" on $day?'),
        content: const Text('Only this exercise’s logs for this day will be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkoutLogsForDay(w.id, day);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Remove-from-plan Dialog (By Exercise)
  Future<void> _openUnassignDialog(Workout w) async {
    final assignedDays = _assignedDaysForWorkout(w.id).toList()..sort();
    if (assignedDays.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(
          content: Text('This exercise is not part of any workout plan yet.'),
        ),
      );
      return;
    }

    final selected = <String>{};
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Remove "${w.name}" from plan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Choose days to remove (history stays):'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: assignedDays.map((d) {
                  final isSel = selected.contains(d);
                  return FilterChip(
                    label: Text(d),
                    selected: isSel,
                    onSelected: (v) => setS(() {
                      if (v) {
                        selected.add(d);
                      } else {
                        selected.remove(d);
                      }
                    }),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selected.isEmpty
                  ? null
                  : () {
                for (final d in selected) {
                  _removeAssignmentForDay(d, w.id);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------- Charts -----------------------------
  void _openProgressChartDialog(Workout w) {
    final cs = Theme.of(context).colorScheme;

    final logs = List<WorkoutLog>.from(_logs[w.id] ?? const <WorkoutLog>[]);
    if (logs.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(content: Text('No entries available')),
      );
      return;
    }
    logs.sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final spots = List<FlSpot>.generate(
      logs.length,
          (i) => FlSpot(
        logs[i].dateTime.millisecondsSinceEpoch.toDouble(),
        logs[i].weightKg,
      ),
    );

    final double minX = spots.first.x;
    final double maxX = spots.last.x;

    double niceNum(double range, {required bool round}) {
      if (range <= 0) return 1;
      final double exp =
      math.pow(10, (math.log(range) / math.ln10).floor()).toDouble();
      final double f = range / exp; // 1..10
      double nf;
      if (round) {
        if (f < 1.5) nf = 1;
        else if (f < 3) nf = 2;
        else if (f < 7) nf = 5;
        else nf = 10;
      } else {
        if (f <= 1) nf = 1;
        else if (f <= 2) nf = 2;
        else if (f <= 5) nf = 5;
        else nf = 10;
      }
      return nf * exp;
    }

    double rawMinY = logs.map((e) => e.weightKg).reduce(math.min);
    double rawMaxY = logs.map((e) => e.weightKg).reduce(math.max);
    if (rawMinY == rawMaxY) {
      rawMinY -= 1;
      rawMaxY += 1;
    }

    const targetLines = 5;
    final niceRange = niceNum(rawMaxY - rawMinY, round: false);
    final yInterval = niceNum(niceRange / (targetLines - 1), round: true);
    final minY = (rawMinY / yInterval).floor() * yInterval;
    final maxY = (rawMaxY / yInterval).ceil() * yInterval;

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    String fmtTooltip(DateTime d) => fmtDate(d);

    const double kLeftAxisSpaceToLine = 4;
    const double kLeftAxisReserved = 38;
    const double kLeftAxisNamePadding = 12;
    const double kFirstDateLeftPad = 8;
    const double kLastDateRightPad = 14;
    const double kBottomReserved = 30;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFFF5F7FA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.show_chart, color: Color(0xFFE53935)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Progress – ${w.name}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: 'Full screen',
              icon: const Icon(Icons.fullscreen),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenChartPage(
                      title: w.name,
                      logs: logs,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          height: 300,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY.toDouble(),
              maxY: maxY.toDouble(),
              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: const Color(0x22000000),
                  strokeWidth: 1,
                  dashArray: const [6, 6],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: const Padding(
                    padding: EdgeInsets.only(right: kLeftAxisNamePadding),
                    child: Text('kg', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  axisNameSize: 26,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: kLeftAxisReserved,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: kLeftAxisSpaceToLine,
                      child: Text(value.toStringAsFixed(0)),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: kBottomReserved,
                    interval: (maxX - minX) == 0 ? 1 : (maxX - minX),
                    getTitlesWidget: (value, meta) {
                      const eps = 0.5;
                      final bool isFirst = (value - minX).abs() < eps;
                      final bool isLast = (value - maxX).abs() < eps;

                      if ((maxX - minX).abs() < eps) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(fmtDate(dt), style: const TextStyle(fontSize: 11)),
                          ),
                        );
                      }
                      if (!isFirst && !isLast) return const SizedBox.shrink();

                      final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final EdgeInsets pad = isFirst
                          ? const EdgeInsets.only(left: kFirstDateLeftPad)
                          : const EdgeInsets.only(right: kLastDateRightPad);

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 6,
                        child: Padding(
                          padding: pad,
                          child: Text(
                            fmtDate(dt),
                            style: const TextStyle(fontSize: 11),
                            textAlign: isFirst ? TextAlign.left : TextAlign.right,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => Colors.white,
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  getTooltipItems: (touchedSpots) => touchedSpots.map((t) {
                    final idx = t.spotIndex.clamp(0, logs.length - 1);
                    final dt = DateTime.fromMillisecondsSinceEpoch(t.x.round());
                    final isDrop = logs[idx].isDropset;

                    final dateStr = fmtTooltip(dt);
                    final weightStr =
                        '${t.y.toStringAsFixed(1)} kg${isDrop ? ' • Dropset' : ''}';

                    return LineTooltipItem(
                      '$dateStr\n',
                      const TextStyle(color: Color(0xFF1A1D1F), fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: weightStr,
                          style: TextStyle(
                            color: const Color(0xFF1A1D1F),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: false,
                  barWidth: 3,
                  color: const Color(0xFFE53935),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      final isDrop = logs[index].isDropset;
                      return FlDotCirclePainter(
                        radius: isDrop ? 5.2 : 3.0,
                        color: isDrop ? const Color(0xFFB71C1C) : const Color(0xFFE53935),
                        strokeWidth: isDrop ? 2.4 : 1.2,
                        strokeColor: isDrop ? const Color(0xFFFFCDD2) : const Color(0x66E53935),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(context),
            Expanded(
              child: _mode == ViewMode.byExercise
                  ? _buildWorkoutListBody()
                  : _buildDayListBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModernHeader(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Icons.fitness_center,
                      color: Color(0xFFE53935),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Gym',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Calendar',
                    icon: const Icon(Icons.calendar_month, color: Color(0xFF6F7789)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkoutCalendarPage(
                            calendarByDate: _calendarByDate,
                            dayColors: _dayColors,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildViewModeMenu(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _mode = ViewMode.byExercise);
                _saveViewMode();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == ViewMode.byExercise
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _mode == ViewMode.byExercise
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      size: 18,
                      color: _mode == ViewMode.byExercise
                          ? const Color(0xFFE53935)
                          : const Color(0xFF6F7789),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exercises',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mode == ViewMode.byExercise
                            ? const Color(0xFF1A1D1F)
                            : const Color(0xFF6F7789),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _mode = ViewMode.byDay);
                _saveViewMode();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == ViewMode.byDay
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _mode == ViewMode.byDay
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_day,
                      size: 18,
                      color: _mode == ViewMode.byDay
                          ? const Color(0xFFE53935)
                          : const Color(0xFF6F7789),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Workout Days',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mode == ViewMode.byDay
                            ? const Color(0xFF1A1D1F)
                            : const Color(0xFF6F7789),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeMenu() => PopupMenuButton<int>(
    tooltip: 'More options',
    icon: const Icon(Icons.more_horiz, color: Color(0xFF6F7789)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    onSelected: (v) {
      // Kann für zusätzliche Optionen verwendet werden
    },
    itemBuilder: (_) => const [],
  );

  Widget _buildModernFAB() {
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
          onTap: _onAddPressed,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBody() => Center(
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
            Icons.fitness_center,
            size: 64,
            color: Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'No workouts yet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D1F),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add your first exercise to get started',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
          ),
        ),
      ],
    ),
  );

  // Übungs-Ansicht
  Widget _buildWorkoutListBody() {
    final active = _getActiveWorkouts();
    if (active.isEmpty) return _buildEmptyBody();

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: active.length,
      onReorder: _reorderActive,
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) {
        final w = active[i];
        final latest = _getLatestLogFor(w.id);
        return _buildModernWorkoutCard(w, i, latest);
      },
    );
  }

  Widget _buildModernWorkoutCard(Workout w, int index, WorkoutLog? latest) {
    return Container(
      key: ValueKey('ex_${w.id}'),
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
          onTap: () async {
            final days = _daysForWorkout(w.id).toList()..sort();
            final outcome = await _openLogDialog(
              w,
              latest: latest,
              contextDay: null,
              availableDays: days,
              creationMode: false,
            );
            if (outcome == null) return;
            if (outcome.log != null) _addLog(w.id, outcome.log!);
          },
          onLongPress: () => _openProgressChartDialog(w),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Color(0xFFD1D5DB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    w.icon,
                    color: const Color(0xFFE53935),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latest == null
                            ? 'No progress yet'
                            : '${latest.day} • ${latest.weightKg} kg • ${latest.sets} Sets',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6F7789),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: Color(0xFF6F7789)),
                  onPressed: () => _openHistoryDialog(w),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF6F7789)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'remove_plan') {
                      await _openUnassignDialog(w);
                    } else if (value == 'clear_history') {
                      _confirmClearHistoryAll(w);
                    } else if (value == 'delete_everywhere') {
                      _confirmDeleteExercise(w);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'remove_plan',
                      child: Text('Remove from plan…'),
                    ),
                    PopupMenuItem(
                      value: 'clear_history',
                      child: Text('Clear all history'),
                    ),
                    PopupMenuItem(
                      value: 'delete_everywhere',
                      child: Text('Delete exercise…'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Day-Ansicht
  Widget _buildDayListBody() {
    final days = _getOrderedDays();
    if (days.isEmpty) {
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
                Icons.calendar_today,
                size: 64,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No workout days yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D1F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add exercises to create workout days',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: days.length,
      onReorder: _reorderDays,
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) {
        final day = days[i];
        final count = _assignmentsByDay[day]?.length ?? 0;
        return _buildModernDayCard(day, i, count);
      },
    );
  }

  Widget _buildModernDayCard(String day, int index, int count) {
    return Container(
      key: ValueKey('day_$day'),
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
          onTap: () => _openDayDetail(day),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Color(0xFFD1D5DB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_note,
                    color: Color(0xFFE53935),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count exercise${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6F7789),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDayDetail(String day) {
    final ordered = _getAssignedWorkoutsForDayOrdered(day);
    final stripe = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayDetailScreen(
          day: day,
          orderedWorkouts: ordered,
          latestForDay: _latestForDay,
          onEdit: (w, latest) async {
            final outcome = await _openLogDialog(
              w,
              latest: latest,
              contextDay: day,
              availableDays: const [],
              creationMode: false,
            );
            if (outcome == null) return;
            if (outcome.log != null) _addLog(w.id, outcome.log!);
          },
          onShowHistory: _openHistoryDialog,
          onShowChart: _openProgressChartDialog,
          onDeleteForDay: (w) => _confirmDeleteForDay(w, day),
          onDeleteAll: _confirmClearHistoryAll,
          onUnassignFromDay: (w) => _removeAssignmentForDay(day, w.id),
          onReorder: (ids) => _reorderDay(day, ids),
          stripeColor: stripe,
          // Checkbox oben rechts
          isDoneToday: () => _isDayMarkedOn(DateTime.now(), day),
          onToggleDoneToday: (v) => _setDayMarkedToday(day, v),
          dayColor: _resolveDayColor(day, cs),
          onPickColor: () => _pickColorForDay(day),
        ),
      ),
    );
  }

  void _openHistoryDialog(Workout w) {
    showDialog<void>(context: context, builder: (_) => _buildHistoryDialog(w));
  }

  Widget _buildHistoryDialog(Workout w) {
    final list = _logs[w.id] ?? <WorkoutLog>[];
    if (list.isEmpty) {
      return const AlertDialog(content: Text('No entries available'));
    }
    final cs = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text('History – ${w.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final log = list[i];
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text('${log.weightKg} kg  •  ${log.sets} Sets'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${log.day}  •  ${_formatDate(log.dateTime)}'),
                  if (log.isDropset && log.extraSetWeights.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: log.extraSetWeights
                          .map((w) => Chip(
                                label: Text('${w.toStringAsFixed(1)} kg'),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
              trailing: log.isDropset
                  ? Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Dropset',
                  style: TextStyle(
                      color: cs.onPrimaryContainer, fontSize: 12),
                ),
              )
                  : null,
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
      ],
    );
  }

  Future<void> _onAddPressed() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WorkoutPickerSheet(
        workouts: _workouts,
        latestFor: _getLatestLogFor,
        onAddOrUpdate: (w) async {
          final days = _daysForWorkout(w.id).toList()..sort();
          final outcome = await _openLogDialog(
            w,
            latest: _getLatestLogFor(w.id),
            contextDay: null,
            availableDays: days,
            creationMode: true,
          );
          if (outcome == null) return;

          if (outcome.log != null) {
            _addLog(w.id, outcome.log!);
          } else if (outcome.assignDay != null) {
            _ensureAssigned(outcome.assignDay!, w.id);
            setState(() {});
          }
        },
      ),
    );
  }

  Future<LogOutcome?> _openLogDialog(
      Workout w, {
        WorkoutLog? latest,
        String? contextDay,
        List<String> availableDays = const [],
        bool creationMode = false,
      }) {
    return showDialog<LogOutcome>(
      context: context,
      builder: (_) => LogInputDialog(
        workout: w,
        latest: latest,
        contextDay: contextDay,
        availableDays: availableDays,
        creationMode: creationMode,
      ),
    );
  }
}

/// ===============================================================
/// Bottom Sheet: Suche + Liste + Beschreibung
/// ===============================================================
class WorkoutPickerSheet extends StatefulWidget {
  const WorkoutPickerSheet({
    super.key,
    required this.workouts,
    required this.latestFor,
    required this.onAddOrUpdate,
  });

  final List<Workout> workouts;
  final WorkoutLog? Function(String id) latestFor;
  final Future<void> Function(Workout workout) onAddOrUpdate;

  @override
  State<WorkoutPickerSheet> createState() => _WorkoutPickerSheetState();
}

class _WorkoutPickerSheetState extends State<WorkoutPickerSheet> {
  String _query = '';

  List<Workout> _applyFilter() {
    final String lower = _query.toLowerCase();
    final List<Workout> filtered = <Workout>[];
    for (final Workout workout in widget.workouts) {
      final byName = workout.name.toLowerCase().contains(lower);
      final byMuscle = workout.muscles.any((m) => m.toLowerCase().contains(lower));
      if (byName || byMuscle) {
        filtered.add(workout);
      }
    }
    return filtered;
  }

  Widget _buildGrabber() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search workout... (name or muscle)',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6F7789)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
        onChanged: (String value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final WorkoutLog? latest = widget.latestFor(workout.id);
    final String subtitle = latest == null
        ? 'No progress yet'
        : 'Update: ${latest.weightKg} kg • ${latest.sets} Sets';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(workout.icon, color: const Color(0xFFE53935)),
        ),
        title: Text(
          workout.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D1F),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6F7789)),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              workout.description,
              style: const TextStyle(color: Color(0xFF6F7789)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onAddOrUpdate(workout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(latest == null ? 'Add' : 'Update'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Workout> filtered = _applyFilter();

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                _buildGrabber(),
                const SizedBox(height: 12),
                _buildSearchField(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: filtered.length,
                    itemBuilder: (_, int index) =>
                        _buildWorkoutCard(filtered[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ===============================================================
// DayDetailScreen mit Checkbox oben rechts („heute erledigt“)
// ===============================================================
class DayDetailScreen extends StatefulWidget {
  final String day;
  final List<Workout> orderedWorkouts;
  final WorkoutLog? Function(String workoutId, String day) latestForDay;
  final Future<void> Function(Workout workout, WorkoutLog? latestForThisDay)
  onEdit;
  final void Function(Workout workout) onShowHistory;
  final void Function(Workout workout) onShowChart;
  final void Function(Workout workout) onDeleteForDay;
  final void Function(Workout workout) onDeleteAll;
  final void Function(Workout workout) onUnassignFromDay;
  final void Function(List<String> newOrder) onReorder;
  final Color stripeColor;

  final bool Function() isDoneToday;
  final Future<void> Function(bool value) onToggleDoneToday;
  final Color dayColor;
  final Future<Color?> Function() onPickColor;

  const DayDetailScreen({
    super.key,
    required this.day,
    required this.orderedWorkouts,
    required this.latestForDay,
    required this.onEdit,
    required this.onShowHistory,
    required this.onShowChart,
    required this.onDeleteForDay,
    required this.onDeleteAll,
    required this.onUnassignFromDay,
    required this.onReorder,
    required this.stripeColor,
    required this.isDoneToday,
    required this.onToggleDoneToday,
    required this.dayColor,
    required this.onPickColor,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late List<Workout> _list;
  late bool _checkedToday;
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _list = List<Workout>.from(widget.orderedWorkouts);
    _checkedToday = widget.isDoneToday();
    _currentColor = widget.dayColor;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _list.removeAt(oldIndex);
    _list.insert(newIndex, item);
    setState(() {});
    widget.onReorder(_list.map((w) => w.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernDayHeader(context),
            Expanded(
              child: _list.isEmpty
                  ? _buildModernEmptyDay()
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      onReorder: _onReorder,
                      buildDefaultDragHandles: false,
                      itemCount: _list.length,
                      itemBuilder: (_, i) {
                        final workout = _list[i];
                        final latest = widget.latestForDay(workout.id, widget.day);
                        return _buildModernDayExerciseCard(workout, i, latest);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyDay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          SizedBox(height: 8),
          Icon(Icons.fitness_center, size: 64, color: Color(0xFF9CA3AF)),
          SizedBox(height: 16),
          Text(
            'No exercises today',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF1A1D1F)),
          ),
          SizedBox(height: 8),
          Text(
            'Add or assign exercises to this day',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDayHeader(BuildContext context) {
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Color(0xFF6F7789)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.day,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1D1F),
              ),
            ),
          ),
          // Color picker button
          IconButton(
            tooltip: 'Pick color for this day',
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: _currentColor,
              child: const Icon(Icons.palette, size: 16, color: Colors.white),
            ),
            onPressed: () async {
              final chosen = await widget.onPickColor();
              if (chosen != null) setState(() => _currentColor = chosen);
            },
          ),
          const SizedBox(width: 4),
          // Done today pill
          GestureDetector(
            onTap: () async {
              final nv = !_checkedToday;
              await widget.onToggleDoneToday(nv);
              setState(() => _checkedToday = nv);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _checkedToday ? const Color(0xFFE8F5E9) : const Color(0xFFF0F4F8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _checkedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: _checkedToday ? const Color(0xFF4CAF50) : const Color(0xFF6F7789),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Done today',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _checkedToday ? const Color(0xFF4CAF50) : const Color(0xFF6F7789),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDayExerciseCard(Workout w, int index, WorkoutLog? latest) {
    return Container(
      key: ValueKey('day_${w.id}'),
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
          onTap: () => widget.onEdit(w, latest),
          onLongPress: () => widget.onShowChart(w),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(
                    Icons.drag_indicator,
                    color: Color(0xFFD1D5DB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(w.icon, color: const Color(0xFFE53935), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1D1F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latest == null
                            ? 'No progress yet'
                            : '${latest.weightKg} kg • ${latest.sets} Sets',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF6F7789)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'History',
                  onPressed: () => widget.onShowHistory(w),
                  icon: const Icon(Icons.history, color: Color(0xFF6F7789)),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Color(0xFF6F7789)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'delete_day') {
                      widget.onDeleteForDay(w);
                    }
                    if (value == 'remove_plan') {
                      widget.onUnassignFromDay(w);
                      setState(() {
                        _list.removeWhere((x) => x.id == w.id);
                      });
                    }
                    if (value == 'delete_all') {
                      widget.onDeleteAll(w);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'delete_day',
                      child: Text('Delete today’s logs only'),
                    ),
                    PopupMenuItem(
                      value: 'remove_plan',
                      child: Text('Remove from this plan (keep history)'),
                    ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Text('Delete all logs for this exercise'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===============================================================
// Gemeinsame Reorder-Tiles
// ===============================================================
class _ReorderTile extends StatelessWidget {
  final int index;
  final Color leadingStripColor;
  final Widget title;
  final Widget subtitle;
  final Widget? trailingMore;
  final Icon? avatar;
  final VoidCallback onHistory;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ReorderTile({
    super.key,
    required this.index,
    required this.leadingStripColor,
    required this.title,
    required this.subtitle,
    required this.avatar,
    required this.onHistory,
    this.onDelete,
    this.onTap,
    this.onLongPress,
    this.trailingMore,
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
                leading: CircleAvatar(child: avatar),
                title: title,
                subtitle: subtitle,
                onTap: onTap,
                onLongPress: onLongPress,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'History',
                      onPressed: onHistory,
                      icon: const Icon(Icons.history),
                    ),
                    if (trailingMore != null) trailingMore!,
                    if (onDelete != null)
                      IconButton(
                        tooltip: 'Remove',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReorderDayTile extends StatelessWidget {
  final int index;
  final Color leadingStripColor;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback onTap;

  const _ReorderDayTile({
    super.key,
    required this.index,
    required this.leadingStripColor,
    required this.title,
    this.subtitle,
    required this.onTap,
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
                leading: const Icon(Icons.fitness_center),
                title: title,
                subtitle: subtitle,
                trailing: const Icon(Icons.chevron_right),
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================================================
/// Dialog: Day selection + Werte
/// ===============================================================
class LogInputDialog extends StatefulWidget {
  const LogInputDialog({
    required this.workout,
    this.latest,
    this.contextDay,
    this.availableDays = const [],
    this.creationMode = false,
    super.key,
  });

  final Workout workout;
  final WorkoutLog? latest;
  final String? contextDay;
  final List<String> availableDays;
  final bool creationMode;

  @override
  State<LogInputDialog> createState() => _LogInputDialogState();
}

class _LogInputDialogState extends State<LogInputDialog> {
  late final TextEditingController _kgController;
  late final TextEditingController _setsController;
  late final TextEditingController _dayController;

  String? _chipDay;
  bool _isDropset = false;
  final TextEditingController _extraWeightsController = TextEditingController();

  bool get _dayLocked => widget.contextDay != null;

  @override
  void initState() {
    super.initState();
    _kgController = TextEditingController();
    _setsController = TextEditingController();
    _dayController = TextEditingController();

    if (widget.latest != null) {
      _kgController.text = widget.latest!.weightKg.toStringAsFixed(1);
      _setsController.text = widget.latest!.sets.toString();
      _isDropset = widget.latest!.isDropset;
      if (!_dayLocked) _dayController.text = widget.latest!.day;
    }

    if (_dayLocked) {
      _chipDay = widget.contextDay;
    }
  }

  @override
  void dispose() {
    _kgController.dispose();
    _setsController.dispose();
    _dayController.dispose();
    _extraWeightsController.dispose();
    super.dispose();
  }

  void _onChipSelected(String day) {
    setState(() {
      _chipDay = day;
      if (_dayController.text.trim().isNotEmpty) _dayController.clear();
    });
  }

  String _resolveChosenDay() {
    if (_dayLocked) return widget.contextDay!;
    final typed = _dayController.text.trim();
    if (typed.isNotEmpty) return typed;
    if (_chipDay != null) return _chipDay!.trim();
    return '';
  }

  bool _anyNumberFilled() =>
      _kgController.text.trim().isNotEmpty ||
          _setsController.text.trim().isNotEmpty;

  bool _validateForTracking() {
    final kg = double.tryParse(_kgController.text.replaceAll(',', '.'));
    final sets = int.tryParse(_setsController.text);
    final day = _resolveChosenDay();

    if (kg == null || kg <= 0) {
      _showSnackBar('Please enter a valid weight (> 0).');
      return false;
    }
    if (sets == null || sets <= 0) {
      _showSnackBar('Please enter a valid number of sets (> 0).');
      return false;
    }
    if (!_dayLocked && day.isEmpty) {
      _showSnackBar('Please select or enter a workout day.');
      return false;
    }
    return true;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _submit() {
    if (widget.creationMode && !_anyNumberFilled()) {
      final day = _resolveChosenDay();
      if (day.isEmpty && !_dayLocked) {
        _showSnackBar('Pick a workout day to add this exercise to a group.');
        return;
      }
      Navigator.pop<LogOutcome>(context, LogOutcome(assignDay: day));
      return;
    }

    if (!_validateForTracking()) return;

    final kg = double.parse(_kgController.text.replaceAll(',', '.'));
    final sets = int.parse(_setsController.text);
    final day = _resolveChosenDay();

    Navigator.pop<LogOutcome>(
      context,
      LogOutcome(
        log: WorkoutLog(
          dateTime: DateTime.now(),
          weightKg: kg,
          sets: sets,
          day: day,
          isDropset: _isDropset,
          extraSetWeights: _parseExtraWeights(_extraWeightsController.text),
        ),
      ),
    );
  }

  List<double> _parseExtraWeights(String text) {
    final raw = text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    final out = <double>[];
    for (final s in raw) {
      final v = double.tryParse(s.replaceAll(',', '.'));
      if (v != null) out.add(v);
    }
    return out;
  }

  Widget _buildDayInput(BuildContext context) {
    if (_dayLocked) return const SizedBox.shrink();

    final hasKnownDays = widget.availableDays.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (hasKnownDays) ...[
          const Text(
            'Workout Day',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6F7789)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.availableDays
                .map((d) => ChoiceChip(
              label: Text(d),
              selected:
              _chipDay == d && _dayController.text.trim().isEmpty,
              onSelected: (_) => _onChipSelected(d),
            ))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _dayController,
          decoration: InputDecoration(
            labelText: hasKnownDays
                ? 'Other (type manually)'
                : (widget.creationMode
                ? 'Workout Day (optional)'
                : 'Workout Day (required)'),
            hintText: hasKnownDays ? 'e.g. Push3' : 'e.g. Push / Pull / Leg …',
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
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: kSuggestedWorkdays.map((d) {
              final selected =
                  _chipDay == d && _dayController.text.trim().isEmpty;
              return ChoiceChip(
                label: Text(d),
                selected: selected,
                onSelected: (_) => _onChipSelected(d),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberFields() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        TextField(
          controller: _kgController,
          keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText:
            widget.creationMode ? 'Weight (kg) – optional' : 'Weight (kg)',
            hintText: 'e.g. 80',
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
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _setsController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: widget.creationMode ? 'Sets – optional' : 'Sets',
            hintText: 'e.g. 3',
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
          ),
        ),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: _isDropset,
          onChanged: (v) => setState(() => _isDropset = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: cs.primary,
          title: const Text('Dropset'),
          secondary: Icon(Icons.bolt, color: cs.primary),
          contentPadding: EdgeInsets.zero,
        ),
        if (_isDropset) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _extraWeightsController,
            decoration: InputDecoration(
              labelText: 'Additional weights (comma separated)',
              hintText: 'e.g. 60, 50, 40',
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
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF5F7FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: Color(0xFFE53935)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.workout.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildDayInput(context),
            const SizedBox(height: 12),
            _buildNumberFields(),
          ],
        ),
      ),
      actions: <Widget>[
        SizedBox(
          width: double.infinity,
          child: Row(
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
                  child: Text(widget.creationMode ? 'Save' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// ===============================================================
/// Vollbild-Seite für die Chart
/// ===============================================================
class FullScreenChartPage extends StatefulWidget {
  final String title;
  final List<WorkoutLog> logs;

  const FullScreenChartPage({
    super.key,
    required this.title,
    required this.logs,
  });

  @override
  State<FullScreenChartPage> createState() => _FullScreenChartPageState();
}

class _FullScreenChartPageState extends State<FullScreenChartPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final logs = List<WorkoutLog>.from(widget.logs)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final spots = List<FlSpot>.generate(
      logs.length,
          (i) => FlSpot(
        logs[i].dateTime.millisecondsSinceEpoch.toDouble(),
        logs[i].weightKg,
      ),
    );

    final double minX = spots.first.x;
    final double maxX = spots.last.x;

    double niceNum(double range, {required bool round}) {
      if (range <= 0) return 1;
      final double exp =
      math.pow(10, (math.log(range) / math.ln10).floor()).toDouble();
      final double f = range / exp;
      double nf;
      if (round) {
        if (f < 1.5) nf = 1;
        else if (f < 3) nf = 2;
        else if (f < 7) nf = 5;
        else nf = 10;
      } else {
        if (f <= 1) nf = 1;
        else if (f <= 2) nf = 2;
        else if (f <= 5) nf = 5;
        else nf = 10;
      }
      return nf * exp;
    }

    double rawMinY = logs.map((e) => e.weightKg).reduce(math.min);
    double rawMaxY = logs.map((e) => e.weightKg).reduce(math.max);
    if (rawMinY == rawMaxY) {
      rawMinY -= 1;
      rawMaxY += 1;
    }

    const targetLines = 5;
    final niceRange = niceNum(rawMaxY - rawMinY, round: false);
    final yInterval = niceNum(niceRange / (targetLines - 1), round: true);
    final minY = (rawMinY / yInterval).floor() * yInterval;
    final maxY = (rawMaxY / yInterval).ceil() * yInterval;

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    String fmtTooltip(DateTime d) => fmtDate(d);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D1F),
        elevation: 0.5,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Exit full screen',
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 12, 18, 12),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: (maxX - minX) == 0 ? 1 : (maxX - minX),
                  getTitlesWidget: (value, meta) {
                    const eps = 0.5;
                    final bool isFirst = (value - minX).abs() < eps;
                    final bool isLast = (value - maxX).abs() < eps;

                    if ((maxX - minX).abs() < eps) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(fmtDate(dt), style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    }
                    if (!isFirst && !isLast) return const SizedBox.shrink();

                    final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 6,
                      child: Padding(
                        padding: EdgeInsets.only(left: isFirst ? 8 : 0, right: isLast ? 24 : 0),
                        child: Text(
                          fmtDate(dt),
                          style: const TextStyle(fontSize: 12),
                          textAlign: isFirst ? TextAlign.left : TextAlign.right,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) => Colors.white,
                tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                getTooltipItems: (touchedSpots) => touchedSpots.map((t) {
                  final idx = t.spotIndex.clamp(0, logs.length - 1);
                  final dt = DateTime.fromMillisecondsSinceEpoch(t.x.round());
                  final isDrop = logs[idx].isDropset;

                  final dateStr = fmtTooltip(dt);
                  final weightStr =
                      '${t.y.toStringAsFixed(1)} kg${isDrop ? ' • Dropset' : ''}';

                  return LineTooltipItem(
                    '$dateStr\n',
                    const TextStyle(color: Color(0xFF1A1D1F), fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: weightStr,
                        style: const TextStyle(
                          color: Color(0xFF1A1D1F),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            minX: minX,
            maxX: maxX,
            minY: minY.toDouble(),
            maxY: maxY.toDouble(),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                barWidth: 3,
                color: const Color(0xFFE53935),
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    final isDrop = logs[index].isDropset;
                    return FlDotCirclePainter(
                      radius: isDrop ? 4.5 : 3.2,
                      color: isDrop ? Color(0xFFB71C1C) : Color(0xFFE53935),
                      strokeWidth: isDrop ? 2 : 1.5,
                      strokeColor: const Color(0x66E53935),
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
/// KOMPAKTER MONATSKALENDER – lokalisiert (z. B. „Oktober 2025“)
/// ===============================================================
class WorkoutCalendarPage extends StatefulWidget {
  final Map<String, Set<String>> calendarByDate;
  final Map<String, int> dayColors;
  const WorkoutCalendarPage({super.key, required this.calendarByDate, required this.dayColors});

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  late DateTime _currentMonth;
  double? _dragStartX;
  bool _dragHandled = false;
  bool _showChips = true; // toggle between chips and count badge

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  int _daysInMonth(DateTime month) {
    final next = DateTime(month.year, month.month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragHandled = false;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragHandled || _dragStartX == null) return;
    final delta = details.globalPosition.dx - _dragStartX!;
    const threshold = 60; // simple swipe threshold
    if (delta.abs() > threshold) {
      if (delta > 0) {
        _prevMonth();
      } else {
        _nextMonth();
      }
      _dragHandled = true; // avoid multiple triggers in one swipe
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _dragStartX = null;
    _dragHandled = false;
  }

  Widget _buildDayContent(List<String> names) {
    if (names.isEmpty) return const SizedBox.shrink();

    if (_showChips) {
      // Show abbreviated chips
      const maxVisible = 4;
      final visible = names.take(maxVisible).toList();
      final overflow = names.length - visible.length;

      Color colorFor(String day) {
        final stored = widget.dayColors[day];
        if (stored != null) return Color(stored);
        final palette = Colors.primaries;
        final base = palette[day.hashCode.abs() % palette.length];
        return base.shade400;
      }

      String shortLabel(String n) {
        if (n.trim().isEmpty) return n;
        final parts = n.split(RegExp(r"\s+"));
        if (parts.length > 1) {
          final ac = parts.map((p) => p.isEmpty ? '' : p[0]).join();
          return ac.substring(0, ac.length.clamp(0, 3));
        }
        return n.length <= 3 ? n : n.substring(0, 3);
      }

      final List<Widget> chips = visible
          .map((n) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorFor(n),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  shortLabel(n),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ))
          .toList();

      if (overflow > 0) {
        chips.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('+$overflow',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
        ));
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: chips
              .map((chip) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: chip,
                  ))
              .toList(),
        ),
      );
    } else {
      // Show count badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${names.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
  }

  void _showFullList(BuildContext context, DateTime date, List<String> names) {
    if (names.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFFF5F7FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final dateLabel = MaterialLocalizations.of(context).formatFullDate(date);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today, color: Color(0xFFE53935), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workouts',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...names.map((n) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: (widget.dayColors[n] != null)
                            ? Color(widget.dayColors[n]!)
                            : _fallbackColor(n),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      n,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _fallbackColor(String day) {
    final palette = Colors.primaries;
    final base = palette[day.hashCode.abs() % palette.length];
    return base.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1..7
    final leadingEmpty = (firstWeekday + 6) % 7; // Start bei Montag
    final days = _daysInMonth(_currentMonth);
    final cells = leadingEmpty + days;
    final rows = (cells / 7).ceil();

    final localizations = MaterialLocalizations.of(context);
    final titleLabel = localizations.formatMonthYear(_currentMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _handleHorizontalDragStart,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Modern header
                  Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      // Back button
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
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
                            Text(
                              titleLabel,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Swipe or use arrows to switch month',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // View toggle
                      _ToggleButton(
                        icon: _showChips ? Icons.grid_view : Icons.filter_list,
                        onTap: () => setState(() => _showChips = !_showChips),
                      ),
                      const SizedBox(width: 8),
                      // Prev / Next
                      _MonthIconButton(icon: Icons.chevron_left, onTap: _prevMonth),
                      const SizedBox(width: 8),
                      _MonthIconButton(icon: Icons.chevron_right, onTap: _nextMonth, isPrimary: true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Dow('Mon'), _Dow('Tue'), _Dow('Wed'),
                    _Dow('Thu'), _Dow('Fri'), _Dow('Sat'), _Dow('Sun'),
                  ],
                ),
                const Divider(height: 0),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.9, // kompakter
                    ),
                    itemCount: rows * 7,
                    itemBuilder: (_, idx) {
                      if (idx < leadingEmpty || idx >= leadingEmpty + days) {
                        return const SizedBox.shrink();
                      }
                      final dayNum = idx - leadingEmpty + 1;
                      final date =
                      DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                      final key = _dateKey(date);
                      final names = widget.calendarByDate[key]?.toList() ?? const <String>[];
                      final isToday = _dateKey(date) == _dateKey(DateTime.now());

                      return GestureDetector(
                        onTap: () => _showFullList(context, date, names),
                        onLongPress: () => _showFullList(context, date, names),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday
                                ? Border.all(color: const Color(0xFFE53935), width: 1.5)
                                : Border.all(color: const Color(0xFFE6E8EC)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('$dayNum',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      )),
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (names.isNotEmpty)
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomLeft,
                                    child: _buildDayContent(names),
                                  ),
                                ),
                            ],
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
            child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        )),
      ),
    );
  }
}

class _MonthIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _MonthIconButton({required this.icon, required this.onTap, this.isPrimary = false});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFE53935) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : const Color(0xFF374151)),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ToggleButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
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
        child: Icon(icon, color: const Color(0xFF374151), size: 20),
      ),
    );
  }
}
