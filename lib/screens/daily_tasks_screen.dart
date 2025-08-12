import 'package:flutter/material.dart';

class DailyTask {
  String id;
  String title;
  bool done;
  DailyTask({required this.id, required this.title, this.done = false});
}

class DailyTasksScreen extends StatefulWidget {
  const DailyTasksScreen({super.key});
  @override
  State<DailyTasksScreen> createState() => _DailyTasksScreenState();
}

class _DailyTasksScreenState extends State<DailyTasksScreen> {
  final List<DailyTask> _tasks = [];
  final _ctrl = TextEditingController();

  void _addTask() {
    final t = _ctrl.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _tasks.add(DailyTask(id: DateTime.now().microsecondsSinceEpoch.toString(), title: t));
      _ctrl.clear();
    });
  }

  void _resetAll() {
    setState(() {
      for (final t in _tasks) t.done = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Tasks'),
        actions: [
          IconButton(
            tooltip: 'Reset all (daily)',
            onPressed: _tasks.isEmpty ? null : _resetAll,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(
                      labelText: 'New daily task',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _addTask,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('No daily tasks yet'))
                : ListView.separated(
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final t = _tasks[i];
                return CheckboxListTile(
                  value: t.done,
                  onChanged: (v) => setState(() => t.done = v ?? false),
                  title: Text(t.title),
                  secondary: const Icon(Icons.today),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
