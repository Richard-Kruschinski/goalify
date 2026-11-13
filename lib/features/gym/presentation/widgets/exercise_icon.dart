import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/skeleton.dart';

/// Draws an exercise icon from the asset bundle.
///
/// The exercise icons ship as SVG; raster paths (PNG/JPG) still work so a
/// custom or older icon path keeps rendering.
///
/// The silhouettes are black, which disappears on the dark icon tile, so in
/// dark mode they are tinted light. Light mode shows them unchanged.
class ExerciseIcon extends StatelessWidget {
  const ExerciseIcon(this.assetPath, {super.key, this.fit = BoxFit.contain});

  final String assetPath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.isDark(context) ? AppColors.inkSoft(context) : null;
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        fit: fit,
        colorFilter: tint == null ? null : ColorFilter.mode(tint, BlendMode.srcIn),
        // Large SVGs take a moment to parse the first time; afterwards they
        // come from the cache and this never shows.
        placeholderBuilder: (_) => const Skeleton(child: SkeletonBox()),
      );
    }
    return Image.asset(
      assetPath,
      fit: fit,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.srcIn,
    );
  }
}
