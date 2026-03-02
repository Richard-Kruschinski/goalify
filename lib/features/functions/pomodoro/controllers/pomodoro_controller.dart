import 'dart:async';
import 'package:flutter/material.dart';
import '../models/pomodoro_stats.dart';
import '../services/platform_channel_service.dart';
import '../../../../core/utils/local_storage.dart';

class PomodoroController extends ChangeNotifier {
  // Timer settings (in seconds for easier testing, can be changed)
  static const int workDuration = 25 * 60; // 25 minutes
  static const int shortBreakDuration = 5 * 60; // 5 minutes
  static const int longBreakDuration = 15 * 60; // 15 minutes
  static const int cyclesBeforeLongBreak = 4;

  // State
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  PomodoroTimerState _timerState = PomodoroTimerState.idle;
  int _remainingSeconds = workDuration;
  int _currentCycle = 1; // 1-4
  PomodoroStats _stats = PomodoroStats();
  
  Timer? _timer;
  final PlatformChannelService _platformService = PlatformChannelService();

  // Getters
  PomodoroPhase get currentPhase => _currentPhase;
  PomodoroTimerState get timerState => _timerState;
  int get remainingSeconds => _remainingSeconds;
  int get currentCycle => _currentCycle;
  PomodoroStats get stats => _stats;
  bool get isAppBlockingActive => _platformService.isBlockingActive;
  bool get isAppBlockingSupported => _platformService.isAppBlockingSupported();
  PlatformChannelService get platformService => _platformService;

  String get currentPhaseLabel {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return 'Work';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }

  int get totalSecondsForPhase {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return workDuration;
      case PomodoroPhase.shortBreak:
        return shortBreakDuration;
      case PomodoroPhase.longBreak:
        return longBreakDuration;
    }
  }

  double get progress {
    return 1.0 - (_remainingSeconds / totalSecondsForPhase);
  }

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  PomodoroController() {
    _loadStats();
  }

  // Load stats from local storage
  Future<void> _loadStats() async {
    final data = await LocalStorage.loadJson('pomodoro_stats', fallback: null);
    if (data != null) {
      _stats = PomodoroStats.fromJson(data);
      _checkAndResetDailyStats();
      notifyListeners();
    }
  }

  // Check if we need to reset daily stats
  void _checkAndResetDailyStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).toIso8601String();
    
    if (_stats.lastResetDate != today) {
      // New day - reset daily stats but keep weekly
      _stats = _stats.copyWith(
        completedSessionsToday: 0,
        totalFocusTimeToday: 0,
        dailyFocusScore: 0,
        lastResetDate: today,
      );
      _saveStats();
    }
  }

  // Save stats to local storage
  Future<void> _saveStats() async {
    await LocalStorage.saveJson('pomodoro_stats', _stats.toJson());
  }

  // Calculate daily focus score
  int _calculateDailyFocusScore() {
    int score = _stats.completedSessionsToday * 10;
    
    // Bonus for completing full cycles (4 work sessions + 1 long break)
    final fullCycles = _stats.completedSessionsToday ~/ 4;
    score += fullCycles * 5;
    
    // Cap at 100
    return score > 100 ? 100 : score;
  }

  // Start the timer
  void start() async {
    if (_timerState == PomodoroTimerState.running) return;

    _timerState = PomodoroTimerState.running;
    
    // Start app blocking if in work phase and on Android
    if (_currentPhase == PomodoroPhase.work && _platformService.isAndroid) {
      await _platformService.startAppBlocking();
    }

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

  // Pause the timer
  void pause() async {
    if (_timerState != PomodoroTimerState.running) return;

    _timer?.cancel();
    _timerState = PomodoroTimerState.paused;
    
    // Stop app blocking when paused
    await _platformService.stopAppBlocking();
    
    notifyListeners();
  }

  // Reset the timer
  void reset() async {
    _timer?.cancel();
    _timerState = PomodoroTimerState.idle;
    _remainingSeconds = totalSecondsForPhase;
    
    // Stop app blocking
    await _platformService.stopAppBlocking();
    
    notifyListeners();
  }

  // Complete current phase and move to next
  void _completePhase() async {
    _timer?.cancel();
    
    // Stop app blocking
    await _platformService.stopAppBlocking();

    // Update stats
    if (_currentPhase == PomodoroPhase.work) {
      // Completed a work session
      _stats = _stats.copyWith(
        completedSessionsToday: _stats.completedSessionsToday + 1,
        totalFocusTimeToday: _stats.totalFocusTimeToday + (workDuration ~/ 60),
        totalFocusTimeThisWeek: _stats.totalFocusTimeThisWeek + (workDuration ~/ 60),
      );
      
      // Move to next cycle or break
      if (_currentCycle >= cyclesBeforeLongBreak) {
        // Time for long break
        _currentPhase = PomodoroPhase.longBreak;
        _currentCycle = 1;
        _stats = _stats.copyWith(
          completedCycles: _stats.completedCycles + 1,
        );
      } else {
        // Short break
        _currentPhase = PomodoroPhase.shortBreak;
        _currentCycle++;
      }
    } else {
      // Completed a break - back to work
      _currentPhase = PomodoroPhase.work;
    }

    // Calculate and update daily focus score
    _stats = _stats.copyWith(
      dailyFocusScore: _calculateDailyFocusScore(),
    );
    
    await _saveStats();

    // Reset timer for next phase
    _remainingSeconds = totalSecondsForPhase;
    _timerState = PomodoroTimerState.idle;
    
    notifyListeners();
  }

  // Skip to next phase manually
  void skipToNextPhase() async {
    _timer?.cancel();
    await _platformService.stopAppBlocking();

    if (_currentPhase == PomodoroPhase.work) {
      if (_currentCycle >= cyclesBeforeLongBreak) {
        _currentPhase = PomodoroPhase.longBreak;
        _currentCycle = 1;
      } else {
        _currentPhase = PomodoroPhase.shortBreak;
        _currentCycle++;
      }
    } else {
      _currentPhase = PomodoroPhase.work;
    }

    _remainingSeconds = totalSecondsForPhase;
    _timerState = PomodoroTimerState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _platformService.stopAppBlocking();
    super.dispose();
  }
}
