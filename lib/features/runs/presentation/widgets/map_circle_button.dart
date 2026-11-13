import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Round button floating over the map (back, settings, compass, recenter).
class MapCircleButton extends StatelessWidget {
  const MapCircleButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.tooltip,
  });

  /// Usually an [Icon]; plain icons take the ink color.
  final Widget child;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context).withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        tooltip: tooltip,
        color: AppColors.ink(context),
        onPressed: onPressed,
        icon: child,
      ),
    );
  }
}
