import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/utils/duration_format.dart';
import '../controllers/rest_timer_controller.dart';
import 'rest_clock_icon.dart';

/// Bottom bar with the running rest: "1:23 / 1:30" (green once the target rest
/// is reached), what comes next and a stop button. Hidden while no rest runs.
/// Tapping it opens the exercise to track the next set.
class RestTimerBar extends StatelessWidget {
  const RestTimerBar({this.onOpenExercise, super.key});

  final void Function(String workoutId)? onOpenExercise;

  /// Without a target rest the clock turns like a second hand.
  static const _secondsPerTurnWithoutTarget = 60;

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<RestTimerController>();
    final session = timer.session;
    if (session == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final target = session.targetRestSeconds;
    final timeColor =
        timer.targetReached ? AppColors.success(context) : AppColors.ink(context);
    final open = onOpenExercise;

    return SafeArea(
      top: false,
      child: Material(
        color: AppColors.card(context),
        elevation: 8,
        child: InkWell(
          onTap: open == null ? null : () => open(session.workoutId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 10),
            child: Row(
              children: [
                RestClockIcon(
                  elapsed: () => timer.elapsed,
                  revolution: Duration(seconds: target ?? _secondsPerTurnWithoutTarget),
                  color: timeColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatClockDuration(timer.elapsed.inSeconds),
                              style: TextStyle(color: timeColor),
                            ),
                            if (target != null)
                              TextSpan(
                                text: ' / ${formatClockDuration(target)}',
                                style: TextStyle(color: AppColors.muted(context)),
                              ),
                          ],
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        describeRest(session, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l10n.restStopTimer,
                  onPressed: timer.stop,
                  icon: Icon(Icons.stop_circle_outlined, color: AppColors.accent(context)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
