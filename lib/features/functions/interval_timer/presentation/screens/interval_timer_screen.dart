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

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showTaskActions(
    BuildContext context,
    IntervalTimerController controller,
    int taskIndex,
  ) {
    if (taskIndex < 0 || taskIndex >= controller.tasks.length) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFFFF6B6B)),
              title: const Text('Edit Task'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditTaskDialog(context, controller, taskIndex);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Delete Task'),
              onTap: () {
                controller.removeTask(taskIndex);
                Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    IntervalTimerController controller,
    int taskIndex,
  ) {
    if (taskIndex < 0 || taskIndex >= controller.tasks.length) return;

    final task = controller.tasks[taskIndex];
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController(text: task.name);
    final durationController = TextEditingController(
      text: (task.durationSeconds / 60).toString(),
    );
    final pauseController = TextEditingController(
      text: taskIndex == 0
          ? '0'
          : (task.pauseBeforeSeconds / 60).toString(),
    );

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: Color(0xFFFF6B6B),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Task',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Task',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Duration (minutes)',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                    ),
                    helperText: 'Decimals allowed, e.g. 0.5 = 30 seconds.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pauseController,
                  enabled: taskIndex != 0,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Pause before task (minutes)',
                    helperText: taskIndex == 0
                        ? 'Always 0 for the first task.'
                        : 'Decimals allowed, e.g. 0.5 = 30 seconds.',
                    filled: true,
                    fillColor: const Color(0xFFF5F6FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6B6B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: () {
                        final newName = nameController.text.trim();
                        final durationText = durationController.text.trim().replaceAll(',', '.');
                        final durationMinutes = double.tryParse(durationText) ?? 0;
                        final newDurationSeconds = (durationMinutes * 60).round();
                        final pauseText = pauseController.text.trim().replaceAll(',', '.');
                        final pauseMinutes = double.tryParse(pauseText) ?? 0;
                        final pauseSeconds = (pauseMinutes * 60).round();

                        if (newName.isEmpty || newDurationSeconds <= 0) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Please enter valid values.')),
                          );
                          return;
                        }

                        controller.updateTask(
                          index: taskIndex,
                          name: newName,
                          durationSeconds: newDurationSeconds,
                          pauseBeforeSeconds: taskIndex == 0 ? 0 : pauseSeconds,
                        );
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProfileSelector(BuildContext context) {
    final controller = context.read<IntervalTimerController>();
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50)),
              title: const Text('Save Profile'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateProfileDialog(context);
              },
            ),
            const Divider(height: 1),
            if (controller.customProfiles.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No saved profiles yet.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...controller.customProfiles.map(
                (profile) => ListTile(
                  leading: Icon(
                    controller.selectedProfileId == profile.id
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: controller.selectedProfileId == profile.id
                        ? const Color(0xFF4CAF50)
                        : Colors.grey,
                  ),
                  title: Text(profile.name),
                  subtitle: Text('${profile.tasks.length} Tasks'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      await controller.deleteCustomProfile(profile.id);
                      if (sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Profile deleted.')),
                      );
                    },
                  ),
                  onTap: () async {
                    await controller.applyCustomProfile(profile.id);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text('Profile "${profile.name}" loaded.')),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    final nameController = TextEditingController();
    final controller = context.read<IntervalTimerController>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bookmark_add_outlined,
                      color: Color(0xFFFF6B6B),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Save Profile',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Profile name',
                  hintText: 'e.g. Kickboxing 12 Rounds',
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFFF6B6B),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () async {
                      if (!controller.hasTasks) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Create at least one task first.')),
                        );
                        return;
                      }

                      final profileName = nameController.text.trim();
                      if (profileName.isEmpty) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Please enter a profile name.')),
                        );
                        return;
                      }

                      await controller.createCustomProfile(profileName);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      messenger.showSnackBar(
                        SnackBar(content: Text('Profile "$profileName" saved.')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _taskNameController = TextEditingController();
    _taskDurationController = TextEditingController();
    _pauseBeforeController = TextEditingController();
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
    final durationText = _taskDurationController.text.trim().replaceAll(',', '.');
    final durationMinutes = double.tryParse(durationText) ?? 0;
    final durationSeconds = (durationMinutes * 60).round();
    final pauseText = _pauseBeforeController.text.trim().replaceAll(',', '.');
    final pauseMinutes = double.tryParse(pauseText) ?? 0;
    final pauseSeconds = (pauseMinutes * 60).round();

    if (name.isEmpty || durationSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid task and duration in minutes.')),
      );
      return;
    }

    controller.addTask(
      name: name,
      durationSeconds: durationSeconds,
      pauseBeforeSeconds: pauseSeconds,
    );

    _taskNameController.clear();
    _taskDurationController.clear();
    _pauseBeforeController.clear();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () => _showProfileSelector(context),
          ),
        ],
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
                          'Create Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'First task: name + duration. For additional tasks, also set the pause before it.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _taskNameController,
                          decoration: InputDecoration(
                            labelText: 'Task',
                            hintText: 'e.g. Jump rope',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.task_alt),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _taskDurationController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Duration (minutes)',
                            hintText: 'e.g. 0.5',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.timer_outlined),
                            helperText: 'Decimals allowed (e.g. 0.5 = 30 seconds).',
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _pauseBeforeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Pause before this task (minutes)',
                            hintText: 'e.g. 0.5',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.free_breakfast_outlined),
                            helperText: controller.tasks.isEmpty
                                ? 'Pause is ignored for the first task.'
                                : 'Decimals allowed (e.g. 0.5 = 30 seconds).',
                          ),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _addTask(controller),
                            icon: const Icon(Icons.add),
                            label: const Text('Add task'),
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
                              'Tasks in profile',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: controller.tasks.isEmpty ? null : controller.clearProfile,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear profile'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        if (controller.tasks.isEmpty)
                          const Text(
                            'No tasks added yet.',
                            style: TextStyle(color: Colors.grey),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.tasks.length,
                            buildDefaultDragHandles: false,
                            onReorder: controller.reorderTasks,
                            itemBuilder: (context, index) {
                              final task = controller.tasks[index];
                              return Card(
                                key: ValueKey('${task.name}_${task.durationSeconds}_${task.pauseBeforeSeconds}_$index'),
                                color: Colors.white,
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  onLongPress: () => _showTaskActions(context, controller, index),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFDDF4E7),
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(task.name),
                                  subtitle: Text(
                                    index == 0
                                        ? 'Duration: ${_formatSeconds(task.durationSeconds)}'
                                        : 'Pause before: ${_formatSeconds(task.pauseBeforeSeconds)} • Duration: ${_formatSeconds(task.durationSeconds)}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () => controller.removeTask(index),
                                      ),
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 4),
                                          child: Icon(Icons.drag_handle, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sequence',
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
                                  ? '${index + 1}. ${task.name} (${_formatSeconds(task.durationSeconds)})'
                                  : '${index + 1}. Pause ${_formatSeconds(task.pauseBeforeSeconds)} → ${task.name} (${_formatSeconds(task.durationSeconds)})',
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
