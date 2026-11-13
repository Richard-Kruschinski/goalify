import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/widgets/animated_sort_icon.dart';

Widget _app(SortIconState state, {bool reduceMotion = false, bool animate = true}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(
          body: Center(child: AnimatedSortIcon(state: state, animate: animate)),
        ),
      ),
    );

const _duration = Duration(milliseconds: 300);

void main() {
  testWidgets('first build and plain rebuilds do not animate', (tester) async {
    await tester.pumpWidget(_app(SortIconState.descending));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(_app(SortIconState.descending));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('every state change animates and settles', (tester) async {
    const order = [
      SortIconState.none,
      SortIconState.ascending,
      SortIconState.none,
      SortIconState.descending,
      SortIconState.none,
      SortIconState.descending,
      SortIconState.ascending,
      SortIconState.descending,
    ];
    await tester.pumpWidget(_app(order.first));
    for (final state in order.skip(1)) {
      await tester.pumpWidget(_app(state));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue, reason: '$state');
      await tester.pump(_duration);
      expect(tester.hasRunningAnimations, isFalse, reason: '$state');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a change mid-animation continues from where it is', (tester) async {
    await tester.pumpWidget(_app(SortIconState.none));
    await tester.pumpWidget(_app(SortIconState.ascending));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(_app(SortIconState.descending));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpWidget(_app(SortIconState.none));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(_duration);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion and animate: false jump', (tester) async {
    await tester.pumpWidget(_app(SortIconState.none, reduceMotion: true));
    await tester.pumpWidget(_app(SortIconState.ascending, reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(_app(SortIconState.none, animate: false));
    await tester.pumpWidget(_app(SortIconState.descending, animate: false));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });
}
