import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/models/pomodoro_stats.dart';
import '../../data/models/pomodoro_profile.dart';
import '../../data/datasources/platform_channel_service.dart';
import '../../data/repositories/pomodoro_repository_impl.dart';
import '../../domain/repositories/pomodoro_repository.dart';
import '../../../../../core/models/timer_live_state.dart';
import '../../../../../core/utils/day_cycle.dart';
import '../../../../../core/services/timer_live_presentation_service.dart';

class PomodoroController extends ChangeNotifier {
  // All persistence goes through the repository abstraction so the storage
  // backend can be swapped without touching this controller.
  final PomodoroRepository _repo = PomodoroRepositoryImpl();

  // Current profile
  PomodoroProfile _currentProfile = PomodoroProfile.classic;
  List<PomodoroProfile> _customProfiles = [];

  // State
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  PomodoroTimerState _timerState = PomodoroTimerState.idle;
  int _remainingSeconds = 0;
  int _currentCycle = 1; // 1-4
  PomodoroStats _stats = PomodoroStats();
  DateTime? _phaseEndsAt;

  Timer? _timer;
  final PlatformChannelService _platformService = PlatformChannelService();
  final _liveService = TimerLivePresentationService.instance;

  // Getters
  PomodoroProfile get currentProfile => _currentProfile;
  List<PomodoroProfile> get allProfiles =>
      [...PomodoroProfile.defaultProfiles, ..._customProfiles];
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
        return 'Fokus';
      case PomodoroPhase.shortBreak:
        return 'Kurze Pause';
      case PomodoroPhase.longBreak:
        return 'Lange Pause';
    }
  }

  int get totalSecondsForPhase {
    switch (_currentPhase) {
      case PomodoroPhase.work:
        return _currentProfile.workDuration * 60;
      case PomodoroPhase.shortBreak:
        return _currentProfile.shortBreakDuration * 60;
      case PomodoroPhase.longBreak:
        return _currentProfile.longBreakDuration * 60;
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
    _loadProfile();
    _loadCustomProfiles();
    _registerLiveCallbacks();
  }

  void _registerLiveCallbacks() {
    _liveService.registerCallbacks(
      'pomodoro',
      onPause: pause,
      onResume: () => start(),
      onStop: reset,
      onSkip: skipToNextPhase,
    );
  }

  TimerLiveState _buildLiveState() => TimerLiveState(
        timerId: 'pomodoro',
        timerType: TimerType.pomodoro,
        title: 'Pomodoro',
        remainingSeconds: _remainingSeconds,
        totalSeconds: totalSecondsForPhase,
        isRunning: _timerState == PomodoroTimerState.running,
        isPaused: _timerState == PomodoroTimerState.paused,
        currentPhase: currentPhaseLabel,
        currentRound: _currentCycle,
        totalRounds: _currentProfile.cyclesBeforeLongBreak,
        additionalActions: const ['skip'],
      );

  // Load profile from local storage
  Future<void> _loadProfile() async {
    final profile = await _repo.loadProfile();
    if (profile != null) {
      _currentProfile = profile;
      _remainingSeconds = totalSecondsForPhase;
      notifyListeners();
    } else {
      _remainingSeconds = totalSecondsForPhase;
    }
  }

  Future<void> _saveProfile() async {
    await _repo.saveProfile(_currentProfile);
  }

  Future<void> _loadCustomProfiles() async {
    final profiles = await _repo.loadCustomProfiles();
    if (profiles != null) {
      _customProfiles = profiles;
      notifyListeners();
    }
  }

  Future<void> _saveCustomProfiles() async {
    await _repo.saveCustomProfiles(_customProfiles);
  }

  Future<void> changeProfile(PomodoroProfile profile) async {
    if (_timerState == PomodoroTimerState.running) return;
    _currentProfile = profile;
    _remainingSeconds = totalSecondsForPhase;
    await _saveProfile();
    notifyListeners();
  }

  Future<void> addCustomProfile(PomodoroProfile profile) async {
    _customProfiles.add(profile);
    await _saveCustomProfiles();
    notifyListeners();
  }

  Future<void> updateCustomProfile(PomodoroProfile updatedProfile) async {
    final index = _customProfiles.indexWhere((p) => p.id == updatedProfile.id);
    if (index == -1) return;
    _customProfiles[index] = updatedProfile;
    if (_currentProfile.id == updatedProfile.id) {
      _currentProfile = updatedProfile;
      _remainingSeconds = totalSecondsForPhase;
      await _saveProfile();
    }
    await _saveCustomProfiles();
    notifyListeners();
  }

  Future<void> deleteCustomProfile(String profileId) async {
    final wasCurrentProfile = _currentProfile.id == profileId;
    _customProfiles.removeWhere((p) => p.id == profileId);
    if (wasCurrentProfile) {
      _currentProfile = PomodoroProfile.classic;
      _remainingSeconds = totalSecondsForPhase;
      await _saveProfile();
    }
    await _saveCustomProfiles();
    notifyListeners();
  }

  Future<void> _loadStats() async {
    final stats = await _repo.loadStats();
    if (stats != null) {
      _stats = stats;
      _checkAndResetDailyStats();
      notifyListeners();
    }
  }

  void _checkAndResetDailyStats() {
    final today = DayCycle.today().toIso8601String();
    if (_stats.lastResetDate != today) {
      _stats = _stats.copyWith(
        completedSessionsToday: 0,
        totalFocusTimeToday: 0,
        dailyFocusScore: 0,
        lastResetDate: today,
      );
      _saveStats();
    }
  }

  Future<void> _saveStats() async {
    await _repo.saveStats(_stats);
  }

  /// Adds completed focus minutes to the per-day history (feeds the weekly
  /// review) and drops entries older than 30 days.
  Future<void> _recordFocusMinutes(int minutes) async {
    final history = await _repo.loadFocusHistory();
    final today = DayCycle.today();
    final todayKey = _dateKey(today);
    history[todayKey] = (history[todayKey] ?? 0) + minutes;

    final cutoff = today.subtract(const Duration(days: 30));
    history.removeWhere((key, _) {
      final parts = key.split('-');
      if (parts.length != 3) return true;
      final date = DateTime(
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 1,
        int.tryParse(parts[2]) ?? 1,
      );
      return date.isBefore(cutoff);
    });

    await _repo.saveFocusHistory(history);
  }

  String _dateKey(DateTime dt) => DayCycle.dateKey(dt);

  int _calculateDailyFocusScore() {
    int score = _stats.completedSessionsToday * 10;
    final fullCycles = _stats.completedSessionsToday ~/ 4;
    score += fullCycles * 5;
    return score > 100 ? 100 : score;
  }

  Future<bool> checkAndRequestNotificationPermission() async {
    if (!_platformService.isAndroid) return true;
    final status = await Permission.notification.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }
    return false;
  }

  // Start the timer
  Future<bool> start() async {
    if (_timerState == PomodoroTimerState.running) return true;

    if (_platformService.isAndroid) {
      final hasPermission = await checkAndRequestNotificationPermission();
      if (!hasPermission) {
        if (kDebugMode) print('Notification permission not granted');
        return false;
      }
    }

    _timerState = PomodoroTimerState.running;
    _phaseEndsAt = DateTime.now().add(Duration(seconds: _remainingSeconds));

    if (_currentPhase == PomodoroPhase.work &&
        _platformService.isAndroid &&
        _currentProfile.shouldBlockApps) {
      await _platformService.startAppBlocking();
    }

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _syncRemainingWithClock();
      if (_remainingSeconds > 0) {
        notifyListeners();
      } else {
        _completePhase();
      }
    });

    // Start live notification
    await _liveService.startLiveTimer(_buildLiveState());

    notifyListeners();
    return true;
  }

  // Pause the timer
  void pause() async {
    if (_timerState != PomodoroTimerState.running) return;

    _syncRemainingWithClock();
    _timer?.cancel();
    _timerState = PomodoroTimerState.paused;
    _phaseEndsAt = null;

    await _platformService.stopAppBlocking();
    await _liveService.pauseLiveTimer();

    notifyListeners();
  }

  // Reset the timer
  void reset() async {
    _timer?.cancel();
    _timerState = PomodoroTimerState.idle;
    _remainingSeconds = totalSecondsForPhase;
    _phaseEndsAt = null;

    await _platformService.stopAppBlocking();
    await _liveService.stopLiveTimer();

    notifyListeners();
  }

  // Complete current phase and move to next
  void _completePhase() async {
    _timer?.cancel();
    _phaseEndsAt = null;
    await _platformService.stopAppBlocking();

    if (_currentPhase == PomodoroPhase.work) {
      _stats = _stats.copyWith(
        completedSessionsToday: _stats.completedSessionsToday + 1,
        totalFocusTimeToday:
            _stats.totalFocusTimeToday + _currentProfile.workDuration,
        totalFocusTimeThisWeek:
            _stats.totalFocusTimeThisWeek + _currentProfile.workDuration,
      );
      await _recordFocusMinutes(_currentProfile.workDuration);
      if (_currentCycle >= _currentProfile.cyclesBeforeLongBreak) {
        _currentPhase = PomodoroPhase.longBreak;
        _currentCycle = 1;
        _stats = _stats.copyWith(completedCycles: _stats.completedCycles + 1);
      } else {
        _currentPhase = PomodoroPhase.shortBreak;
        _currentCycle++;
      }
    } else {
      _currentPhase = PomodoroPhase.work;
    }

    _stats = _stats.copyWith(dailyFocusScore: _calculateDailyFocusScore());
    await _saveStats();

    _remainingSeconds = totalSecondsForPhase;
    _timerState = PomodoroTimerState.idle;

    // Notify live service: phase completed, timer goes idle
    await _liveService.finishLiveTimer('Phase abgeschlossen! Nächste Phase bereit.');

    notifyListeners();
  }

  // Skip to next phase manually
  void skipToNextPhase() async {
    _timer?.cancel();
    _phaseEndsAt = null;
    await _platformService.stopAppBlocking();

    if (_currentPhase == PomodoroPhase.work) {
      if (_currentCycle >= _currentProfile.cyclesBeforeLongBreak) {
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

    await _liveService.stopLiveTimer();
    notifyListeners();
  }

  void _syncRemainingWithClock() {
    if (_timerState != PomodoroTimerState.running || _phaseEndsAt == null) {
      return;
    }
    final secondsLeft =
        _phaseEndsAt!.difference(DateTime.now()).inSeconds;
    _remainingSeconds = secondsLeft > 0 ? secondsLeft : 0;
  }

  void syncWithSystemTime() {
    if (_timerState != PomodoroTimerState.running) return;
    _syncRemainingWithClock();
    if (_remainingSeconds <= 0) {
      _completePhase();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _phaseEndsAt = null;
    _platformService.stopAppBlocking();
    super.dispose();
  }
}
