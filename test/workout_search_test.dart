import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/gym/data/models/gym_models.dart';
import 'package:Goalify/features/gym/presentation/widgets/workout_search_field.dart';

void main() {
  const benchPress = Workout(
    id: 'bench',
    name: 'Bankdrücken (Kurzhanteln)',
    description: '',
    muscles: ['Brust', 'Trizeps'],
  );

  group('workoutMatchesQuery', () {
    test('an empty or blank query matches everything', () {
      expect(workoutMatchesQuery(benchPress, ''), isTrue);
      expect(workoutMatchesQuery(benchPress, '   '), isTrue);
    });

    test('matches part of the name, ignoring case', () {
      expect(workoutMatchesQuery(benchPress, 'kurzhantel'), isTrue);
      expect(workoutMatchesQuery(benchPress, 'BANK'), isTrue);
    });

    test('matches a muscle', () {
      expect(workoutMatchesQuery(benchPress, 'trizeps'), isTrue);
    });

    test('ignores surrounding spaces', () {
      expect(workoutMatchesQuery(benchPress, ' brust '), isTrue);
    });

    test('does not match unrelated text', () {
      expect(workoutMatchesQuery(benchPress, 'kniebeuge'), isFalse);
    });
  });
}
