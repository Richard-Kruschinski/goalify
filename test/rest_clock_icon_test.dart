import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/gym/presentation/widgets/rest_clock_icon.dart';

void main() {
  const rest = Duration(seconds: 90);

  test('one full turn equals the target rest', () {
    expect(RestClockIcon.turnFraction(Duration.zero, rest), 0);
    expect(RestClockIcon.turnFraction(const Duration(seconds: 45), rest), 0.5);
    expect(RestClockIcon.turnFraction(const Duration(seconds: 90), rest), 0);
  });

  test('keeps turning after the target rest', () {
    expect(RestClockIcon.turnFraction(const Duration(seconds: 135), rest), 0.5);
  });

  test('stays at 12 o\'clock without a usable revolution', () {
    expect(RestClockIcon.turnFraction(const Duration(seconds: 10), Duration.zero), 0);
  });

  testWidgets('stops its ticker when removed', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RestClockIcon(
          elapsed: () => const Duration(seconds: 20),
          revolution: rest,
          color: Colors.red,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(const SizedBox());
    expect(tester.hasRunningAnimations, isFalse);
  });
}
