import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/pomodoro_controller.dart';
import '../../models/pomodoro_stats.dart';

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PomodoroController(),
      child: const _PomodoroScreenContent(),
    );
  }
}

class _PomodoroScreenContent extends StatefulWidget {
  const _PomodoroScreenContent();

  @override
  State<_PomodoroScreenContent> createState() => _PomodoroScreenContentState();
}

class _PomodoroScreenContentState extends State<_PomodoroScreenContent> {
  @override
  void initState() {
    super.initState();
    // Show permission request dialog if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PomodoroController>();
      if (controller.isAppBlockingSupported) {
        _checkAndRequestAccessibilityPermission();
      } else {
        // Show iOS dialog
        _showIOSDialog(context);
      }
    });
  }

  Future<void> _checkAndRequestAccessibilityPermission() async {
    final controller = context.read<PomodoroController>();
    final isEnabled = await controller.platformService.isAccessibilityServiceEnabled();
    
    if (!isEnabled && mounted) {
      _showAccessibilityPermissionDialog();
    }
  }

  void _showAccessibilityPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.accessibility_new,
                  color: Color(0xFFFF6B6B),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Bedienungshilfen erforderlich',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                'Um ablenkende Apps während Ihrer Fokus-Sessions zu blockieren, benötigt Goalify Zugriff auf die Bedienungshilfen.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final controller = context.read<PomodoroController>();
                    await controller.platformService.openAccessibilitySettings();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Erlauben',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Später',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showIOSDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C9AFF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF4C9AFF),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'App Blocking Not Supported',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                'App blocking is not supported on iOS. You can still use the Pomodoro timer, but other apps won\'t be blocked during work sessions.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4C9AFF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pomodoro Timer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Consumer<PomodoroController>(
        builder: (context, controller, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Phase indicator
                _PhaseIndicator(controller: controller),
                const SizedBox(height: 24),
                
                // Timer display with circular progress
                _TimerDisplay(controller: controller),
                const SizedBox(height: 32),
                
                // Control buttons
                _ControlButtons(controller: controller),
                const SizedBox(height: 24),
                
                // Focus mode indicator
                if (controller.isAppBlockingActive)
                  _FocusModeIndicator(),
                const SizedBox(height: 24),
                
                // Statistics
                _StatisticsSection(stats: controller.stats),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PhaseIndicator extends StatelessWidget {
  final PomodoroController controller;

  const _PhaseIndicator({required this.controller});

  Color _getPhaseColor() {
    switch (controller.currentPhase) {
      case PomodoroPhase.work:
        return const Color(0xFFFF6B6B);
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        return const Color(0xFF51CF66);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.currentPhaseLabel,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getPhaseColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Cycle ${controller.currentCycle}/4',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getPhaseColor().withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              controller.currentPhase == PomodoroPhase.work
                  ? Icons.work_outline
                  : Icons.coffee_outlined,
              color: _getPhaseColor(),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerDisplay extends StatelessWidget {
  final PomodoroController controller;

  const _TimerDisplay({required this.controller});

  Color _getPhaseColor() {
    switch (controller.currentPhase) {
      case PomodoroPhase.work:
        return const Color(0xFFFF6B6B);
      case PomodoroPhase.shortBreak:
      case PomodoroPhase.longBreak:
        return const Color(0xFF51CF66);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress indicator
          SizedBox(
            width: 240,
            height: 240,
            child: CircularProgressIndicator(
              value: controller.progress,
              strokeWidth: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_getPhaseColor()),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Time display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                controller.formattedTime,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _getPhaseColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  controller.timerState == PomodoroTimerState.running
                      ? 'Running'
                      : controller.timerState == PomodoroTimerState.paused
                          ? 'Paused'
                          : 'Ready',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _getPhaseColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final PomodoroController controller;

  const _ControlButtons({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        _CircularButton(
          icon: Icons.refresh,
          onPressed: controller.reset,
          color: Colors.grey[700]!,
          size: 56,
        ),
        const SizedBox(width: 20),
        
        // Play/Pause button (larger)
        _CircularButton(
          icon: controller.timerState == PomodoroTimerState.running
              ? Icons.pause
              : Icons.play_arrow,
          onPressed: controller.timerState == PomodoroTimerState.running
              ? controller.pause
              : controller.start,
          color: controller.currentPhase == PomodoroPhase.work
              ? const Color(0xFFFF6B6B)
              : const Color(0xFF51CF66),
          size: 80,
          iconSize: 40,
        ),
        const SizedBox(width: 20),
        
        // Skip button
        _CircularButton(
          icon: Icons.skip_next,
          onPressed: controller.skipToNextPhase,
          color: Colors.grey[700]!,
          size: 56,
        ),
      ],
    );
  }
}

class _CircularButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;
  final double? iconSize;

  const _CircularButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.size = 60,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            color: Colors.white,
            size: iconSize ?? size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _FocusModeIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B6B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.block,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Focus Mode Active',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Other apps are blocked',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatelessWidget {
  final PomodoroStats stats;

  const _StatisticsSection({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Progress',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Daily Focus Score
        _DailyFocusScoreCard(score: stats.dailyFocusScore),
        const SizedBox(height: 12),
        
        // Stats grid
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline,
                label: 'Sessions',
                value: '${stats.completedSessionsToday}',
                color: const Color(0xFF51CF66),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.access_time,
                label: 'Focus Time',
                value: '${stats.totalFocusTimeToday}m',
                color: const Color(0xFF4C9AFF),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_today,
                label: 'This Week',
                value: '${stats.totalFocusTimeThisWeek}m',
                color: const Color(0xFFFF9F43),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.repeat,
                label: 'Cycles',
                value: '${stats.completedCycles}',
                color: const Color(0xFFE056FD),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DailyFocusScoreCard extends StatelessWidget {
  final int score;

  const _DailyFocusScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular score indicator
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getScoreColor(score),
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$score',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(score),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Focus Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreMessage(score),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF51CF66);
    if (score >= 50) return const Color(0xFF4C9AFF);
    if (score >= 20) return const Color(0xFFFF9F43);
    return const Color(0xFFFF6B6B);
  }

  String _getScoreMessage(int score) {
    if (score >= 80) return 'Excellent! Keep it up!';
    if (score >= 50) return 'Great progress today!';
    if (score >= 20) return 'Good start!';
    return 'Let\'s get focused!';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
