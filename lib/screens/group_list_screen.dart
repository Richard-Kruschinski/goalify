import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../store/app_store.dart';
import '../widgets/create_dialogs.dart';
import 'group_detail_screen.dart';

class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  final store = AppStore();

  @override
  void initState() {
    super.initState();
    // Demodaten beim ersten Start
    if (store.listGroups().isEmpty) {
      final g = store.createGroup(
        name: 'Demo Group',
        deadline: DateTime.now().add(const Duration(days: 7)),
      );
      store.joinGroup(groupId: g.id, uid: 'u2', name: 'Alex');
      store.addTask(groupId: g.id, title: '10k Schritte', points: 1);
      store.addTask(groupId: g.id, title: 'Workout', points: 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = store.listGroups();
    return Scaffold(
      appBar: AppBar(title: const Text('Goalify – Groups')),
      body: ListView.separated(
        itemCount: groups.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (_, i) {
          final g = groups[i];
          final remaining = g.deadline.difference(DateTime.now());
          return ListTile(
            leading: CircleAvatar(
              radius: 24,
              backgroundImage: (g.imageUrl != null && g.imageUrl!.isNotEmpty)
                  ? NetworkImage(g.imageUrl!)
                  : const AssetImage('assets/images/placeholder.jpg') as ImageProvider,
            ),
            title: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                'Deadline: ${DateFormat('dd.MM.yyyy HH:mm').format(g.deadline)}  •  ${remaining.isNegative ? "abgelaufen" : "${remaining.inDays} days"}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GroupDetailScreen(groupId: g.id)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog(context: context, builder: (_) => const CreateGroupDialog());
          if (created != null) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Neue Gruppe'),
      ),
    );
  }
}
