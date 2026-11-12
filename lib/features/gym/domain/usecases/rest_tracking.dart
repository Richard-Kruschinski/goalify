import '../../../../core/utils/day_cycle.dart';
import '../../data/models/gym_models.dart';

/// Rules around tracked sets: counting them per day, deciding when an exercise
/// is done, finding the next exercise and collecting rest times.
class RestTracking {
  const RestTracking._();

  /// Sets tracked on the logical [day] (see [DayCycle]).
  static int setsDoneOn(List<SetEvent> events, DateTime day) =>
      events.where((e) => DayCycle.dayOf(e.at) == day).length;

  /// Without a set target an exercise is never "done", only counted.
  static bool isComplete(int setsDone, int? targetSets) =>
      targetSets != null && targetSets > 0 && setsDone >= targetSets;

  /// First exercise after [currentId] in [orderedIds] that is not done yet.
  static String? nextOpenExercise(
    List<String> orderedIds,
    String currentId,
    bool Function(String id) isDone,
  ) {
    final start = orderedIds.indexOf(currentId) + 1;
    for (final id in orderedIds.skip(start)) {
      if (id != currentId && !isDone(id)) return id;
    }
    return null;
  }

  /// Rest times recorded before the sets of one workout log (same logical day
  /// and training day), in tracking order.
  static List<int> restsFor(List<SetEvent> events, WorkoutLog log) {
    final logDay = DayCycle.dayOf(log.dateTime);
    return events
        .where((e) => e.day == log.day && DayCycle.dayOf(e.at) == logDay)
        .map((e) => e.restBeforeSeconds)
        .whereType<int>()
        .toList();
  }
}
