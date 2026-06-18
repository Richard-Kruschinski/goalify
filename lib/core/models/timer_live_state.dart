enum TimerType { pomodoro, music, interval }

class TimerLiveState {
  final String timerId;
  final TimerType timerType;
  final String title;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isPaused;
  final String currentPhase;
  final int currentRound;
  final int totalRounds;
  // Additional optional actions beyond pause+stop, e.g. ['skip']
  final List<String> additionalActions;

  const TimerLiveState({
    required this.timerId,
    required this.timerType,
    required this.title,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.isRunning = true,
    this.isPaused = false,
    this.currentPhase = '',
    this.currentRound = 0,
    this.totalRounds = 0,
    this.additionalActions = const [],
  });

  Map<String, dynamic> toMap() => {
        'timerId': timerId,
        'timerType': timerType.name,
        'title': title,
        'remainingSeconds': remainingSeconds,
        'totalSeconds': totalSeconds,
        'isRunning': isRunning,
        'isPaused': isPaused,
        'currentPhase': currentPhase,
        'currentRound': currentRound,
        'totalRounds': totalRounds,
        'additionalActions': additionalActions,
      };

  TimerLiveState copyWith({
    int? remainingSeconds,
    int? totalSeconds,
    bool? isRunning,
    bool? isPaused,
    String? currentPhase,
    int? currentRound,
    int? totalRounds,
    List<String>? additionalActions,
  }) =>
      TimerLiveState(
        timerId: timerId,
        timerType: timerType,
        title: title,
        remainingSeconds: remainingSeconds ?? this.remainingSeconds,
        totalSeconds: totalSeconds ?? this.totalSeconds,
        isRunning: isRunning ?? this.isRunning,
        isPaused: isPaused ?? this.isPaused,
        currentPhase: currentPhase ?? this.currentPhase,
        currentRound: currentRound ?? this.currentRound,
        totalRounds: totalRounds ?? this.totalRounds,
        additionalActions: additionalActions ?? this.additionalActions,
      );
}
