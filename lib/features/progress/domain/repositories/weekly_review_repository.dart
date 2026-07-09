import '../../data/models/weekly_review_data.dart';

/// Contract for building the weekly review shown on the progress screen.
///
/// The presentation layer depends only on this abstraction. The default
/// implementation aggregates data recorded by the tasks, gym and pomodoro
/// features; a database/server backend can be added later without changing
/// the UI.
abstract class WeeklyReviewRepository {
  Future<WeeklyReviewData> loadWeeklyReview();
}
