import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/gym/presentation/widgets/animated_check.dart';
import 'package:Goalify/features/gym/presentation/widgets/set_progress_widgets.dart';
import 'package:Goalify/l10n/generated/app_localizations.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    );

Widget _check({required bool checked, bool animateIn = false}) =>
    AnimatedCheck(checked: checked, animateIn: animateIn, color: Colors.green, emptyColor: Colors.grey);

void main() {
  testWidgets('a check that is already there does not animate', (tester) async {
    await tester.pumpWidget(_app(_check(checked: true)));
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('becoming checked draws in and then settles', (tester) async {
    await tester.pumpWidget(_app(_check(checked: false)));
    await tester.pumpWidget(_app(_check(checked: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pump(AnimatedCheck.duration);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a new check can animate in on its first build', (tester) async {
    await tester.pumpWidget(_app(_check(checked: true, animateIn: true)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('reduced motion shows the check without animation', (tester) async {
    await tester.pumpWidget(_app(_check(checked: false), reduceMotion: true));
    await tester.pumpWidget(_app(_check(checked: true), reduceMotion: true));
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
  });

  group('SetProgressDots', () {
    testWidgets('only the newly tracked set animates', (tester) async {
      await tester.pumpWidget(_app(const SetProgressDots(setsDone: 1, targetSets: 3)));
      expect(tester.hasRunningAnimations, isFalse);

      await tester.pumpWidget(_app(const SetProgressDots(setsDone: 2, targetSets: 3)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pump(AnimatedCheck.duration);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('without a target a new check also animates', (tester) async {
      await tester.pumpWidget(_app(const SetProgressDots(setsDone: 1)));
      await tester.pumpWidget(_app(const SetProgressDots(setsDone: 2)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
    });
  });
}
