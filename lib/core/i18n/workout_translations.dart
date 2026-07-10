import 'dart:convert';
import 'package:flutter/services.dart';
import '../../features/gym/data/models/gym_models.dart';

/// Translates the built-in workouts from assets/workouts.json.
///
/// English is the base language (the texts inside workouts.json itself).
/// Adding a new language:
/// 1. Create assets/workout_i18n_<code>.json (same structure as the _de file:
///    a "workouts" map keyed by workout id and a "muscles" map keyed by the
///    English muscle name)
/// 2. Register the file under `assets:` in pubspec.yaml
/// Missing entries automatically fall back to the English original, so a
/// translation file may be incomplete while it is being worked on.
class WorkoutTranslations {
  WorkoutTranslations._();

  static final Map<String, Map<String, dynamic>?> _cache = {};

  static Future<Map<String, dynamic>?> _load(String langCode) async {
    if (_cache.containsKey(langCode)) return _cache[langCode];
    try {
      final jsonStr =
          await rootBundle.loadString('assets/workout_i18n_$langCode.json');
      _cache[langCode] = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      // No translation file for this language -> keep English.
      _cache[langCode] = null;
    }
    return _cache[langCode];
  }

  /// Returns the list with name, description and muscles translated for
  /// [langCode]. Ids not present in the translation file (e.g. custom
  /// user-created workouts) are returned unchanged.
  static Future<List<Workout>> localize(
      List<Workout> workouts, String langCode) async {
    if (langCode == 'en') return workouts;
    final data = await _load(langCode);
    if (data == null) return workouts;

    final workoutMap = data['workouts'] as Map<String, dynamic>? ?? const {};
    final muscleMap = data['muscles'] as Map<String, dynamic>? ?? const {};

    return workouts.map((w) {
      final t = workoutMap[w.id] as Map<String, dynamic>?;
      final muscles =
          w.muscles.map((m) => (muscleMap[m] as String?) ?? m).toList();
      return Workout(
        id: w.id,
        name: (t?['name'] as String?) ?? w.name,
        description: (t?['description'] as String?) ?? w.description,
        icon: w.icon,
        iconPath: w.iconPath,
        muscles: muscles,
        isDurationBased: w.isDurationBased,
      );
    }).toList();
  }
}
