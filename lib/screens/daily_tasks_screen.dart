import 'dart:async';
import 'package:flutter/material.dart';
import '../storage/local_storage.dart'; // Pfad ggf. anpassen

/// --- Model ---
class DailyTask {
  final String id;
  final String title;
  final String? description;
  final String? category; // z. B. Gym, Work, Leisure
  final int points;
  final bool keep; // true = bleibt über Tage, false = nur heute
  bool done;

  DailyTask({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.points = 1,
    this.keep = false, // Standard: nur für heute
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
  };

  factory DailyTask.fromMap(Map<String, dynamic> m) => DailyTask(
    id: m['id'] as String,
    title: m['title'] as String,
    description: m['description'] as String?,
    category: m['category'] as String?,
    points: (m['points'] ?? 1) as int,
    keep: (m['keep'] ?? false) as bool,
    done: (m['done'] ?? false) as bool,
  );
}

/// --- Screen ---
class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});
  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen>
    with WidgetsBindingObserver {
  static const _kDailyTasksKey = 'daily_tasks_v1';
  static const _kDailyRolloverKey = 'daily_last_rollover_v1';

  final List<DailyTask> _tasks = [];
  int _todayPoints = 0;

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

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ---- Progress: Heutige Punkte persistieren ----
  Future<void> _saveProgressToday() async {
    final key = _todayKey();
    final raw = await LocalStorage.loadJson('progress_history_v1', fallback: {});
    final hist = Map<String, dynamic>.from(raw as Map);
    hist[key] = _todayPoints;
    await LocalStorage.saveJson('progress_history_v1', hist);
  }

  // 🔽 Laden & Speichern
  Future<void> _load() async {
    final raw = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
    if (raw is List) {
      _tasks
        ..clear()
        ..addAll(
          raw.map((e) => DailyTask.fromMap(Map<String, dynamic>.from(e))),
        );
      await _dailyRolloverIfNeeded(); // Tageswechsel anwenden (löschen/entchecken)
      _recalcTodayPoints();
      await _saveProgressToday(); // sicherstellen, dass der heutige Stand gespeichert ist
      if (mounted) setState(() {});
    }
  }

  Future<void> _save() async {
    await LocalStorage.saveJson(
      _kDailyTasksKey,
      _tasks.map((t) => t.toMap()).toList(),
    );
  }

  Future<void> _markRolloverDoneForToday() async {
    await LocalStorage.saveJson(_kDailyRolloverKey, _todayKey());
  }

  Future<void> _dailyRolloverIfNeeded() async {
    final last = await LocalStorage.loadJson(_kDailyRolloverKey, fallback: '');
    final today = _todayKey();
    if (last == today) return; // schon erledigt

    bool changed = false;

    // 1) "Nur heute" -> löschen
    _tasks.removeWhere((t) {
      final remove = !t.keep;
      if (remove) changed = true;
      return remove;
    });

    // 2) "Bleibt" -> Haken entfernen
    for (final t in _tasks) {
      if (t.keep && t.done) {
        t.done = false;
        changed = true;
      }
    }

    _recalcTodayPoints();
    await _markRolloverDoneForToday();
    await _saveProgressToday(); // neuen Tagesstand (i. d. R. 0) in die History schreiben
    if (changed) {
      await _save();
      if (mounted) setState(() {});
    }
  }

  void _recalcTodayPoints() {
    _todayPoints =
        _tasks.where((t) => t.done).fold<int>(0, (sum, t) => sum + t.points);
  }

  // -- Add
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
        _tasks.add(created); // neu ist standardmäßig done=false
        _recalcTodayPoints();
      });
      await _save();
      await _saveProgressToday(); // History bleibt synchron (ändert sich hier i. d. R. nicht)
    }
  }

  // -- Toggle
  Future<void> _toggleDone(DailyTask t) async {
    setState(() {
      t.done = !t.done;
      _recalcTodayPoints();
    });
    await _save();
    await _saveProgressToday(); // Punkte nach Toggle sichern
  }

  // -- Delete
  Future<void> _deleteAt(int i) async {
    setState(() {
      _tasks.removeAt(i);
      _recalcTodayPoints();
    });
    await _save();
    await _saveProgressToday(); // Punkte nach Löschen sichern
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
    await _save();
    await _saveProgressToday(); // Tagespunkte -> 0 sichern
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        actions: [
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
            onPressed: _tasks.isEmpty ? null : _resetAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _tasks.isEmpty
          ? const Center(child: Text('No daily tasks yet'))
          : ListView.separated(
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (_, i) {
          final t = _tasks[i];
          return ListTile(
            leading: Checkbox(
              value: t.done,
              onChanged: (_) => _toggleDone(t),
            ),
            title: Text(
              t.title,
              style: t.done
                  ? const TextStyle(
                decoration: TextDecoration.lineThrough,
              )
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
                    if (t.keep)
                      const Chip(
                        label: Text('keeps'),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _deleteAt(i),
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
}

/// --- Bottom Sheet Formular ---
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
  bool _keep = false; // standardmäßig "nur heute"

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
                      value: _points.toDouble(),
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
