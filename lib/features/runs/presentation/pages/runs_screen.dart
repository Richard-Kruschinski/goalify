import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/day_cycle.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/widgets/liquid_glass_segmented.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../functions/presentation/pages/functions_screen.dart';
import '../../data/models/run.dart';
import '../../domain/usecases/route_stats.dart';
import '../controllers/run_controller.dart';
import '../widgets/run_format.dart';
import 'run_detail_page.dart';
import 'run_tracking_page.dart';

class RunsScreen extends StatefulWidget {
  const RunsScreen({super.key});

  @override
  State<RunsScreen> createState() => _RunsScreenState();
}

class _RunsScreenState extends State<RunsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<RunController>().load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<RunController>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0,
        toolbarHeight: 80,
        title: Text(
          l10n.runsTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.ink(context),
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: AppColors.bg(context),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (controller.isTracking)
            _ActiveRunCard(controller: controller)
          else
            _StartSection(controller: controller),
          const SizedBox(height: 24),
          Text(
            l10n.runHistory,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink(context),
            ),
          ),
          const SizedBox(height: 12),
          if (controller.loaded && controller.runs.isEmpty)
            Text(
              l10n.runsEmpty,
              style: TextStyle(color: AppColors.muted(context)),
            ),
          for (final run in controller.runs) ...[
            _RunTile(run: run),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StartSection extends StatelessWidget {
  const _StartSection({required this.controller});

  final RunController controller;

  Future<void> _start(BuildContext context) async {
    final problem = await controller.start();
    if (!context.mounted) return;
    if (problem == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RunTrackingPage()),
      );
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSingleSnackBar(
      SnackBar(
        content: Text(switch (problem) {
          RunStartProblem.locationServiceOff => l10n.runLocationServiceOff,
          RunStartProblem.permissionDenied => l10n.runPermissionDenied,
          RunStartProblem.permissionDeniedForever => l10n.runPermissionDenied,
        }),
        action: problem == RunStartProblem.permissionDenied
            ? null
            : SnackBarAction(
                label: l10n.runOpenSettings,
                onPressed: () => controller.openSettingsFor(problem),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LiquidGlassSegmented<RunActivity>(
          selectedIconColor: AppColors.accent(context),
          selected: controller.activity,
          onChanged: controller.selectActivity,
          segments: [
            for (final activity in RunActivity.values)
              LiquidGlassSegment(
                value: activity,
                icon: runActivityIcon(activity),
                label: runActivityLabel(l10n, activity),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          onPressed: () => _start(context),
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.runStart),
        ),
      ],
    );
  }
}

class _ActiveRunCard extends StatelessWidget {
  const _ActiveRunCard({required this.controller});

  final RunController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = controller.state == RunTrackingState.paused
        ? l10n.runPaused
        : l10n.runActive;
    return FunctionCard(
      title: '$status · ${runActivityLabel(l10n, controller.activity)}',
      subtitle:
          '${formatKilometers(context, controller.distanceMeters)} ${l10n.runUnitKm}'
          ' · ${formatClockDuration(controller.movingTime.inSeconds)}',
      icon: runActivityIcon(controller.activity),
      isActive: true,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RunTrackingPage()),
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({required this.run});

  final Run run;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final meters = RouteStats.distanceMeters(run.segments);
    final pace = RouteStats.paceSecondsPerKm(meters, run.movingTime);
    final day = DateFormat.MMMEd(locale).format(DayCycle.dayOf(run.startedAt));
    final time = DateFormat.Hm(locale).format(run.startedAt);
    return FunctionCard(
      title:
          '${formatKilometers(context, meters)} ${l10n.runUnitKm}'
          ' · ${runActivityLabel(l10n, run.activity)}',
      subtitle:
          '$day, $time · ${formatClockDuration(run.movingTime.inSeconds)}'
          ' · ${formatPace(pace)} ${l10n.runPacePerKm}',
      icon: runActivityIcon(run.activity),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RunDetailPage(run: run)),
      ),
    );
  }
}
