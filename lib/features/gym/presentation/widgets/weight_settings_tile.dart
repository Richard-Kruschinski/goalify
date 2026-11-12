import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/gym_models.dart';
import 'options_menu_tile.dart';

/// "Weight settings" row of the exercise options bottom sheet.
///
/// Shared by the exercise list and the day detail screen so both menus stay in
/// sync; the subtitle reflects the bar weight currently stored for the exercise.
class WeightSettingsTile extends StatelessWidget {
  const WeightSettingsTile({
    required this.settings,
    required this.onTap,
    this.borderRadius,
    super.key,
  });

  final ExerciseWeightSettings settings;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;

  static String formatKg(double kg) =>
      kg % 1 == 0 ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return OptionsMenuTile(
      icon: Icons.straighten_rounded,
      title: l.weightSettings,
      subtitle: settings.hasBar
          ? l.barWeightCurrent(formatKg(settings.barWeightKg))
          : l.weightSettingsSubtitle,
      onTap: onTap,
      borderRadius: borderRadius,
    );
  }
}
