class PomodoroProfile {
  final String id;
  final String name;
  final int workDuration; // in minutes
  final int shortBreakDuration; // in minutes
  final int longBreakDuration; // in minutes
  final int cyclesBeforeLongBreak;

  PomodoroProfile({
    required this.id,
    required this.name,
    required this.workDuration,
    required this.shortBreakDuration,
    required this.longBreakDuration,
    required this.cyclesBeforeLongBreak,
  });

  // Predefined profiles
  static PomodoroProfile get classic => PomodoroProfile(
        id: 'classic',
        name: 'Klassisch',
        workDuration: 25,
        shortBreakDuration: 5,
        longBreakDuration: 15,
        cyclesBeforeLongBreak: 4,
      );

  static PomodoroProfile get short => PomodoroProfile(
        id: 'short',
        name: 'Kurz',
        workDuration: 15,
        shortBreakDuration: 3,
        longBreakDuration: 10,
        cyclesBeforeLongBreak: 4,
      );

  static PomodoroProfile get long => PomodoroProfile(
        id: 'long',
        name: 'Lang',
        workDuration: 50,
        shortBreakDuration: 10,
        longBreakDuration: 30,
        cyclesBeforeLongBreak: 3,
      );

  static PomodoroProfile get intense => PomodoroProfile(
        id: 'intense',
        name: 'Intensiv',
        workDuration: 45,
        shortBreakDuration: 5,
        longBreakDuration: 20,
        cyclesBeforeLongBreak: 3,
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
    );
  }

  PomodoroProfile copyWith({
    String? id,
    String? name,
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? cyclesBeforeLongBreak,
  }) {
    return PomodoroProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      cyclesBeforeLongBreak: cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
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
