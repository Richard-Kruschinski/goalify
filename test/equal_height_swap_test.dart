import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/widgets/equal_height_swap.dart';

void main() {
  // Like the distraction blocker: a tall session clock (on) or a short hint
  // (off), with the on/off switch below.
  Widget screen({required bool on}) => MaterialApp(
        home: Column(
          children: [
            EqualHeightSwap(
              showFirst: on,
              first: const SizedBox(height: 120, child: Text('00:00:01')),
              second: const SizedBox(height: 60, child: Text('Toggle the switch')),
            ),
            const Text('switch'),
          ],
        ),
      );

  testWidgets('the widget below stays in place when the content swaps', (tester) async {
    await tester.pumpWidget(screen(on: false));
    final offPosition = tester.getTopLeft(find.text('switch'));

    await tester.pumpWidget(screen(on: true));
    final onPosition = tester.getTopLeft(find.text('switch'));

    expect(onPosition, offPosition);
    expect(onPosition.dy, 120);
  });

  // The hidden content keeps its size (it stays in the tree), but cannot be
  // seen or tapped.
  testWidgets('only the selected content is shown and tappable', (tester) async {
    await tester.pumpWidget(screen(on: true));
    expect(find.text('00:00:01').hitTestable(), findsOneWidget);
    expect(find.text('Toggle the switch').hitTestable(), findsNothing);
  });
}
