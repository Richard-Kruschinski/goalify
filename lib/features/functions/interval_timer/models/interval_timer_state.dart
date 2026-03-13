class IntervalTaskProfileItem {
  final String name;
  final int durationSeconds;
  final int pauseBeforeSeconds;

  const IntervalTaskProfileItem({
    required this.name,
    required this.durationSeconds,
    this.pauseBeforeSeconds = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'durationSeconds': durationSeconds,
      'pauseBeforeSeconds': pauseBeforeSeconds,
    };
  }

  factory IntervalTaskProfileItem.fromJson(Map<String, dynamic> json) {
    return IntervalTaskProfileItem(
      name: (json['name'] ?? '') as String,
      durationSeconds: (json['durationSeconds'] ?? 1) as int,
      pauseBeforeSeconds: (json['pauseBeforeSeconds'] ?? 0) as int,
    );
  }
}

class IntervalTimerProfile {
  final String id;
  final String name;
  final List<IntervalTaskProfileItem> tasks;

  const IntervalTimerProfile({
    required this.id,
    required this.name,
    required this.tasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory IntervalTimerProfile.fromJson(Map<String, dynamic> json) {
    final taskList = (json['tasks'] as List<dynamic>? ?? const []);
    return IntervalTimerProfile(
      id: (json['id'] ?? '') as String,
      name: (json['name'] ?? '') as String,
      tasks: taskList
          .whereType<Map<String, dynamic>>()
          .map(IntervalTaskProfileItem.fromJson)
          .toList(),
    );
  }
}

enum IntervalTimerPhase {
  task,
  pause,
}

enum IntervalTimerState {
  idle,
  running,
  paused,
}
