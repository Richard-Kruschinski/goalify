import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/interval_timer_controller.dart';
import '../../models/interval_timer_state.dart';

class IntervalTimerScreen extends StatelessWidget {
  const IntervalTimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _IntervalTimerScreenContent();
  }
}

class _IntervalTimerScreenContent extends StatefulWidget {
  const _IntervalTimerScreenContent();

  @override
  State<_IntervalTimerScreenContent> createState() => _IntervalTimerScreenContentState();
}

class _IntervalTimerScreenContentState extends State<_IntervalTimerScreenContent> {
  late TextEditingController _workDurationController;
  late TextEditingController _breakDurationController;
  late TextEditingController _cyclesController;

  @override
  void initState() {
    super.initState();
    final controller = context.read<IntervalTimerController>();
    _workDurationController = TextEditingController(text: (controller.workDuration ~/ 60).toString());
    _breakDurationController = TextEditingController(text: (controller.breakDuration ~/ 60).toString());
    _cyclesController = TextEditingController(text: controller.totalCycles.toString());
  }

  @override
  void dispose() {
    _workDurationController.dispose();
    _breakDurationController.dispose();
    _cyclesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Interval Timer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: Consumer<IntervalTimerController>(
        builder: (context, controller, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timer Display
                  Center(
                    child: Column(
                      children: [
                        // Phase label
                        Text(
                          controller.currentPhaseLabel,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Large timer
                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.currentPhase == IntervalTimerPhase.work
                                ? const Color(0xFFDDF4E7)
                                : const Color(0xFFFFE8E8),
                          ),
                          child: Stack(
                            children: [
                              // Progress circle
                              CircularProgressIndicator(
                                value: controller.progress,
                                strokeWidth: 8,
                                valueColor: AlwaysStoppedAnimation(
                                  controller.currentPhase == IntervalTimerPhase.work
                                      ? Colors.green[600]
                                      : Colors.red[600],
                                ),
                              ),
                              // Timer text
                              Center(
                                child: Text(
                                  controller.formattedTime,
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Cycle indicator
                        Text(
                          'Cycle ${controller.currentCycle} / ${controller.totalCycles}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (controller.timerState == IntervalTimerState.idle)
                        ElevatedButton.icon(
                          onPressed: controller.start,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        )
                      else if (controller.timerState == IntervalTimerState.running)
                        ElevatedButton.icon(
                          onPressed: controller.pause,
                          icon: const Icon(Icons.pause),
                          label: const Text('Pause'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                        )
                      else if (controller.timerState == IntervalTimerState.paused)
                        ElevatedButton.icon(
                          onPressed: controller.resume,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Resume'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: controller.reset,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  
                  // Settings
                  if (controller.timerState == IntervalTimerState.idle)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Work Duration
                        TextField(
                          controller: _workDurationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Work Duration (minutes)',
                            hintText: '1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.work_outline),
                          ),
                          onChanged: (value) {
                            final minutes = int.tryParse(value) ?? 1;
                            controller.setWorkDuration(minutes * 60);
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Break Duration
                        TextField(
                          controller: _breakDurationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Break Duration (minutes)',
                            hintText: '1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.free_breakfast_outlined),
                          ),
                          onChanged: (value) {
                            final minutes = int.tryParse(value) ?? 1;
                            controller.setBreakDuration(minutes * 60);
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Total Cycles
                        TextField(
                          controller: _cyclesController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Number of Cycles',
                            hintText: '4',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.repeat),
                          ),
                          onChanged: (value) {
                            final cycles = int.tryParse(value) ?? 4;
                            controller.setTotalCycles(cycles);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
