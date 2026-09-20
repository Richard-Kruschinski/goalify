import 'package:flutter/material.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../../pomodoro/presentation/pages/pomodoro_screen.dart';
import '../../pomodoro/presentation/controllers/pomodoro_controller.dart';
import '../../pomodoro/data/models/pomodoro_stats.dart';
import '../../distraction_blocker/presentation/pages/distraction_blocker_screen.dart';
import '../../distraction_blocker/presentation/controllers/distraction_blocker_controller.dart';
import '../../music_timer/presentation/pages/music_timer_screen.dart';
import '../../music_timer/presentation/controllers/music_timer_controller.dart';
import '../../interval_timer/presentation/pages/interval_timer_screen.dart';
import '../../interval_timer/presentation/controllers/interval_timer_controller.dart';
import '../../interval_timer/data/models/interval_timer_state.dart';
import '../../settings/presentation/pages/settings_screen.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';

class FunctionsScreen extends StatelessWidget {
  const FunctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0,
        toolbarHeight: 80,
        title: Text(
          l10n.functionsTitle,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Consumer<PomodoroController>(
            builder: (context, pomodoroController, _) {
              final isTimerRunning = pomodoroController.timerState == PomodoroTimerState.running;
              return FunctionCard(
                title: l10n.pomodoroTimer,
                subtitle: isTimerRunning
                    ? l10n.pomodoroCardRunning(pomodoroController.formattedTime)
                    : l10n.pomodoroCardSubtitle,
                icon: Icons.timer,
                iconBackgroundColor: (AppColors.isDark(context) ? const Color(0xFF331D1D) : const Color(0xFFFFE8E8)),
                isActive: isTimerRunning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PomodoroScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<DistractionBlockerController>(
            builder: (context, distractionBlocker, _) {
              final isActive = distractionBlocker.isActive;
              return FunctionCard(
                title: l10n.distractionBlockerTitle,
                subtitle: isActive
                    ? l10n.blockerCardActive(distractionBlocker.currentSessionDuration)
                    : l10n.blockerCardSubtitle,
                icon: Icons.block,
                iconBackgroundColor: (AppColors.isDark(context) ? const Color(0xFF2B2038) : const Color(0xFFE8D6F7)),
                isActive: isActive,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DistractionBlockerScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<MusicTimerController>(
            builder: (context, musicTimer, _) {
              final isRunning = musicTimer.isRunning;
              return FunctionCard(
                title: l10n.musicTimerTitle,
                subtitle: isRunning
                    ? l10n.musicTimerCardRunning(musicTimer.formattedTimeWithHours)
                    : l10n.musicTimerCardSubtitle,
                icon: Icons.music_note,
                iconBackgroundColor: (AppColors.isDark(context) ? const Color(0xFF322414) : const Color(0xFFFEE8D1)),
                isActive: isRunning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MusicTimerScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<IntervalTimerController>(
            builder: (context, intervalTimer, _) {
              final isRunning = intervalTimer.timerState == IntervalTimerState.running;
              return FunctionCard(
                title: l10n.intervalTimerTitle,
                subtitle: isRunning
                    ? l10n.intervalCardRunning(
                        intervalItemLabel(l10n, intervalTimer), intervalTimer.formattedTime)
                    : l10n.intervalCardSubtitle,
                icon: Icons.sports_martial_arts,
                iconBackgroundColor: (AppColors.isDark(context) ? const Color(0xFF16291F) : const Color(0xFFDDF4E7)),
                isActive: isRunning,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const IntervalTimerScreen(),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          FunctionCard(
            title: AppLocalizations.of(context).settingsTitle,
            subtitle: AppLocalizations.of(context).settingsSubtitle,
            icon: Icons.tune,
            iconBackgroundColor: (AppColors.isDark(context) ? const Color(0xFF232833) : const Color(0xFFE9EDF5)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class FunctionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackgroundColor;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isInteractive;

  const FunctionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    this.onTap,
    this.isActive = false,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(20),
      elevation: isActive ? 4 : 2,
      shadowColor: isActive 
          ? Colors.red.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: isInteractive
            ? (onTap ?? () {
                ScaffoldMessenger.of(context).showSingleSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
                );
              })
            : null,
        borderRadius: BorderRadius.circular(20),
        splashColor: isInteractive ? null : Colors.transparent,
        highlightColor: isInteractive ? null : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Row(
                children: [
                  // Leading Icon
                  Container(
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      icon,
                      color: AppColors.inkSoft(context),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink(context),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isActive
                                    ? const Color(0xFFFF6B6B)
                                    : AppColors.muted(context),
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Trailing Button
                  if (isInteractive)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFFF6B6B)
                              : AppColors.border(context),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: isActive
                            ? const Color(0xFFFF6B6B)
                            : AppColors.muted(context),
                      ),
                    ),
                ],
              ),
              // Active indicator badge
              if (isActive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}