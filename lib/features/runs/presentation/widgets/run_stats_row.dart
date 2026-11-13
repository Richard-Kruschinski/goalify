import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/usecases/route_stats.dart';
import 'run_format.dart';

/// Distance, time and pace side by side. Used live and in the run detail.
class RunStatsRow extends StatelessWidget {
  const RunStatsRow({
    super.key,
    required this.distanceMeters,
    required this.movingTime,
  });

  final double distanceMeters;
  final Duration movingTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pace = RouteStats.paceSecondsPerKm(distanceMeters, movingTime);
    // Bottom-aligned, so the labels share one line under the taller middle value.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _Stat(
          value: formatClockDuration(movingTime.inSeconds),
          label: l10n.runTime,
        ),
        _Stat(value: formatPace(pace), label: l10n.runPacePerKm, large: true),
        _Stat(
          value: formatKilometers(context, distanceMeters),
          label: l10n.runUnitKm,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.large = false});

  final String value;
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: large ? 44 : 26,
              height: 1.1,
              fontWeight: FontWeight.bold,
              color: AppColors.ink(context),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(label, style: TextStyle(color: AppColors.muted(context))),
        ],
      ),
    );
  }
}
