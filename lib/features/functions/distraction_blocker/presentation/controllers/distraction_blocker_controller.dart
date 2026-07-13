import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../../../../core/utils/local_storage.dart';
import '../../../pomodoro/data/datasources/platform_channel_service.dart';

/// Controller for the Distraction Blocker feature
/// Simple on/off switch that blocks all apps in the blocklist
class DistractionBlockerController extends ChangeNotifier {
  bool _isActive = false;
  DateTime? _activatedAt;
  int _totalBlockingSeconds = 0; // Total seconds blocked today
  int _blockedAttempts = 0;
  DateTime? _lastResetDate;
  Timer? _updateTimer;
  int _attemptRefreshTick = 0;
  bool _isRefreshingAttempts = false;

  final PlatformChannelService _platformService = PlatformChannelService();

  // iOS only: number of apps/categories picked via the Screen Time picker
  int _blockedSelectionCount = 0;

  bool get isActive => _isActive;
  DateTime? get activatedAt => _activatedAt;
  int get totalBlockingSeconds => _totalBlockingSeconds;
  int get blockedAttempts => _blockedAttempts;
  int get blockedSelectionCount => _blockedSelectionCount;
  PlatformChannelService get platformService => _platformService;

  /// Get formatted blocking duration for current session
  String get currentSessionDuration {
    if (!_isActive || _activatedAt == null) return '00:00:00';
    
    final now = DateTime.now();
    final duration = now.difference(_activatedAt!);
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted total blocking time for today
  String get todayTotalDuration {
    final hours = _totalBlockingSeconds ~/ 3600;
    final minutes = (_totalBlockingSeconds % 3600) ~/ 60;
    final seconds = _totalBlockingSeconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  DistractionBlockerController() {
    _loadState();
    _checkDayReset();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  /// Start UI update timer
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _attemptRefreshTick++;
      if (_isActive && _attemptRefreshTick >= 2) {
        _attemptRefreshTick = 0;
        _refreshBlockedAttemptsCount(notify: false);
      }
      notifyListeners(); // Update UI every second
    });
  }

  /// Stop UI update timer
  void _stopUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  /// Load saved state from storage
  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isActive = prefs.getBool('distraction_blocker_active') ?? false;
      _totalBlockingSeconds = prefs.getInt('distraction_blocker_total_seconds') ?? 0;
      _blockedAttempts = prefs.getInt('distraction_blocker_blocked_attempts') ?? 0;
      
      final activatedAtString = prefs.getString('distraction_blocker_activated_at');
      if (activatedAtString != null) {
        _activatedAt = DateTime.parse(activatedAtString);
      }
      
      final lastResetString = prefs.getString('distraction_blocker_last_reset');
      if (lastResetString != null) {
        _lastResetDate = DateTime.parse(lastResetString);
      }
      
      // If the blocker was active, restart it (best effort on restore)
      if (_isActive) {
        await _platformService.startAppBlocking();
        _startUpdateTimer(); // Start UI updates
      }

      await _refreshBlockedAttemptsCount(notify: false);
      await refreshBlockedSelectionCount(notify: false);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading distraction blocker state: $e');
    }
  }

  /// Save state to storage
  Future<void> _saveState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('distraction_blocker_active', _isActive);
      await prefs.setInt('distraction_blocker_total_seconds', _totalBlockingSeconds);
      await prefs.setInt('distraction_blocker_blocked_attempts', _blockedAttempts);
      
      if (_activatedAt != null) {
        await prefs.setString('distraction_blocker_activated_at', _activatedAt!.toIso8601String());
      } else {
        await prefs.remove('distraction_blocker_activated_at');
      }
      
      if (_lastResetDate != null) {
        await prefs.setString('distraction_blocker_last_reset', _lastResetDate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Error saving distraction blocker state: $e');
    }
  }

  /// Check if we need to reset daily statistics
  Future<void> _checkDayReset() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (_lastResetDate == null) {
      _lastResetDate = today;
      await _saveState();
      return;
    }
    
    final lastReset = DateTime(_lastResetDate!.year, _lastResetDate!.month, _lastResetDate!.day);
    
    if (today.isAfter(lastReset)) {
      // New day - reset statistics but keep blocker active if it was on
      _totalBlockingSeconds = 0;
      _lastResetDate = today;
      await _saveState();
      notifyListeners();
    }
  }

  /// Toggle the distraction blocker on/off
  Future<void> toggle() async {
    if (_isActive) {
      await stopBlocking();
    } else {
      await startBlocking();
    }
  }

  /// Start blocking apps
  /// Throws [StateError] when the platform refuses to start blocking
  /// (e.g. missing accessibility service on Android, missing Screen Time
  /// authorization or empty app selection on iOS).
  Future<void> startBlocking() async {
    try {
      await _checkDayReset();

      // Start app blocking via platform channel
      final started = await _platformService.startAppBlocking();
      if (!started) {
        throw StateError('App blocking could not be started');
      }
      await _refreshBlockedAttemptsCount(notify: false);

      _isActive = true;
      _activatedAt = DateTime.now();
      
      _startUpdateTimer(); // Start UI updates
      
      await _saveState();
      notifyListeners();
      
      debugPrint('Distraction blocker activated');
    } catch (e) {
      debugPrint('Error starting distraction blocker: $e');
      rethrow;
    }
  }

  /// Stop blocking apps
  Future<void> stopBlocking() async {
    try {
      // Stop app blocking via platform channel
      await _platformService.stopAppBlocking();
      
      _stopUpdateTimer(); // Stop UI updates
      
      // Calculate session duration and add to total
      if (_activatedAt != null) {
        final now = DateTime.now();
        final sessionDuration = now.difference(_activatedAt!);
        _totalBlockingSeconds += sessionDuration.inSeconds;
        await _recordBlockingHistory(_activatedAt!, now);
      }
      
      _isActive = false;
      _activatedAt = null;
      
      await _saveState();
      notifyListeners();
      
      debugPrint('Distraction blocker deactivated');
    } catch (e) {
      debugPrint('Error stopping distraction blocker: $e');
      rethrow;
    }
  }

  /// Adds a finished blocking session to the per-day history
  /// (`Map<dateKey yyyy-mm-dd, blocked seconds>`) that feeds the weekly review
  /// on the progress screen. Sessions spanning midnight are split across the
  /// days they cover; entries older than 30 days are dropped.
  Future<void> _recordBlockingHistory(DateTime start, DateTime end) async {
    if (!end.isAfter(start)) return;

    final raw = await LocalStorage.loadJson(
      'distraction_blocker_history_v1',
      fallback: {},
    );
    final history = <String, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (v is num) history[k.toString()] = v.toInt();
      });
    }

    var cursor = start;
    while (cursor.isBefore(end)) {
      final nextMidnight =
          DateTime(cursor.year, cursor.month, cursor.day + 1);
      final sliceEnd = nextMidnight.isBefore(end) ? nextMidnight : end;
      final key = _dateKey(cursor);
      history[key] =
          (history[key] ?? 0) + sliceEnd.difference(cursor).inSeconds;
      cursor = sliceEnd;
    }

    final cutoff = DateTime.now().subtract(const Duration(days: 30));
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

    await LocalStorage.saveJson('distraction_blocker_history_v1', history);
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Get current live session duration in seconds
  int getCurrentSessionSeconds() {
    if (!_isActive || _activatedAt == null) return 0;
    return DateTime.now().difference(_activatedAt!).inSeconds;
  }

  /// Get total blocking seconds including current session
  int getTotalSecondsToday() {
    return _totalBlockingSeconds + getCurrentSessionSeconds();
  }

  /// Reload the number of apps selected for blocking (iOS Screen Time picker)
  Future<void> refreshBlockedSelectionCount({bool notify = true}) async {
    if (!_platformService.isIOS) return;

    try {
      final count = await _platformService.getBlockedSelectionCount();
      if (count != _blockedSelectionCount) {
        _blockedSelectionCount = count;
        if (notify) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing blocked selection count: $e');
    }
  }

  Future<void> _refreshBlockedAttemptsCount({bool notify = true}) async {
    if (_isRefreshingAttempts) return;
    _isRefreshingAttempts = true;

    try {
      final attempts = await _platformService.getBlockedAttemptsCount();
      if (attempts != _blockedAttempts) {
        _blockedAttempts = attempts;
        await _saveState();
        if (notify) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error refreshing blocked attempts: $e');
    } finally {
      _isRefreshingAttempts = false;
    }
  }
}
