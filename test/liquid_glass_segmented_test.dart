import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/widgets/liquid_glass_segmented.dart';

void main() {
  testWidgets('tap and drag move the selection without errors', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(16),
              child: LiquidGlassSegmented<int>(
                selected: selected,
                onChanged: (v) => setState(() => selected = v),
                segments: const [
                  LiquidGlassSegment(value: 0, icon: Icons.contrast, label: 'A'),
                  LiquidGlassSegment(value: 1, icon: Icons.light_mode, label: 'B'),
                  LiquidGlassSegment(value: 2, icon: Icons.dark_mode, label: 'C'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Give the shader time to load, then paint with it.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    // The refraction painter (and its content snapshot) is in use.
    expect(
      find.byWidgetPredicate((w) =>
          w is CustomPaint && w.painter.runtimeType.toString() == '_RefractionPainter'),
      findsOneWidget,
    );

    await tester.tap(find.text('B'), warnIfMissed: false);
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(selected, 1);

    await tester.drag(find.text('B'), const Offset(400, 0), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(tester.takeException(), isNull);
  });
}
