class PomodoroStats {
  final int completedSessionsToday;
  final int totalFocusTimeToday; // in minutes
  final int totalFocusTimeThisWeek; // in minutes
  final int completedCycles;
  final String lastResetDate; // ISO 8601 date string
  final int dailyFocusScore; // 0-100

  PomodoroStats({
    this.completedSessionsToday = 0,
    this.totalFocusTimeToday = 0,
    this.totalFocusTimeThisWeek = 0,
    this.completedCycles = 0,
    this.lastResetDate = '',
    this.dailyFocusScore = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'completedSessionsToday': completedSessionsToday,
      'totalFocusTimeToday': totalFocusTimeToday,
      'totalFocusTimeThisWeek': totalFocusTimeThisWeek,
      'completedCycles': completedCycles,
      'lastResetDate': lastResetDate,
      'dailyFocusScore': dailyFocusScore,
    };
  }

  factory PomodoroStats.fromJson(Map<String, dynamic> json) {
    return PomodoroStats(
      completedSessionsToday: json['completedSessionsToday'] ?? 0,
      totalFocusTimeToday: json['totalFocusTimeToday'] ?? 0,
      totalFocusTimeThisWeek: json['totalFocusTimeThisWeek'] ?? 0,
      completedCycles: json['completedCycles'] ?? 0,
      lastResetDate: json['lastResetDate'] ?? '',
      dailyFocusScore: json['dailyFocusScore'] ?? 0,
    );
  }

  PomodoroStats copyWith({
    int? completedSessionsToday,
    int? totalFocusTimeToday,
    int? totalFocusTimeThisWeek,
    int? completedCycles,
    String? lastResetDate,
    int? dailyFocusScore,
  }) {
    return PomodoroStats(
      completedSessionsToday: completedSessionsToday ?? this.completedSessionsToday,
      totalFocusTimeToday: totalFocusTimeToday ?? this.totalFocusTimeToday,
      totalFocusTimeThisWeek: totalFocusTimeThisWeek ?? this.totalFocusTimeThisWeek,
      completedCycles: completedCycles ?? this.completedCycles,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      dailyFocusScore: dailyFocusScore ?? this.dailyFocusScore,
    );
  }
}

enum PomodoroPhase {
  work,
  shortBreak,
  longBreak,
}

enum PomodoroTimerState {
  idle,
  running,
  paused,
}
