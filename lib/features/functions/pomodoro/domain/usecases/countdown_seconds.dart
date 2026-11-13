/// Whole seconds left until [end], as shown on the countdown.
///
/// Rounds up: timer ticks always fire a few ms late, so truncating would
/// skip a second on the first tick and end the phase one second early.
int countdownSecondsLeft(DateTime end, DateTime now) {
  final msLeft = end.difference(now).inMilliseconds;
  return msLeft > 0 ? (msLeft + 999) ~/ 1000 : 0;
}
