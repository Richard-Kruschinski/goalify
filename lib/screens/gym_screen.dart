import 'package:flutter/material.dart';
import '../storage/local_storage.dart'; // <- Lokaler Speicher (saveJson/loadJson)

enum ViewMode { byExercise, byDay }

const List<String> kSuggestedWorkdays = <String>[
  'Push',
  'Pull',
  'Leg',
  'Arm',
  'Upper Body',
  'Lower Body',
];

class Workout {
  final String id;
  final String name;
  final String description;
  final IconData icon;

  const Workout({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
  });
}

class WorkoutLog {
  final DateTime dateTime;
  final double weightKg;
  final int sets;
  final String day;

  const WorkoutLog({
    required this.dateTime,
    required this.weightKg,
    required this.sets,
    required this.day,
  });

  Map<String, dynamic> toMap() => {
    'dateTime': dateTime.toIso8601String(),
    'weightKg': weightKg,
    'sets': sets,
    'day': day,
  };

  factory WorkoutLog.fromMap(Map<String, dynamic> m) => WorkoutLog(
    dateTime: DateTime.parse(m['dateTime'] as String),
    weightKg: (m['weightKg'] as num).toDouble(),
    sets: (m['sets'] as num).toInt(),
    day: m['day'] as String,
  );
}

class LogInputResult {
  final double weightKg;
  final int sets;
  final String day;

  const LogInputResult({
    required this.weightKg,
    required this.sets,
    required this.day,
  });
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
  // ---- Keys für lokalen Speicher ----
  static const _kGymLogsKey = 'gym_logs_v1';
  static const _kGymViewKey = 'gym_view_mode_v1';
  static const _kOrderActiveKey = 'gym_order_by_exercise_v1';
  static const _kOrderByDayKey = 'gym_order_by_day_v1';

  ViewMode _mode = ViewMode.byExercise;

  // Katalog der verfügbaren Übungen (fix, nicht persistiert)
  final List<Workout> _workouts = <Workout>[
    const Workout(
      id: 'bench_press',
      name: 'Bench Press',
      description:
      'Classic barbell chest exercise. Focus on chest, triceps, and front shoulders.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'incline_bench_press',
      name: 'Incline Bench Press',
      description:
      'Performed on an incline bench. Emphasizes upper chest and shoulders.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'incline_bench_press_dumbbell',
      name: 'Incline Bench Press (Dumbbell)',
      description:
      'Variation with dumbbells for greater range of motion and stabilization.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'bench_press_dumbbell',
      name: 'Bench Press (Dumbbell)',
      description:
      'Bench press using dumbbells. Promotes balanced chest activation and stability.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'overhead_press',
      name: 'Overhead Press',
      description:
      'Press barbell overhead. Focus on shoulder strength and core stability.',
      icon: Icons.upload,
    ),
    const Workout(
      id: 'shoulder_press_machine',
      name: 'Shoulder Press (Machine)',
      description: 'Machine-guided pressing movement for front and side delts.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'lateral_raise_machine',
      name: 'Lateral Raise (Machine)',
      description: 'Isolation exercise for side delts using a machine.',
      icon: Icons.accessibility,
    ),
    const Workout(
      id: 'lateral_raise_dumbbell',
      name: 'Lateral Raise (Dumbbell)',
      description: 'Classic shoulder exercise with dumbbells for lateral delts.',
      icon: Icons.accessibility,
    ),
    const Workout(
      id: 'squat',
      name: 'Squat',
      description:
      'Fundamental leg and glute exercise. Keep depth and neutral spine.',
      icon: Icons.accessibility_new,
    ),
    const Workout(
      id: 'hex_squat',
      name: 'Hex Squat',
      description:
      'Machine-guided squat variation. Focuses on quadriceps activation.',
      icon: Icons.accessibility_new,
    ),
    const Workout(
      id: 'deadlift',
      name: 'Deadlift',
      description:
      'Fundamental back and leg exercise. Keep bar close and spine neutral.',
      icon: Icons.align_vertical_bottom,
    ),
    const Workout(
      id: 'tbar_row',
      name: 'T-Bar Row',
      description: 'Row variation with T-bar. Targets upper back and rear delts.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'lat_pulldown',
      name: 'Lat Pulldown',
      description:
      'Pull-down movement targeting the lats. Grip variations shift muscle focus.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'reverse_fly',
      name: 'Reverse Fly',
      description: 'Reverse fly motion. Focus on rear delts and upper back.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'cable_cross',
      name: 'Cable Cross',
      description:
      'Cable exercise for chest definition. Adjustable angles for variation.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'hammer_curls',
      name: 'Hammer Curls',
      description:
      'Biceps exercise with neutral grip. Targets the brachialis.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'concentration_curls',
      name: 'Concentration Curls',
      description:
      'One-arm biceps curl. Focuses on peak contraction and isolation.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'triceps_pushdown',
      name: 'Triceps Pushdown',
      description:
      'Triceps exercise at the cable machine. Can use bar or rope.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'calf_raise_seated',
      name: 'Calf Raises (Seated)',
      description: 'Seated calf raise. Focus on the soleus muscle.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'calf_raise_machine',
      name: 'Calf Raises (Standing Machine)',
      description:
      'Standing calf raises at the machine. Focus on the gastrocnemius.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'leg_curl',
      name: 'Leg Curls',
      description: 'Machine hamstring curl. Isolates the hamstrings.',
      icon: Icons.fitness_center,
    ),
    const Workout(
      id: 'leg_extension',
      name: 'Leg Extension',
      description: 'Machine quad extension. Isolates the quadriceps.',
      icon: Icons.fitness_center,
    ),
  ];

  /// Historie pro Workout
  final Map<String, List<WorkoutLog>> _logs = <String, List<WorkoutLog>>{};

  /// Reihenfolgen: global (Übungs-Ansicht) & pro Day
  List<String> _orderActive = <String>[];
  Map<String, List<String>> _orderByDay = <String, List<String>>{};

  @override
  void initState() {
    super.initState();
    _load(); // <- Logs + View-Mode + Orders laden
  }

  // ----------------------------- Persistenz -----------------------------

  Future<void> _load() async {
    // View-Mode laden
    final vm =
    await LocalStorage.loadJson(_kGymViewKey, fallback: 'byExercise');
    _mode = (vm == 'byDay') ? ViewMode.byDay : ViewMode.byExercise;

    // Logs laden
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

    // Order (Übungen)
    final orderActiveRaw =
    await LocalStorage.loadJson(_kOrderActiveKey, fallback: []);
    _orderActive = (orderActiveRaw is List)
        ? orderActiveRaw.map((e) => e.toString()).toList()
        : <String>[];

    // Order (pro Day)
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

    if (mounted) setState(() {});
  }

  Future<void> _saveLogs() async {
    final encoded =
    _logs.map((k, v) => MapEntry(k, v.map((e) => e.toMap()).toList()));
    await LocalStorage.saveJson(_kGymLogsKey, encoded);
  }

  Future<void> _saveViewMode() async {
    await LocalStorage.saveJson(_kGymViewKey, _mode.name); // "byExercise"|"byDay"
  }

  Future<void> _saveOrderActive() async {
    await LocalStorage.saveJson(_kOrderActiveKey, _orderActive);
  }

  Future<void> _saveOrderByDay() async {
    await LocalStorage.saveJson(_kOrderByDayKey, _orderByDay);
  }

  // ----------------------------- Logik -----------------------------

  WorkoutLog? _getLatestLogFor(String workoutId) {
    final List<WorkoutLog>? list = _logs[workoutId];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  String _formatDate(DateTime dateTime) {
    final String day = dateTime.day.toString().padLeft(2, '0');
    final String month = dateTime.month.toString().padLeft(2, '0');
    final String year = dateTime.year.toString();
    return '$day.$month.$year';
  }

  void _addLog(String workoutId, LogInputResult result) {
    setState(() {
      final List<WorkoutLog> list =
      _logs.putIfAbsent(workoutId, () => <WorkoutLog>[]);
      list.add(
        WorkoutLog(
          dateTime: DateTime.now(),
          weightKg: result.weightKg,
          sets: result.sets,
          day: result.day,
        ),
      );
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
    final active =
    _workouts.where((w) => _getLatestLogFor(w.id) != null).toList();

    // fehlende IDs hinten anhängen (und persistieren)
    final activeIds = active.map((w) => w.id).toList();
    bool changed = false;
    for (final id in activeIds) {
      if (!_orderActive.contains(id)) {
        _orderActive.add(id);
        changed = true;
      }
    }
    if (changed) _saveOrderActive();

    // sortieren nach _orderActive
    active.sort((a, b) {
      final ia = _orderActive.indexOf(a.id);
      final ib = _orderActive.indexOf(b.id);
      return ia.compareTo(ib);
    });
    return active;
  }

  void _reorderActive(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;

    final active = _getActiveWorkouts();
    if (active.isEmpty) return;

    final ids = active.map((w) => w.id).toList();
    final id = ids.removeAt(oldIndex);
    ids.insert(newIndex, id);

    // _orderActive so umbauen, dass die aktiven IDs in neuer Reihenfolge stehen
    final setActive = ids.toSet();
    _orderActive.removeWhere(setActive.contains);
    _orderActive.insertAll(0, ids);

    _saveOrderActive();
    setState(() {});
  }

  // ---------- Reihenfolge: pro Day ----------

  List<Workout> _getWorkoutsForDayOrdered(String day) {
    final filtered = _workouts.where((w) {
      final l = _logs[w.id];
      if (l == null) return false;
      return l.any((log) => log.day == day);
    }).toList();

    final ids = filtered.map((w) => w.id).toList();
    final order = List<String>.from(_orderByDay[day] ?? const []);

    // fehlende einfügen
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

    // sortieren nach order
    filtered.sort((a, b) {
      final ia = order.indexOf(a.id);
      final ib = order.indexOf(b.id);
      return ia.compareTo(ib);
    });
    return filtered;
  }

  void _reorderDay(String day, List<String> newOrder) {
    _orderByDay[day] = newOrder;
    _saveOrderByDay();
    setState(() {});
  }

  // ----------------------------- Delete + Bestätigungs-Dialoge -----------------------------

  void _deleteWorkoutLogsAll(String workoutId) {
    setState(() {
      _logs.remove(workoutId);
    });
    _saveLogs();
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

  void _confirmDeleteExercise(Workout workout) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove "${workout.name}"?'),
        content: const Text('This will delete all logs for this exercise.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkoutLogsAll(workout.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteForDay(Workout workout, String day) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove "${workout.name}" from $day?'),
        content: Text('Only this exercise’s logs for "$day" will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteWorkoutLogsForDay(workout.id, day);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ----------------------------- UI: Bausteine -----------------------------

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Gym'),
      actions: [
        _buildViewModeMenu(),
      ],
    );
  }

  Widget _buildViewModeMenu() {
    return PopupMenuButton<ViewMode>(
      tooltip: 'Select view',
      onSelected: (ViewMode value) {
        setState(() {
          _mode = value;
        });
        _saveViewMode(); // <- View-Mode merken
      },
      itemBuilder: (BuildContext context) {
        return [
          _buildViewModeMenuItem(ViewMode.byExercise, 'By Exercise'),
          _buildViewModeMenuItem(ViewMode.byDay, 'By Workout Day'),
        ];
      },
    );
  }

  PopupMenuItem<ViewMode> _buildViewModeMenuItem(ViewMode mode, String label) {
    return PopupMenuItem<ViewMode>(
      value: mode,
      child: Row(
        children: [
          Icon(
            _mode == mode
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildEmptyBody() {
    return const Center(
      child: Text('No workouts added yet'),
    );
  }

  // --- Übungs-Ansicht: Reorderable ---
  Widget _buildWorkoutListBody() {
    final List<Workout> active = _getActiveWorkouts();
    if (active.isEmpty) return _buildEmptyBody();

    final stripe = Theme.of(context).colorScheme.primary;

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 96, top: 8),
      itemCount: active.length,
      onReorder: _reorderActive,
      buildDefaultDragHandles: false, // eigener Handle (Streifen)
      itemBuilder: (_, i) {
        final workout = active[i];
        final latest = _getLatestLogFor(workout.id)!;

        return _ReorderTile(
          key: ValueKey('ex_${workout.id}'),
          index: i,
          leadingStripColor: stripe,
          title: Text(workout.name),
          subtitle:
          Text('${latest.day} • ${latest.weightKg} kg • ${latest.sets} Sets'),
          avatar: Icon(workout.icon),
          onHistory: () => _openHistoryDialog(workout),
          onDelete: () => _confirmDeleteExercise(workout),
          onTap: () async {
            final LogInputResult? result =
            await _openLogInputDialog(workout, latest);
            if (result != null) {
              _addLog(workout.id, result);
            }
          },
        );
      },
    );
  }

  // --- Day-Liste (nur Auswahl) ---
  Widget _buildDayListBody() {
    final Set<String> allDays = <String>{};
    for (final List<WorkoutLog> list in _logs.values) {
      for (final WorkoutLog log in list) {
        allDays.add(log.day);
      }
    }
    if (allDays.isEmpty) {
      return const Center(child: Text('No workout days available yet'));
    }

    final List<String> days = allDays.toList()..sort();
    return ListView.separated(
      itemCount: days.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (_, int i) => ListTile(
        leading: const Icon(Icons.fitness_center),
        title: Text(days[i]),
        onTap: () => _openDayDetail(days[i]),
      ),
    );
  }

  void _openDayDetail(String day) {
    final ordered = _getWorkoutsForDayOrdered(day);
    final stripe = Theme.of(context).colorScheme.primary;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayDetailScreen(
          day: day,
          orderedWorkouts: ordered,
          latestForDay: _latestForDay,
          onEdit: (workout, latestForThisDay) async {
            final res = await _openLogInputDialog(workout, latestForThisDay);
            if (res != null) _addLog(workout.id, res);
          },
          onShowHistory: (workout) => _openHistoryDialog(workout),
          onDeleteForDay: (workout) => _confirmDeleteForDay(workout, day),
          onDeleteAll: (workout) => _confirmDeleteExercise(workout),
          onReorder: (newOrderIds) => _reorderDay(day, newOrderIds),
          stripeColor: stripe,
        ),
      ),
    );
  }

  void _openHistoryDialog(Workout workout) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => _buildHistoryDialog(workout),
    );
  }

  Widget _buildHistoryDialog(Workout workout) {
    final List<WorkoutLog> list = _logs[workout.id] ?? <WorkoutLog>[];

    return AlertDialog(
      title: Text('Historie – ${workout.name}'),
      content: _buildHistoryDialogContent(list),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildHistoryDialogContent(List<WorkoutLog> list) {
    if (list.isEmpty) return const Text('No entries available');

    return SizedBox(
      width: double.maxFinite,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: list.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (_, index) {
          final WorkoutLog log = list[index];
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text('${log.weightKg} kg  •  ${log.sets} Sets'),
            subtitle: Text('${log.day}  •  ${_formatDate(log.dateTime)}'),
          );
        },
      ),
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
        onAddOrUpdate: (Workout workout) async {
          final LogInputResult? result =
          await _openLogInputDialog(workout, _getLatestLogFor(workout.id));
          if (result != null) _addLog(workout.id, result);
        },
      ),
    );
  }

  Future<LogInputResult?> _openLogInputDialog(
      Workout workout,
      WorkoutLog? latest,
      ) {
    return showDialog<LogInputResult>(
      context: context,
      builder: (_) => LogInputDialog(workout: workout, latest: latest),
    );
  }

  // ----------------------------- Build -----------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _mode == ViewMode.byExercise
          ? _buildWorkoutListBody()
          : _buildDayListBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddPressed,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

//---------------------------------------------------
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
      if (workout.name.toLowerCase().contains(lower)) {
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search workout...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (String value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final WorkoutLog? latest = widget.latestFor(workout.id);
    final String subtitle =
    latest == null ? 'No progress yet' : 'Update: ${latest.weightKg} kg • ${latest.sets} Sets';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(child: Icon(workout.icon)),
        title: Text(workout.name),
        subtitle: Text(subtitle),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                workout.description,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () => widget.onAddOrUpdate(workout),
                  icon: const Icon(Icons.add),
                  label: Text(latest == null ? 'Add' : 'Update'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Close'),
                ),
              ],
            ),
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
          return Column(
            children: <Widget>[
              const SizedBox(height: 8),
              _buildGrabber(),
              const SizedBox(height: 8),
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
          );
        },
      ),
    );
  }
}

// ===============================================================
// DayDetailScreen mit Reorder + Persist via Callback
// ===============================================================
class DayDetailScreen extends StatefulWidget {
  final String day;
  final List<Workout> orderedWorkouts; // bereits sortiert vom Parent
  final WorkoutLog? Function(String workoutId, String day) latestForDay;
  final Future<void> Function(Workout workout, WorkoutLog? latestForThisDay)
  onEdit;
  final void Function(Workout workout) onShowHistory;
  final void Function(Workout workout) onDeleteForDay;
  final void Function(Workout workout) onDeleteAll;
  final void Function(List<String> newOrder) onReorder;
  final Color stripeColor;

  const DayDetailScreen({
    super.key,
    required this.day,
    required this.orderedWorkouts,
    required this.latestForDay,
    required this.onEdit,
    required this.onShowHistory,
    required this.onDeleteForDay,
    required this.onDeleteAll,
    required this.onReorder,
    required this.stripeColor,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late List<Workout> _list;

  @override
  void initState() {
    super.initState();
    _list = List<Workout>.from(widget.orderedWorkouts);
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
      appBar: AppBar(title: Text(widget.day)),
      body: _list.isEmpty
          ? const Center(child: Text('No exercises today'))
          : ReorderableListView.builder(
        onReorder: _onReorder,
        buildDefaultDragHandles: false,
        itemCount: _list.length,
        itemBuilder: (_, i) {
          final workout = _list[i];
          final latest = widget.latestForDay(workout.id, widget.day);

          return _ReorderTile(
            key: ValueKey('day_${workout.id}'),
            index: i,
            leadingStripColor: widget.stripeColor,
            title: Text(workout.name),
            subtitle: latest == null
                ? const Text('No progress yet')
                : Text('${latest.weightKg} kg • ${latest.sets} Sets'),
            avatar: Icon(workout.icon),
            onHistory: () => widget.onShowHistory(workout),
            onTap: () => widget.onEdit(workout, latest),
            // Menü für Delete-Aktionen
            trailingMore: PopupMenuButton<String>(
              tooltip: 'more',
              onSelected: (value) {
                if (value == 'delete_day') widget.onDeleteForDay(workout);
                if (value == 'delete_all') widget.onDeleteAll(workout);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete_day',
                  child: Text('Delete today’s logs only'),
                ),
                PopupMenuItem(
                  value: 'delete_all',
                  child: Text('Delete all logs for this exercise'),
                ),
              ],
              icon: const Icon(Icons.more_vert),
            ),
          );
        },
      ),
    );
  }
}

// ===============================================================
// Gemeinsames Tile mit Streifen in Theme-Farbe (Drag-Handle)
// ===============================================================
class _ReorderTile extends StatelessWidget {
  final int index;
  final Color leadingStripColor;
  final Widget title;
  final Widget subtitle;
  final Widget? trailingMore;
  final Icon? avatar;
  final VoidCallback onHistory;
  final VoidCallback? onDelete; // optional: nur in Übungs-Ansicht
  final VoidCallback? onTap;

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
    this.trailingMore,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: key, // wichtig für Reorderable
      child: Container(
        decoration: const BoxDecoration(
          border:
          Border(bottom: BorderSide(width: 0.5, color: Color(0x1F000000))),
        ),
        child: Row(
          children: [
            // Streifen = Drag-Handle (Long-Press)
            ReorderableDelayedDragStartListener(
              index: index,
              // Falls deine Flutter-Version delay nicht kennt: Zeile auskommentieren.
              // delay: const Duration(milliseconds: 1500),
              child: Container(
                width: 10,
                height: 54, // ~ ListTile-Höhe
                color: leadingStripColor,
              ),
            ),
            const SizedBox(width: 8),

            // Inhalt
            Expanded(
              child: ListTile(
                leading: CircleAvatar(child: avatar),
                title: title,
                subtitle: subtitle,
                onTap: onTap,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Historie',
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

/// ===============================================================
/// Dialog: Eingabe Day (pflicht), Gewicht & Sets
/// ===============================================================
class LogInputDialog extends StatefulWidget {
  const LogInputDialog({
    required this.workout,
    this.latest,
    super.key,
  });

  final Workout workout;
  final WorkoutLog? latest;

  @override
  State<LogInputDialog> createState() => _LogInputDialogState();
}

class _LogInputDialogState extends State<LogInputDialog> {
  late final TextEditingController _kgController;
  late final TextEditingController _setsController;
  late final TextEditingController _dayController;

  String? _chipDay;

  @override
  void initState() {
    super.initState();
    _kgController = TextEditingController();
    _setsController = TextEditingController();
    _dayController = TextEditingController();

    if (widget.latest != null) {
      _kgController.text = widget.latest!.weightKg.toStringAsFixed(1);
      _setsController.text = widget.latest!.sets.toString();
      _dayController.text = widget.latest!.day;
    }
  }

  @override
  void dispose() {
    _kgController.dispose();
    _setsController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _onChipSelected(String day) {
    setState(() {
      _chipDay = day;
      if (_dayController.text.trim().isNotEmpty) _dayController.clear();
    });
  }

  String _resolveChosenDay() {
    final String typed = _dayController.text.trim();
    if (typed.isNotEmpty) return typed;
    if (_chipDay != null) return _chipDay!.trim();
    return '';
  }

  bool _validateInputs() {
    final double? kg = double.tryParse(_kgController.text.replaceAll(',', '.'));
    final int? sets = int.tryParse(_setsController.text);
    final String day = _resolveChosenDay();

    if (kg == null) {
      _showSnackBar('Please enter a valid weight');
      return false;
    }
    if (kg <= 0) {
      _showSnackBar('Weight must be greater than 0');
      return false;
    }
    if (sets == null) {
      _showSnackBar('Please enter a valid number of sets');
      return false;
    }
    if (sets <= 0) {
      _showSnackBar('Sets must be greater than 0');
      return false;
    }
    if (day.isEmpty) {
      _showSnackBar('Please select or enter a workout day');
      return false;
    }
    return true;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (!_validateInputs()) return;

    final double kg = double.parse(_kgController.text.replaceAll(',', '.'));
    final int sets = int.parse(_setsController.text);
    final String day = _resolveChosenDay();

    Navigator.pop<LogInputResult>(
      context,
      LogInputResult(weightKg: kg, sets: sets, day: day),
    );
  }

  Widget _buildDayInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: _dayController,
          decoration: const InputDecoration(
            labelText: 'Workout-Day (required)',
            hintText: 'e.g. Push / Pull / Leg …',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: kSuggestedWorkdays.map((String d) {
              final bool selected =
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
    return Column(
      children: <Widget>[
        TextField(
          controller: _kgController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Weight (kg)',
            hintText: 'e.g. 80',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _setsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Sets',
            hintText: 'e.g. 3',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.workout.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildDayInput(),
            const SizedBox(height: 12),
            _buildNumberFields(),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
