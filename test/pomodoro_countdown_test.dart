import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/functions/pomodoro/domain/usecases/countdown_seconds.dart';

void main() {
  final end = DateTime(2026, 1, 1, 12, 0, 0);

  test('a tick that fires a few ms late still shows the next second', () {
    final now = end.subtract(const Duration(seconds: 1492, milliseconds: 997));
    expect(countdownSecondsLeft(end, now), 1493);
  });

  test('exactly on a full second shows that second', () {
    final now = end.subtract(const Duration(seconds: 1494));
    expect(countdownSecondsLeft(end, now), 1494);
  });

  test('less than a second left is still 1, not 0', () {
    final now = end.subtract(const Duration(milliseconds: 400));
    expect(countdownSecondsLeft(end, now), 1);
  });

  test('past the end is 0', () {
    expect(countdownSecondsLeft(end, end), 0);
    expect(countdownSecondsLeft(end, end.add(const Duration(seconds: 2))), 0);
  });
}
