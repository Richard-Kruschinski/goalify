import 'package:flutter/material.dart';
import '../store/app_store.dart';
import '../widgets/deadline_banner.dart';
import '../widgets/scoreboard.dart';
import '../models/group.dart' as gm;
import '../models/task_item.dart' as tm;
import '../widgets/create_dialogs.dart';



class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  const GroupDetailScreen({super.key, required this.groupId}); //-- KEy ist eine eindeutige ID des Objekts

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState(); //-- "=>" ist wie ein return (nur kürzer)  Wir aber nur für getter und so benutzt
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final store = AppStore(); //-- neue Instanz von AppStore

  gm.Group get g => store.getGroup(widget.groupId)!; //-- das ist das gleiche wie das:
  //gm.Group get g {
//  return store.getGroup(widget.groupId)!;
  //}

  @override
  Widget build(BuildContext context) { //-- build rendert die UI
    bool isLocked;
    if (DateTime.now().isAfter(g.deadline)) {
      isLocked = true;
    } else {
      isLocked = false;
    }
    return Scaffold(
      appBar: AppBar(title: Text(g.name)),
      body: Column( //-- Der haupt teil soll im style von Zeilen (also Vertikales Layout und Widget werden untereinander angeordnet)
        children: [
          DeadlineBanner(deadline: g.deadline),
          Expanded(
            child: Row(
              children: [
                // Tasks
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader('Tasks'),
                      Expanded(
                        child: ListView.builder(
                          itemCount: g.tasks.length,
                          itemBuilder: (_, i) {
                            final t = g.tasks[i];
                            return _TaskCard(
                              t: t,
                              isLocked: isLocked,
                              onComplete: () {
                                final ok = store.completeTask(
                                  groupId: g.id,
                                  taskId: t.id,
                                  uid: store.currentUid,
                                );
                                if (!ok) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Nicht möglich (Deadline oder Task inaktiv).')),
                                  );
                                }
                                setState(() {});
                              },
                              onToggleActive: () {
                                store.toggleTaskActive(
                                  groupId: g.id,
                                  taskId: t.id,
                                  active: !t.isActive,
                                );
                                setState(() {});
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final created = await showDialog<bool>(
                              context: context,
                              builder: (_) => CreateTaskDialog(groupId: g.id),
                            );
                            if (created == true) setState(() {});
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Task hinzufügen'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scoreboard
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader('Scoreboard'),
                      // Scoreboard importiert Member selbst, daher hier kein Member-Import nötig
                      Expanded(child: Scoreboard(members: g.members.values.toList())),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget { //-- neues Widget namens "_SectionHeader"
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding( //-- "Padding" sagt wie viel Abstand von dem Widget an welche Seite es geben soll
      padding: const EdgeInsets.all(12.0), //-- An allen Seiten sollen 12 Pixel abstand gehalten werden
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)), //-- Text des Widget was im Konstruktor war
      //-- "frontsize" sagt wie groß die Schrift sein soll (hier 18 Pixel hoch), "FontWeight.w600" sagt wie fett ein bustabe ist. w600 ist normal also halbfett
    );
  }
}

class _TaskCard extends StatelessWidget {
  final tm.TaskItem t;
  final bool isLocked;
  final VoidCallback onComplete;
  final VoidCallback onToggleActive;

  const _TaskCard({
    required this.t,
    required this.isLocked,
    required this.onComplete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), //-- Abstand links/rechts = 12, oben/unten = 6 Pixel.
      child: ListTile(
        title: Text(t.title),
        subtitle: Text('Punkte: ${t.pointValue}  •  ${t.isActive ? "aktiv" : "inaktiv"}'),
        trailing: FilledButton(
          onPressed: (isLocked || !t.isActive) ? null : onComplete,
          child: const Text('Done'),
        ),
        onLongPress: onToggleActive,
      ),
    );
  }
}
