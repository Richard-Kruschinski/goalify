import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Draws an exercise icon from the asset bundle.
///
/// The exercise icons ship as SVG; raster paths (PNG/JPG) still work so a
/// custom or older icon path keeps rendering.
class ExerciseIcon extends StatelessWidget {
  const ExerciseIcon(this.assetPath, {super.key, this.fit = BoxFit.contain});

  final String assetPath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(assetPath, fit: fit);
    }
    return Image.asset(assetPath, fit: fit);
  }
}
