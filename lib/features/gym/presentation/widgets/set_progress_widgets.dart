import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// One check per planned set ("✓ ✓ ○"). Without a set target only the sets
/// tracked today get a check. Shared by the exercise list and day detail.
class SetProgressDots extends StatelessWidget {
  const SetProgressDots({required this.setsDone, this.targetSets, super.key});

  final int setsDone;
  final int? targetSets;

  @override
  Widget build(BuildContext context) {
    final target = targetSets;
    final slots = target == null || target <= 0 ? setsDone : target;
    if (slots == 0) return const SizedBox.shrink();

    final done = AppColors.success(context);
    final open = AppColors.border(context);
    return Semantics(
      label: target == null
          ? null
          : AppLocalizations.of(context).restSetsDone(setsDone.clamp(0, target), target),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 2,
          children: [
            for (var i = 0; i < slots; i++)
              Icon(
                i < setsDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                size: 14,
                color: i < setsDone ? done : open,
              ),
          ],
        ),
      ),
    );
  }
}

/// Exercise name with a check next to it once all planned sets are done.
class ExerciseCardTitle extends StatelessWidget {
  const ExerciseCardTitle({required this.name, required this.complete, super.key});

  final String name;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ink(context),
            ),
          ),
        ),
        if (complete) ...[
          const SizedBox(width: 6),
          Icon(Icons.check_circle_rounded, size: 18, color: AppColors.success(context)),
        ],
      ],
    );
  }
}
