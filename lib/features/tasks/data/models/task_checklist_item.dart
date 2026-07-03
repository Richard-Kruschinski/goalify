/// Checklist-style note entry attached to a [DailyTask].
class TaskChecklistItem {
  final String text;
  bool done;

  TaskChecklistItem({
    required this.text,
    this.done = false,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'done': done,
  };

  factory TaskChecklistItem.fromMap(Map<String, dynamic> m) => TaskChecklistItem(
    text: (m['text'] ?? '').toString(),
    done: (m['done'] ?? false) as bool,
  );
}
