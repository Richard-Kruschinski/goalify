import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../i18n/task_labels.dart';

class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toString();
    final labels = [
      for (int d = 1; d <= 7; d++) localizedWeekdayShort(d, localeName),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final day = index + 1;
        final selected = selectedDays.contains(day);

        return GestureDetector(
          onTap: () {
            final next = Set<int>.from(selectedDays);
            if (selected) {
              next.remove(day);
            } else {
              next.add(day);
            }
            onChanged(next);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.accent(context) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.accent(context) : AppColors.border(context),
                width: 1.5,
              ),
            ),
            child: Text(
              labels[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.muted(context),
              ),
            ),
          ),
        );
      }),
    );
  }
}

