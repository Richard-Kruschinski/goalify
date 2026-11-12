import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/utils/duration_format.dart';

void main() {
  test('formatClockDuration pads seconds and adds hours when needed', () {
    expect(formatClockDuration(0), '0:00');
    expect(formatClockDuration(65), '1:05');
    expect(formatClockDuration(600), '10:00');
    expect(formatClockDuration(3725), '1:02:05');
  });
}
