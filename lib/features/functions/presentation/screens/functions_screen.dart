import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pomodoro/presentation/screens/pomodoro_screen.dart';
import '../../pomodoro/controllers/pomodoro_controller.dart';
import '../../pomodoro/models/pomodoro_stats.dart';
import '../../distraction_blocker/presentation/screens/distraction_blocker_screen.dart';
import '../../distraction_blocker/controllers/distraction_blocker_controller.dart';
import '../../music_timer/presentation/screens/music_timer_screen.dart';
import '../../music_timer/controllers/music_timer_controller.dart';
import '../../interval_timer/presentation/screens/interval_timer_screen.dart';
import '../../interval_timer/controllers/interval_timer_controller.dart';
import '../../interval_timer/models/interval_timer_state.dart';

class FunctionsScreen extends StatelessWidget {
  const FunctionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        title: const Text(
          'Functions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Consumer<PomodoroController>(
            builder: (context, pomodoroController, _) {
              final isTimerRunning = pomodoroController.timerState == PomodoroTimerState.running;
              return FunctionCard(
                title: 'Pomodoro Timer',
                subtitle: isTimerRunning 
                    ? 'Timer running: ${pomodoroController.formattedTime}'
                    : 'Work in focused intervals with breaks',
                icon: Icons.timer,
                iconBackgroundColor: const Color(0xFFFFE8E8),
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
                title: 'Distraction Blocker',
                subtitle: isActive
                    ? 'Active: ${distractionBlocker.currentSessionDuration}'
                    : 'Block distracting apps and stay focused',
                icon: Icons.block,
                iconBackgroundColor: const Color(0xFFE8D6F7),
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
                title: 'Music Timer',
                subtitle: isRunning
                    ? 'Timer: ${musicTimer.formattedTimeWithHours}'
                    : 'Play music with a countdown timer',
                icon: Icons.music_note,
                iconBackgroundColor: const Color(0xFFFEE8D1),
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
                title: 'Interval Timer',
                subtitle: isRunning
                    ? 'Running: ${intervalTimer.formattedTime} (Cycle ${intervalTimer.currentCycle}/${intervalTimer.totalCycles})'
                    : 'Task -> Break -> Task -> Break (for kickboxing and rounds)',
                icon: Icons.sports_martial_arts,
                iconBackgroundColor: const Color(0xFFDDF4E7),
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
          const FunctionCard(
            title: 'Options',
            subtitle: 'Coming soon',
            icon: Icons.tune,
            iconBackgroundColor: Color(0xFFE9EDF5),
            isInteractive: false,
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: isActive ? 4 : 2,
      shadowColor: isActive 
          ? Colors.red.withValues(alpha: 0.2)
          : Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: isInteractive
            ? (onTap ?? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming Soon')),
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
                      color: Colors.grey[800],
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
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[600],
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
                          color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: isActive ? const Color(0xFFFF6B6B) : Colors.grey[600],
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
