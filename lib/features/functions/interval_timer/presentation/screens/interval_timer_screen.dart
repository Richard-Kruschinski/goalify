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
  late TextEditingController _taskNameController;
  late TextEditingController _taskDurationController;
  late TextEditingController _pauseBeforeController;

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController();
    _taskDurationController = TextEditingController(text: '1');
    _pauseBeforeController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _taskNameController.dispose();
    _taskDurationController.dispose();
    _pauseBeforeController.dispose();
    super.dispose();
  }

  void _addTask(IntervalTimerController controller) {
    final name = _taskNameController.text.trim();
    final durationMinutes = int.tryParse(_taskDurationController.text.trim()) ?? 0;
    final pauseMinutes = int.tryParse(_pauseBeforeController.text.trim()) ?? 0;

    if (name.isEmpty || durationMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte Aufgabe und Dauer korrekt eingeben.')),
      );
      return;
    }

    controller.addTask(
      name: name,
      durationSeconds: durationMinutes * 60,
      pauseBeforeSeconds: pauseMinutes * 60,
    );

    _taskNameController.clear();
    _taskDurationController.text = '1';
    _pauseBeforeController.text = '0';
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
                  Center(
                    child: Column(
                      children: [
                        Text(
                          controller.currentPhaseLabel,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.currentItemLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: controller.currentPhase == IntervalTimerPhase.task
                                ? const Color(0xFFDDF4E7)
                                : const Color(0xFFFFE8E8),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 220,
                                height: 220,
                                child: CircularProgressIndicator(
                                  value: controller.progress,
                                  strokeWidth: 8,
                                  valueColor: AlwaysStoppedAnimation(
                                    controller.currentPhase == IntervalTimerPhase.task
                                        ? Colors.green[600]
                                        : Colors.red[600],
                                  ),
                                ),
                              ),
                              Center(
                                child: Text(
                                  controller.formattedTime,
                                  style: const TextStyle(
                                    fontSize: 52,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Task ${controller.currentTaskNumber} / ${controller.totalTasks}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

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

                  if (controller.timerState == IntervalTimerState.idle)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Profil erstellen',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Erste Aufgabe: Name + Dauer. Bei weiteren Aufgaben zusätzlich Pause davor eintragen.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _taskNameController,
                          decoration: InputDecoration(
                            labelText: 'Aufgabe',
                            hintText: 'z. B. Seilspringen',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.task_alt),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _taskDurationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Dauer (Minuten)',
                            hintText: '1',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.timer_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _pauseBeforeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Pause vor dieser Aufgabe (Minuten)',
                            hintText: '0',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.free_breakfast_outlined),
                            helperText: controller.tasks.isEmpty
                                ? 'Bei der ersten Aufgabe wird die Pause ignoriert.'
                                : 'Wird als Pause zwischen der letzten und dieser Aufgabe genutzt.',
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _addTask(controller),
                            icon: const Icon(Icons.add),
                            label: const Text('Task hinzufügen'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tasks im Profil',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.tasks.isEmpty ? null : controller.clearProfile,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Profil leeren'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (controller.tasks.isEmpty)
                          const Text(
                            'Noch keine Aufgaben hinzugefügt.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          Column(
                            children: List.generate(controller.tasks.length, (index) {
                              final task = controller.tasks[index];
                              return Card(
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFDDF4E7),
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(task.name),
                                  subtitle: Text(
                                    index == 0
                                        ? 'Dauer: ${task.durationSeconds ~/ 60} Min'
                                        : 'Pause davor: ${task.pauseBeforeSeconds ~/ 60} Min • Dauer: ${task.durationSeconds ~/ 60} Min',
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => controller.removeTask(index),
                                  ),
                                ),
                              );
                            }),
                          ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ablauf',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(controller.tasks.length, (index) {
                          final task = controller.tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              index == 0
                                  ? '${index + 1}. ${task.name} (${task.durationSeconds ~/ 60} Min)'
                                  : '${index + 1}. Pause ${task.pauseBeforeSeconds ~/ 60} Min → ${task.name} (${task.durationSeconds ~/ 60} Min)',
                              style: const TextStyle(color: Colors.black87),
                            ),
                          );
                        }),
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
