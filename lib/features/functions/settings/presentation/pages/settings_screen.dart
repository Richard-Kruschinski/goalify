import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/settings/settings_controller.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../l10n/generated/app_localizations.dart';

/// App options: theme mode (dark mode) and language.
/// Fully theme-aware - serves as the reference for migrating
/// other screens to dark mode.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsController>();

    final bg = AppColors.bg(context);
    final card = AppColors.card(context);
    final ink = AppColors.ink(context);
    final muted = AppColors.muted(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: card,
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: IconThemeData(color: ink),
        title: Text(
          l10n.settingsTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: ink,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionLabel(text: l10n.appearanceSection, color: muted),
          const SizedBox(height: 8),
          _OptionCard(
            color: card,
            children: [
              _OptionTile(
                icon: Icons.brightness_auto,
                title: l10n.themeSystem,
                subtitle: l10n.themeSystemDescription,
                selected: settings.themeMode == ThemeMode.system,
                ink: ink,
                muted: muted,
                onTap: () => settings.setThemeMode(ThemeMode.system),
              ),
              _OptionTile(
                icon: Icons.light_mode,
                title: l10n.themeLight,
                subtitle: l10n.themeLightDescription,
                selected: settings.themeMode == ThemeMode.light,
                ink: ink,
                muted: muted,
                onTap: () => settings.setThemeMode(ThemeMode.light),
              ),
              _OptionTile(
                icon: Icons.dark_mode,
                title: l10n.themeDark,
                subtitle: l10n.themeDarkDescription,
                selected: settings.themeMode == ThemeMode.dark,
                ink: ink,
                muted: muted,
                onTap: () => settings.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionLabel(text: l10n.languageSection, color: muted),
          const SizedBox(height: 8),
          _OptionCard(
            color: card,
            children: [
              _OptionTile(
                icon: Icons.smartphone,
                title: l10n.languageSystem,
                subtitle: l10n.languageSystemDescription,
                selected: settings.languageCode == null,
                ink: ink,
                muted: muted,
                onTap: () => settings.setLanguageCode(null),
              ),
              // One tile per supported language - new languages added to
              // SettingsController.supportedLanguages show up automatically.
              for (final lang in SettingsController.supportedLanguages)
                _OptionTile(
                  badge: lang.code.toUpperCase(),
                  title: lang.nativeName,
                  selected: settings.languageCode == lang.code,
                  ink: ink,
                  muted: muted,
                  onTap: () => settings.setLanguageCode(lang.code),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: color,
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.color, required this.children});

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 64,
                color: Colors.grey.withValues(alpha: 0.15),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    this.icon,
    this.badge,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.ink,
    required this.muted,
    required this.onTap,
  });

  final IconData? icon;
  final String? badge;
  final String title;
  final String? subtitle;
  final bool selected;
  final Color ink;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final accentSoft = AppColors.accentSoft(context);
    final chipBg = AppColors.chip(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? accentSoft : chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: badge != null
                  ? Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: selected ? accent : muted,
                      ),
                    )
                  : Icon(icon, size: 22, color: selected ? accent : muted),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 12.5, color: muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 22,
              color: selected ? accent : muted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
