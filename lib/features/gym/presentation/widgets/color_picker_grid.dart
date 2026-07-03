import 'package:flutter/material.dart';

/// ===============================================================
/// Color Picker Grid Widget
/// ===============================================================
class ColorPickerGrid extends StatelessWidget {
  final Function(Color) onColorSelected;

  const ColorPickerGrid({
    super.key,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    const List<MaterialColor> colorOptions = <MaterialColor>[
      Colors.blue,
      Colors.lightBlue,
      Colors.indigo,
      Colors.deepPurple,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.deepOrange,
      Colors.orange,
      Colors.amber,
      Colors.lime,
      Colors.lightGreen,
      Colors.green,
      Colors.teal,
      Colors.cyan,
      Colors.blueGrey,
      Colors.brown,
      Colors.grey,
    ];

    return SizedBox(
      width: double.maxFinite,
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        alignment: WrapAlignment.center,
        children: colorOptions.map((colorOption) {
          final color = colorOption.shade400;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onColorSelected(color),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

