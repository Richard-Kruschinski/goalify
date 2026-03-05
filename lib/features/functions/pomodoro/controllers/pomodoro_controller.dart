import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/pomodoro_stats.dart';
import '../models/pomodoro_profile.dart';
import '../services/platform_channel_service.dart';
import '../../../../core/utils/local_storage.dart';

class PomodoroController extends ChangeNotifier {
  // Current profile
  PomodoroProfile _currentProfile = PomodoroProfile.classic;
  List<PomodoroProfile> _customProfiles = [];

  // State
  PomodoroPhase _currentPhase = PomodoroPhase.work;
  PomodoroTimerState _timerState = PomodoroTimerState.idle;
  int _remainingSeconds = 0;
  int _currentCycle = 1; // 1-4
  PomodoroStats _stats = PomodoroStats();
  
  Timer? _timer;
  final PlatformChannelService _platformService = PlatformChannelService();

  // Getters
  PomodoroProfile get currentProfile => _currentProfile;
  List<PomodoroProfile> get allProfiles => [...PomodoroProfile.defaultProfiles, ..._customProfiles];
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
  }

  // Load profile from local storage
  Future<void> _loadProfile() async {
    final data = await LocalStorage.loadJson('pomodoro_profile', fallback: null);
    if (data != null) {
      _currentProfile = PomodoroProfile.fromJson(data);
      _remainingSeconds = totalSecondsForPhase;
      notifyListeners();
    } else {
      _remainingSeconds = totalSecondsForPhase;
    }
  }

  // Save profile to local storage
  Future<void> _saveProfile() async {
    await LocalStorage.saveJson('pomodoro_profile', _currentProfile.toJson());
  }

  // Load custom profiles from local storage
  Future<void> _loadCustomProfiles() async {
    final data = await LocalStorage.loadJson('pomodoro_custom_profiles', fallback: null);
    if (data != null && data is List) {
      _customProfiles = data.map((item) => PomodoroProfile.fromJson(item)).toList();
      notifyListeners();
    }
  }

  // Save custom profiles to local storage
  Future<void> _saveCustomProfiles() async {
    await LocalStorage.saveJson('pomodoro_custom_profiles', _customProfiles.map((p) => p.toJson()).toList());
  }

  // Change profile
  Future<void> changeProfile(PomodoroProfile profile) async {
    if (_timerState == PomodoroTimerState.running) {
      return; // Don't change profile while timer is running
    }

    _currentProfile = profile;
    _remainingSeconds = totalSecondsForPhase;
    await _saveProfile();
    notifyListeners();
  }

  // Add custom profile
  Future<void> addCustomProfile(PomodoroProfile profile) async {
    _customProfiles.add(profile);
    await _saveCustomProfiles();
    notifyListeners();
  }

  // Update custom profile
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

  // Delete custom profile
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

  // Check and request notification permission (Android 13+)
  Future<bool> checkAndRequestNotificationPermission() async {
    if (!_platformService.isAndroid) {
      return true; // iOS doesn't need this permission for our use case
    }

    final status = await Permission.notification.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    // Permanently denied - user needs to go to settings
    return false;
  }

  // Start the timer
  Future<bool> start() async {
    if (_timerState == PomodoroTimerState.running) return true;

    // Check notification permission before starting
    if (_platformService.isAndroid) {
      if (kDebugMode) {
        print('Checking notification permission...');
      }
      final hasPermission = await checkAndRequestNotificationPermission();
      if (!hasPermission) {
        if (kDebugMode) {
          print('Notification permission not granted');
        }
        // Permission not granted - return false to indicate failure
        return false;
      }
      if (kDebugMode) {
        print('Notification permission granted');
      }
    }

    _timerState = PomodoroTimerState.running;
    
    // Start app blocking if in work phase and on Android
    if (_currentPhase == PomodoroPhase.work && _platformService.isAndroid) {
      if (kDebugMode) {
        print('Starting app blocking...');
      }
      final blockingStarted = await _platformService.startAppBlocking();
      if (!blockingStarted) {
        // App blocking failed, but timer can still work
        if (kDebugMode) {
          print('App blocking failed to start, but timer will continue');
        }
      } else {
        if (kDebugMode) {
          print('App blocking started successfully');
        }
      }
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
    return true;
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
        totalFocusTimeToday: _stats.totalFocusTimeToday + _currentProfile.workDuration,
        totalFocusTimeThisWeek: _stats.totalFocusTimeThisWeek + _currentProfile.workDuration,
      );
      
      // Move to next cycle or break
      if (_currentCycle >= _currentProfile.cyclesBeforeLongBreak) {
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
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _platformService.stopAppBlocking();
    super.dispose();
  }
}
