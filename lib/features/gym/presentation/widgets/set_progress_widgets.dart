import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'animated_check.dart';

/// One check per planned set ("✓ ✓ ○"). Without a set target only the sets
/// tracked today get a check. Shared by the exercise list and day detail.
/// Checks that come in while the card is visible draw themselves in.
class SetProgressDots extends StatefulWidget {
  const SetProgressDots({required this.setsDone, this.targetSets, super.key});

  final int setsDone;
  final int? targetSets;

  @override
  State<SetProgressDots> createState() => _SetProgressDotsState();
}

class _SetProgressDotsState extends State<SetProgressDots> {
  /// Checks from this index on are new and animate; the ones already there
  /// when the card was built stay still.
  late int _firstNewCheck = widget.setsDone;

  @override
  void didUpdateWidget(SetProgressDots old) {
    super.didUpdateWidget(old);
    if (widget.setsDone > old.setsDone) _firstNewCheck = old.setsDone;
  }

  @override
  Widget build(BuildContext context) {
    final setsDone = widget.setsDone;
    final target = widget.targetSets;
    final slots = target == null || target <= 0 ? setsDone : target;
    if (slots == 0) return const SizedBox.shrink();

    return Semantics(
      label: target == null
          ? null
          : AppLocalizations.of(context).restSetsDone(setsDone.clamp(0, target), target),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Wrap(
          spacing: 3,
          children: [
            for (var i = 0; i < slots; i++)
              AnimatedCheck(
                key: ValueKey(i),
                checked: i < setsDone,
                animateIn: i >= _firstNewCheck,
                color: AppColors.success(context),
                emptyColor: AppColors.border(context),
              ),
          ],
        ),
      ),
    );
  }
}

/// Exercise name with a check next to it once all planned sets are done;
/// the check draws itself in when the last set is saved.
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
        // Always in the tree, so its state notices the switch to "complete".
        Padding(
          padding: EdgeInsets.only(left: complete ? 6 : 0),
          child: AnimatedCheck(
            checked: complete,
            size: 18,
            color: AppColors.success(context),
          ),
        ),
      ],
    );
  }
}
