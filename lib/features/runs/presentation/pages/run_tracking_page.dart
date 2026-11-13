import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../controllers/run_controller.dart';
import '../widgets/map_circle_button.dart';
import '../widgets/run_route_map.dart';
import '../widgets/run_stats_row.dart';

enum _FinishChoice { save, discard, resume }

/// Space the floating stats card takes at the bottom of the map, margin
/// included.
const _statsCardHeight = 170.0;

/// One round map button (48) plus the gap to the next one.
const _mapButtonSlot = 56.0;

final _buttonStyle = FilledButton.styleFrom(
  minimumSize: const Size.fromHeight(52),
);

/// Live view of the running session. Leaving it keeps the run recording.
class RunTrackingPage extends StatelessWidget {
  const RunTrackingPage({super.key});

  Future<void> _finish(BuildContext context, RunController controller) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showDialog<_FinishChoice>(
      context: context,
      builder: (dialogContext) {
        void close(_FinishChoice? choice) =>
            Navigator.pop(dialogContext, choice);
        // Nothing to save yet: offer to go on instead of a dead end.
        if (!controller.hasRoute) {
          return AlertDialog(
            title: Text(l10n.runNoRouteTitle),
            content: Text(l10n.runNoRoute),
            actions: [
              TextButton(
                onPressed: () => close(_FinishChoice.discard),
                child: Text(l10n.runDiscard),
              ),
              TextButton(
                onPressed: () => close(_FinishChoice.resume),
                child: Text(l10n.runResume),
              ),
            ],
          );
        }
        return AlertDialog(
          title: Text(l10n.runFinishTitle),
          actions: [
            TextButton(onPressed: () => close(null), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () => close(_FinishChoice.discard),
              child: Text(l10n.runDiscard),
            ),
            FilledButton(
              onPressed: () => close(_FinishChoice.save),
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
    switch (choice) {
      case null:
        return;
      case _FinishChoice.resume:
        controller.resume();
        return;
      case _FinishChoice.save:
        await controller.finish();
      case _FinishChoice.discard:
        await controller.discard();
    }
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<RunController>();
    final position = controller.currentPosition;
    final paused = controller.state == RunTrackingState.paused;
    // No app bar: the map reaches the top of the screen. Light status bar
    // icons, because the map underneath is dark.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg(context),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: position == null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 16),
                                Text(l10n.runSearchingGps),
                              ],
                            ),
                          )
                        : RunRouteMap(
                            segments: controller.segments,
                            currentPosition: position,
                            follow: true,
                            bottomInset: _statsCardHeight,
                            controlsTopInset: _mapButtonSlot,
                          ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16 + MediaQuery.paddingOf(context).top,
                    child: MapCircleButton(
                      tooltip: MaterialLocalizations.of(
                        context,
                      ).backButtonTooltip,
                      onPressed: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    top: 16 + MediaQuery.paddingOf(context).top,
                    child: MapCircleButton(
                      tooltip: l10n.settingsTitle,
                      // Placeholder until run settings exist.
                      onPressed: () =>
                          ScaffoldMessenger.of(context).showSingleSnackBar(
                            SnackBar(content: Text(l10n.comingSoon)),
                          ),
                      child: const Icon(Icons.settings),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _StatsCard(controller: controller),
                  ),
                ],
              ),
            ),
            Material(
              color: AppColors.card(context),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  // Running: pause is the only action. Finishing needs a pause
                  // first, so it cannot be hit by accident mid-run.
                  child: Row(
                    children: paused
                        ? [
                            Expanded(
                              child: FilledButton.icon(
                                style: _buttonStyle,
                                onPressed: controller.resume,
                                icon: const Icon(Icons.play_arrow),
                                label: Text(l10n.runResume),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.tonalIcon(
                                style: _buttonStyle,
                                onPressed: () => _finish(context, controller),
                                icon: const Icon(Icons.stop),
                                label: Text(l10n.runStop),
                              ),
                            ),
                          ]
                        : [
                            Expanded(
                              child: FilledButton.icon(
                                style: _buttonStyle,
                                onPressed: controller.pause,
                                icon: const Icon(Icons.pause),
                                label: Text(l10n.runPause),
                              ),
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floats over the map, apart from the buttons: a status strip on top,
/// the live numbers below.
class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.controller});

  final RunController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paused = controller.state == RunTrackingState.paused;
    return Material(
      color: AppColors.card(context),
      elevation: 6,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: paused
                ? AppColors.warning(context)
                : AppColors.accent(context),
            child: Text(
              paused ? l10n.runPaused : l10n.runActive,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: RunStatsRow(
              distanceMeters: controller.distanceMeters,
              movingTime: controller.movingTime,
            ),
          ),
        ],
      ),
    );
  }
}
