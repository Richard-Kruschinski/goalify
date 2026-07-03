import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../pomodoro/data/datasources/platform_channel_service.dart';
import '../../../../../core/models/timer_live_state.dart';
import '../../../../../core/services/timer_live_presentation_service.dart';

class MusicTimerController extends ChangeNotifier {
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;

  final PlatformChannelService _platformService = PlatformChannelService();
  final _liveService = TimerLivePresentationService.instance;

  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  int get remainingSeconds => _remainingSeconds;

  String get formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedTimeWithHours {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return formattedTime;
  }

  MusicTimerController() {
    _loadState();
    _liveService.registerCallbacks(
      'music',
      onPause: pauseTimer,
      onResume: resumeTimer,
      onStop: stopTimer,
    );
  }

  TimerLiveState _buildLiveState() => TimerLiveState(
        timerId: 'music',
        timerType: TimerType.music,
        title: 'Musik Timer',
        remainingSeconds: _remainingSeconds,
        totalSeconds: _remainingSeconds, // no fixed total for music timer
        isRunning: _isRunning && !_isPaused,
        isPaused: _isPaused,
        currentPhase: '',
      );

  /// Start timer with specified duration in seconds
  Future<void> startTimer(int durationSeconds) async {
    if (_isRunning) await stopTimer();

    _remainingSeconds = durationSeconds;
    _isRunning = true;
    _isPaused = false;

    _startTicker();
    await _saveState();

    await _liveService.startLiveTimer(_buildLiveState());
    notifyListeners();
  }

  /// Pause the countdown (music keeps playing)
  Future<void> pauseTimer() async {
    if (!_isRunning || _isPaused) return;
    _timer?.cancel();
    _timer = null;
    _isPaused = true;
    await _saveState();
    await _liveService.pauseLiveTimer();
    notifyListeners();
  }

  /// Resume the countdown after a pause
  Future<void> resumeTimer() async {
    if (!_isRunning || !_isPaused) return;
    _isPaused = false;
    _startTicker();
    await _saveState();
    await _liveService.resumeLiveTimer(_buildLiveState());
    notifyListeners();
  }

  /// Stop timer without pausing music
  Future<void> stopTimer() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPaused = false;
    _remainingSeconds = 0;
    await _saveState();
    await _liveService.stopLiveTimer();
    notifyListeners();
  }

  void addMinutes(int minutes) {
    if (_isRunning) {
      _remainingSeconds += minutes * 60;
      notifyListeners();
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        _onTimerComplete();
      }
    });
  }

  Future<void> _onTimerComplete() async {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _isPaused = false;
    _remainingSeconds = 0;

    try {
      await _platformService.pauseMusic();
      debugPrint('Music paused successfully');
    } catch (e) {
      debugPrint('Error pausing music: $e');
    }

    await _saveState();
    await _liveService.finishLiveTimer('Musik wurde gestoppt.');
    notifyListeners();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isRunning = prefs.getBool('music_timer_running') ?? false;
      _isPaused = prefs.getBool('music_timer_paused') ?? false;
      _remainingSeconds = prefs.getInt('music_timer_remaining') ?? 0;

      final savedTimeString = prefs.getString('music_timer_saved_time');
      if (savedTimeString != null && _isRunning && !_isPaused) {
        final savedTime = DateTime.parse(savedTimeString);
        final elapsed = DateTime.now().difference(savedTime).inSeconds;
        _remainingSeconds -= elapsed;

        if (_remainingSeconds <= 0) {
          _remainingSeconds = 0;
          _isRunning = false;
          _isPaused = false;
        } else {
          _startTicker();
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading music timer state: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('music_timer_running', _isRunning);
      await prefs.setBool('music_timer_paused', _isPaused);
      await prefs.setInt('music_timer_remaining', _remainingSeconds);
      if (_isRunning && !_isPaused) {
        await prefs.setString(
            'music_timer_saved_time', DateTime.now().toIso8601String());
      } else {
        await prefs.remove('music_timer_saved_time');
      }
    } catch (e) {
      debugPrint('Error saving music timer state: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
