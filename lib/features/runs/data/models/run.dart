import 'package:latlong2/latlong.dart';

enum RunActivity { run, walk, bike }

class RoutePoint {
  const RoutePoint(this.position, this.time);

  final LatLng position;
  final DateTime time;
}

/// One recorded outing. Every pause starts a new segment, so the map does not
/// draw a straight line across the gap and the gap is not counted as distance.
class Run {
  const Run({
    required this.id,
    required this.activity,
    required this.startedAt,
    required this.movingTime,
    required this.segments,
  });

  final String id;
  final RunActivity activity;
  final DateTime startedAt;

  /// Time without pauses.
  final Duration movingTime;
  final List<List<RoutePoint>> segments;

  Map<String, dynamic> toMap() => {
    'id': id,
    'activity': activity.name,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'movingSeconds': movingTime.inSeconds,
    // Flat [lat, lng, secondsSinceStart, ...] per segment keeps a one-hour
    // run at a few dozen KB instead of a list of maps.
    'segments': [
      for (final segment in segments)
        [
          for (final p in segment) ...[
            _round(p.position.latitude),
            _round(p.position.longitude),
            p.time.difference(startedAt).inSeconds,
          ],
        ],
    ],
  };

  factory Run.fromMap(Map<String, dynamic> map) {
    final startedAt = DateTime.fromMillisecondsSinceEpoch(
      map['startedAt'] as int,
    );
    return Run(
      id: map['id'] as String,
      activity:
          RunActivity.values.asNameMap()[map['activity']] ?? RunActivity.run,
      startedAt: startedAt,
      movingTime: Duration(seconds: map['movingSeconds'] as int),
      segments: [
        for (final flat in map['segments'] as List)
          [
            for (var i = 0; i + 2 < (flat as List).length; i += 3)
              RoutePoint(
                LatLng(
                  (flat[i] as num).toDouble(),
                  (flat[i + 1] as num).toDouble(),
                ),
                startedAt.add(Duration(seconds: flat[i + 2] as int)),
              ),
          ],
      ],
    );
  }

  /// Six decimals are about 10 cm, finer than any phone GPS.
  static double _round(double degrees) => (degrees * 1e6).roundToDouble() / 1e6;
}
