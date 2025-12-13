import 'package:flutter/material.dart';

class DeadlineBanner extends StatelessWidget {
  final DateTime deadline;
  const DeadlineBanner({super.key, required this.deadline});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final diff = deadline.difference(now);
    final expired = diff.isNegative;
    final text = expired
        ? 'Deadline überschritten'
        : 'Deadline in ${diff.inDays} Tagen, ${diff.inHours % 24} Std';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: expired ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
      child: Text(text, style: TextStyle(color: expired ? Colors.red : Colors.green[800])),
    );
  }
}
