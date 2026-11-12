import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/gym_models.dart';
import '../../../../core/utils/duration_format.dart';
import 'options_menu_tile.dart';

/// "Sets & rest" row of the exercise options bottom sheet; the subtitle shows
/// what is set, e.g. "3 sets · Rest 1:30".
class RestSettingsTile extends StatelessWidget {
  const RestSettingsTile({required this.settings, required this.onTap, super.key});

  final ExerciseRestSettings settings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sets = settings.targetSets;
    final rest = settings.targetRestSeconds;
    final parts = [
      if (sets != null) l.setsCount(sets),
      if (rest != null) l.restTargetValue(formatClockDuration(rest)),
    ];
    return OptionsMenuTile(
      icon: Icons.timer_outlined,
      title: l.restSettings,
      subtitle: parts.isEmpty ? l.restSettingsSubtitle : parts.join(' · '),
      onTap: onTap,
    );
  }
}
