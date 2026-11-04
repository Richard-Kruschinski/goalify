/// Sort modes for the three gym lists (exercises, workouts, splits).
///
/// Each tab offers only the modes that make sense for it, see [forTab].
enum GymSortMode {
  manual,
  alphabetical,
  recent,
  heaviest,
  byWorkout,
  exerciseCount,
  workoutCount;

  /// Which way the mode sorts when not reversed: names read best A-Z, while
  /// dates, weights and counts are only useful with the biggest value on top.
  bool get isDescendingByNature => switch (this) {
        recent || heaviest || exerciseCount || workoutCount => true,
        manual || alphabetical || byWorkout => false,
      };

  /// Reversing a hand-made order has no meaning.
  bool get supportsReverse => this != manual;

  static GymSortMode fromName(String? raw) => GymSortMode.values.firstWhere(
        (m) => m.name == raw,
        orElse: () => GymSortMode.manual,
      );
}

/// The active sort of one tab.
class GymSortState {
  const GymSortState([this.mode = GymSortMode.manual, this.reversed = false]);

  final GymSortMode mode;
  final bool reversed;

  bool get isManual => mode == GymSortMode.manual;
  bool get descending => mode.isDescendingByNature != reversed;

  /// Picking the active mode again flips it; a different mode starts from its
  /// natural direction.
  GymSortState select(GymSortMode next) => next == mode
      ? GymSortState(mode, mode.supportsReverse && !reversed)
      : GymSortState(next);

  Map<String, dynamic> toMap() => {'mode': mode.name, 'reversed': reversed};

  factory GymSortState.fromMap(Object? raw) {
    if (raw is! Map) return const GymSortState();
    final mode = GymSortMode.fromName(raw['mode']?.toString());
    return GymSortState(mode, mode.supportsReverse && raw['reversed'] == true);
  }

  /// Sorts [items] by [key] in this state's direction. Items without a key
  /// (never trained, no weight) stay at the bottom either way, and ties fall
  /// back to [name] A-Z so the order is stable.
  List<T> apply<T>(
    List<T> items, {
    required Comparable<dynamic>? Function(T item) key,
    required String Function(T item) name,
  }) {
    if (isManual) return items;
    int byName(T a, T b) =>
        name(a).toLowerCase().compareTo(name(b).toLowerCase());
    final sorted = List<T>.from(items)
      ..sort((a, b) {
        final ka = key(a);
        final kb = key(b);
        if (ka == null && kb == null) return byName(a, b);
        if (ka == null) return 1;
        if (kb == null) return -1;
        final c = descending ? kb.compareTo(ka) : ka.compareTo(kb);
        return c != 0 ? c : byName(a, b);
      });
    return sorted;
  }
}
