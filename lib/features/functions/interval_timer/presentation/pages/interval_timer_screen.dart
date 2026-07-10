import 'package:flutter/material.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import '../controllers/interval_timer_controller.dart';
import '../../data/models/interval_timer_state.dart';

/// Localized version of IntervalTimerController.currentItemLabel.
/// The controller keeps a context-free English/German fallback for native
/// notifications; the UI uses this to render the label in the app language.
String intervalItemLabel(AppLocalizations l10n, IntervalTimerController c) {
  if (!c.hasTasks) return l10n.noProfileCreated;
  if (c.isInPause) return l10n.pauseBefore(c.pendingTaskName ?? '');
  return c.currentTaskName ?? '';
}

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

class _IntervalTimerScreenContentState extends State<_IntervalTimerScreenContent> with WidgetsBindingObserver {
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
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Color(0xFFFF6B6B)),
              title: Text(AppLocalizations.of(context).editTaskTitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditTaskDialog(context, controller, taskIndex);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(AppLocalizations.of(context).deleteTaskAction),
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
            color: AppColors.card(context),
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
                    Text(
                      AppLocalizations.of(context).editTaskTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).taskLabel,
                    filled: true,
                    fillColor: AppColors.bg(context),
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
                    labelText: AppLocalizations.of(context).durationMinutes,
                    filled: true,
                    fillColor: AppColors.bg(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
                    ),
                    helperText: AppLocalizations.of(context).decimalsAllowed,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pauseController,
                  enabled: taskIndex != 0,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).pauseBeforeTask,
                    helperText: taskIndex == 0
                        ? AppLocalizations.of(context).alwaysZeroFirst
                        : AppLocalizations.of(context).decimalsAllowed,
                    filled: true,
                    fillColor: AppColors.bg(context),
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
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.muted(context)),
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
                          messenger.showSingleSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).enterValidValues)),
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
                      child: Text(AppLocalizations.of(context).save),
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
      backgroundColor: AppColors.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Color(0xFF4CAF50)),
              title: Text(AppLocalizations.of(context).saveProfile),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateProfileDialog(context);
              },
            ),
            const Divider(height: 1),
            if (controller.customProfiles.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context).noSavedProfiles,
                  style: TextStyle(color: AppColors.muted(context)),
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
                        : AppColors.muted(context),
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
                      messenger.showSingleSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).profileDeleted)),
                      );
                    },
                  ),
                  onTap: () async {
                    await controller.applyCustomProfile(profile.id);
                    if (sheetContext.mounted) {
                      Navigator.pop(sheetContext);
                    }
                    messenger.showSingleSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context).profileLoaded(profile.name))),
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
            color: AppColors.card(context),
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
                  Text(
                    AppLocalizations.of(context).saveProfile,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).profileName,
                  hintText: AppLocalizations.of(context).intervalProfileNameHint,
                  filled: true,
                  fillColor: AppColors.bg(context),
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
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: AppColors.muted(context)),
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
                        messenger.showSingleSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).createTaskFirst)),
                        );
                        return;
                      }

                      final profileName = nameController.text.trim();
                      if (profileName.isEmpty) {
                        messenger.showSingleSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context).enterProfileName)),
                        );
                        return;
                      }

                      await controller.createCustomProfile(profileName);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      messenger.showSingleSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context).profileSaved(profileName))),
                      );
                    },
                    child: Text(AppLocalizations.of(context).save),
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
    // Register lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
    
    _taskNameController = TextEditingController();
    _taskDurationController = TextEditingController();
    _pauseBeforeController = TextEditingController();
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _taskNameController.dispose();
    _taskDurationController.dispose();
    _pauseBeforeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = context.read<IntervalTimerController>();
    
    switch (state) {
      case AppLifecycleState.paused:
        // App moved to background (screen locked, switched to another app)
        if (controller.timerState == IntervalTimerState.running) {
          controller.pause();
        }
        break;
      case AppLifecycleState.resumed:
        // App resumed from background
        // Timer can be restarted manually by user via UI
        break;
      default:
        break;
    }
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
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).enterValidTaskDuration)),
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
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Consumer<IntervalTimerController>(
          builder: (context, controller, _) {
            return Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroTimer(controller),
                        const SizedBox(height: 16),
                        _buildActionButtons(controller),
                        const SizedBox(height: 20),
                        if (controller.timerState == IntervalTimerState.idle)
                          _buildProfileEditor(controller)
                        else
                          _buildRunningSequence(controller),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back, color: AppColors.ink(context)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).intervalTimerTitle,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.ink(context),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showProfileSelector(context),
            icon: Icon(Icons.tune, color: AppColors.ink(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTimer(IntervalTimerController controller) {
    final inTask = controller.currentPhase == IntervalTimerPhase.task;
    final isRunning = controller.timerState == IntervalTimerState.running;
    final accent = inTask ? Color(0xFF2E7D32) : AppColors.accent(context);
    final ringBg = inTask ? (AppColors.isDark(context) ? Color(0xFF15291C) : Color(0xFFE8F5E9)) : AppColors.accentSoft(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFFFFF), (AppColors.isDark(context) ? Color(0xFF1B1F24) : Color(0xFFF9FAFC))],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPhaseChip(
                label: inTask
                    ? AppLocalizations.of(context).taskLabel
                    : AppLocalizations.of(context).pause,
                color: accent,
                icon: inTask ? Icons.fitness_center : Icons.free_breakfast,
              ),
              const SizedBox(width: 8),
              _buildPhaseChip(
                label: AppLocalizations.of(context).taskOf(controller.currentTaskNumber, controller.totalTasks),
                color: const Color(0xFF546E7A),
                icon: Icons.format_list_numbered,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            intervalItemLabel(AppLocalizations.of(context), controller),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isRunning ? 32 : 17,
              height: 1.1,
              fontWeight: isRunning ? FontWeight.w800 : FontWeight.w600,
              color: AppColors.ink(context),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 228,
            height: 228,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ringBg,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 208,
                  height: 208,
                  child: CircularProgressIndicator(
                    value: controller.progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.card(context),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.formattedTime,
                      style: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink(context),
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      inTask ? AppLocalizations.of(context).focusNow : AppLocalizations.of(context).recovery,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChip({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(IntervalTimerController controller) {
    VoidCallback? primaryAction;
    String primaryLabel;
    IconData primaryIcon;
    Color primaryColor;

    if (controller.timerState == IntervalTimerState.running) {
      primaryAction = controller.pause;
      primaryLabel = AppLocalizations.of(context).pause;
      primaryIcon = Icons.pause;
      primaryColor = const Color(0xFFFF9800);
    } else if (controller.timerState == IntervalTimerState.paused) {
      primaryAction = controller.resume;
      primaryLabel = AppLocalizations.of(context).resume;
      primaryIcon = Icons.play_arrow;
      primaryColor = const Color(0xFF2E7D32);
    } else {
      primaryAction = controller.start;
      primaryLabel = AppLocalizations.of(context).start;
      primaryIcon = Icons.play_arrow;
      primaryColor = const Color(0xFF2E7D32);
    }

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: primaryAction,
            icon: Icon(primaryIcon),
            label: Text(primaryLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.reset,
            icon: const Icon(Icons.refresh),
            label: Text(AppLocalizations.of(context).reset),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.muted(context),
              side: const BorderSide(color: Color(0xFFD8DEE8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileEditor(IntervalTimerController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).createProfile,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).createProfileSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.muted(context),
                ),
              ),
              const SizedBox(height: 14),
              _buildInputField(
                controller: _taskNameController,
                label: AppLocalizations.of(context).taskLabel,
                hint: AppLocalizations.of(context).taskHint,
                icon: Icons.task_alt,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _taskDurationController,
                label: AppLocalizations.of(context).durationMinutes,
                hint: AppLocalizations.of(context).durationHint,
                icon: Icons.timer_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                helperText: AppLocalizations.of(context).decimalsAllowedShort,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _pauseBeforeController,
                label: AppLocalizations.of(context).pauseBeforeThisTask,
                hint: AppLocalizations.of(context).durationHint,
                icon: Icons.free_breakfast_outlined,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                helperText: controller.tasks.isEmpty
                    ? AppLocalizations.of(context).ignoredForFirst
                    : AppLocalizations.of(context).decimalsAllowedShort,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addTask(controller),
                  icon: const Icon(Icons.add),
                  label: Text(AppLocalizations.of(context).addTask),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context).tasksInProfile,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink(context),
              ),
            ),
            TextButton.icon(
              onPressed: controller.tasks.isEmpty ? null : controller.clearProfile,
              icon: const Icon(Icons.delete_outline),
              label: Text(AppLocalizations.of(context).clear),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (controller.tasks.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              AppLocalizations.of(context).noTasksAdded,
              style: TextStyle(color: AppColors.muted(context)),
            ),
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
              return Container(
                key: ValueKey('${task.name}_${task.durationSeconds}_${task.pauseBeforeSeconds}_$index'),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  onLongPress: () => _showTaskActions(context, controller, index),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.accentSoft(context),
                    foregroundColor: AppColors.accent(context),
                    child: Text('${index + 1}'),
                  ),
                  title: Text(
                    task.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    index == 0
                        ? AppLocalizations.of(context).durationValue(_formatSeconds(task.durationSeconds))
                        : AppLocalizations.of(context).pauseDuration(_formatSeconds(task.pauseBeforeSeconds), _formatSeconds(task.durationSeconds)),
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
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.drag_indicator, color: AppColors.faint(context)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRunningSequence(IntervalTimerController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).sequence,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink(context),
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(controller.tasks.length, (index) {
            final task = controller.tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                index == 0
                    ? '${index + 1}. ${task.name} (${_formatSeconds(task.durationSeconds)})'
                    : '${index + 1}. Pause ${_formatSeconds(task.pauseBeforeSeconds)} -> ${task.name} (${_formatSeconds(task.durationSeconds)})',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink(context),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? helperText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: Icon(icon, color: AppColors.muted(context)),
        filled: true,
        fillColor: AppColors.bg(context),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.accent(context), width: 1.5),
        ),
      ),
    );
  }
}