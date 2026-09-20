/// Repeat pattern for recurring tasks
enum TaskRepeatPattern {
  daily,
  every_2_days,
  every_3_days,
  weekly_days,
  every_7_days,
  biweekly,
  monthly,
  custom;

  String get label {
    switch (this) {
      case TaskRepeatPattern.daily:
        return 'Daily';
      case TaskRepeatPattern.every_2_days:
        return 'Every 2 days';
      case TaskRepeatPattern.every_3_days:
        return 'Every 3 days';
      case TaskRepeatPattern.weekly_days:
        return 'Weekly';
      case TaskRepeatPattern.every_7_days:
        return 'Every 7 days';
      case TaskRepeatPattern.biweekly:
        return 'Biweekly';
      case TaskRepeatPattern.monthly:
        return 'Monthly';
      case TaskRepeatPattern.custom:
        return 'Custom days...';
    }
  }

  int get intervalDays {
    switch (this) {
      case TaskRepeatPattern.daily:
        return 1;
      case TaskRepeatPattern.every_2_days:
        return 2;
      case TaskRepeatPattern.every_3_days:
        return 3;
      case TaskRepeatPattern.weekly_days:
        return 7;
      case TaskRepeatPattern.every_7_days:
        return 7;
      case TaskRepeatPattern.biweekly:
        return 14;
      case TaskRepeatPattern.monthly:
        return 30;
      case TaskRepeatPattern.custom:
        return 1; // fallback, use customDays instead
    }
  }

  static TaskRepeatPattern fromString(String? str) {
    if (str == null) return TaskRepeatPattern.daily;
    try {
      return TaskRepeatPattern.values.firstWhere((e) => e.name == str);
    } catch (_) {
      return TaskRepeatPattern.daily;
    }
  }

  String toStorageString() => name;
}
