class IntervalTaskProfileItem {
  final String name;
  final int durationSeconds;
  final int pauseBeforeSeconds;

  const IntervalTaskProfileItem({
    required this.name,
    required this.durationSeconds,
    this.pauseBeforeSeconds = 0,
  });
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
