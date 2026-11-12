import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/i18n/current_l10n.dart';
import '../../../../core/models/timer_live_state.dart';
import '../../../../core/services/timer_live_presentation_service.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// One rest between two sets, counted up from [startedAt].
class RestSession {
  const RestSession({
    required this.workoutId,
    required this.workoutName,
    required this.setNumber,
    required this.startedAt,
    this.targetSets,
    this.targetRestSeconds,
    this.nextExerciseName,
  });

  final String workoutId;
  final String workoutName;

  /// How many sets of this exercise were tracked today, this one included.
  final int setNumber;
  final DateTime startedAt;
  final int? targetSets;
  final int? targetRestSeconds;

  /// After the last planned set: the next open exercise of the day, if any.
  final String? nextExerciseName;

  bool get isLastSet => targetSets != null && setNumber >= targetSets!;
}

/// "Bankdrücken · Satz 2 von 3"; after the last planned set
/// "Bankdrücken fertig · Als Nächstes: Bizeps-Curls". Shared by the in-app
/// bar and the lock screen notification.
String describeRest(RestSession session, AppLocalizations l10n) {
  if (session.isLastSet) {
    final next = session.nextExerciseName;
    final upNext = next == null ? l10n.restWorkoutDone : l10n.restNextExercise(next);
    return '${l10n.restExerciseDone(session.workoutName)} · $upNext';
  }
  final target = session.targetSets;
  final progress = target == null
      ? l10n.restSetNumber(session.setNumber)
      : l10n.restSetProgress(session.setNumber, target);
  return '${session.workoutName} · $progress';
}

/// The gym rest timer. App-wide (provided in main.dart), because the Gym tab
/// is rebuilt whenever the bottom navigation switches tabs.
///
/// Time is derived from [RestSession.startedAt] rather than counted in ticks,
/// so it stays correct while the app sleeps in the background.
class RestTimerController extends ChangeNotifier {
  RestTimerController({
    required int Function() autoOffMinutes,
    bool Function()? isEnabled,
    DateTime Function()? clock,
    TimerLivePresentationService? liveService,
  })  : _autoOffMinutes = autoOffMinutes,
        _isEnabled = isEnabled ?? _alwaysEnabled,
        _now = clock ?? DateTime.now,
        _live = liveService ?? TimerLivePresentationService.instance {
    _live.registerCallbacks(liveTimerId, onStop: stop);
  }

  static const liveTimerId = 'rest';

  final int Function() _autoOffMinutes;
  final bool Function() _isEnabled;

  static bool _alwaysEnabled() => true;
  final DateTime Function() _now;
  final TimerLivePresentationService _live;

  RestSession? _session;
  Timer? _ticker;

  RestSession? get session => _session;

  Duration get elapsed =>
      _session == null ? Duration.zero : _now().difference(_session!.startedAt);

  bool get targetReached {
    final target = _session?.targetRestSeconds;
    return target != null && elapsed.inSeconds >= target;
  }

  bool get _isExpired =>
      _session != null && elapsed >= Duration(minutes: _autoOffMinutes());

  /// Starts a new rest at 0:00 for a just tracked set; does nothing while the
  /// rest timer is switched off in the settings.
  /// Returns how long the replaced rest ran, or null if none was running.
  int? startRest({
    required String workoutId,
    required String workoutName,
    required int setNumber,
    int? targetSets,
    int? targetRestSeconds,
    String? nextExerciseName,
  }) {
    if (!_isEnabled()) return null;
    final previousRest =
        _session == null || _isExpired ? null : elapsed.inSeconds;
    _session = RestSession(
      workoutId: workoutId,
      workoutName: workoutName,
      setNumber: setNumber,
      startedAt: _now(),
      targetSets: targetSets,
      targetRestSeconds: targetRestSeconds,
      nextExerciseName: nextExerciseName,
    );
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    _publishLive(_session!);
    notifyListeners();
    return previousRest;
  }

  void stop() {
    if (_session == null) return;
    _ticker?.cancel();
    _ticker = null;
    _session = null;
    _live.stopLiveTimer(timerId: liveTimerId);
    notifyListeners();
  }

  /// Called every second: ends the rest after the auto-off time or once the
  /// rest timer was switched off, otherwise lets listeners redraw the clock.
  @visibleForTesting
  void tick() {
    if (_isExpired || !_isEnabled()) {
      stop();
      return;
    }
    notifyListeners();
  }

  void _publishLive(RestSession session) {
    final l10n = CurrentL10n.of;
    _live.startLiveTimer(
      TimerLiveState(
        timerId: liveTimerId,
        timerType: TimerType.rest,
        title: l10n.restTimerTitle,
        remainingSeconds: 0,
        totalSeconds: session.targetRestSeconds ?? 0,
        currentPhase: describeRest(session, l10n),
        countUp: true,
        alertAtSeconds: session.targetRestSeconds,
        autoStopSeconds: _autoOffMinutes() * 60,
      ),
      preempt: true,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
