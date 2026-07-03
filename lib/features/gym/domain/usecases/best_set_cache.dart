import '../../data/models/gym_models.dart';

/// Manager für Best-Set-Caching pro Übung
class BestSetCache {
  final Map<String, BestSetRecord> _cache = {};

  /// Berechnet den Score eines Satzes nach Priorität:
  /// 1. Höchstes Gewicht über alle Logs
  /// 2. Bei gleich hohem Gewicht: höchste Reps
  /// 3. Bei gleich hohem Gewicht+Reps: frühestes Datum gewinnt
  static double _calculateScore(WorkoutLog log) {
    // Score = weight * 10000 + reps * 100 - (days_since_epoch / 100000)
    // So dass höheres Gewicht und Reps gewinnen, aber bei Gleichheit das frühere Datum
    final daysSinceEpoch = log.dateTime.difference(DateTime(1970)).inDays;
    return (log.maxWeightKg * 10000) + (log.heaviestSetReps * 100) - (daysSinceEpoch / 100000);
  }

  /// Findet den besten Satz aus einer Liste von Logs
  BestSetRecord? findBest(List<WorkoutLog> logs) {
    if (logs.isEmpty) return null;

    // Sortiere nach Score (höher = besser)
    final sorted = [...logs]..sort(
      (a, b) => _calculateScore(b).compareTo(_calculateScore(a)),
    );

    final bestLog = sorted.first;
    return BestSetRecord(
      dateTime: bestLog.dateTime,
      maxWeight: bestLog.maxWeightKg,
      maxReps: bestLog.heaviestSetReps,
      setCount: bestLog.setCount,
      score: _calculateScore(bestLog),
    );
  }

  /// Aktualisiert den Cache für eine Übung
  void updateBest(String workoutId, BestSetRecord? best) {
    if (best != null) {
      _cache[workoutId] = best;
    } else {
      _cache.remove(workoutId);
    }
  }

  /// Holt den aktuellen Best-Set aus dem Cache
  BestSetRecord? getBest(String workoutId) {
    return _cache[workoutId];
  }

  /// Lädt den Cache aus Daten
  void loadFromMap(Map<String, dynamic> data) {
    _cache.clear();
    data.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        _cache[key] = BestSetRecord.fromMap(value);
      }
    });
  }

  /// Speichert den Cache als Map
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    _cache.forEach((key, value) {
      result[key] = value.toMap();
    });
    return result;
  }

  /// Leert den Cache
  void clear() {
    _cache.clear();
  }
}

/// ===============================================================
/// Modern Confirmation Dialog Helper
/// ===============================================================
