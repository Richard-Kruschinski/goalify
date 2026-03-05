import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pomodoro/presentation/screens/pomodoro_screen.dart';
import '../../pomodoro/controllers/pomodoro_controller.dart';
import '../../pomodoro/models/pomodoro_stats.dart';

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
          const FunctionCard(
            title: 'Distraction Blocker',
            subtitle: 'Block distracting apps and stay focused',
            icon: Icons.block,
            iconBackgroundColor: Color(0xFFE8D6F7),
          ),
          const SizedBox(height: 16),
          const FunctionCard(
            title: 'Music Timer',
            subtitle: 'Play music with a countdown timer',
            icon: Icons.music_note,
            iconBackgroundColor: Color(0xFFFEE8D1),
          ),
          const SizedBox(height: 16),
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
          const FunctionCard(
            title: 'Deep Work Mode',
            subtitle: 'Eliminate distractions and enter flow state',
            icon: Icons.psychology,
            iconBackgroundColor: Color(0xFFD6E8FF),
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

  const FunctionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    this.onTap,
    this.isActive = false,
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
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming Soon')),
          );
        },
        borderRadius: BorderRadius.circular(20),
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
