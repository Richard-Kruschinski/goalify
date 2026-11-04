import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/gym/presentation/gym_sort.dart';

void main() {
  final items = ['Beta', 'alpha', 'Gamma', 'Delta'];
  final weights = {'Beta': 80.0, 'alpha': 100.0, 'Gamma': null, 'Delta': 60.0};

  test('manual keeps the given order', () {
    expect(const GymSortState().apply<String>(items, key: (s) => s, name: (s) => s), items);
  });

  test('alphabetical ignores case', () {
    const s = GymSortState(GymSortMode.alphabetical);
    expect(s.apply<String>(items, key: (s) => s.toLowerCase(), name: (s) => s),
        ['alpha', 'Beta', 'Delta', 'Gamma']);
  });

  test('heaviest is descending and keeps missing values last, also reversed', () {
    const s = GymSortState(GymSortMode.heaviest);
    expect(s.apply<String>(items, key: (s) => weights[s], name: (s) => s),
        ['alpha', 'Beta', 'Delta', 'Gamma']);
    final r = s.select(GymSortMode.heaviest);
    expect(r.reversed, isTrue);
    expect(r.apply<String>(items, key: (s) => weights[s], name: (s) => s),
        ['Delta', 'Beta', 'alpha', 'Gamma']);
  });

  test('switching mode resets the direction, manual never reverses', () {
    const s = GymSortState(GymSortMode.recent, true);
    expect(s.select(GymSortMode.alphabetical).reversed, isFalse);
    expect(const GymSortState().select(GymSortMode.manual).reversed, isFalse);
  });

  test('round-trips through its stored map', () {
    const s = GymSortState(GymSortMode.recent, true);
    final back = GymSortState.fromMap(s.toMap());
    expect(back.mode, GymSortMode.recent);
    expect(back.reversed, isTrue);
    expect(GymSortState.fromMap(null).isManual, isTrue);
  });
}
