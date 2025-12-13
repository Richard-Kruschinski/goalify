import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../store/app_store.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final nameCtrl = TextEditingController();
  DateTime deadline = DateTime.now().add(const Duration(days: 7));
  final store = AppStore();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Gruppe erstellen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Deadline:'),
              const SizedBox(width: 8),
              Expanded(child: Text(DateFormat('dd.MM.yyyy HH:mm').format(deadline))),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDate: deadline,
                  );
                  if (d != null) {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(deadline),
                      builder: (context, child) {
                        final mq = MediaQuery.of(context);
                        return MediaQuery(
                          data: mq.copyWith(alwaysUse24HourFormat: true),
                          child: child ?? const SizedBox.shrink(),
                        );
                      },
                    );
                    final time = t ?? const TimeOfDay(hour: 23, minute: 59);
                    setState(() {
                      deadline = DateTime(d.year, d.month, d.day, time.hour, time.minute);
                    });
                  }
                },
                child: const Text('ändern'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;
            final g = store.createGroup(name: name, deadline: deadline);
            Navigator.pop(context, g);
          },
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}

class CreateTaskDialog extends StatefulWidget {
  final String groupId;
  const CreateTaskDialog({super.key, required this.groupId});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final titleCtrl = TextEditingController();
  int points = 1;
  final store = AppStore();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Task hinzufügen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Titel'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Punkte:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: points,
                items: const [1, 2, 3, 5]
                    .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                    .toList(),
                onChanged: (v) => setState(() => points = v ?? 1),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
        FilledButton(
          onPressed: () {
            final title = titleCtrl.text.trim();
            if (title.isEmpty) return;
            store.addTask(groupId: widget.groupId, title: title, points: points);
            Navigator.pop(context, true);
          },
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
