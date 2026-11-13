import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/runs/data/models/run.dart';
import 'package:Goalify/features/runs/domain/usecases/route_stats.dart';
import 'package:latlong2/latlong.dart';

final _start = DateTime(2026, 11, 13, 7);

RoutePoint _point(double lat, int second) =>
    RoutePoint(LatLng(lat, 13.4), _start.add(Duration(seconds: second)));

void main() {
  group('RouteStats.distanceMeters', () {
    test('sums the legs of a segment', () {
      // 0.001° latitude is about 111 m.
      final meters = RouteStats.distanceMeters([
        [_point(52.000, 0), _point(52.001, 30), _point(52.002, 60)],
      ]);
      expect(meters, closeTo(222.4, 1));
    });

    test('does not count the gap between two segments', () {
      final meters = RouteStats.distanceMeters([
        [_point(52.000, 0), _point(52.001, 30)],
        [_point(52.010, 300), _point(52.011, 330)],
      ]);
      expect(meters, closeTo(222.4, 1));
    });

    test('keeps meter fractions instead of rounding each leg', () {
      final legs = [for (var i = 0; i < 100; i++) _point(52 + i * 0.000025, i)];
      // 99 legs of about 2.78 m each.
      expect(RouteStats.distanceMeters([legs]), closeTo(275.2, 1));
    });

    test('is zero for an empty route', () {
      expect(RouteStats.distanceMeters([]), 0);
      expect(
        RouteStats.distanceMeters([
          [_point(52, 0)],
        ]),
        0,
      );
    });
  });

  group('RouteStats.paceSecondsPerKm', () {
    test('is time per kilometer', () {
      expect(
        RouteStats.paceSecondsPerKm(2000, const Duration(minutes: 11)),
        330,
      );
    });

    test('is null for very short distances', () {
      expect(
        RouteStats.paceSecondsPerKm(49, const Duration(minutes: 1)),
        isNull,
      );
    });
  });

  group('RouteStats.isWorthSaving', () {
    test('is false while standing still, even with many fixes', () {
      final standing = [for (var s = 0; s < 30; s++) _point(52, s)];
      expect(RouteStats.isWorthSaving([standing]), isFalse);
    });

    test('is false for GPS jitter of a few meters', () {
      // 0.00003° latitude is about 3.3 m.
      final jitter = [_point(52, 0), _point(52.00003, 5), _point(52, 10)];
      expect(RouteStats.isWorthSaving([jitter]), isFalse);
    });

    test('is true once the route is 50 m long', () {
      expect(
        RouteStats.isWorthSaving([
          [_point(52.000, 0), _point(52.0005, 20)], // about 56 m
        ]),
        isTrue,
      );
    });
  });

  group('GpsPointFilter', () {
    test('rejects inaccurate fixes', () {
      expect(
        GpsPointFilter.accepts(
          activity: RunActivity.run,
          candidate: _point(52, 0),
          accuracyMeters: 40,
        ),
        isFalse,
      );
    });

    test('accepts a jogging step', () {
      expect(
        GpsPointFilter.accepts(
          activity: RunActivity.run,
          previous: _point(52.0000, 0),
          candidate: _point(52.0001, 3), // about 11 m in 3 s
          accuracyMeters: 8,
        ),
        isTrue,
      );
    });

    test('rejects a jump faster than a runner', () {
      expect(
        GpsPointFilter.accepts(
          activity: RunActivity.run,
          previous: _point(52.000, 0),
          candidate: _point(52.001, 2), // about 111 m in 2 s
          accuracyMeters: 8,
        ),
        isFalse,
      );
    });

    test('allows the same jump speed on a bike only up to its limit', () {
      final previous = _point(52.000, 0);
      final candidate = _point(52.001, 5); // about 22 m/s
      expect(
        GpsPointFilter.accepts(
          activity: RunActivity.bike,
          previous: previous,
          candidate: candidate,
          accuracyMeters: 8,
        ),
        isTrue,
      );
      expect(
        GpsPointFilter.accepts(
          activity: RunActivity.walk,
          previous: previous,
          candidate: candidate,
          accuracyMeters: 8,
        ),
        isFalse,
      );
    });
  });

  test('Run survives a storage round trip', () {
    final run = Run(
      id: 'a',
      activity: RunActivity.bike,
      startedAt: _start,
      movingTime: const Duration(minutes: 3),
      segments: [
        [_point(52.1234567, 0), _point(52.1235, 4)],
        [_point(52.2, 100)],
      ],
    );
    final copy = Run.fromMap(run.toMap());
    expect(copy.activity, RunActivity.bike);
    expect(copy.movingTime, run.movingTime);
    expect(copy.segments.map((s) => s.length), [2, 1]);
    expect(copy.segments[0][0].position.latitude, 52.123457);
    expect(copy.segments[1][0].time, _start.add(const Duration(seconds: 100)));
  });
}
