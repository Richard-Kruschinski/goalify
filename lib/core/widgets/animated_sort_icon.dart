import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// What a sort button currently shows.
enum SortIconState {
  /// Hand-made order: muted double arrow (up + down).
  none,

  /// Accent arrow pointing up.
  ascending,

  /// Accent arrow pointing down.
  descending,
}

/// Sort icon that morphs between [SortIconState]s instead of swapping glyphs.
///
/// - none ↔ up/down: the matching arrow of the double arrow slides to the
///   centre and grows, the other one fades out in place (and back).
/// - up ↔ down: the single arrow turns half a circle, always clockwise.
/// - the colour blends between muted and accent with the same timing.
///
/// Only a change of [state] animates. A new State (e.g. after `MainNav`
/// rebuilt the tab) starts on the final picture, and with [animate] false or
/// reduced motion the icon jumps. Details: docs/sort-icon-animation.md.
class AnimatedSortIcon extends StatefulWidget {
  const AnimatedSortIcon({
    super.key,
    required this.state,
    this.size = 24,
    this.color,
    this.animate = true,
    this.duration = const Duration(milliseconds: 300),
  });

  final SortIconState state;
  final double size;

  /// Overrides the default (muted for [SortIconState.none], accent otherwise).
  final Color? color;

  /// False lets a state change jump, e.g. while the saved sort is loading.
  final bool animate;
  final Duration duration;

  @override
  State<AnimatedSortIcon> createState() => _AnimatedSortIconState();
}

class _AnimatedSortIconState extends State<AnimatedSortIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration, value: 1);
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

  late List<_ArrowPose> _from = _restPoses(widget.state);
  late List<_ArrowPose> _to = _from;
  Color? _fromColor;

  @override
  void didUpdateWidget(AnimatedSortIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
    if (oldWidget.state == widget.state) return;

    final current = _lerpPoses(_from, _to, _curve.value);
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!widget.animate || reduceMotion) {
      _from = _to = _targetPoses(widget.state, current);
      _fromColor = null;
      _controller.value = 1;
      return;
    }
    _fromColor = Color.lerp(
      _fromColor ?? _colorFor(oldWidget),
      _colorFor(oldWidget),
      _curve.value,
    );
    _from = current;
    _to = _targetPoses(widget.state, current);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  Color _colorFor(AnimatedSortIcon w) =>
      w.color ??
      (w.state == SortIconState.none
          ? AppColors.muted(context)
          : AppColors.accent(context));

  @override
  Widget build(BuildContext context) {
    final target = _colorFor(widget);
    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(
        painter: _SortIconPainter(
          animation: _curve,
          from: _from,
          to: _to,
          fromColor: _fromColor ?? target,
          toColor: target,
        ),
      ),
    );
  }
}

// ----------------------------- Geometry -----------------------------
// All values in a 24×24 box (like a Material icon), centre (12, 12).
// Angle 0 points up, π points down; turning is clockwise.

const double _up = 0;
const double _down = math.pi;

const _pairUp = _ArrowPose(angle: _up, dx: -3.5, dy: -2, length: 12, head: 4);
const _pairDown =
    _ArrowPose(angle: _down, dx: 3.5, dy: 2, length: 12, head: 4);
const _single = _ArrowPose(angle: _up, dx: 0, dy: 0, length: 15, head: 6.5);

@immutable
class _ArrowPose {
  const _ArrowPose({
    required this.angle,
    required this.dx,
    required this.dy,
    required this.length,
    required this.head,
    this.opacity = 1,
  });

  final double angle;
  final double dx;
  final double dy;
  final double length;
  final double head;
  final double opacity;

  _ArrowPose copyWith({double? angle, double? opacity, double? scale}) {
    final s = scale ?? 1;
    return _ArrowPose(
      angle: angle ?? this.angle,
      dx: dx,
      dy: dy,
      length: length * s,
      head: head * s,
      opacity: opacity ?? this.opacity,
    );
  }

  static _ArrowPose lerp(_ArrowPose a, _ArrowPose b, double t) => _ArrowPose(
        angle: _lerp(a.angle, b.angle, t),
        dx: _lerp(a.dx, b.dx, t),
        dy: _lerp(a.dy, b.dy, t),
        length: _lerp(a.length, b.length, t),
        head: _lerp(a.head, b.head, t),
        opacity: _lerp(a.opacity, b.opacity, t).clamp(0.0, 1.0),
      );
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

List<_ArrowPose> _lerpPoses(
  List<_ArrowPose> a,
  List<_ArrowPose> b,
  double t,
) =>
    [for (var i = 0; i < a.length; i++) _ArrowPose.lerp(a[i], b[i], t)];

/// Picture of [state] without any history; slot 0 is the "up" arrow.
List<_ArrowPose> _restPoses(SortIconState state) => switch (state) {
      SortIconState.none => const [_pairUp, _pairDown],
      SortIconState.ascending => [_single, _hidden(_pairDown)],
      SortIconState.descending => [
          _hidden(_pairUp),
          _single.copyWith(angle: _down),
        ],
    };

/// An arrow that is gone: invisible and a bit smaller, so it fades in or
/// out while shrinking/growing in place.
_ArrowPose _hidden(_ArrowPose p) => p.copyWith(opacity: 0, scale: 0.5);

/// [direction] shifted by whole turns to the copy nearest [from]; on a tie
/// (exactly half a turn away) it turns clockwise.
double _nearestAngle(double from, double direction) {
  const turn = 2 * math.pi;
  final k = ((from - direction) / turn).roundToDouble();
  var a = direction + k * turn;
  if ((a - from) < -math.pi + 1e-6) a += turn;
  return a;
}

double _angularDistance(double a, double b) =>
    (_nearestAngle(a, b) - a).abs();

/// End poses for [state], matched slot by slot to [current] so every arrow
/// travels the shortest believable way (also when interrupted mid-way).
List<_ArrowPose> _targetPoses(SortIconState state, List<_ArrowPose> current) {
  // The most visible arrow leads; on equal opacity slot 0 wins.
  final lead = current[1].opacity > current[0].opacity + 0.01 ? 1 : 0;
  final other = 1 - lead;
  final result = List<_ArrowPose>.filled(2, _single);

  if (state == SortIconState.none) {
    final leadAngle = current[lead].angle;
    final leadIsUp = _angularDistance(leadAngle, _up) <=
        _angularDistance(leadAngle, _down);
    final leadTarget = leadIsUp ? _pairUp : _pairDown;
    final otherTarget = leadIsUp ? _pairDown : _pairUp;
    result[lead] =
        leadTarget.copyWith(angle: _nearestAngle(leadAngle, leadTarget.angle));
    result[other] = otherTarget.copyWith(
      angle: _nearestAngle(current[other].angle, otherTarget.angle),
    );
    _snapIfHidden(current, other, result[other]);
    return result;
  }

  final direction = state == SortIconState.ascending ? _up : _down;
  // Among the visible arrows, the one already pointing the right way moves
  // to the centre; with only one visible arrow, that one turns around.
  var mover = lead;
  if (current[other].opacity > 0.5 &&
      _angularDistance(current[other].angle, direction) <
          _angularDistance(current[lead].angle, direction)) {
    mover = 1 - lead;
  }
  final rest = 1 - mover;
  result[mover] = _single.copyWith(
    angle: _nearestAngle(current[mover].angle, direction),
  );
  result[rest] = _hidden(current[rest]);
  _snapIfHidden(current, mover, result[mover]);
  return result;
}

/// An invisible arrow must not visibly fly or spin into place: it starts
/// small at its target spot instead.
void _snapIfHidden(List<_ArrowPose> current, int slot, _ArrowPose target) {
  if (current[slot].opacity < 0.05) {
    current[slot] = _hidden(target);
  }
}

// ----------------------------- Painting -----------------------------

class _SortIconPainter extends CustomPainter {
  _SortIconPainter({
    required this.animation,
    required this.from,
    required this.to,
    required this.fromColor,
    required this.toColor,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final List<_ArrowPose> from;
  final List<_ArrowPose> to;
  final Color fromColor;
  final Color toColor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final color = Color.lerp(fromColor, toColor, t)!;
    final scale = size.shortestSide / 24;
    canvas.save();
    canvas.scale(scale);
    for (final pose in _lerpPoses(from, to, t)) {
      if (pose.opacity <= 0.001) continue;
      _paintArrow(canvas, pose, color);
    }
    canvas.restore();
  }

  void _paintArrow(Canvas canvas, _ArrowPose p, Color color) {
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * p.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final half = p.length / 2;
    // Arrow pointing up around the origin; the canvas turns it.
    final path = Path()
      ..moveTo(0, half)
      ..lineTo(0, -half)
      ..moveTo(-p.head, -half + p.head)
      ..lineTo(0, -half)
      ..lineTo(p.head, -half + p.head);
    canvas.save();
    canvas.translate(12 + p.dx, 12 + p.dy);
    canvas.rotate(p.angle);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SortIconPainter old) =>
      old.from != from ||
      old.to != to ||
      old.fromColor != fromColor ||
      old.toColor != toColor ||
      old.animation != animation;
}
