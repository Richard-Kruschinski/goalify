import 'package:flutter/material.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/snackbar_utils.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../controllers/pomodoro_controller.dart';
import '../../data/models/pomodoro_stats.dart';
import '../../data/models/pomodoro_profile.dart';

/// Localized display name for a Pomodoro profile. Default (built-in) profiles
/// are stored with stable ids and English names; only the display is
/// translated, so persisted data and custom names stay untouched.
String pomodoroProfileName(AppLocalizations l10n, PomodoroProfile profile) {
  switch (profile.id) {
    case 'classic':
      return l10n.profileClassic;
    case 'short':
      return l10n.profileShort;
    case 'long':
      return l10n.profileLong;
    case 'intense':
      return l10n.profileIntense;
    default:
      return profile.name;
  }
}

/// Localized Pomodoro phase label (the controller keeps a context-free
/// fallback for native notifications).
String _localizedPhaseLabel(BuildContext context, PomodoroPhase phase) {
  final l10n = AppLocalizations.of(context);
  switch (phase) {
    case PomodoroPhase.work:
      return l10n.pomodoroFocus;
    case PomodoroPhase.shortBreak:
      return l10n.shortBreak;
    case PomodoroPhase.longBreak:
      return l10n.longBreak;
  }
}

class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use the global PomodoroController provided by MultiProvider in main.dart
    return const _PomodoroScreenContent();
  }
}

class _PomodoroScreenContent extends StatefulWidget {
  const _PomodoroScreenContent();

  @override
  State<_PomodoroScreenContent> createState() => _PomodoroScreenContentState();
}

class _PomodoroScreenContentState extends State<_PomodoroScreenContent> with WidgetsBindingObserver {
  bool _isDefaultProfile(PomodoroProfile profile) {
    return PomodoroProfile.defaultProfiles.any((p) => p.id == profile.id);
  }

  void _showProfileActions(BuildContext context, PomodoroProfile profile) {
    final isDefaultProfile = _isDefaultProfile(profile);

    if (isDefaultProfile) {
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).defaultProfilesNotEditable),
          backgroundColor: Color(0xFFFF6B6B),
        ),
      );
      return;
    }

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
              leading: const Icon(Icons.edit, color: Color(0xFFFF6B6B)),
              title: Text(AppLocalizations.of(context).edit),
              onTap: () {
                Navigator.pop(sheetContext);
                _showEditProfileDialog(context, profile);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text(AppLocalizations.of(context).delete),
              onTap: () {
                Navigator.pop(sheetContext);
                _showDeleteProfileDialog(context, profile);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, PomodoroProfile profile) {
    final nameController = TextEditingController(text: profile.name);
    final workController = TextEditingController(text: profile.workDuration.toString());
    final shortBreakController = TextEditingController(text: profile.shortBreakDuration.toString());
    final longBreakController = TextEditingController(text: profile.longBreakDuration.toString());
    final cyclesController = TextEditingController(text: profile.cyclesBeforeLongBreak.toString());
    bool shouldBlockApps = profile.shouldBlockApps; // Track app blocking preference
    final pomodoroController = context.read<PomodoroController>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_note,
                            color: Color(0xFFFF6B6B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                        child: Text(
                          AppLocalizations.of(context).editProfile,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Name
                  _ModernTextField(
                    controller: nameController,
                    label: AppLocalizations.of(context).profileName,
                    icon: Icons.label_outline,
                    hint: profile.name,
                  ),
                  const SizedBox(height: 16),
                  
                  // Work Duration
                  _ModernTextField(
                    controller: workController,
                    label: AppLocalizations.of(context).workDuration,
                    icon: Icons.work_outline,
                    hint: AppLocalizations.of(context).minutesLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Short Break
                  _ModernTextField(
                    controller: shortBreakController,
                    label: AppLocalizations.of(context).shortBreak,
                    icon: Icons.free_breakfast_outlined,
                    hint: AppLocalizations.of(context).minutesLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Long Break
                  _ModernTextField(
                    controller: longBreakController,
                    label: AppLocalizations.of(context).longBreak,
                    icon: Icons.spa_outlined,
                    hint: AppLocalizations.of(context).minutesLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Cycles
                  _ModernTextField(
                    controller: cyclesController,
                    label: AppLocalizations.of(context).cyclesBeforeLongBreak,
                    icon: Icons.repeat,
                    hint: AppLocalizations.of(context).numberLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  
                  // Block Apps Checkbox  
                  CheckboxListTile(
                    value: shouldBlockApps,
                    onChanged: (value) {
                      setState(() {
                        shouldBlockApps = value ?? true;
                      });
                    },
                    title: Text(AppLocalizations.of(context).blockApps),
                    subtitle: Text(AppLocalizations.of(context).blockAppsSubtitle),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFFF6B6B),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.border(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).cancel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final newName = nameController.text.trim();
                            if (newName.isEmpty) {
                              messenger.showSingleSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).enterProfileName),
                                  backgroundColor: Color(0xFFFF6B6B),
                                ),
                              );
                              return;
                            }

                            final updatedProfile = profile.copyWith(
                              name: newName,
                              workDuration: int.tryParse(workController.text) ?? profile.workDuration,
                              shortBreakDuration: int.tryParse(shortBreakController.text) ?? profile.shortBreakDuration,
                              longBreakDuration: int.tryParse(longBreakController.text) ?? profile.longBreakDuration,
                              cyclesBeforeLongBreak: int.tryParse(cyclesController.text) ?? profile.cyclesBeforeLongBreak,
                              shouldBlockApps: shouldBlockApps,
                            );

                            await pomodoroController.updateCustomProfile(updatedProfile);

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              messenger.showSingleSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).profileUpdated),
                                  backgroundColor: Color(0xFF51CF66),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  void _showDeleteProfileDialog(BuildContext context, PomodoroProfile profile) {
    final pomodoroController = context.read<PomodoroController>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).deleteProfile,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Content
                Text(
                  AppLocalizations.of(context).deleteProfileConfirm(profile.name),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.muted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AppColors.border(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await pomodoroController.deleteCustomProfile(profile.id);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                            messenger.showSingleSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(context).profileDeleted),
                                backgroundColor: Color(0xFF51CF66),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
    
    // Show permission request dialogs if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PomodoroController>();
      if (controller.isAppBlockingSupported) {
        _checkPermissions();
      } else {
        // Show iOS dialog
        _showIOSDialog(context);
      }
    });
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = context.read<PomodoroController>();
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App resumed from background: sync wall-clock based remaining time
        controller.syncWithSystemTime();
        break;
      default:
        break;
    }
  }

  Future<void> _checkPermissions() async {
    // First check notification permission (required on Android 13+)
    await _checkAndRequestNotificationPermission();
    
    // Then check accessibility permission
    await _checkAndRequestAccessibilityPermission();
  }

  Future<void> _checkAndRequestNotificationPermission() async {
    final status = await Permission.notification.status;
    
    if (status.isDenied && mounted) {
      _showNotificationPermissionDialog();
    }
  }

  Future<void> _checkAndRequestAccessibilityPermission() async {
    final controller = context.read<PomodoroController>();
    final isEnabled = await controller.platformService.isAccessibilityServiceEnabled();
    
    if (!isEnabled && mounted) {
      _showAccessibilityPermissionDialog();
    }
  }

  void _showNotificationPermissionDialog() {
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
            color: AppColors.card(context),
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
                  Icons.notifications_active,
                  color: Color(0xFFFF6B6B),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                AppLocalizations.of(context).notificationsRequired,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                AppLocalizations.of(context).notificationsRequiredText,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted(context),
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
                    await Permission.notification.request();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B6B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).allow,
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
                    foregroundColor: AppColors.muted(context),
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).later,
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
            color: AppColors.card(context),
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
              Text(
                AppLocalizations.of(context).accessibilityRequired,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                AppLocalizations.of(context).accessibilityRequiredText,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted(context),
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
                  child: Text(
                    AppLocalizations.of(context).allow,
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
                    foregroundColor: AppColors.muted(context),
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).later,
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
            color: AppColors.card(context),
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
              Text(
                AppLocalizations.of(context).appBlockingNotSupported,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Content
              Text(
                AppLocalizations.of(context).appBlockingNotSupportedText,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted(context),
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

  void _showProfileSelector(BuildContext context) {
    final parentContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.85,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Consumer<PomodoroController>(
              builder: (_, controller, __) => Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).selectTimerProfile,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showCreateProfileDialog(parentContext);
                          },
                          color: const Color(0xFFFF6B6B),
                        ),
                      ],
                    ),
                  ),

                  // Profile list
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: controller.allProfiles.length,
                      itemBuilder: (context, index) {
                        final profile = controller.allProfiles[index];
                        final isSelected = profile.id == controller.currentProfile.id;

                        return _ProfileTile(
                          profile: profile,
                          isSelected: isSelected,
                          onLongPress: () => _showProfileActions(parentContext, profile),
                          onTap: () async {
                            await controller.changeProfile(profile);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateProfileDialog(BuildContext context) {
    final nameController = TextEditingController();
    final workController = TextEditingController();
    final shortBreakController = TextEditingController();
    final longBreakController = TextEditingController();
    final cyclesController = TextEditingController();
    bool shouldBlockApps = true; // Default: block apps
    final pomodoroController = context.read<PomodoroController>();
    final messenger = ScaffoldMessenger.of(context);
    
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: Color(0xFFFF6B6B),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                        child: Text(
                          AppLocalizations.of(context).createCustomProfile,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Profile Name
                  _ModernTextField(
                    controller: nameController,
                    label: AppLocalizations.of(context).profileName,
                    icon: Icons.label_outline,
                    hint: AppLocalizations.of(context).profileNameHint,
                  ),
                  const SizedBox(height: 16),
                  
                  // Work Duration
                  _ModernTextField(
                    controller: workController,
                    label: AppLocalizations.of(context).workDuration,
                    icon: Icons.work_outline,
                    hint: AppLocalizations.of(context).minutesLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Short Break
                  _ModernTextField(
                    controller: shortBreakController,
                    label: AppLocalizations.of(context).shortBreak,
                    icon: Icons.free_breakfast_outlined,
                    hint: AppLocalizations.of(context).minutesLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Long Break
                  _ModernTextField(
                    controller: longBreakController,
                    label: AppLocalizations.of(context).longBreak,
                    icon: Icons.spa_outlined,
                    hint: AppLocalizations.of(context).minutesLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  
                  // Cycles
                  _ModernTextField(
                    controller: cyclesController,
                    label: AppLocalizations.of(context).cyclesBeforeLongBreak,
                    icon: Icons.repeat,
                    hint: AppLocalizations.of(context).numberLabel,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  
                  // Block Apps Checkbox  
                  CheckboxListTile(
                    value: shouldBlockApps,
                    onChanged: (value) {
                      setState(() {
                        shouldBlockApps = value ?? true;
                      });
                    },
                    title: Text(AppLocalizations.of(context).blockApps),
                    subtitle: Text(AppLocalizations.of(context).blockAppsSubtitle),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFFF6B6B),
                  ),
                  const SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: AppColors.border(context)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).cancel,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              messenger.showSingleSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).enterProfileName),
                                  backgroundColor: Color(0xFFFF6B6B),
                                ),
                              );
                              return;
                            }

                            final workDuration = int.tryParse(workController.text.trim());
                            final shortBreakDuration = int.tryParse(shortBreakController.text.trim());
                            final longBreakDuration = int.tryParse(longBreakController.text.trim());
                            final cyclesBeforeLongBreak = int.tryParse(cyclesController.text.trim());

                            if (workDuration == null ||
                                shortBreakDuration == null ||
                                longBreakDuration == null ||
                                cyclesBeforeLongBreak == null ||
                                workDuration <= 0 ||
                                shortBreakDuration <= 0 ||
                                longBreakDuration <= 0 ||
                                cyclesBeforeLongBreak <= 0) {
                              messenger.showSingleSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).enterValidDurations),
                                  backgroundColor: Color(0xFFFF6B6B),
                                ),
                              );
                              return;
                            }
                            
                            final profile = PomodoroProfile(
                              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                              name: nameController.text.trim(),
                              workDuration: workDuration,
                              shortBreakDuration: shortBreakDuration,
                              longBreakDuration: longBreakDuration,
                              cyclesBeforeLongBreak: cyclesBeforeLongBreak,
                              shouldBlockApps: shouldBlockApps,
                            );
                            
                            await pomodoroController.addCustomProfile(profile);
                            
                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              messenger.showSingleSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context).profileCreated(profile.name)),
                                  backgroundColor: const Color(0xFF51CF66),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B6B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).create,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.ink(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).pomodoroTimer,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.ink(context),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.ink(context)),
            onPressed: () {
              _showProfileSelector(context);
            },
          ),
        ],
      ),
      body: Consumer<PomodoroController>(
        builder: (context, controller, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Phase indicator
                _PhaseIndicator(controller: controller),
                const SizedBox(height: 12),
                
                // Current profile indicator
                _CurrentProfileIndicator(profile: controller.currentProfile),
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

class _CurrentProfileIndicator extends StatelessWidget {
  final PomodoroProfile profile;

  const _CurrentProfileIndicator({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: AppColors.muted(context)),
          const SizedBox(width: 8),
          Text(
            pomodoroProfileName(AppLocalizations.of(context), profile),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.muted(context),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '(${profile.workDuration} ${AppLocalizations.of(context).unitMin})',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.faint(context),
            ),
          ),
        ],
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
        color: AppColors.card(context),
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
                _localizedPhaseLabel(context, controller.currentPhase),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _getPhaseColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).cycleOf(controller.currentCycle),
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted(context),
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
        color: AppColors.card(context),
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
              backgroundColor: AppColors.border(context),
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
                style: TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink(context),
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
                      ? AppLocalizations.of(context).running
                      : controller.timerState == PomodoroTimerState.paused
                          ? AppLocalizations.of(context).paused
                          : AppLocalizations.of(context).ready,
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

  Future<void> _handlePlayPause(BuildContext context) async {
    if (controller.timerState == PomodoroTimerState.running) {
      controller.pause();
    } else {
      final success = await controller.start();
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSingleSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).notificationPermissionRequired),
            duration: Duration(seconds: 4),
            backgroundColor: Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Reset button
        _CircularButton(
          icon: Icons.refresh,
          onPressed: controller.reset,
          color: AppColors.muted(context),
          size: 56,
        ),
        const SizedBox(width: 20),
        
        // Play/Pause button (larger)
        _CircularButton(
          icon: controller.timerState == PomodoroTimerState.running
              ? Icons.pause
              : Icons.play_arrow,
          onPressed: () => _handlePlayPause(context),
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
          color: AppColors.muted(context),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).focusModeActive,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context).otherAppsBlocked,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.muted(context),
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
        Text(
          AppLocalizations.of(context).todaysProgress,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink(context),
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
                label: AppLocalizations.of(context).sessions,
                value: '${stats.completedSessionsToday}',
                color: const Color(0xFF51CF66),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.access_time,
                label: AppLocalizations.of(context).focusTime,
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
                label: AppLocalizations.of(context).thisWeek,
                value: '${stats.totalFocusTimeThisWeek}m',
                color: const Color(0xFFFF9F43),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.repeat,
                label: AppLocalizations.of(context).cycles,
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
        color: AppColors.card(context),
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
                  backgroundColor: AppColors.border(context),
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
                Text(
                  AppLocalizations.of(context).dailyFocusScore,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getScoreMessage(context, score),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted(context),
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

  String _getScoreMessage(BuildContext context, int score) {
    if (score >= 80) return AppLocalizations.of(context).scoreExcellent;
    if (score >= 50) return AppLocalizations.of(context).scoreGreat;
    if (score >= 20) return AppLocalizations.of(context).scoreGood;
    return AppLocalizations.of(context).scoreGetFocused;
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
        color: AppColors.card(context),
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
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.ink(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final PomodoroProfile profile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ProfileTile({
    required this.profile,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF6B6B).withValues(alpha: 0.1) : AppColors.chip(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFFFF6B6B) : AppColors.border(context),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Selected indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFFF6B6B) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Color(0xFFFF6B6B) : AppColors.faint(context),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            
            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pomodoroProfileName(AppLocalizations.of(context), profile),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Color(0xFFFF6B6B) : AppColors.ink(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).profileDurations(
                      '${profile.workDuration} ${AppLocalizations.of(context).unitMin}',
                      '${profile.shortBreakDuration} ${AppLocalizations.of(context).unitMin}',
                      '${profile.longBreakDuration} ${AppLocalizations.of(context).unitMin}',
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.muted(context),
                    ),
                  ),
                  Text(
                    '${profile.cyclesBeforeLongBreak} cycles before long break',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.faint(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.hint,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.muted(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.chip(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.faint(context),
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                icon,
                color: const Color(0xFFFF6B6B),
                size: 22,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}