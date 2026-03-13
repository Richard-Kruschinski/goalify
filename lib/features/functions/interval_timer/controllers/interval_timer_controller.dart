import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/interval_timer_state.dart';

class IntervalTimerController extends ChangeNotifier {
  // Profile
  final List<IntervalTaskProfileItem> _tasks = [];

  // Runtime state
  IntervalTimerPhase _currentPhase = IntervalTimerPhase.task;
  IntervalTimerState _timerState = IntervalTimerState.idle;
  int _remainingSeconds = 0;
  int _currentTaskIndex = 0;
  int _currentPauseSeconds = 0;
  int _pendingTaskIndex = 0;

  Timer? _timer;

  // Getters
  List<IntervalTaskProfileItem> get tasks => List.unmodifiable(_tasks);
  IntervalTimerPhase get currentPhase => _currentPhase;
  IntervalTimerState get timerState => _timerState;
  int get remainingSeconds => _remainingSeconds;
  int get currentTaskNumber => _tasks.isEmpty ? 0 : _currentTaskIndex + 1;
  int get totalTasks => _tasks.length;
  bool get hasTasks => _tasks.isNotEmpty;
  bool get isInPause => _currentPhase == IntervalTimerPhase.pause;

  String get currentPhaseLabel {
    return _currentPhase == IntervalTimerPhase.task ? 'Aufgabe' : 'Pause';
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get currentItemLabel {
    if (_tasks.isEmpty) return 'Kein Profil erstellt';
    if (_currentPhase == IntervalTimerPhase.pause) {
      return 'Pause vor ${_tasks[_pendingTaskIndex].name}';
    }
    return _tasks[_currentTaskIndex].name;
  }

  int get totalSecondsForPhase {
    if (_tasks.isEmpty) return 0;
    return _currentPhase == IntervalTimerPhase.pause
        ? _currentPauseSeconds
        : _tasks[_currentTaskIndex].durationSeconds;
  }

  double get progress {
    final total = totalSecondsForPhase;
    if (total <= 0) return 0;
    return (1.0 - (_remainingSeconds / total)).clamp(0.0, 1.0);
  }

  void addTask({
    required String name,
    required int durationSeconds,
    int pauseBeforeSeconds = 0,
  }) {
    final sanitizedName = name.trim();
    final safeDuration = durationSeconds < 1 ? 1 : durationSeconds;
    final safePause = pauseBeforeSeconds < 0 ? 0 : pauseBeforeSeconds;

    if (sanitizedName.isEmpty) return;
    if (_timerState != IntervalTimerState.idle) return;

    _tasks.add(
      IntervalTaskProfileItem(
        name: sanitizedName,
        durationSeconds: safeDuration,
        pauseBeforeSeconds: _tasks.isEmpty ? 0 : safePause,
      ),
    );

    if (_tasks.length == 1) {
      _currentTaskIndex = 0;
      _currentPhase = IntervalTimerPhase.task;
      _remainingSeconds = _tasks.first.durationSeconds;
    }

    notifyListeners();
  }

  void removeTask(int index) {
    if (_timerState != IntervalTimerState.idle) return;
    if (index < 0 || index >= _tasks.length) return;

    _tasks.removeAt(index);
    if (_tasks.isEmpty) {
      _currentTaskIndex = 0;
      _remainingSeconds = 0;
      _currentPhase = IntervalTimerPhase.task;
      notifyListeners();
      return;
    }

    _currentTaskIndex = 0;
    _currentPhase = IntervalTimerPhase.task;
    _remainingSeconds = _tasks.first.durationSeconds;

    if (_tasks.first.pauseBeforeSeconds != 0) {
      _tasks[0] = IntervalTaskProfileItem(
        name: _tasks[0].name,
        durationSeconds: _tasks[0].durationSeconds,
        pauseBeforeSeconds: 0,
      );
    }

    notifyListeners();
  }

  void clearProfile() {
    if (_timerState != IntervalTimerState.idle) return;

    _tasks.clear();
    _currentTaskIndex = 0;
    _pendingTaskIndex = 0;
    _currentPauseSeconds = 0;
    _currentPhase = IntervalTimerPhase.task;
    _remainingSeconds = 0;
    notifyListeners();
  }

  void start() {
    if (_timerState == IntervalTimerState.running) return;
    if (_tasks.isEmpty) return;

    if (_currentPhase == IntervalTimerPhase.task && _remainingSeconds <= 0) {
      _remainingSeconds = _tasks[_currentTaskIndex].durationSeconds;
    }
    if (_currentPhase == IntervalTimerPhase.pause && _remainingSeconds <= 0) {
      _remainingSeconds = _currentPauseSeconds;
    }

    _timer?.cancel();

    _timerState = IntervalTimerState.running;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completePhase();
      }
    });

    notifyListeners();
  }

  void pause() {
    if (_timerState != IntervalTimerState.running) return;

    _timer?.cancel();
    _timerState = IntervalTimerState.paused;
    notifyListeners();
  }

  void resume() {
    if (_timerState != IntervalTimerState.paused) return;
    start();
  }

  void reset() {
    _timer?.cancel();
    _timerState = IntervalTimerState.idle;
    _currentPhase = IntervalTimerPhase.task;
    _pendingTaskIndex = 0;
    _currentPauseSeconds = 0;
    _currentTaskIndex = 0;
    _remainingSeconds = _tasks.isEmpty ? 0 : _tasks.first.durationSeconds;
    notifyListeners();
  }

  void _completePhase() {
    _timer?.cancel();

    if (_tasks.isEmpty) {
      reset();
      return;
    }

    if (_currentPhase == IntervalTimerPhase.pause) {
      _currentTaskIndex = _pendingTaskIndex;
      _currentPhase = IntervalTimerPhase.task;
      _remainingSeconds = _tasks[_currentTaskIndex].durationSeconds;
      start();
      return;
    }

    final nextTaskIndex = _currentTaskIndex + 1;
    if (nextTaskIndex >= _tasks.length) {
      _timerState = IntervalTimerState.idle;
      _currentPhase = IntervalTimerPhase.task;
      _currentTaskIndex = 0;
      _pendingTaskIndex = 0;
      _currentPauseSeconds = 0;
      _remainingSeconds = _tasks.first.durationSeconds;
      notifyListeners();
      return;
    }

    final pauseBeforeNext = _tasks[nextTaskIndex].pauseBeforeSeconds;
    if (pauseBeforeNext > 0) {
      _currentPauseSeconds = pauseBeforeNext;
      _pendingTaskIndex = nextTaskIndex;
      _currentPhase = IntervalTimerPhase.pause;
      _remainingSeconds = pauseBeforeNext;
    } else {
      _currentTaskIndex = nextTaskIndex;
      _currentPhase = IntervalTimerPhase.task;
      _remainingSeconds = _tasks[_currentTaskIndex].durationSeconds;
    }

    start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
