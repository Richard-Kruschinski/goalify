class PomodoroProfile {
  final String id;
  final String name;
  final int workDuration; // in minutes
  final int shortBreakDuration; // in minutes
  final int longBreakDuration; // in minutes
  final int cyclesBeforeLongBreak;
  final bool shouldBlockApps; // whether to block apps during work sessions

  PomodoroProfile({
    required this.id,
    required this.name,
    required this.workDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.cyclesBeforeLongBreak,
    this.shouldBlockApps = true, // default: block apps
  });

  // Predefined profiles
  static PomodoroProfile get classic => PomodoroProfile(
        id: 'classic',
        name: 'Classic',
        workDuration: 25,
        shortBreakDuration: 5,
        longBreakDuration: 15,
        cyclesBeforeLongBreak: 4,
        shouldBlockApps: true,
      );

  static PomodoroProfile get short => PomodoroProfile(
        id: 'short',
        name: 'Short',
        workDuration: 15,
        shortBreakDuration: 3,
        longBreakDuration: 10,
        cyclesBeforeLongBreak: 4,
        shouldBlockApps: true,
      );

  static PomodoroProfile get long => PomodoroProfile(
        id: 'long',
        name: 'Long',
        workDuration: 50,
        shortBreakDuration: 10,
        longBreakDuration: 30,
        cyclesBeforeLongBreak: 3,
        shouldBlockApps: true,
      );

  static PomodoroProfile get intense => PomodoroProfile(
        id: 'intense',
        name: 'Intense',
        workDuration: 45,
        shortBreakDuration: 5,
        longBreakDuration: 20,
        cyclesBeforeLongBreak: 3,
        shouldBlockApps: true,
      );

  static List<PomodoroProfile> get defaultProfiles => [
        classic,
        short,
        long,
        intense,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workDuration': workDuration,
      'shortBreakDuration': shortBreakDuration,
      'longBreakDuration': longBreakDuration,
      'cyclesBeforeLongBreak': cyclesBeforeLongBreak,
      'shouldBlockApps': shouldBlockApps,
    };
  }

  factory PomodoroProfile.fromJson(Map<String, dynamic> json) {
    return PomodoroProfile(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      workDuration: json['workDuration'] ?? 25,
      shortBreakDuration: json['shortBreakDuration'] ?? 5,
      longBreakDuration: json['longBreakDuration'] ?? 15,
      cyclesBeforeLongBreak: json['cyclesBeforeLongBreak'] ?? 4,
      shouldBlockApps: json['shouldBlockApps'] ?? true,
    );
  }

  PomodoroProfile copyWith({
    String? id,
    String? name,
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? cyclesBeforeLongBreak,
    bool? shouldBlockApps,
  }) {
    return PomodoroProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
      shouldBlockApps: shouldBlockApps ?? this.shouldBlockApps,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PomodoroProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
