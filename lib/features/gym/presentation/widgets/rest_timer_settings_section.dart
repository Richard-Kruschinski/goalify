import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/settings/settings_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/settings_tiles.dart';
import '../../../../core/widgets/value_stepper.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Global rest timer settings: on/off switch and "stop automatically"
/// minutes. Values live in [SettingsController]. Shown in the gym settings
/// screen (Gym → … → Gym settings).
class RestTimerSettingsSection extends StatelessWidget {
  const RestTimerSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();

    final card = AppColors.card(context);
    final ink = AppColors.ink(context);
    final muted = AppColors.muted(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSectionLabel(text: l10n.restSection, color: muted),
        const SizedBox(height: 8),
        SettingsCard(
          color: card,
          children: [
            SettingsSwitchTile(
              icon: Icons.timer_outlined,
              title: l10n.restTimerEnabledTitle,
              subtitle: l10n.restTimerEnabledDescription,
              value: settings.restTimerEnabled,
              ink: ink,
              muted: muted,
              onChanged: settings.setRestTimerEnabled,
            ),
            if (settings.restTimerEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.restAutoOffTitle,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: ink,
                        ),
                      ),
                    ),
                    ValueStepper(
                      value: settings.restAutoOffMinutes,
                      min: SettingsController.minRestAutoOffMinutes,
                      max: SettingsController.maxRestAutoOffMinutes,
                      label: (minutes) => '$minutes ${l10n.unitMin}',
                      decreaseTooltip: l10n.decrease,
                      increaseTooltip: l10n.increase,
                      onChanged: settings.setRestAutoOffMinutes,
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (settings.restTimerEnabled) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l10n.restAutoOffDescription,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
        ],
      ],
    );
  }
}
