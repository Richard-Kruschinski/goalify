import 'package:flutter/material.dart';

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
    const labels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];

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
              color: selected ? const Color(0xFFE53935) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Text(
              labels[index],
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF6F7789),
              ),
            ),
          ),
        );
      }),
    );
  }
}

