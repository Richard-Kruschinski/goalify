import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/rest_timer_settings_section.dart';

/// Gym settings, opened from the … menu on the gym screen.
class GymSettingsScreen extends StatelessWidget {
  const GymSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final card = AppColors.card(context);
    final ink = AppColors.ink(context);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: IconThemeData(color: ink),
        title: Text(
          l10n.gymSettingsTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: const [
          RestTimerSettingsSection(),
        ],
      ),
    );
  }
}
