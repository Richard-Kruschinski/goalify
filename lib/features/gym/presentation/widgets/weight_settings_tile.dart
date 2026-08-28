import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gym_models.dart';

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
    final subtitle = settings.hasBar
        ? l.barWeightCurrent(formatKg(settings.barWeightKg))
        : l.weightSettingsSubtitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (AppColors.isDark(context)
                      ? const Color(0xFF13292B)
                      : const Color(0xFFE0F2F1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.straighten_rounded,
                  color: Color(0xFF00897B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.weightSettings,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.border(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
