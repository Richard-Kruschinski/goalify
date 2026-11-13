import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/day_cycle.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/run.dart';
import '../../domain/usecases/route_stats.dart';
import '../controllers/run_controller.dart';
import '../widgets/run_format.dart';
import '../widgets/run_route_map.dart';
import '../widgets/run_stats_row.dart';

class RunDetailPage extends StatelessWidget {
  const RunDetailPage({super.key, required this.run});

  final Run run;

  Future<void> _delete(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.runDeleteTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<RunController>().deleteRun(run.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final day = DateFormat.yMMMEd(locale).format(DayCycle.dayOf(run.startedAt));
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        title: Text('${runActivityLabel(l10n, run.activity)} · $day'),
        actions: [
          IconButton(
            tooltip: l10n.delete,
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: RunRouteMap(segments: run.segments)),
          Material(
            color: AppColors.card(context),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: RunStatsRow(
                  distanceMeters: RouteStats.distanceMeters(run.segments),
                  movingTime: run.movingTime,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
