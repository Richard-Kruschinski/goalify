import 'package:flutter/material.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/tool_hue.dart';
import 'package:provider/provider.dart';
import '../controllers/music_timer_controller.dart';

class MusicTimerScreen extends StatefulWidget {
  const MusicTimerScreen({super.key});

  @override
  State<MusicTimerScreen> createState() => _MusicTimerScreenState();
}

class _MusicTimerScreenState extends State<MusicTimerScreen> {
  int _selectedMinutes = 30;

  final List<int> _presetMinutes = [5, 10, 15, 20, 30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.bg(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.ink(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppLocalizations.of(context).musicTimerTitle,
          style: TextStyle(
            color: AppColors.ink(context),
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<MusicTimerController>(
        builder: (context, controller, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTimerCard(controller),
                const SizedBox(height: 20),
                if (!controller.isRunning) ...[
                  _buildPresetsCard(),
                  const SizedBox(height: 20),
                ],
                _buildInfoCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _cardDecoration({Color? borderColor}) => BoxDecoration(
    color: AppColors.card(context),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: borderColor ?? AppColors.border(context)),
    boxShadow: AppColors.cardShadow(context),
  );

  Widget _buildTimerCard(MusicTimerController controller) {
    final isRunning = controller.isRunning;
    final l10n = AppLocalizations.of(context);
    final accent = ToolHue.music.of(context);

    return Container(
      decoration: _cardDecoration(
        borderColor: isRunning ? accent.withValues(alpha: 0.4) : null,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isRunning ? accent : ToolHue.music.soft(context),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRunning ? Icons.music_note : Icons.music_note_outlined,
              size: 36,
              color: isRunning ? ToolHue.music.onFill(context) : accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isRunning ? l10n.timerActiveCaps : l10n.setTimerCaps,
            style: TextStyle(
              color: AppColors.ink(context),
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isRunning ? l10n.musicWillStop : l10n.musicTimerIdleHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted(context), fontSize: 15),
          ),
          const SizedBox(height: 24),
          // Both panels live in one IndexedStack, which is always as tall as
          // the taller one. That keeps the start/stop button below at the
          // same height when the timer is started or stopped.
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ToolHue.music.soft(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: IndexedStack(
              index: isRunning ? 1 : 0,
              alignment: Alignment.center,
              children: [
                _buildIdlePanel(l10n, accent),
                _buildRunningPanel(l10n, accent, controller),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (isRunning)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await controller.stopTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.chip(context),
                  foregroundColor: AppColors.ink(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.stopTimerCaps,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  await controller.startTimer(_selectedMinutes * 60);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: ToolHue.music.onFill(context),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  l10n.startTimerCaps,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRunningPanel(
    AppLocalizations l10n,
    Color accent,
    MusicTimerController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            l10n.timeRemaining,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.muted(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            controller.formattedTimeWithHours,
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w600,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildQuickAddButton('+5 ${l10n.unitMin}', 5, controller),
              const SizedBox(width: 8),
              _buildQuickAddButton('+10 ${l10n.unitMin}', 10, controller),
              const SizedBox(width: 8),
              _buildQuickAddButton('+15 ${l10n.unitMin}', 15, controller),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIdlePanel(AppLocalizations l10n, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Column(
        children: [
          Text(
            '$_selectedMinutes',
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w600,
              color: accent,
              fontFeatures: const [FontFeature.tabularFigures()],
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.minutesUnit,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.muted(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _selectedMinutes.toDouble(),
            min: 1,
            max: 180,
            divisions: 179,
            activeColor: accent,
            inactiveColor: AppColors.border(context),
            onChanged: (value) {
              setState(() {
                _selectedMinutes = value.toInt();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButton(
    String label,
    int minutes,
    MusicTimerController controller,
  ) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () {
          controller.addMinutes(minutes);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink(context),
          backgroundColor: AppColors.card(context),
          side: BorderSide(color: AppColors.border(context)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ToolHue.music.soft(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ToolHue.music.of(context), size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.ink(context),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsCard() {
    final accent = ToolHue.music.of(context);
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.bolt, AppLocalizations.of(context).quickPresets),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _presetMinutes.map((minutes) {
              final isSelected = minutes == _selectedMinutes;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMinutes = minutes;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ToolHue.music.soft(context)
                        : AppColors.chip(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? accent.withValues(alpha: 0.5)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    '$minutes ${AppLocalizations.of(context).unitMin}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? accent : AppColors.ink(context),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.info_outline,
            AppLocalizations.of(context).howItWorks,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).musicTimerHowItWorks,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: AppColors.muted(context),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.chip(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.music_note,
                  color: ToolHue.music.of(context),
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).worksWithAllMediaApps,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.muted(context),
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
}
