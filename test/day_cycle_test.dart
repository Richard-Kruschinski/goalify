import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/utils/day_cycle.dart';

void main() {
  tearDown(() => DayCycle.setStartMinuteOfDay(DayCycle.defaultStartMinuteOfDay));

  group('start 00:00 (calendar midnight)', () {
    test('a timestamp keeps its calendar day', () {
      expect(
        DayCycle.dayOf(DateTime(2026, 8, 14, 1, 30)),
        DateTime(2026, 8, 14),
      );
      expect(DayCycle.keyOf(DateTime(2026, 8, 14, 23, 59)), '2026-08-14');
    });
  });

  group('start 02:00 (day runs 02:00 -> 01:59)', () {
    setUp(() => DayCycle.setStart(2, 0));

    test('after the boundary the timestamp belongs to that calendar day', () {
      expect(
        DayCycle.dayOf(DateTime(2026, 8, 14, 2, 0)),
        DateTime(2026, 8, 14),
      );
      expect(
        DayCycle.dayOf(DateTime(2026, 8, 14, 23, 59)),
        DateTime(2026, 8, 14),
      );
    });

    test('before the boundary it still belongs to the previous day', () {
      expect(
        DayCycle.dayOf(DateTime(2026, 8, 15, 0, 30)),
        DateTime(2026, 8, 14),
      );
      expect(DayCycle.keyOf(DateTime(2026, 8, 15, 1, 59)), '2026-08-14');
    });

    test('boundaries wrap the logical day', () {
      final day = DateTime(2026, 8, 14);
      expect(DayCycle.startOf(day), DateTime(2026, 8, 14, 2));
      expect(DayCycle.endOf(day), DateTime(2026, 8, 15, 2));
    });

    test('nextBoundary is the upcoming rollover', () {
      expect(
        DayCycle.nextBoundary(DateTime(2026, 8, 15, 1, 0)),
        DateTime(2026, 8, 15, 2),
      );
      expect(
        DayCycle.nextBoundary(DateTime(2026, 8, 15, 3, 0)),
        DateTime(2026, 8, 16, 2),
      );
    });

    test('untilNextBoundary counts down to the rollover', () {
      expect(
        DayCycle.untilNextBoundary(DateTime(2026, 8, 15, 1, 0)),
        const Duration(hours: 1),
      );
    });
  });

  group('start 03:30 (minute precision)', () {
    setUp(() => DayCycle.setStart(3, 30));

    test('splits the night at the exact minute', () {
      expect(DayCycle.startHour, 3);
      expect(DayCycle.startMinute, 30);
      expect(
        DayCycle.dayOf(DateTime(2026, 8, 15, 3, 29)),
        DateTime(2026, 8, 14),
      );
      expect(
        DayCycle.dayOf(DateTime(2026, 8, 15, 3, 30)),
        DateTime(2026, 8, 15),
      );
    });

    test('boundaries carry the minute', () {
      expect(
        DayCycle.endOf(DateTime(2026, 8, 14)),
        DateTime(2026, 8, 15, 3, 30),
      );
    });
  });

  test('changing the start time bumps the revision', () {
    final before = DayCycle.revision.value;
    DayCycle.setStart(5, 15);
    expect(DayCycle.revision.value, before + 1);
    // Setting the same value again is a no-op.
    DayCycle.setStart(5, 15);
    expect(DayCycle.revision.value, before + 1);
  });

  test('out-of-range values wrap into a day', () {
    DayCycle.setStart(26, 0);
    expect(DayCycle.startHour, 2);
    DayCycle.setStartMinuteOfDay(-30);
    expect(DayCycle.startHour, 23);
    expect(DayCycle.startMinute, 30);
  });
}
