import 'package:flutter/material.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../controllers/distraction_blocker_controller.dart';
import '../../../pomodoro/data/datasources/app_blocking_config.dart';

class DistractionBlockerScreen extends StatefulWidget {
  const DistractionBlockerScreen({super.key});

  @override
  State<DistractionBlockerScreen> createState() => _DistractionBlockerScreenState();
}

class _DistractionBlockerScreenState extends State<DistractionBlockerScreen> with WidgetsBindingObserver {
  Timer? _updateTimer;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Opens Apple's Screen Time app picker (iOS only) and refreshes the count
  Future<void> _selectAppsToBlock(DistractionBlockerController controller) async {
    final l10n = AppLocalizations.of(context);
    final service = controller.platformService;

    final available = await service.isAppBlockingAvailable();
    if (!available) {
      _showSnack(l10n.blockerIosVersionUnsupported);
      return;
    }

    final granted = await service.requestScreenTimeAuthorization();
    if (!granted) {
      _showSnack(l10n.screenTimePermissionDenied);
      return;
    }

    await service.selectAppsToBlock(
      doneLabel: l10n.done,
      cancelLabel: l10n.cancel,
    );
    await controller.refreshBlockedSelectionCount();
  }

  Future<void> _handleToggle(DistractionBlockerController controller) async {
    final l10n = AppLocalizations.of(context);

    if (controller.isActive) {
      await controller.stopBlocking();
      return;
    }

    final service = controller.platformService;
    if (service.isIOS) {
      // iOS needs Screen Time authorization and an app selection first
      final available = await service.isAppBlockingAvailable();
      if (!available) {
        _showSnack(l10n.blockerIosVersionUnsupported);
        return;
      }

      final granted = await service.requestScreenTimeAuthorization();
      if (!granted) {
        _showSnack(l10n.screenTimePermissionDenied);
        return;
      }

      var count = await service.getBlockedSelectionCount();
      if (count == 0 && mounted) {
        await service.selectAppsToBlock(
          doneLabel: l10n.done,
          cancelLabel: l10n.cancel,
        );
        count = await service.getBlockedSelectionCount();
      }
      await controller.refreshBlockedSelectionCount();
      if (count == 0) {
        _showSnack(l10n.noAppsSelectedForBlocking);
        return;
      }
    }

    try {
      await controller.startBlocking();
    } catch (_) {
      _showSnack(l10n.blockerStartFailed);
    }
  }

  @override
  void initState() {
    super.initState();
    // Register lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);
    
    // Update UI every second when blocker is active
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    // Unregister lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        // Keep blocker active while app is in background/minimized.
        break;
      case AppLifecycleState.inactive:
        // Keep blocker active during transient inactive states as well.
        break;
      case AppLifecycleState.resumed:
        // Nothing to do: blocker state is managed by controller persistence.
        break;
      default:
        break;
    }
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
          AppLocalizations.of(context).distractionBlockerTitle,
          style: TextStyle(
            color: AppColors.ink(context),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<DistractionBlockerController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main blocker card
                _buildBlockerCard(controller),
                
                const SizedBox(height: 20),
                
                // Statistics
                _buildStatisticsCard(controller),
                
                const SizedBox(height: 20),
                
                // Info card
                _buildInfoCard(controller),

                const SizedBox(height: 20),

                // Blocked apps list
                _buildBlockedAppsCard(controller),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockerCard(DistractionBlockerController controller) {
    final isActive = controller.isActive;
    
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with icon and status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isActive ? Color(0xFFFF6B6B) : (AppColors.isDark(context) ? const Color(0xFF2B2038) : const Color(0xFFE8D6F7)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Icon
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isActive ? Icons.shield : Icons.shield_outlined,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Status text
                Text(
                  isActive
                      ? AppLocalizations.of(context).statusActive
                      : AppLocalizations.of(context).statusInactive,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                
                const SizedBox(height: 12),
                Text(
                  isActive
                      ? AppLocalizations.of(context).appsCurrentlyBlocked
                      : AppLocalizations.of(context).appsNotBlocked,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                // Blocked-attempt counting needs the Android accessibility
                // service; iOS shields apps system-side without reporting hits
                if (!controller.platformService.isIOS) ...[
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context)
                        .distractionAttemptsPrevented(controller.blockedAttempts),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Body with timer and switch
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Session duration
                if (isActive) ...[
                  Container(
                    width: double.infinity,
                    height: 120,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (AppColors.isDark(context) ? const Color(0xFF2E1A1A) : const Color(0xFFFFF5F5)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (AppColors.isDark(context) ? const Color(0xFF3A2222) : const Color(0xFFFFE0E0))),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context).blockerCurrentSession,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.currentSessionDuration,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B6B),
                            fontFeatures: [FontFeature.tabularFigures()],
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 120,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (AppColors.isDark(context) ? const Color(0xFF241F33) : const Color(0xFFF8F5FF)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: (AppColors.isDark(context) ? const Color(0xFF2B2038) : const Color(0xFFE8D6F7))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (AppColors.isDark(context) ? const Color(0xFF2B2038) : const Color(0xFFE8D6F7)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF9B6FD9),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).toggleToStartBlocking,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.muted(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Toggle switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.bg(context),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isActive ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: !isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          AppLocalizations.of(context).toggleOff,
                          style: TextStyle(
                            color: !isActive ? Color(0xFF9B6FD9) : AppColors.faint(context),
                            fontWeight: !isActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      GestureDetector(
                        onTap: () => _handleToggle(controller),
                        child: Container(
                          width: 56,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isActive ? Color(0xFFFF6B6B) : AppColors.border(context),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: isActive ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              width: 28,
                              height: 28,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          AppLocalizations.of(context).toggleOn,
                          style: TextStyle(
                            color: isActive ? Color(0xFFFF6B6B) : AppColors.faint(context),
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(DistractionBlockerController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (AppColors.isDark(context) ? const Color(0xFF14273A) : const Color(0xFFE8F4FF)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Color(0xFF4A9EFF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).todaysStatistics,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Total blocking time today
          _buildStatRow(
            icon: Icons.timer_outlined,
            label: AppLocalizations.of(context).totalBlockingTime,
            value: controller.todayTotalDuration,
            color: const Color(0xFF4A9EFF),
          ),
          
          const SizedBox(height: 16),
          
          // Apps blocked
          _buildStatRow(
            icon: Icons.block,
            label: AppLocalizations.of(context).appsBeingBlocked,
            value: controller.platformService.isIOS
                ? '${controller.blockedSelectionCount}'
                : '${AppBlockingConfig.blockedAppsCount}',
            color: const Color(0xFFFF9066),
          ),

          if (!controller.platformService.isIOS) ...[
            const SizedBox(height: 16),
            _buildStatRow(
              icon: Icons.shield,
              label: AppLocalizations.of(context).attemptsPrevented,
              value: '${controller.blockedAttempts}',
              color: const Color(0xFF66BB6A),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5A5A5A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DistractionBlockerController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (AppColors.isDark(context) ? const Color(0xFF15291C) : const Color(0xFFE8F5E9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF66BB6A),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).howItWorks,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).blockerHowItWorksText,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF5A5A5A),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (AppColors.isDark(context) ? const Color(0xFF2E2712) : const Color(0xFFFFF8E1)),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Color(0xFFFFA726), size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.platformService.isIOS
                        ? AppLocalizations.of(context).requiresScreenTime
                        : AppLocalizations.of(context).requiresAccessibility,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF5A5A5A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsCard(DistractionBlockerController controller) {
    final isIOS = controller.platformService.isIOS;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.block,
                  color: Color(0xFFFF6B6B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).blockedApps,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isIOS
                      ? '${controller.blockedSelectionCount}'
                      : '${AppBlockingConfig.blockedAppsCount}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bg(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.apps,
                  color: Color(0xFF9B6FD9),
                  size: 22,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isIOS
                        ? AppLocalizations.of(context).blockedAppsSelectionIos
                        : AppLocalizations.of(context).blockedAppsCategories,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A5A5A),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isIOS) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _selectAppsToBlock(controller),
                icon: const Icon(Icons.apps, size: 20),
                label: Text(AppLocalizations.of(context).chooseAppsToBlock),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}