import 'package:flutter/foundation.dart';

/// Defines when a "day" starts for everything the app tracks per day
/// (daily tasks, gym/creatine calendar, progress charts, weekly review).
///
/// Some people go to bed at 3 a.m. and still consider that the same day, so the
/// rollover time is configurable in the settings (00:00 = calendar midnight,
/// 02:00 = the day runs from 02:00 until 01:59 the next morning).
///
/// The trick is a single shift: subtracting the start time from a real
/// timestamp maps it onto its *logical* day, so all existing yyyy-MM-dd based
/// storage keeps working unchanged.
///
/// Rule of thumb when using this class:
/// * a real timestamp (`DateTime.now()`, a log's `dateTime`) -> [dayOf]
/// * an already normalised day (calendar cell, picked date) -> use as is
class DayCycle {
  DayCycle._();

  static const int minutesPerDay = 24 * 60;
  static const int defaultStartMinuteOfDay = 0;

  static int _startMinuteOfDay = defaultStartMinuteOfDay;

  /// Bumped whenever the start time changes so open screens can reload.
  static final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Minutes since midnight (0-1439) at which a new day begins.
  static int get startMinuteOfDay => _startMinuteOfDay;

  /// Hour part (0-23) of the start time.
  static int get startHour => _startMinuteOfDay ~/ 60;

  /// Minute part (0-59) of the start time.
  static int get startMinute => _startMinuteOfDay % 60;

  /// Applies a new start time. Out-of-range values are wrapped into a day.
  static void setStart(int hour, int minute) =>
      setStartMinuteOfDay(hour * 60 + minute);

  /// Applies a new start time given as minutes since midnight.
  static void setStartMinuteOfDay(int minuteOfDay) {
    final normalized = ((minuteOfDay % minutesPerDay) + minutesPerDay) % minutesPerDay;
    if (normalized == _startMinuteOfDay) return;
    _startMinuteOfDay = normalized;
    revision.value++;
  }

  /// [timestamp] shifted back by the start time, so times before the day start
  /// still fall into the previous day.
  static DateTime shift(DateTime timestamp) =>
      timestamp.subtract(Duration(minutes: _startMinuteOfDay));

  /// The logical day (midnight-normalised) a real timestamp belongs to.
  static DateTime dayOf(DateTime timestamp) {
    final shifted = shift(timestamp);
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  /// The logical day we are currently in.
  static DateTime today() => dayOf(DateTime.now());

  /// Wall-clock instant at which the logical day [day] begins.
  static DateTime startOf(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour, startMinute);

  /// Wall-clock instant at which the logical day [day] ends (= start of the
  /// following day).
  static DateTime endOf(DateTime day) =>
      DateTime(day.year, day.month, day.day + 1, startHour, startMinute);

  /// Next instant at which the day rolls over, seen from [from].
  static DateTime nextBoundary([DateTime? from]) {
    final now = from ?? DateTime.now();
    return endOf(dayOf(now));
  }

  /// Time left until the next rollover. Never negative.
  static Duration untilNextBoundary([DateTime? from]) {
    final now = from ?? DateTime.now();
    final diff = nextBoundary(now).difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// yyyy-MM-dd key for an already normalised day.
  static String dateKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  /// yyyy-MM-dd key of the logical day a real timestamp belongs to.
  static String keyOf(DateTime timestamp) => dateKey(dayOf(timestamp));

  /// yyyy-MM-dd key of the logical day we are currently in.
  static String todayKey() => dateKey(today());
}
