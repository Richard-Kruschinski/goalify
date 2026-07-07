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

String formatDurationShort(int seconds) {
  if (seconds <= 0) return '0 s';
  final int minutes = seconds ~/ 60;
  final int secs = seconds % 60;
  if (minutes > 0 && secs > 0) return '$minutes min $secs s';
  if (minutes > 0) return '$minutes min';
  return '$seconds s';
}

bool isDurationWorkout(Workout workout) => workout.isDurationBased;

String latestSummaryText(Workout workout, WorkoutLog? latest) {
  if (latest == null) return 'No progress yet';
  if (isDurationWorkout(workout)) {
    final dur = latest.longestDurationSeconds;
    final value = dur > 0 ? formatDurationShort(dur) : '${latest.setCount} Sets';
    return '${latest.day} • $value';
  }
  final value = latest.hasAnyDropsets
      ? 'Dropset'
      : '${latest.maxWeightKg.toStringAsFixed(1)} kg × ${latest.heaviestSetReps} reps';
  return '${latest.day} • $value';
}

String latestUpdateText(Workout workout, WorkoutLog? latest) {
  if (latest == null) return 'No progress yet';
  if (isDurationWorkout(workout)) {
    final dur = latest.longestDurationSeconds;
    final value = dur > 0 ? formatDurationShort(dur) : '${latest.setCount} Sets';
    return 'Update: $value';
  }
  final value = latest.hasAnyDropsets
      ? 'Dropset'
      : '${latest.maxWeightKg.toStringAsFixed(1)} kg × ${latest.heaviestSetReps} reps';
  return 'Update: $value';
}

class Workout {
  final String id;
  final String name;
  final String description;
  final IconData? icon;
  final String? iconPath;
  final List<String> muscles;
  final bool isDurationBased;

  const Workout({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.iconPath,
    this.muscles = const [],
    this.isDurationBased = false,
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
    );
  }
}

class WorkoutSet {
  final double weightKg;
  final int reps;
  final int? durationSeconds;
  final List<WorkoutSet> dropsets; // Dropsets gehören zu diesem Set

  const WorkoutSet({
    required this.weightKg,
    required this.reps,
    this.durationSeconds,
    this.dropsets = const [],
  });

  bool get hasDuration => (durationSeconds ?? 0) > 0;
  bool get hasDropsets => dropsets.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'weightKg': weightKg,
    'reps': reps,
    if (durationSeconds != null) 'durationSeconds': durationSeconds,
    if (dropsets.isNotEmpty) 'dropsets': dropsets.map((s) => s.toMap()).toList(),
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
    return sets.reduce((a, b) => a.weightKg >= b.weightKg ? a : b);
  }

  // Gibt das Gewicht des heaviest Sets zurück
  double get maxWeightKg => heaviestSet?.weightKg ?? 0.0;
  
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

/// Rückgabewert des Dialogs:
/// - log != null  -> tracken
/// - assignDay != null -> nur Plan-Zuweisung (ohne History)
class LogOutcome {
  final WorkoutLog? log;
  final String? assignDay;
  const LogOutcome({this.log, this.assignDay});
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
