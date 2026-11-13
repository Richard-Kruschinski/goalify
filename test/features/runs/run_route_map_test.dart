import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/runs/data/models/run.dart';
import 'package:Goalify/features/runs/presentation/widgets/run_route_map.dart';
import 'package:Goalify/l10n/generated/app_localizations.dart';
import 'package:latlong2/latlong.dart';

final _start = DateTime(2026, 11, 14, 7);

double _needleAngle(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find
        .ancestor(
          of: find.byIcon(Icons.navigation),
          matching: find.byType(Transform),
        )
        .first,
  );
  final matrix = transform.transform;
  return math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
}

void main() {
  testWidgets('compass needle follows a pure rotation back to north', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RunRouteMap(
            segments: [
              [
                RoutePoint(const LatLng(52.000, 13.4), _start),
                RoutePoint(
                  const LatLng(52.001, 13.4),
                  _start.add(const Duration(seconds: 30)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // A rotation without any pan, like the compass button does.
    tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .rotate(90);
    await tester.pump();
    expect(_needleAngle(tester), closeTo(math.pi / 2, 1e-6));

    await tester.tap(find.byIcon(Icons.navigation));
    await tester.pumpAndSettle();
    expect(_needleAngle(tester), closeTo(0, 1e-6));
  });
}
