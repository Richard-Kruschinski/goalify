import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

/// Check in a circle that draws itself when it becomes checked: the icon pops
/// in, the ring is drawn, then the tick (Flutter port of the "animated success
/// checkmark" SVG/CSS: stroke-dashoffset drawing plus a pop-in scale).
///
/// Already checked when first built: shown at once, unless [animateIn] asks
/// for the draw-in (used for checks that are new). Reduced motion: no animation.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({
    required this.checked,
    required this.color,
    this.emptyColor,
    this.size = 14,
    this.animateIn = false,
    super.key,
  });

  final bool checked;
  final Color color;

  /// Ring shown while unchecked; null shows nothing.
  final Color? emptyColor;
  final double size;
  final bool animateIn;

  static const duration = Duration(milliseconds: 1100);

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck> with SingleTickerProviderStateMixin {
  // Timeline of the original CSS (1.1 s): pop-in 0–0.6 s, ring 0.2–0.8 s,
  // tick 0.7–1.1 s, all with the same overshooting cubic-bezier.
  static const _overshoot = Cubic(0.34, 1.56, 0.64, 1);
  static const _total = 1.1;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AnimatedCheck.duration,
    value: widget.checked && !widget.animateIn ? 1 : 0,
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1.1), weight: 80),
    TweenSequenceItem(tween: Tween(begin: 1.1, end: 1), weight: 20),
  ]).animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6 / _total, curve: Curves.easeOut),
  ));

  late final Animation<double> _ring = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2 / _total, 0.8 / _total, curve: _overshoot),
  );

  late final Animation<double> _tick = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.7 / _total, 1, curve: _overshoot),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.checked && widget.animateIn && _controller.value == 0) _play();
  }

  @override
  void didUpdateWidget(AnimatedCheck old) {
    super.didUpdateWidget(old);
    if (widget.checked && !old.checked) _play();
    if (!widget.checked && old.checked) _controller.value = 0;
  }

  void _play() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emptyColor = widget.emptyColor;
    if (!widget.checked && emptyColor == null) return SizedBox.square(dimension: 0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final drawing = widget.checked;
        return Transform.scale(
          scale: drawing ? _scale.value : 1,
          child: CustomPaint(
            size: Size.square(widget.size),
            painter: _CheckPainter(
              ring: drawing ? _ring.value.clamp(0.0, 1.0) : 0,
              tick: drawing ? _tick.value.clamp(0.0, 1.0) : 0,
              color: widget.color,
              emptyColor: emptyColor,
            ),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({
    required this.ring,
    required this.tick,
    required this.color,
    required this.emptyColor,
  });

  final double ring;
  final double tick;
  final Color color;
  final Color? emptyColor;

  // Geometry of the SVG's 100 × 100 viewBox: circle r=40, tick 35,50 → 45,60 → 65,40.
  // The stroke is thicker than the SVG's 6 so it stays readable at 14 px.
  static const _viewBox = 100.0;
  static const _radius = 40.0;
  static const _strokeWidth = 11.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / _viewBox);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const center = Offset(_viewBox / 2, _viewBox / 2);
    final empty = emptyColor;
    if (empty != null && ring < 1) {
      canvas.drawCircle(center, _radius, paint..color = empty);
    }

    paint.color = color;
    final circle = Path()
      ..addArc(Rect.fromCircle(center: center, radius: _radius), 0, 2 * math.pi);
    _drawPortion(canvas, circle, ring, paint);

    final check = Path()
      ..moveTo(35, 50)
      ..lineTo(45, 60)
      ..lineTo(65, 40);
    _drawPortion(canvas, check, tick, paint);
  }

  /// Draws the first [fraction] of [path], like an animated stroke-dashoffset.
  static void _drawPortion(Canvas canvas, Path path, double fraction, Paint paint) {
    if (fraction <= 0) return;
    for (final PathMetric metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * fraction), paint);
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) =>
      old.ring != ring || old.tick != tick || old.color != color || old.emptyColor != emptyColor;
}
