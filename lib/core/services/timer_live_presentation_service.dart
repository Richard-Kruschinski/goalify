import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/timer_live_state.dart';

/// Callbacks for a specific timer type registered by its controller.
class _TimerCallbacks {
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onSkip;

  const _TimerCallbacks({
    this.onPause,
    this.onResume,
    this.onStop,
    this.onSkip,
  });
}

/// Central service that bridges Flutter timer controllers with native
/// system-level timer presentations (Android foreground service notification,
/// iOS Live Activity / local notification).
///
/// Usage:
///   1. Each controller calls [registerCallbacks] once at init.
///   2. On timer start  → [startLiveTimer]
///   3. On pause        → [pauseLiveTimer]
///   4. On resume       → [resumeLiveTimer]
///   5. On stop/reset   → [stopLiveTimer]
///   6. On phase change → [updatePhase]
///   7. On natural end  → [finishLiveTimer]
class TimerLivePresentationService {
  TimerLivePresentationService._();
  static final TimerLivePresentationService instance =
      TimerLivePresentationService._();

  static const MethodChannel _channel =
      MethodChannel('com.goalify/timer_service');

  // ValueNotifier for tab navigation triggered by notification tap.
  // main.dart listens to this to switch to the Functions tab.
  static final ValueNotifier<int?> navigateToTabNotifier = ValueNotifier(null);

  final Map<String, _TimerCallbacks> _callbacks = {};
  String? _activeTimerId;

  void init() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Register action callbacks for a given timer ID.
  /// Call this once from each controller's constructor.
  void registerCallbacks(
    String timerId, {
    VoidCallback? onPause,
    VoidCallback? onResume,
    VoidCallback? onStop,
    VoidCallback? onSkip,
  }) {
    _callbacks[timerId] = _TimerCallbacks(
      onPause: onPause,
      onResume: onResume,
      onStop: onStop,
      onSkip: onSkip,
    );
  }

  Future<void> startLiveTimer(TimerLiveState state) async {
    _activeTimerId = state.timerId;
    await _invoke('startTimer', state.toMap());
  }

  Future<void> pauseLiveTimer() async {
    await _invoke('pauseTimer', null);
  }

  Future<void> resumeLiveTimer(TimerLiveState state) async {
    await _invoke('resumeTimer', {
      'remainingSeconds': state.remainingSeconds,
    });
  }

  Future<void> stopLiveTimer() async {
    _activeTimerId = null;
    await _invoke('stopTimer', null);
  }

  /// Call when a phase transitions mid-run (e.g. Pomodoro focus → break).
  Future<void> updatePhase(TimerLiveState state) async {
    await _invoke('updatePhase', {
      'currentPhase': state.currentPhase,
      'currentRound': state.currentRound,
      'totalRounds': state.totalRounds,
      'remainingSeconds': state.remainingSeconds,
      'totalSeconds': state.totalSeconds,
    });
  }

  /// Call when the timer expires naturally (shows a completion notification).
  Future<void> finishLiveTimer(String message) async {
    _activeTimerId = null;
    await _invoke('finishTimer', {'message': message});
  }

  // ---------------------------------------------------------------------------

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onTimerAction':
        final action = call.arguments as String?;
        if (action != null) _dispatch(action);
        break;
      case 'navigateToTimer':
        // Navigate to Functions tab (index 3)
        navigateToTabNotifier.value = 3;
        break;
    }
  }

  void _dispatch(String action) {
    final id = _activeTimerId;
    if (id == null) return;
    final cb = _callbacks[id];
    if (cb == null) return;
    switch (action) {
      case 'pause':
        cb.onPause?.call();
        break;
      case 'resume':
        cb.onResume?.call();
        break;
      case 'stop':
        cb.onStop?.call();
        break;
      case 'skip':
        cb.onSkip?.call();
        break;
    }
  }

  Future<void> _invoke(String method, dynamic args) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      await _channel.invokeMethod(method, args);
    } on PlatformException catch (e) {
      if (kDebugMode) print('TimerLivePresentationService [$method]: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('TimerLivePresentationService [$method]: $e');
    }
  }
}
