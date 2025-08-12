import 'member.dart';
import 'task_item.dart';

class Group {
  final String id;
  String name;
  DateTime deadline;
  final String ownerUid;
  final Map<String, Member> members; // uid -> Member
  final List<TaskItem> tasks;
  String? imageUrl; // null = kein Bild gesetzt


  Group({
    required this.id,
    required this.name,
    required this.deadline,
    required this.ownerUid,
    Map<String, Member>? members,
    List<TaskItem>? tasks,
  })  : members = members ?? {},
        tasks = tasks ?? [];
}
