import 'dart:math' as math;
import 'package:flutter/material.dart';

IconData _iconFromString(String? name) {
  switch (name) {
    case 'upload':
      return Icons.upload;
    case 'accessibility':
      return Icons.accessibility;
    case 'accessibility_new':
      return Icons.accessibility_new;
    case 'align_vertical_bottom':
      return Icons.align_vertical_bottom;
    case 'fitness_center':
    default:
      return Icons.fitness_center;
  }
}

/// Localized unit / label strings used when rendering workout values.
/// Kept as a plain data holder so the model layer stays independent of the
/// generated l10n code; the presentation layer builds it from AppLocalizations
/// (see `workoutUnitsOf` in core/i18n/task_labels.dart). Defaults to English.
class WorkoutUnits {
  final String kg;
  final String reps;
  final String minShort;
  final String secShort;
  final String sets;
  final String dropset;
  final String noProgress;
  final String update;

  const WorkoutUnits({
    this.kg = 'kg',
    this.reps = 'reps',
    this.minShort = 'min',
    this.secShort = 's',
    this.sets = 'Sets',
    this.dropset = 'Dropset',
    this.noProgress = 'No progress yet',
    this.update = 'Update',
  });

  static const WorkoutUnits en = WorkoutUnits();
}

String formatDurationShort(int seconds, [WorkoutUnits u = WorkoutUnits.en]) {
  if (seconds <= 0) return '0 ${u.secShort}';
  final int minutes = seconds ~/ 60;
  final int secs = seconds % 60;
  if (minutes > 0 && secs > 0) return '$minutes ${u.minShort} $secs ${u.secShort}';
  if (minutes > 0) return '$minutes ${u.minShort}';
  return '$seconds ${u.secShort}';
}

bool isDurationWorkout(Workout workout) => workout.isDurationBased;

String latestSummaryText(Workout workout, WorkoutLog? latest,
    [WorkoutUnits u = WorkoutUnits.en]) {
  if (latest == null) return u.noProgress;
  if (isDurationWorkout(workout)) {
    final dur = latest.longestDurationSeconds;
    final value = dur > 0 ? formatDurationShort(dur, u) : '${latest.setCount} ${u.sets}';
    return '${latest.day} • $value';
  }
  final value = latest.hasAnyDropsets
      ? u.dropset
      : '${latest.maxWeightKg.toStringAsFixed(1)} ${u.kg} × ${latest.heaviestSetReps} ${u.reps}';
  return '${latest.day} • $value';
}

String latestUpdateText(Workout workout, WorkoutLog? latest,
    [WorkoutUnits u = WorkoutUnits.en]) {
  if (latest == null) return u.noProgress;
  if (isDurationWorkout(workout)) {
    final dur = latest.longestDurationSeconds;
    final value = dur > 0 ? formatDurationShort(dur, u) : '${latest.setCount} ${u.sets}';
    return '${u.update}: $value';
  }
  final value = latest.hasAnyDropsets
      ? u.dropset
      : '${latest.maxWeightKg.toStringAsFixed(1)} ${u.kg} × ${latest.heaviestSetReps} ${u.reps}';
  return '${u.update}: $value';
}

class Workout {
  final String id;
  final String name;
  final String description;
  final IconData? icon;
  final String? iconPath;
  final List<String> muscles;
  final bool isDurationBased;

  /// Weight of the empty bar this exercise is usually done with, in kg.
  /// 0 means the exercise has no bar. Only a starting point — the user can
  /// override it per exercise in the weight settings.
  final double defaultBarWeightKg;

  /// Whether the bar weight setting is offered for this exercise at all.
  ///
  /// Only barbell lifts carry a `barWeightKg` in assets/workouts.json, so
  /// machine, cable, dumbbell and user-created exercises never show the
  /// option - a bar weight is meaningless for them.
  bool get supportsBarWeight => defaultBarWeightKg > 0;

  const Workout({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.iconPath,
    this.muscles = const [],
    this.isDurationBased = false,
    this.defaultBarWeightKg = 0,
  });

  factory Workout.fromJson(Map<String, dynamic> m) {
    final iconString = m['icon'] as String;
    final bool isAssetPath = iconString.startsWith('assets/');
    final inputType = (m['inputType'] ?? m['input_type'] ?? '').toString().toLowerCase();

    return Workout(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String,
      icon: isAssetPath ? null : _iconFromString(iconString),
      iconPath: isAssetPath ? iconString : null,
      muscles: (m['muscles'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      isDurationBased: inputType == 'duration' || (m['durationOnly'] == true),
      defaultBarWeightKg: (m['barWeightKg'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WorkoutSet {
  /// Value the user typed. Depending on [weightIncludesBar] this is either the
  /// full weight (bar + plates) or the plates alone.
  final double weightKg;
  final int reps;
  final int? durationSeconds;
  final List<WorkoutSet> dropsets; // Dropsets gehören zu diesem Set

  /// Bar weight configured for the exercise when this set was logged. Stored
  /// per set so changing the setting later leaves the history untouched unless
  /// the user explicitly asks for a recalculation.
  final double barWeightKg;

  /// Whether [weightKg] already contains [barWeightKg].
  final bool weightIncludesBar;

  const WorkoutSet({
    required this.weightKg,
    required this.reps,
    this.durationSeconds,
    this.dropsets = const [],
    this.barWeightKg = 0,
    this.weightIncludesBar = true,
  });

  bool get hasDuration => (durationSeconds ?? 0) > 0;
  bool get hasDropsets => dropsets.isNotEmpty;
  bool get hasBar => barWeightKg > 0;

  /// Bar + plates — the value every statistic shows.
  double get totalWeightKg =>
      weightIncludesBar ? weightKg : weightKg + barWeightKg;

  /// The plates alone, without the bar.
  double get plateWeightKg =>
      weightIncludesBar ? weightKg - barWeightKg : weightKg;

  /// Copy carrying a different bar weight, dropsets included. Used when the
  /// user recalculates past logs after changing the bar weight.
  ///
  /// The plates stay exactly what they were — only the bar underneath changes.
  /// So a set tracked as 80 kg including a 20 kg bar becomes 90 kg once the bar
  /// is corrected to 30 kg (80 − 20 + 30), while a set that only tracked its
  /// 80 kg of plates keeps that number and just totals 10 kg higher.
  WorkoutSet withBarWeight(double newBarWeightKg) => WorkoutSet(
    weightKg: weightIncludesBar ? plateWeightKg + newBarWeightKg : weightKg,
    reps: reps,
    durationSeconds: durationSeconds,
    dropsets: dropsets.map((d) => d.withBarWeight(newBarWeightKg)).toList(),
    barWeightKg: newBarWeightKg,
    weightIncludesBar: weightIncludesBar,
  );

  Map<String, dynamic> toMap() => {
    'weightKg': weightKg,
    'reps': reps,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (dropsets.isNotEmpty) 'dropsets': dropsets.map((s) => s.toMap()).toList(),
    if (barWeightKg > 0) 'barWeightKg': barWeightKg,
    if (!weightIncludesBar) 'weightIncludesBar': false,
  };

  factory WorkoutSet.fromMap(Map<String, dynamic> m) {
    final dropsetsList = (m['dropsets'] as List? ?? [])
        .map((s) => WorkoutSet.fromMap(Map<String, dynamic>.from(s)))
        .toList();

    return WorkoutSet(
      weightKg: (m['weightKg'] as num?)?.toDouble() ?? 0.0,
      reps: (m['reps'] as num?)?.toInt() ?? 0,
      durationSeconds: (m['durationSeconds'] as num?)?.toInt(),
      dropsets: dropsetsList,
      // Logs written before bar weights existed carry the plain value.
      barWeightKg: (m['barWeightKg'] as num?)?.toDouble() ?? 0.0,
      weightIncludesBar: m['weightIncludesBar'] as bool? ?? true,
    );
  }
}

class WorkoutLog {
  final DateTime dateTime;
  final String day;
  final List<WorkoutSet> sets; // Liste von Sets, jedes mit Weight und Reps

  const WorkoutLog({
    required this.dateTime,
    required this.day,
    required this.sets,
  });

  // Für Kompatibilität: gibt das Gewicht des ersten Sets zurück
  double get weightKg => sets.isNotEmpty ? sets.first.weightKg : 0.0;
  // Für Kompatibilität: gibt die Anzahl der Sets zurück
  int get setCount => sets.length;

  bool get hasDurationSets => sets.any((s) => s.hasDuration);

  // Nutzt die längste Set-Dauer als wichtigste Kennzahl für Dauer-Workouts
  int get longestDurationSeconds => hasDurationSets
      ? sets.map((s) => s.durationSeconds ?? 0).reduce(math.max)
      : 0;

  // Gibt das Set mit dem höchsten Gewicht zurück
  WorkoutSet? get heaviestSet {
    if (sets.isEmpty || hasDurationSets) return sets.isEmpty ? null : sets.first;
    return sets.reduce((a, b) => a.totalWeightKg >= b.totalWeightKg ? a : b);
  }

  // Gewicht des heaviest Sets — immer Stange + Scheiben
  double get maxWeightKg => heaviestSet?.totalWeightKg ?? 0.0;

  // Stangengewicht dieses Logs (0 = keine Stange hinterlegt)
  double get barWeightKg => sets.isEmpty ? 0.0 : sets.first.barWeightKg;

  bool get hasBarWeight => sets.any((s) => s.hasBar);

  /// Kopie mit neuem Stangengewicht für alle Sets — für die nachträgliche
  /// Neuberechnung der Historie.
  WorkoutLog withBarWeight(double newBarWeightKg) => WorkoutLog(
    dateTime: dateTime,
    day: day,
    sets: sets.map((s) => s.withBarWeight(newBarWeightKg)).toList(),
  );

  // Gibt die Reps des heaviest Sets zurück
  int get heaviestSetReps => heaviestSet?.reps ?? 0;

  // Erkennt ob es ein Dropset ist (jetzt prüfen wir ob Sets Dropsets haben)
  bool get hasAnyDropsets {
    return sets.any((s) => s.hasDropsets);
  }

  // Gibt die Displaystring für die Sets zurück (mit Dropset-Erkennung)
  String get setDisplayString {
    if (sets.isEmpty) return '0 Sets';
    if (hasDurationSets) {
      final dur = longestDurationSeconds;
      if (dur <= 0) return '${sets.length} Sets';
      return '${sets.length} Sets • ${formatDurationShort(dur)}';
    }
    
    // Zähle Dropsets
    int totalDropsets = 0;
    for (final set in sets) {
      totalDropsets += set.dropsets.length;
    }
    
    if (totalDropsets > 0) {
      return 'Dropset (${sets.length} + $totalDropsets)';
    }
    return '${maxWeightKg.toStringAsFixed(1)} kg × $heaviestSetReps reps';
  }

  Map<String, dynamic> toMap() => {
    'dateTime': dateTime.toIso8601String(),
    'day': day,
    'sets': sets.map((s) => s.toMap()).toList(),
  };

  factory WorkoutLog.fromMap(Map<String, dynamic> m) {
    final setsList = (m['sets'] as List? ?? [])
        .map((s) => WorkoutSet.fromMap(Map<String, dynamic>.from(s)))
        .toList();
    
    // Fallback für alte Daten (mit weightKg und sets)
    if (setsList.isEmpty && m['weightKg'] != null && m['sets'] != null) {
      final weight = (m['weightKg'] as num).toDouble();
      final setCount = (m['sets'] as num).toInt();
      for (int i = 0; i < setCount; i++) {
        // Alte Daten: erstelle Sets mit gleichen Gewicht und 0 Reps
        setsList.add(WorkoutSet(weightKg: weight, reps: 0));
      }
    }

    return WorkoutLog(
      dateTime: DateTime.parse(m['dateTime'] as String),
      day: m['day'] as String,
      sets: setsList,
    );
  }
}

/// Gewichts-Einstellungen einer Übung (Stangengewicht + Tracking-Modus).
/// Gilt dauerhaft für die Übung; jeder neue Log übernimmt sie als Snapshot.
class ExerciseWeightSettings {
  /// Gewicht der Stange in kg. 0 = keine Stange hinterlegt.
  final double barWeightKg;

  /// true  -> das getrackte Gewicht enthält die Stange bereits
  /// false -> es werden nur die Gewichtsscheiben getrackt
  final bool trackedIncludesBar;

  const ExerciseWeightSettings({
    this.barWeightKg = 0,
    this.trackedIncludesBar = true,
  });

  bool get hasBar => barWeightKg > 0;

  ExerciseWeightSettings copyWith({
    double? barWeightKg,
    bool? trackedIncludesBar,
  }) =>
      ExerciseWeightSettings(
        barWeightKg: barWeightKg ?? this.barWeightKg,
        trackedIncludesBar: trackedIncludesBar ?? this.trackedIncludesBar,
      );

  Map<String, dynamic> toMap() => {
    'barWeightKg': barWeightKg,
    'trackedIncludesBar': trackedIncludesBar,
  };

  factory ExerciseWeightSettings.fromMap(Map<String, dynamic> m) =>
      ExerciseWeightSettings(
        barWeightKg: (m['barWeightKg'] as num?)?.toDouble() ?? 0.0,
        trackedIncludesBar: m['trackedIncludesBar'] as bool? ?? true,
      );
}

/// Rückgabewert des Dialogs:
/// - log != null  -> tracken
/// - assignDay != null -> nur Plan-Zuweisung (ohne History)
/// - trackedIncludesBar != null -> Checkbox-Zustand, der für die Übung
///   dauerhaft gespeichert werden soll
class LogOutcome {
  final WorkoutLog? log;
  final String? assignDay;
  final bool? trackedIncludesBar;
  const LogOutcome({this.log, this.assignDay, this.trackedIncludesBar});
}

class SplitEditorResult {
  final String name;
  final List<String> days;

  const SplitEditorResult({required this.name, required this.days});
}

/// ===============================================================
/// Best Set Tracking & Scoring
/// ===============================================================

/// Speichert Informationen über den besten Satz für eine Übung
class BestSetRecord {
  final DateTime dateTime;      // Wann war dieser beste Satz?
  final double maxWeight;       // Höchstes Gewicht in allen Sets
  final int maxReps;           // Reps beim höchsten Gewicht
  final int setCount;          // Wie viele Sets insgesamt
  final double score;          // Numerischer Score zur Sortierung

  const BestSetRecord({
    required this.dateTime,
    required this.maxWeight,
    required this.maxReps,
    required this.setCount,
    required this.score,
  });

  Map<String, dynamic> toMap() => {
    'dateTime': dateTime.toIso8601String(),
    'maxWeight': maxWeight,
    'maxReps': maxReps,
    'setCount': setCount,
    'score': score,
  };

  factory BestSetRecord.fromMap(Map<String, dynamic> m) {
    return BestSetRecord(
      dateTime: DateTime.parse(m['dateTime'] as String),
      maxWeight: (m['maxWeight'] as num?)?.toDouble() ?? 0.0,
      maxReps: (m['maxReps'] as num?)?.toInt() ?? 0,
      setCount: (m['setCount'] as num?)?.toInt() ?? 0,
      score: (m['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
