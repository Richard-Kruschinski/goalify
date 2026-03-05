import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../pomodoro/services/platform_channel_service.dart';

/// Controller for the Music Timer feature
/// Allows users to set a timer that pauses music when it expires
class MusicTimerController extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  
  final PlatformChannelService _platformService = PlatformChannelService();

  bool get isRunning => _isRunning;
  int get remainingSeconds => _remainingSeconds;

  /// Get formatted time as MM:SS
  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted time as HH:MM:SS for longer durations
  String get formattedTimeWithHours {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return formattedTime;
  }

  /// Start timer with specified duration in seconds
  Future<void> startTimer(int durationSeconds) async {
    if (_isRunning) {
      await stopTimer();
    }

    _remainingSeconds = durationSeconds;
    _isRunning = true;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });

    await _saveState();
    notifyListeners();
  }

  /// Stop timer without pausing music
  Future<void> stopTimer() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;
    
    await _saveState();
    notifyListeners();
  }

  /// Called when timer reaches zero
  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _remainingSeconds = 0;

    // Pause music playback
    try {
      await _platformService.pauseMusic();
      debugPrint('Music paused successfully');
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }

    await _saveState();
    notifyListeners();
  }

  /// Add time to running timer (in minutes)
  void addMinutes(int minutes) {
    if (_isRunning) {
      _remainingSeconds += minutes * 60;
      notifyListeners();
    }
  }

  /// Load saved state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isRunning = prefs.getBool('music_timer_running') ?? false;
      _remainingSeconds = prefs.getInt('music_timer_remaining') ?? 0;
      
      final savedTimeString = prefs.getString('music_timer_saved_time');
      if (savedTimeString != null && _isRunning) {
        final savedTime = DateTime.parse(savedTimeString);
        final elapsed = DateTime.now().difference(savedTime).inSeconds;
        
        _remainingSeconds -= elapsed;
        
        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _isRunning = false;
        } else {
          // Restart timer
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_remainingSeconds > 0) {
              _remainingSeconds--;
              notifyListeners();
            } else {
              _onTimerComplete();
            }
          });
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading music timer state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('music_timer_running', _isRunning);
      await prefs.setInt('music_timer_remaining', _remainingSeconds);
      
      if (_isRunning) {
        await prefs.setString('music_timer_saved_time', DateTime.now().toIso8601String());
      } else {
        await prefs.remove('music_timer_saved_time');
      }
    } catch (e) {
      debugPrint('Error saving music timer state: $e');
    }
  }

  MusicTimerController() {
    _loadState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
