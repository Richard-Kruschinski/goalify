import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/timer_live_state.dart';
import '../i18n/current_l10n.dart';

/// Callbacks for a specific timer type registered by its controller.
class _TimerCallbacks {
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;
  final VoidCallback? onSkip;
  final TimerLiveState? Function()? currentLiveState;

  const _TimerCallbacks({
    this.onPause,
    this.onResume,
    this.onStop,
    this.onSkip,
    this.currentLiveState,
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

  // Bottom navigation indices, see MainNav in main.dart.
  static const _gymTabIndex = 2;
  static const _functionsTabIndex = 3;

  final Map<String, _TimerCallbacks> _callbacks = {};
  String? _activeTimerId;

  // The native side shows one timer at a time. A timer started with
  // `preempt: true` (the gym rest timer) takes the slot; the timer it pushed
  // aside keeps running in the app and is re-published once the slot is free.
  String? _preemptingTimerId;
  String? _suspendedTimerId;

  void init() {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Register action callbacks for a given timer ID.
  /// Call this once from each controller's constructor.
  /// [currentLiveState] returns the timer's state while it is running or
  /// paused (null when idle); used to re-publish it after a preempting timer.
  void registerCallbacks(
    String timerId, {
    VoidCallback? onPause,
    VoidCallback? onResume,
    VoidCallback? onStop,
    VoidCallback? onSkip,
    TimerLiveState? Function()? currentLiveState,
  }) {
    _callbacks[timerId] = _TimerCallbacks(
      onPause: onPause,
      onResume: onResume,
      onStop: onStop,
      onSkip: onSkip,
      currentLiveState: currentLiveState,
    );
  }

  Future<void> startLiveTimer(TimerLiveState state, {bool preempt = false}) async {
    if (!preempt && _isBlocked(state.timerId)) {
      _suspendedTimerId = state.timerId;
      return;
    }
    if (preempt) {
      final current = _activeTimerId;
      if (current != null && current != state.timerId) _suspendedTimerId = current;
      _preemptingTimerId = state.timerId;
    }
    _activeTimerId = state.timerId;
    await _invoke('startTimer', {...state.toMap(), 'labels': _labels()});
  }

  /// True while a preempting timer other than [timerId] owns the native slot.
  bool _isBlocked(String? timerId) =>
      _preemptingTimerId != null && timerId != _preemptingTimerId;

  /// A suspended timer that ends needs no restore later.
  void _forgetSuspended(String? timerId) {
    if (_suspendedTimerId == timerId) _suspendedTimerId = null;
  }

  /// Button and status texts for the notification, in the app language.
  Map<String, String> _labels() {
    final l10n = CurrentL10n.of;
    return {
      'pause': l10n.pause,
      'resume': l10n.resume,
      'stop': l10n.notifStop,
      'skip': l10n.notifSkip,
      'paused': l10n.paused,
      'done': l10n.notifDone,
      'restAlert': l10n.restTargetReachedAlert,
    };
  }

  Future<void> pauseLiveTimer({String? timerId}) async {
    if (_isBlocked(timerId)) return;
    await _invoke('pauseTimer', null);
  }

  Future<void> resumeLiveTimer(TimerLiveState state) async {
    if (_isBlocked(state.timerId)) return;
    await _invoke('resumeTimer', {
      'remainingSeconds': state.remainingSeconds,
    });
  }

  Future<void> stopLiveTimer({String? timerId}) async {
    if (_isBlocked(timerId)) {
      _forgetSuspended(timerId);
      return;
    }
    _activeTimerId = null;
    await _invoke('stopTimer', null);
    if (_preemptingTimerId != null) _releasePreemption();
  }

  void _releasePreemption() {
    _preemptingTimerId = null;
    final suspended = _suspendedTimerId;
    _suspendedTimerId = null;
    final state = suspended == null ? null : _callbacks[suspended]?.currentLiveState?.call();
    if (state == null) return;
    startLiveTimer(state).then((_) {
      if (state.isPaused) pauseLiveTimer(timerId: state.timerId);
    });
  }

  /// Call when a phase transitions mid-run (e.g. Pomodoro focus → break).
  Future<void> updatePhase(TimerLiveState state) async {
    if (_isBlocked(state.timerId)) return;
    await _invoke('updatePhase', {
      'currentPhase': state.currentPhase,
      'currentRound': state.currentRound,
      'totalRounds': state.totalRounds,
      'remainingSeconds': state.remainingSeconds,
      'totalSeconds': state.totalSeconds,
    });
  }

  /// Call when the timer expires naturally (shows a completion notification).
  Future<void> finishLiveTimer(String message, {String? timerId}) async {
    if (_isBlocked(timerId)) {
      _forgetSuspended(timerId);
      return;
    }
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
        // The rest timer belongs to the Gym tab, all other timers to Functions.
        navigateToTabNotifier.value = call.arguments == TimerType.rest.name
            ? _gymTabIndex
            : _functionsTabIndex;
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
