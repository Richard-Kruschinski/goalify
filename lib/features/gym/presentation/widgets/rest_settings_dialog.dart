import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/value_stepper.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/gym_models.dart';
import '../../../../core/utils/duration_format.dart';

/// Dialog for the planned sets and the target rest of one exercise.
/// 0 in either stepper means "off" and is stored as null.
class RestSettingsDialog extends StatefulWidget {
  const RestSettingsDialog({required this.workoutName, required this.initial, super.key});

  final String workoutName;
  final ExerciseRestSettings initial;

  static const maxSets = 20;
  static const restStepSeconds = 15;
  static const maxRestSeconds = 600;

  /// Returns the new settings, or null when cancelled.
  static Future<ExerciseRestSettings?> show(
    BuildContext context, {
    required String workoutName,
    required ExerciseRestSettings initial,
  }) =>
      showDialog<ExerciseRestSettings>(
        context: context,
        builder: (_) => RestSettingsDialog(workoutName: workoutName, initial: initial),
      );

  @override
  State<RestSettingsDialog> createState() => _RestSettingsDialogState();
}

class _RestSettingsDialogState extends State<RestSettingsDialog> {
  late int _sets = widget.initial.targetSets ?? 0;
  late int _restSeconds = widget.initial.targetRestSeconds ?? 0;

  ExerciseRestSettings get _result => ExerciseRestSettings(
        targetSets: _sets > 0 ? _sets : null,
        targetRestSeconds: _restSeconds > 0 ? _restSeconds : null,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String offOr(int value, String Function(int) format) =>
        value == 0 ? l10n.restOff : format(value);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.restSettingsFor(widget.workoutName),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink(context),
              ),
            ),
            const SizedBox(height: 16),
            _SettingRow(
              label: l10n.restTargetSets,
              stepper: ValueStepper(
                value: _sets,
                min: 0,
                max: RestSettingsDialog.maxSets,
                label: (v) => offOr(v, (v) => '$v'),
                decreaseTooltip: l10n.decrease,
                increaseTooltip: l10n.increase,
                onChanged: (v) => setState(() => _sets = v),
              ),
            ),
            const SizedBox(height: 8),
            _SettingRow(
              label: l10n.restTargetRest,
              stepper: ValueStepper(
                value: _restSeconds,
                min: 0,
                max: RestSettingsDialog.maxRestSeconds,
                step: RestSettingsDialog.restStepSeconds,
                label: (v) => offOr(v, formatClockDuration),
                decreaseTooltip: l10n.decrease,
                increaseTooltip: l10n.increase,
                onChanged: (v) => setState(() => _restSeconds = v),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.restSettingsExplain,
              style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _result),
                  child: Text(l10n.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.label, required this.stepper});

  final String label;
  final Widget stepper;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 15, color: AppColors.ink(context)),
          ),
        ),
        stepper,
      ],
    );
  }
}
