/// Aggregated numbers for the weekly review card: the current week
/// (Monday through today) compared against the full previous week (Mon-Sun).
class WeeklyReviewData {
  final int focusMinutes;
  final int prevFocusMinutes;
  final int blockerMinutes;
  final int prevBlockerMinutes;
  final int tasksDone;
  final int prevTasksDone;
  final int workouts;
  final int prevWorkouts;

  const WeeklyReviewData({
    this.focusMinutes = 0,
    this.prevFocusMinutes = 0,
    this.blockerMinutes = 0,
    this.prevBlockerMinutes = 0,
    this.tasksDone = 0,
    this.prevTasksDone = 0,
    this.workouts = 0,
    this.prevWorkouts = 0,
  });

  bool get isEmpty =>
      focusMinutes == 0 &&
      prevFocusMinutes == 0 &&
      blockerMinutes == 0 &&
      prevBlockerMinutes == 0 &&
      tasksDone == 0 &&
      prevTasksDone == 0 &&
      workouts == 0 &&
      prevWorkouts == 0;
}
