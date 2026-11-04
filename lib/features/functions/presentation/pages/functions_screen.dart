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
                hue: _ToolHue.focus.of(context),
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
                hue: _ToolHue.blocker.of(context),
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
                hue: _ToolHue.music.of(context),
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
                hue: _ToolHue.interval.of(context),
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
  /// The tool's own toned hue for its tile and running state; null keeps the
  /// card neutral (settings).
  final Color? hue;
  final VoidCallback? onTap;
  final bool isActive;
  final bool isInteractive;

  const FunctionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.hue,
    this.onTap,
    this.isActive = false,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final tone = hue ?? AppColors.accent(context);
    final tileColor = hue != null
        ? hue!.withValues(alpha: dark ? 0.16 : 0.12)
        : AppColors.chip(context);

    return Material(
      color: AppColors.card(context),
      elevation: dark ? 0 : 1,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isActive
            ? BorderSide(color: tone.withValues(alpha: 0.5))
            : dark
                ? BorderSide(color: AppColors.border(context))
                : BorderSide.none,
      ),
      child: InkWell(
        onTap: isInteractive
            ? (onTap ?? () {
                ScaffoldMessenger.of(context).showSingleSnackBar(
                  SnackBar(content: Text(AppLocalizations.of(context).comingSoon)),
                );
              })
            : null,
        borderRadius: BorderRadius.circular(20),
        splashColor: isInteractive ? tone.withValues(alpha: 0.08) : Colors.transparent,
        highlightColor: isInteractive ? tone.withValues(alpha: 0.04) : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // The tool's tile: its own hue, solid while it runs.
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isActive ? tone : tileColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? (dark ? AppColors.darkBg : Colors.white)
                      : (hue ?? AppColors.inkSoft(context)),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isActive) ...[
                          // Live dot: the tool is running right now.
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tone,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: isActive ? tone : AppColors.muted(context),
                              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isInteractive)
                Icon(
                  Icons.chevron_right,
                  size: 24,
                  color: isActive ? tone : AppColors.faint(context),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Each tool keeps one toned hue so the list reads at a glance and every
/// tool is recognisable: tomato for Pomodoro, violet for the blocker, amber
/// for music, green for intervals. Settings stays neutral.
enum _ToolHue {
  focus(Color(0xFFE53935), Color(0xFFE5534B)),
  blocker(Color(0xFF6A4BC4), Color(0xFF9D86E3)),
  music(Color(0xFFB7791F), Color(0xFFD9A045)),
  interval(Color(0xFF2E7D4F), Color(0xFF5BB57A));

  const _ToolHue(this.light, this.dark);

  final Color light;
  final Color dark;

  Color of(BuildContext context) => AppColors.isDark(context) ? dark : light;
}
