import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/interval_timer_state.dart';

class IntervalTimerController extends ChangeNotifier {
  // Settings
  int _workDuration = 30; // in seconds
  int _breakDuration = 10; // in seconds
  int _totalCycles = 4;

  // State
  IntervalTimerPhase _currentPhase = IntervalTimerPhase.work;
  IntervalTimerState _timerState = IntervalTimerState.idle;
  int _remainingSeconds = 30;
  int _currentCycle = 1;

  Timer? _timer;

  // Getters
  int get workDuration => _workDuration;
  int get breakDuration => _breakDuration;
  int get totalCycles => _totalCycles;
  IntervalTimerPhase get currentPhase => _currentPhase;
  IntervalTimerState get timerState => _timerState;
  int get remainingSeconds => _remainingSeconds;
  int get currentCycle => _currentCycle;

  String get currentPhaseLabel {
    return _currentPhase == IntervalTimerPhase.work ? 'Work' : 'Break';
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  int get totalSecondsForPhase {
    return _currentPhase == IntervalTimerPhase.work
        ? _workDuration
        : _breakDuration;
  }

  double get progress {
    return 1.0 - (_remainingSeconds / totalSecondsForPhase);
  }

  // Set durations
  void setWorkDuration(int seconds) {
    _workDuration = seconds;
    if (_timerState == IntervalTimerState.idle) {
      _remainingSeconds = _workDuration;
    }
    notifyListeners();
  }

  void setBreakDuration(int seconds) {
    _breakDuration = seconds;
    if (_timerState == IntervalTimerState.idle && _currentPhase == IntervalTimerPhase.break_) {
      _remainingSeconds = _breakDuration;
    }
    notifyListeners();
  }

  void setTotalCycles(int cycles) {
    _totalCycles = cycles;
    notifyListeners();
  }

  // Start timer
  void start() {
    if (_timerState == IntervalTimerState.running) return;

    _timerState = IntervalTimerState.running;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completePhase();
      }
    });

    notifyListeners();
  }

  // Pause timer
  void pause() {
    if (_timerState != IntervalTimerState.running) return;

    _timer?.cancel();
    _timerState = IntervalTimerState.paused;
    notifyListeners();
  }

  // Resume timer
  void resume() {
    if (_timerState != IntervalTimerState.paused) return;

    _timerState = IntervalTimerState.running;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _completePhase();
      }
    });

    notifyListeners();
  }

  // Reset timer
  void reset() {
    _timer?.cancel();
    _timerState = IntervalTimerState.idle;
    _currentPhase = IntervalTimerPhase.work;
    _currentCycle = 1;
    _remainingSeconds = _workDuration;
    notifyListeners();
  }

  // Complete current phase
  void _completePhase() {
    _timer?.cancel();

    if (_currentPhase == IntervalTimerPhase.work) {
      // Switch to break
      _currentPhase = IntervalTimerPhase.break_;
      _remainingSeconds = _breakDuration;
    } else {
      // Switch to work
      if (_currentCycle < _totalCycles) {
        _currentCycle++;
        _currentPhase = IntervalTimerPhase.work;
        _remainingSeconds = _workDuration;
      } else {
        // All cycles completed
        _timerState = IntervalTimerState.idle;
        _currentPhase = IntervalTimerPhase.work;
        _currentCycle = 1;
        _remainingSeconds = _workDuration;
        notifyListeners();
        return;
      }
    }

    // Continue timer
    start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
