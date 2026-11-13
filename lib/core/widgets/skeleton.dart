import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Shimmer placeholder for content that is really being loaded.
///
/// Show it only while a load is running and replace it as soon as the data is
/// there: no minimum display time. All [SkeletonBox]es below one [Skeleton]
/// share a single animation. With "reduce motion" on, the boxes stand still.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );
  bool _animate = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context);
    if (_animate) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _SkeletonScope(
        animation: _animate ? _controller : null,
        child: widget.child,
      );
}

class _SkeletonScope extends InheritedWidget {
  const _SkeletonScope({required this.animation, required super.child});

  final Animation<double>? animation;

  @override
  bool updateShouldNotify(_SkeletonScope old) => animation != old.animation;
}

/// One grey block of a skeleton. Without width/height it fills the space it
/// is given (and stays empty in unbounded space).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = AppColors.chip(context);
    final highlight =
        Color.alphaBlend(AppColors.ink(context).withValues(alpha: 0.06), base);
    final shape = BorderRadius.circular(radius);
    final animation = context
        .dependOnInheritedWidgetOfExactType<_SkeletonScope>()
        ?.animation;

    if (animation == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: base, borderRadius: shape),
      );
    }
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: shape,
          gradient: LinearGradient(
            colors: [base, highlight, base],
            stops: const [0.3, 0.5, 0.7],
            // Sweeps from left (-1) to right (+1) once per cycle.
            transform: _SlideGradient(animation.value * 2 - 1),
          ),
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.offset);

  final double offset;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * offset, 0, 0);
}

/// Placeholder list in the shape of the app's list cards (Daily tasks, Gym
/// exercises/days/splits): 48 px icon tile, title and subtitle line.
class SkeletonCardList extends StatelessWidget {
  const SkeletonCardList({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow(context),
          ),
          child: Row(
            children: [
              const SkeletonBox(width: 48, height: 48, radius: 12),
              const SizedBox(width: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: c.maxWidth * 0.6, height: 14),
                      const SizedBox(height: 8),
                      SkeletonBox(width: c.maxWidth * 0.35, height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
