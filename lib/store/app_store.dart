import '../models/group.dart' as gm;
import '../models/member.dart' as mm;
import '../models/task_item.dart' as tm;

class AppStore {
  static final AppStore _i = AppStore._();
  AppStore._();
  factory AppStore() => _i;

  // Simulierter eingeloggter User
  final String currentUid = 'u1';
  final String currentName = 'You';

  // Stark typisiert auf Group
  final Map<String, gm.Group> _groups = {}; // id -> group

  List<gm.Group> listGroups() =>
      _groups.values.toList()..sort((a, b) => a.deadline.compareTo(b.deadline));

  gm.Group? getGroup(String id) => _groups[id];

  gm.Group createGroup({required String name, required DateTime deadline}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final g = gm.Group(
      id: id,
      name: name,
      deadline: deadline,
      ownerUid: currentUid,
      members: {currentUid: mm.Member(uid: currentUid, name: currentName)},
    );
    _groups[id] = g;
    return g;
  }

  void joinGroup({
    required String groupId,
    required String uid,
    required String name,
  }) {
    final g = _groups[groupId];
    if (g == null) return;
    g.members.putIfAbsent(uid, () => mm.Member(uid: uid, name: name));
  }

  void addTask({
    required String groupId,
    required String title,
    int points = 1,
  }) {
    final g = _groups[groupId];
    if (g == null) return;
    final t = tm.TaskItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      pointValue: points,
    );
    g.tasks.add(t);
  }

  bool completeTask({
    required String groupId,
    required String taskId,
    required String uid,
  }) {
    final g = _groups[groupId];
    if (g == null) return false;
    if (DateTime.now().isAfter(g.deadline)) return false;

    final idx = g.tasks.indexWhere((t) => t.id == taskId);
    if (idx < 0 || !g.tasks[idx].isActive) return false;

    final member = g.members[uid];
    if (member == null) return false;

    member.score += g.tasks[idx].pointValue;
    return true;
  }

  void toggleTaskActive({
    required String groupId,
    required String taskId,
    required bool active,
  }) {
    final g = _groups[groupId];
    if (g == null) return;
    final i = g.tasks.indexWhere((t) => t.id == taskId);
    if (i >= 0) g.tasks[i].isActive = active;
  }
}
