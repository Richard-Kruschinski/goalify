class TaskItem {
  final String id;
  final String title;
  final int pointValue;
  final DateTime createdAt;
  bool isActive;

  TaskItem({
    required this.id,
    required this.title,
    this.pointValue = 1,
    DateTime? createdAt,
    this.isActive = true,
  }) : createdAt = createdAt ?? DateTime.now();
}
