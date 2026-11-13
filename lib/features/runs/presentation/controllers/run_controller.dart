import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/i18n/current_l10n.dart';
import '../../data/models/run.dart';
import '../../data/repositories/runs_repository_impl.dart';
import '../../domain/repositories/runs_repository.dart';
import '../../domain/usecases/route_stats.dart';

enum RunTrackingState { idle, running, paused }

enum RunStartProblem {
  locationServiceOff,
  permissionDenied,
  permissionDeniedForever,
}

/// App-wide (see main.dart), so a run keeps recording while the user
/// switches tabs.
class RunController extends ChangeNotifier {
  RunController({RunsRepository? repository})
    : _repository = repository ?? RunsRepositoryImpl();

  /// Ignore fixes closer than this to the last one: GPS jitter while standing.
  static const _minMetersBetweenFixes = 3;

  final RunsRepository _repository;

  List<Run> _runs = [];
  bool _loaded = false;

  RunTrackingState _state = RunTrackingState.idle;
  RunActivity _activity = RunActivity.run;
  DateTime? _startedAt;
  final List<List<RoutePoint>> _segments = [];
  double _distanceMeters = 0;
  Duration _movingBeforePause = Duration.zero;
  DateTime? _runningSince;
  LatLng? _currentPosition;
  StreamSubscription<Position>? _positions;
  Timer? _ticker;

  List<Run> get runs => UnmodifiableListView(_runs);
  bool get loaded => _loaded;
  RunTrackingState get state => _state;
  bool get isTracking => _state != RunTrackingState.idle;
  RunActivity get activity => _activity;
  List<List<RoutePoint>> get segments => UnmodifiableListView(_segments);
  double get distanceMeters => _distanceMeters;
  LatLng? get currentPosition => _currentPosition;
  bool get hasRoute => RouteStats.isWorthSaving(_segments);

  Duration get movingTime {
    final since = _runningSince;
    if (since == null) return _movingBeforePause;
    return _movingBeforePause + DateTime.now().difference(since);
  }

  Future<void> load() async {
    if (_loaded) return;
    _runs = (await _repository.loadRuns())
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    _loaded = true;
    notifyListeners();
  }

  void selectActivity(RunActivity activity) {
    if (isTracking) return;
    _activity = activity;
    notifyListeners();
  }

  /// Returns why tracking could not start, or null once it runs.
  Future<RunStartProblem?> start() async {
    if (isTracking) return null;
    final problem = await _checkLocationAccess();
    if (problem != null) return problem;

    _startedAt = DateTime.now();
    _segments
      ..clear()
      ..add([]);
    _distanceMeters = 0;
    _movingBeforePause = Duration.zero;
    _runningSince = _startedAt;
    _currentPosition = null;
    _state = RunTrackingState.running;
    _positions =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings(),
        ).listen(
          _onPosition,
          onError: (Object error) =>
              debugPrint('RunController: location stream failed: $error'),
        );
    _startTicker();
    notifyListeners();
    return null;
  }

  void pause() {
    if (_state != RunTrackingState.running) return;
    _movingBeforePause = movingTime;
    _runningSince = null;
    _state = RunTrackingState.paused;
    _ticker?.cancel();
    notifyListeners();
  }

  void resume() {
    if (_state != RunTrackingState.paused) return;
    _segments.add([]);
    _runningSince = DateTime.now();
    _state = RunTrackingState.running;
    _startTicker();
    notifyListeners();
  }

  Future<void> finish() async {
    if (!isTracking) return;
    final run = Run(
      id: _startedAt!.microsecondsSinceEpoch.toString(),
      activity: _activity,
      startedAt: _startedAt!,
      movingTime: movingTime,
      segments: _segments.where((s) => s.isNotEmpty).toList(),
    );
    await _stopTracking();
    _runs.insert(0, run);
    notifyListeners();
    await _repository.saveRuns(_runs);
  }

  Future<void> discard() async {
    await _stopTracking();
    notifyListeners();
  }

  Future<void> deleteRun(String id) async {
    _runs.removeWhere((r) => r.id == id);
    notifyListeners();
    await _repository.saveRuns(_runs);
  }

  Future<void> openSettingsFor(RunStartProblem problem) =>
      problem == RunStartProblem.locationServiceOff
      ? Geolocator.openLocationSettings()
      : Geolocator.openAppSettings();

  void _onPosition(Position position) {
    _currentPosition = LatLng(position.latitude, position.longitude);
    if (_state == RunTrackingState.running) _addPoint(position.accuracy);
    notifyListeners();
  }

  void _addPoint(double accuracyMeters) {
    final point = RoutePoint(_currentPosition!, DateTime.now());
    final segment = _segments.last;
    final previous = segment.isEmpty ? null : segment.last;
    final accepted = GpsPointFilter.accepts(
      activity: _activity,
      previous: previous,
      candidate: point,
      accuracyMeters: accuracyMeters,
    );
    if (!accepted) return;
    if (previous != null) {
      _distanceMeters += RouteStats.legMeters(
        previous.position,
        point.position,
      );
    }
    segment.add(point);
  }

  Future<RunStartProblem?> _checkLocationAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return RunStartProblem.locationServiceOff;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return switch (permission) {
      LocationPermission.denied => RunStartProblem.permissionDenied,
      LocationPermission.deniedForever =>
        RunStartProblem.permissionDeniedForever,
      _ => null,
    };
  }

  /// The platform settings keep GPS alive with the screen off: a location
  /// foreground service on Android, background updates on iOS.
  LocationSettings _locationSettings() {
    final l10n = CurrentL10n.of;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _minMetersBetweenFixes,
        intervalDuration: const Duration(seconds: 2),
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: l10n.runNotificationTitle,
          notificationText: l10n.runNotificationText,
          notificationChannelName: l10n.runsTitle,
          enableWakeLock: true,
          setOngoing: true,
        ),
      ),
      TargetPlatform.iOS => AppleSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _minMetersBetweenFixes,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      ),
      _ => const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _minMetersBetweenFixes,
      ),
    };
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => notifyListeners(),
    );
  }

  Future<void> _stopTracking() async {
    _ticker?.cancel();
    await _positions?.cancel();
    _positions = null;
    _state = RunTrackingState.idle;
    _runningSince = null;
    _startedAt = null;
    _segments.clear();
    _currentPosition = null;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _positions?.cancel();
    super.dispose();
  }
}
