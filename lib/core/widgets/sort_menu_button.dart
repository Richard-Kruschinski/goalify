import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'animated_sort_icon.dart';

/// One entry of a [SortMenuButton].
class SortOption<T> {
  const SortOption({
    required this.value,
    required this.icon,
    required this.label,
    this.reversible = true,
  });

  final T value;
  final IconData icon;
  final String label;

  /// False for a hand-made order, where flipping has no meaning.
  final bool reversible;
}

/// Header sort button with the same look and rules as the daily screen:
/// the icon is muted for the custom order and accent while a sort is active,
/// its arrow shows the direction, and picking the active entry again flips it.
class SortMenuButton<T> extends StatelessWidget {
  const SortMenuButton({
    super.key,
    required this.options,
    required this.selected,
    required this.descending,
    required this.onSelected,
    required this.tooltip,
    this.animate = true,
  });

  final List<SortOption<T>> options;
  final T selected;

  /// Effective direction of the active sort (natural direction plus reverse).
  final bool descending;
  final ValueChanged<T> onSelected;
  final String tooltip;

  /// Passed to [AnimatedSortIcon]; false while the saved sort is loading.
  final bool animate;

  SortOption<T> get _active =>
      options.firstWhere((o) => o.value == selected, orElse: () => options.first);

  SortIconState get _iconState => !_active.reversible
      ? SortIconState.none
      : (descending ? SortIconState.descending : SortIconState.ascending);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: AnimatedSortIcon(state: _iconState, animate: animate),
      color: AppColors.card(context),
      surfaceTintColor: AppColors.card(context),
      elevation: AppColors.isDark(context) ? 0 : 10,
      shadowColor: const Color(0x29000000),
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: AppColors.isDark(context)
            ? BorderSide(color: AppColors.border(context))
            : BorderSide.none,
      ),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final o in options) _item(context, o),
      ],
    );
  }

  PopupMenuItem<T> _item(BuildContext context, SortOption<T> o) {
    final isSelected = o.value == selected;
    final tone = isSelected ? AppColors.accent(context) : AppColors.inkSoft(context);
    return PopupMenuItem<T>(
      value: o.value,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accentSoft(context)
                  : AppColors.chip(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(o.icon, size: 18, color: tone),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              o.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? AppColors.accent(context)
                    : AppColors.ink(context),
              ),
            ),
          ),
          // The arrow doubles as the hint that tapping again flips it.
          if (isSelected)
            o.reversible
                ? AnimatedSortIcon(state: _iconState, size: 18)
                : Icon(Icons.check, size: 18, color: AppColors.accent(context)),
        ],
      ),
    );
  }
}
