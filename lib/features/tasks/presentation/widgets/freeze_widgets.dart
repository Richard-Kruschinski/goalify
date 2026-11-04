import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/daily_task.dart';

/// Button style for spending a freeze token. Frost blue in both themes; in
/// dark mode the label is dark because white on the light blue lacks contrast.
ButtonStyle _freezeButtonStyle(BuildContext context) {
  final dark = AppColors.isDark(context);
  return FilledButton.styleFrom(
    backgroundColor: AppColors.info(context),
    foregroundColor: dark ? AppColors.darkBg : Colors.white,
    disabledBackgroundColor: AppColors.chip(context),
    disabledForegroundColor: AppColors.faint(context),
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}

/// Round frost badge with the snowflake, the one mark for "frozen".
class _FrostMark extends StatelessWidget {
  const _FrostMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.info(context).withValues(alpha: 0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.ac_unit, size: size * 0.5, color: AppColors.info(context)),
    );
  }
}

/// Lies over the task list on a frozen day, today or in the past.
class FrostBanner extends StatelessWidget {
  const FrostBanner({super.key, required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoSoft(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.info(context).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const _FrostMark(size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).dayFrozenTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One snowflake per token slot: filled for tokens left, faint for empty ones.
class _TokenTray extends StatelessWidget {
  const _TokenTray({required this.tokens, required this.maxTokens});

  final int tokens;
  final int maxTokens;

  @override
  Widget build(BuildContext context) {
    final slots = tokens > maxTokens ? tokens : maxTokens;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < slots; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.ac_unit,
              size: 20,
              color: i < tokens
                  ? AppColors.info(context)
                  : AppColors.border(context),
            ),
          ),
      ],
    );
  }
}

/// Opened from the snowflake chip: freeze today with one token.
class FreezeSheet extends StatelessWidget {
  const FreezeSheet({
    super.key,
    required this.frozen,
    required this.tokens,
    required this.maxTokens,
    required this.onFreeze,
  });

  final bool frozen;
  final int tokens;
  final int maxTokens;
  final Future<void> Function() onFreeze;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canFreeze = !frozen && tokens > 0;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FrostMark(size: 56),
            const SizedBox(height: 16),
            Text(
              frozen ? l10n.dayFrozenTitle : l10n.freezeTodayTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              frozen ? l10n.dayFrozenTodaySubtitle : l10n.freezeSheetBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(height: 24),
            _TokenTray(tokens: tokens, maxTokens: maxTokens),
            const SizedBox(height: 8),
            Text(
              l10n.freezeTokensLeft(tokens, maxTokens),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.muted(context),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              l10n.freezeTokenRefill(maxTokens),
              style: TextStyle(fontSize: 12, color: AppColors.faint(context)),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: canFreeze ? onFreeze : null,
              style: _freezeButtonStyle(context),
              child: Text(
                frozen
                    ? l10n.alreadyFrozen
                    : tokens > 0
                        ? l10n.freezeConfirmButton
                        : l10n.noTokensLeft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown on the first open of a new day when yesterday would break streaks.
/// Pops `true` to spend a token on yesterday.
class RetroFreezeDialog extends StatelessWidget {
  const RetroFreezeDialog({
    super.key,
    required this.tasks,
    required this.tokens,
    required this.maxTokens,
  });

  final List<DailyTask> tasks;
  final int tokens;
  final int maxTokens;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FrostMark(size: 48),
          const SizedBox(height: 16),
          Text(
            l10n.retroFreezeTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.ink(context),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.retroFreezeBody,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.muted(context),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.chip(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Column(
                  children: [
                    for (final t in tasks)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ink(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.local_fire_department,
                              size: 14,
                              color: AppColors.warning(context),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              t.isLimitedRecurring
                                  ? l10n.streakCycleCount(t.streak)
                                  : l10n.streakCount(t.streak),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.warning(context),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.freezeTokensLeft(tokens, maxTokens),
                style: TextStyle(fontSize: 12, color: AppColors.faint(context)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: AppColors.muted(context)),
          child: Text(l10n.notNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: _freezeButtonStyle(context).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          ),
          child: Text(l10n.freezeConfirmButton),
        ),
      ],
    );
  }
}
