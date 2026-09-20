import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/settings/settings_controller.dart';
import '../../../../../core/sounds/sound_controller.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/time_wheel_picker.dart';
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
    final sounds = context.watch<SoundController>();

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
          _SectionLabel(text: l10n.dayStartSection, color: muted),
          const SizedBox(height: 8),
          // The day boundary drives daily tasks, gym/creatine tracking and the
          // progress charts - see DayCycle.
          _OptionCard(
            color: card,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TimeWheelPicker(
                  initialHour: settings.dayStartHour,
                  initialMinute: settings.dayStartMinute,
                  onChanged: settings.setDayStart,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              l10n.dayStartDescription,
              style: TextStyle(fontSize: 12.5, color: muted),
            ),
          ),
          const SizedBox(height: 24),
          _SectionLabel(text: l10n.soundsSection, color: muted),
          const SizedBox(height: 8),
          _OptionCard(
            color: card,
            children: [
              _SwitchTile(
                icon: Icons.volume_up,
                title: l10n.soundsEnabledTitle,
                subtitle: l10n.soundsEnabledDescription,
                value: sounds.enabled,
                ink: ink,
                muted: muted,
                onChanged: sounds.setEnabled,
              ),
              if (sounds.enabled)
                _VolumeTile(
                  title: l10n.soundVolume,
                  volume: sounds.volume,
                  ink: ink,
                  muted: muted,
                  onChanged: sounds.setVolume,
                  onChangeEnd: (_) {
                    final sound =
                        sounds.soundForEvent(SoundEvent.dailyTaskCompleted);
                    if (sound != null) sounds.preview(sound);
                  },
                ),
            ],
          ),
          // One sound picker per event - new SoundEvent values show up
          // automatically (they only need a label in _soundEventLabel).
          if (sounds.enabled && sounds.sounds.isNotEmpty)
            for (final event in SoundEvent.values) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  _soundEventLabel(l10n, event),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _SearchableDropdown(
                options: [
                  for (final sound in sounds.sounds)
                    _DropdownOption(
                      id: sound.id,
                      name: sound.name,
                      leading: Icon(Icons.music_note, size: 18, color: muted),
                    ),
                ],
                selectedId: sounds.soundForEvent(event)?.id,
                onSelected: (id) {
                  if (id == null) return;
                  sounds.setSoundForEvent(event, id);
                  sounds.preview(
                    sounds.sounds.firstWhere((s) => s.id == id),
                  );
                },
              ),
            ],
          const SizedBox(height: 24),
          _SectionLabel(text: l10n.languageSection, color: muted),
          const SizedBox(height: 8),
          // New languages added to SettingsController.supportedLanguages
          // show up automatically.
          _SearchableDropdown(
            options: [
              _DropdownOption(
                id: null,
                name: l10n.languageSystem,
                leading: Icon(Icons.smartphone, size: 18, color: muted),
              ),
              for (final lang in SettingsController.supportedLanguages)
                _DropdownOption(
                  id: lang.code,
                  name: lang.nativeName,
                  leading: CountryFlag.fromCountryCode(
                    lang.flagCountryCode,
                    theme: const ImageTheme(
                      width: 21,
                      height: 14,
                      shape: RoundedRectangle(3),
                    ),
                  ),
                ),
            ],
            selectedId: settings.languageCode,
            onSelected: settings.setLanguageCode,
          ),
        ],
      ),
    );
  }
}

/// Display name for a sound event in the settings screen.
/// Every [SoundEvent] needs a case here (compile error reminds you).
String _soundEventLabel(AppLocalizations l10n, SoundEvent event) {
  switch (event) {
    case SoundEvent.dailyTaskCompleted:
      return l10n.soundEventDailyTaskCompleted;
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

/// One row in a searchable dropdown. [id] can be null so a "system"/default
/// entry can be represented.
class _DropdownOption {
  const _DropdownOption({required this.id, required this.name, required this.leading});

  final String? id;
  final String name;

  /// Small widget shown before the name (flag, icon, ...).
  final Widget leading;
}

/// Select field that opens an overlay with a search box and an option list -
/// styled like a web select/combobox (field with accent border when open,
/// floating panel with search on top). Opens upwards when there is not
/// enough room below the field. Used for the language and sound pickers.
class _SearchableDropdown extends StatefulWidget {
  const _SearchableDropdown({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_DropdownOption> options;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  @override
  State<_SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<_SearchableDropdown>
    with WidgetsBindingObserver {
  final OverlayPortalController _overlay = OverlayPortalController();
  final LayerLink _link = LayerLink();
  final TextEditingController _search = TextEditingController();
  double _fieldWidth = 0;
  bool _open = false;

  /// True when there is not enough room below the field, so the panel
  /// opens above it instead of running off screen.
  bool _openUp = false;
  double _listMaxHeight = 280;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  /// The keyboard can appear after the panel is already open (the user taps
  /// the search box). Re-measure so the list does not end up behind it.
  @override
  void didChangeMetrics() {
    if (!_open) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_open) return;
      setState(_updatePlacement);
    });
  }

  void _toggle() {
    if (_open) {
      _close();
      return;
    }
    _search.clear();
    _updatePlacement();
    setState(() => _open = true);
    _overlay.show();
  }

  /// Decides open direction and list height from the space around the field.
  void _updatePlacement() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final media = MediaQuery.of(context);
    final fieldTop = box.localToGlobal(Offset.zero).dy;
    final fieldBottom = fieldTop + box.size.height;
    final spaceBelow =
        media.size.height - media.viewInsets.bottom - fieldBottom - 16;
    final spaceAbove = fieldTop - media.padding.top - 16;
    _openUp = spaceBelow < 220 && spaceAbove > spaceBelow;
    // Panel = search row (~48) + 6px gap + list; the list gets the rest.
    final available = (_openUp ? spaceAbove : spaceBelow) - 6 - 48;
    _listMaxHeight = available.clamp(96.0, 280.0);
  }

  void _close() {
    if (!_open) return;
    _overlay.hide();
    setState(() => _open = false);
  }

  void _select(String? id) {
    widget.onSelected(id);
    _close();
  }

  Widget _leading(_DropdownOption option) =>
      SizedBox(width: 24, child: option.leading);

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    final card = AppColors.card(context);
    final ink = AppColors.ink(context);
    final muted = AppColors.muted(context);
    final accent = AppColors.accent(context);

    final selected = widget.options.firstWhere(
      (o) => o.id == widget.selectedId,
      orElse: () => widget.options.first,
    );

    return CompositedTransformTarget(
      link: _link,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _fieldWidth = constraints.maxWidth;
          return OverlayPortal(
            controller: _overlay,
            overlayChildBuilder: (context) =>
                _buildOverlay(l10n, card, ink, muted, accent),
            child: InkWell(
              onTap: _toggle,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _open ? accent : muted.withValues(alpha: 0.35),
                    width: _open ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    _leading(selected),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selected.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: ink,
                        ),
                      ),
                    ),
                    Icon(
                      _open ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: muted,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverlay(
    AppLocalizations l10n,
    Color card,
    Color ink,
    Color muted,
    Color accent,
  ) {
    final query = _search.text.trim().toLowerCase();
    final options = widget.options
        .where((o) =>
            query.isEmpty ||
            o.name.toLowerCase().contains(query) ||
            (o.id ?? '').toLowerCase().contains(query))
        .toList();

    return Stack(
      children: [
        // Invisible barrier: tap anywhere outside closes the dropdown.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: _openUp ? Alignment.topLeft : Alignment.bottomLeft,
          followerAnchor: _openUp ? Alignment.bottomLeft : Alignment.topLeft,
          offset: Offset(0, _openUp ? -6 : 6),
          showWhenUnlinked: false,
          child: Align(
            alignment: _openUp ? Alignment.bottomLeft : Alignment.topLeft,
            child: SizedBox(
              width: _fieldWidth,
              child: Material(
                color: card,
                elevation: 8,
                shadowColor: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(10),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 18, color: muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _search,
                              // Kein autofocus: die Liste soll erst ohne
                              // Tastatur erscheinen. Die Tastatur kommt erst,
                              // wenn der Nutzer das Suchfeld antippt.
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(fontSize: 14.5, color: ink),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: l10n.searchHint,
                                hintStyle: TextStyle(fontSize: 14.5, color: muted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: _listMaxHeight),
                      child: ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        children: [
                          for (final option in options)
                            InkWell(
                              onTap: () => _select(option.id),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                child: Row(
                                  children: [
                                    _leading(option),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        option.name,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w500,
                                          color: ink,
                                        ),
                                      ),
                                    ),
                                    if (option.id == widget.selectedId)
                                      Icon(Icons.check, size: 18, color: accent),
                                  ],
                                ),
                              ),
                            ),
                          if (options.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                '—',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: muted),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.ink,
    required this.muted,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final Color ink;
  final Color muted;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final accentSoft = AppColors.accentSoft(context);
    final chipBg = AppColors.chip(context);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: value ? accentSoft : chipBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 22, color: value ? accent : muted),
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
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _VolumeTile extends StatelessWidget {
  const _VolumeTile({
    required this.title,
    required this.volume,
    required this.ink,
    required this.muted,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String title;
  final double volume;
  final Color ink;
  final Color muted;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent(context);
    final chipBg = AppColors.chip(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: chipBg,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              volume == 0 ? Icons.volume_off : Icons.volume_down,
              size: 22,
              color: muted,
            ),
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
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: volume,
                    onChanged: onChanged,
                    onChangeEnd: onChangeEnd,
                    activeColor: accent,
                    inactiveColor: muted.withValues(alpha: 0.25),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 42,
            child: Text(
              '${(volume * 100).round()}%',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.ink,
    required this.muted,
    required this.onTap,
  });

  final IconData icon;
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
              child: Icon(icon, size: 22, color: selected ? accent : muted),
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
