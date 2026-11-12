import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// "−  value  +" control. [label] formats the value (e.g. "1:30", "Off").
/// The buttons disable themselves at [min] and [max].
class ValueStepper extends StatelessWidget {
  const ValueStepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
    this.step = 1,
    this.decreaseTooltip,
    this.increaseTooltip,
    super.key,
  });

  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;
  final String Function(int value) label;
  final String? decreaseTooltip;
  final String? increaseTooltip;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          tooltip: decreaseTooltip,
          onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
          icon: const Icon(Icons.remove),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64),
          child: Text(
            label(value),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: AppColors.ink(context),
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: increaseTooltip,
          onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
