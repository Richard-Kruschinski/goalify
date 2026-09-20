import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/gym/data/models/gym_models.dart';

WorkoutLog _log(List<WorkoutSet> sets) => WorkoutLog(
      dateTime: DateTime(2026, 8, 28),
      day: 'Pull',
      sets: sets,
    );

void main() {
  group('WorkoutSet bar weight', () {
    test('plate-only tracking adds the bar to the total', () {
      const set = WorkoutSet(
        weightKg: 80,
        reps: 8,
        barWeightKg: 20,
        weightIncludesBar: false,
      );
      expect(set.totalWeightKg, 100);
      expect(set.plateWeightKg, 80);
    });

    test('full-weight tracking keeps the entered value as the total', () {
      const set = WorkoutSet(
        weightKg: 100,
        reps: 8,
        barWeightKg: 20,
        weightIncludesBar: true,
      );
      expect(set.totalWeightKg, 100);
      expect(set.plateWeightKg, 80);
    });

    test('sets without a bar behave as before', () {
      const set = WorkoutSet(weightKg: 60, reps: 10);
      expect(set.hasBar, isFalse);
      expect(set.totalWeightKg, 60);
    });
  });

  group('serialization', () {
    test('round-trips the bar fields', () {
      const set = WorkoutSet(
        weightKg: 80,
        reps: 8,
        barWeightKg: 22.5,
        weightIncludesBar: false,
        dropsets: [
          WorkoutSet(
            weightKg: 60,
            reps: 10,
            barWeightKg: 22.5,
            weightIncludesBar: false,
          ),
        ],
      );
      final restored = WorkoutSet.fromMap(set.toMap());
      expect(restored.barWeightKg, 22.5);
      expect(restored.weightIncludesBar, isFalse);
      expect(restored.totalWeightKg, 102.5);
      expect(restored.dropsets.single.totalWeightKg, 82.5);
    });

    test('logs written before the feature keep their plain weight', () {
      final restored = WorkoutSet.fromMap({'weightKg': 90.0, 'reps': 5});
      expect(restored.barWeightKg, 0);
      expect(restored.weightIncludesBar, isTrue);
      expect(restored.totalWeightKg, 90);
    });

    test('omits the bar fields when no bar is configured', () {
      const set = WorkoutSet(weightKg: 90, reps: 5);
      expect(set.toMap().containsKey('barWeightKg'), isFalse);
      expect(set.toMap().containsKey('weightIncludesBar'), isFalse);
    });
  });

  group('WorkoutLog statistics', () {
    test('heaviest set is picked by total weight, not the entered value', () {
      final log = _log(const [
        // 90 entered, bar included -> 90 total
        WorkoutSet(weightKg: 90, reps: 5, barWeightKg: 20),
        // 80 entered as plates only -> 100 total
        WorkoutSet(
          weightKg: 80,
          reps: 3,
          barWeightKg: 20,
          weightIncludesBar: false,
        ),
      ]);
      expect(log.maxWeightKg, 100);
      expect(log.heaviestSetReps, 3);
    });

    test('withBarWeight shifts plate-only totals and leaves plates alone', () {
      final log = _log(const [
        WorkoutSet(
          weightKg: 80,
          reps: 8,
          barWeightKg: 20,
          weightIncludesBar: false,
        ),
      ]);
      final updated = log.withBarWeight(25);
      expect(updated.maxWeightKg, 105);
      expect(updated.sets.single.plateWeightKg, 80);
      expect(updated.sets.single.weightKg, 80, reason: 'entered value untouched');
    });

    test('withBarWeight swaps the bar inside a bar-inclusive total', () {
      // 80 kg tracked including a 20 kg bar -> 60 kg of plates.
      final log = _log(const [
        WorkoutSet(weightKg: 80, reps: 8, barWeightKg: 20),
      ]);
      final updated = log.withBarWeight(30);
      expect(updated.maxWeightKg, 90, reason: '80 - 20 + 30');
      expect(updated.sets.single.plateWeightKg, 60, reason: 'plates unchanged');
    });

    test('withBarWeight reaches dropsets too', () {
      final log = _log(const [
        WorkoutSet(
          weightKg: 80,
          reps: 8,
          barWeightKg: 20,
          dropsets: [WorkoutSet(weightKg: 60, reps: 10, barWeightKg: 20)],
        ),
      ]);
      final updated = log.withBarWeight(30);
      expect(updated.sets.single.dropsets.single.totalWeightKg, 70);
    });
  });
}
