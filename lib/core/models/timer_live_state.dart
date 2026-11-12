enum TimerType { pomodoro, music, interval, rest }

class TimerLiveState {
  final String timerId;
  final TimerType timerType;
  final String title;
  /// Countdown: seconds left. Count-up ([countUp]): seconds already elapsed.
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRunning;
  final bool isPaused;
  final String currentPhase;
  final int currentRound;
  final int totalRounds;
  // Additional optional actions beyond pause+stop, e.g. ['skip']
  final List<String> additionalActions;
  /// Counts up like a stopwatch instead of down; only a stop button is shown.
  final bool countUp;
  /// Count-up only: vibrating alert once this many seconds have elapsed.
  final int? alertAtSeconds;
  /// Count-up only: the native side ends the timer after this many seconds,
  /// even while the app is in the background.
  final int? autoStopSeconds;

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
    this.countUp = false,
    this.alertAtSeconds,
    this.autoStopSeconds,
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
        'countUp': countUp,
        'alertAtSeconds': alertAtSeconds,
        'autoStopSeconds': autoStopSeconds,
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
        countUp: countUp,
        alertAtSeconds: alertAtSeconds,
        autoStopSeconds: autoStopSeconds,
      );
}
