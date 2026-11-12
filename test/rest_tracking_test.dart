import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/utils/day_cycle.dart';
import 'package:Goalify/features/gym/data/models/gym_models.dart';
import 'package:Goalify/features/gym/domain/usecases/rest_tracking.dart';

void main() {
  tearDown(() => DayCycle.setStartMinuteOfDay(DayCycle.defaultStartMinuteOfDay));

  SetEvent event(DateTime at, {String day = 'Pull', int? rest}) =>
      SetEvent(at: at, day: day, restBeforeSeconds: rest);

  group('setsDoneOn', () {
    test('counts only the sets of the given logical day', () {
      final events = [
        event(DateTime(2026, 11, 11, 18)),
        event(DateTime(2026, 11, 12, 18)),
        event(DateTime(2026, 11, 12, 18, 5)),
      ];
      expect(RestTracking.setsDoneOn(events, DateTime(2026, 11, 12)), 2);
    });

    test('a set after midnight still belongs to the evening before a later day start', () {
      DayCycle.setStart(2, 0);
      final events = [event(DateTime(2026, 11, 13, 1, 30))];
      expect(RestTracking.setsDoneOn(events, DateTime(2026, 11, 12)), 1);
    });
  });

  group('isComplete', () {
    test('needs a target and enough sets', () {
      expect(RestTracking.isComplete(3, 3), isTrue);
      expect(RestTracking.isComplete(4, 3), isTrue);
      expect(RestTracking.isComplete(2, 3), isFalse);
      expect(RestTracking.isComplete(5, null), isFalse);
      expect(RestTracking.isComplete(0, 0), isFalse);
    });
  });

  group('nextOpenExercise', () {
    test('skips exercises that are already done', () {
      final next = RestTracking.nextOpenExercise(
        ['bench', 'row', 'curl'],
        'bench',
        (id) => id == 'row',
      );
      expect(next, 'curl');
    });

    test('is null after the last exercise', () {
      expect(RestTracking.nextOpenExercise(['bench', 'curl'], 'curl', (_) => false), isNull);
    });

    test('starts from the top when the current exercise is not in the day', () {
      expect(RestTracking.nextOpenExercise(['bench', 'curl'], 'squat', (_) => false), 'bench');
    });
  });

  group('restsFor', () {
    test('returns the recorded rests of the same day and training day', () {
      final log = WorkoutLog(dateTime: DateTime(2026, 11, 12, 18, 30), day: 'Pull', sets: const []);
      final events = [
        event(DateTime(2026, 11, 12, 18)),
        event(DateTime(2026, 11, 12, 18, 2), rest: 95),
        event(DateTime(2026, 11, 12, 18, 4), rest: 110),
        event(DateTime(2026, 11, 12, 18, 6), day: 'Push', rest: 60),
        event(DateTime(2026, 11, 11, 18, 2), rest: 70),
      ];
      expect(RestTracking.restsFor(events, log), [95, 110]);
    });
  });

  group('serialization', () {
    test('rest settings survive a round trip, empty values stay null', () {
      const settings = ExerciseRestSettings(targetSets: 3, targetRestSeconds: 90);
      final copy = ExerciseRestSettings.fromMap(settings.toMap());
      expect(copy.targetSets, 3);
      expect(copy.targetRestSeconds, 90);

      final empty = ExerciseRestSettings.fromMap(const ExerciseRestSettings().toMap());
      expect(empty.targetSets, isNull);
      expect(empty.targetRestSeconds, isNull);
    });

    test('set events survive a round trip', () {
      final original = event(DateTime(2026, 11, 12, 18, 2), rest: 95);
      final copy = SetEvent.fromMap(original.toMap());
      expect(copy.at, original.at);
      expect(copy.day, 'Pull');
      expect(copy.restBeforeSeconds, 95);
    });
  });
}
