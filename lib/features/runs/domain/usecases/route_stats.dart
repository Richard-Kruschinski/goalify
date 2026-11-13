import 'package:latlong2/latlong.dart';

import '../../data/models/run.dart';

class RouteStats {
  RouteStats._();

  // latlong2 rounds to whole meters by default. With a point every few meters
  // that would lose a sizeable share of the distance.
  static const _distance = Distance(roundResult: false);

  /// Below this the pace jumps around too much to be useful.
  static const minMetersForPace = 50.0;

  static double legMeters(LatLng from, LatLng to) =>
      _distance.distance(from, to);

  static double distanceMeters(List<List<RoutePoint>> segments) {
    var total = 0.0;
    for (final segment in segments) {
      for (var i = 1; i < segment.length; i++) {
        total += legMeters(segment[i - 1].position, segment[i].position);
      }
    }
    return total;
  }

  /// Whether a session covered enough ground to keep. Counting fixes is not
  /// enough: standing still still delivers fixes, and GPS jitters a few
  /// meters around the spot.
  static bool isWorthSaving(List<List<RoutePoint>> segments) =>
      distanceMeters(segments) >= minMetersForPace;

  /// Seconds per kilometer, or null while the distance is too short.
  static int? paceSecondsPerKm(double meters, Duration movingTime) {
    if (meters < minMetersForPace) return null;
    return (movingTime.inSeconds * 1000 / meters).round();
  }
}

/// Drops GPS fixes that would draw spikes into the route: fixes with a poor
/// accuracy, and jumps faster than the activity can physically move.
class GpsPointFilter {
  GpsPointFilter._();

  static const maxAccuracyMeters = 25.0;

  static double maxSpeedMetersPerSecond(RunActivity activity) =>
      switch (activity) {
        RunActivity.run || RunActivity.walk => 12,
        RunActivity.bike => 30,
      };

  static bool accepts({
    required RunActivity activity,
    required RoutePoint candidate,
    required double accuracyMeters,
    RoutePoint? previous,
  }) {
    if (accuracyMeters > maxAccuracyMeters) return false;
    if (previous == null) return true;
    final meters = RouteStats.legMeters(previous.position, candidate.position);
    // Two fixes in the same second still need a time base to compare against.
    final seconds =
        candidate.time
            .difference(previous.time)
            .inMilliseconds
            .clamp(1000, 1 << 31) /
        1000;
    return meters / seconds <= maxSpeedMetersPerSecond(activity);
  }
}
