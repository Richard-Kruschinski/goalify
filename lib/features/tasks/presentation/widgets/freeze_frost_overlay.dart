import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Lays a one-shot "freezing over" effect on top of [child] whenever
/// [trigger] changes: frost crystals grow in from the edges, the area takes on
/// an icy tint and a snowflake bursts from the centre, then everything fades
/// and leaves the plain frozen state underneath.
///
/// Only a change of [trigger] plays it, so a rebuild of an already frozen day
/// stays still. The overlay ignores touches and is skipped when the platform
/// asks for reduced motion.
class FreezeFrostOverlay extends StatefulWidget {
  const FreezeFrostOverlay({
    super.key,
    required this.trigger,
    required this.child,
    this.startDelay = const Duration(milliseconds: 220),
  });

  /// Bump this to play the animation once.
  final int trigger;
  final Widget child;

  /// Lets a sheet or dialog that spent the token slide away first.
  final Duration startDelay;

  @override
  State<FreezeFrostOverlay> createState() => _FreezeFrostOverlayState();
}

class _FreezeFrostOverlayState extends State<FreezeFrostOverlay>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 1500);

  late final AnimationController _controller =
      AnimationController(vsync: this, duration: _duration)
        ..addStatusListener((_) => setState(() {}));
  Timer? _delay;
  _FrostPattern? _pattern;

  @override
  void didUpdateWidget(FreezeFrostOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) _play();
  }

  void _play() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _delay?.cancel();
    _delay = Timer(widget.startDelay, () {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = _controller.isAnimating;
    return Stack(
      children: [
        widget.child,
        if (running)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    if (_pattern?.size != size) {
                      _pattern = _FrostPattern.generate(size);
                    }
                    return CustomPaint(
                      size: size,
                      painter: _FrostPainter(
                        progress: _controller,
                        pattern: _pattern!,
                        palette: _FrostPalette.of(context),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Colours per theme. Light mode needs a deeper blue, white frost would
/// vanish on the white cards; dark mode gets the classic icy white.
class _FrostPalette {
  const _FrostPalette({
    required this.frost,
    required this.glow,
    required this.tint,
    required this.edge,
  });

  final Color frost;
  final Color glow;
  final Color tint;
  final Color edge;

  static _FrostPalette of(BuildContext context) {
    final info = AppColors.info(context);
    if (AppColors.isDark(context)) {
      return _FrostPalette(
        frost: const Color(0xFFE4F1FF),
        glow: const Color(0xFF9CC8F5),
        tint: info,
        edge: const Color(0xFF9CC8F5),
      );
    }
    return _FrostPalette(
      frost: const Color(0xFF6FA6DE),
      glow: const Color(0xFFBFDAF5),
      tint: info,
      edge: const Color(0xFF8DBBE8),
    );
  }
}

/// One straight piece of a crystal. [d0] and [d1] are the growth distance at
/// which it starts and finishes, so crystals grow outward from their root.
class _Segment {
  const _Segment(this.a, this.b, this.d0, this.d1, this.depth);

  final Offset a;
  final Offset b;
  final double d0;
  final double d1;
  final int depth;
}

class _Flake {
  const _Flake(this.angle, this.distance, this.size, this.spin);

  final double angle;
  final double distance;
  final double size;
  final double spin;
}

/// Crystal layout for one size. Seeded, so the same screen always freezes the
/// same way and nothing is rebuilt per frame.
class _FrostPattern {
  _FrostPattern(this.size, this.segments, this.flakes, this.reach);

  final Size size;
  final List<_Segment> segments;
  final List<_Flake> flakes;

  /// Growth distance at which the last segment is done.
  final double reach;

  static _FrostPattern generate(Size size) {
    final rnd = math.Random(7);
    final segments = <_Segment>[];
    final w = size.width;
    final h = size.height;
    final shortSide = math.min(w, h);
    final baseLen = (shortSide * 0.2).clamp(40.0, 120.0);

    double rand(double lo, double hi) => lo + rnd.nextDouble() * (hi - lo);

    void branch(Offset p, double angle, double len, int depth, double d) {
      final steps = depth == 0 ? 4 : (depth == 1 ? 3 : 2);
      final stepLen = len / steps;
      var pos = p;
      var dist = d;
      var a = angle;
      for (var i = 0; i < steps; i++) {
        a += rand(-0.12, 0.12);
        final next = pos + Offset(math.cos(a), math.sin(a)) * stepLen;
        segments.add(_Segment(pos, next, dist, dist + stepLen, depth));
        dist += stepLen;
        pos = next;
        if (depth < 2 && i < steps - 1) {
          final sideLen = len * (depth == 0 ? 0.42 : 0.5) * (1 - i / steps);
          for (final sign in const [-1.0, 1.0]) {
            if (rnd.nextDouble() < 0.85) {
              branch(pos, a + sign * rand(0.9, 1.15), sideLen, depth + 1, dist);
            }
          }
        }
      }
    }

    void crystal(Offset root, double inward, double scale) {
      final len = baseLen * scale * rand(0.6, 1.15);
      branch(root, inward + rand(-0.45, 0.45), len, 0, rand(0, baseLen * 0.5));
    }

    // Seeds along all four edges, pointing inward.
    const spacing = 34.0;
    for (var x = rand(0, spacing); x < w; x += spacing * rand(0.7, 1.3)) {
      crystal(Offset(x, 0), math.pi / 2, 1);
      crystal(Offset(x, h), -math.pi / 2, 1);
    }
    for (var y = rand(0, spacing); y < h; y += spacing * rand(0.7, 1.3)) {
      crystal(Offset(0, y), 0, 1);
      crystal(Offset(w, y), math.pi, 1);
    }
    // Heavier growth in the corners, like frost on a window pane.
    final corners = <(Offset, double)>[
      (Offset.zero, math.pi / 4),
      (Offset(w, 0), 3 * math.pi / 4),
      (Offset(0, h), -math.pi / 4),
      (Offset(w, h), -3 * math.pi / 4),
    ];
    for (final (corner, inward) in corners) {
      for (var i = 0; i < 3; i++) {
        crystal(corner, inward, 1.7);
      }
    }

    var reach = 0.0;
    for (final s in segments) {
      if (s.d1 > reach) reach = s.d1;
    }

    final flakes = <_Flake>[
      for (var i = 0; i < 12; i++)
        _Flake(
          i * math.pi * 2 / 12 + rand(-0.2, 0.2),
          shortSide * rand(0.28, 0.48),
          rand(6, 12),
          rand(-1.5, 1.5),
        ),
    ];

    return _FrostPattern(size, segments, flakes, reach);
  }
}

class _FrostPainter extends CustomPainter {
  _FrostPainter({
    required this.progress,
    required this.pattern,
    required this.palette,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final _FrostPattern pattern;
  final _FrostPalette palette;

  static double _seg(double t, double start, double end) =>
      ((t - start) / (end - start)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final grow = Curves.easeOutCubic.transform(_seg(t, 0, 0.5));
    final fade = 1 - Curves.easeIn.transform(_seg(t, 0.68, 1));
    if (fade <= 0) return;

    _paintTint(canvas, size, grow, fade);
    _paintEdges(canvas, size, grow, fade);
    _paintCrystals(canvas, grow, fade);
    _paintBurst(canvas, size, t, fade);
  }

  /// Cool wash over the cards.
  void _paintTint(Canvas canvas, Size size, double grow, double fade) {
    final alpha = 0.14 * grow * fade;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = palette.tint.withValues(alpha: alpha),
    );
  }

  /// Soft frosted bands along the edges, the frame of the window pane.
  void _paintEdges(Canvas canvas, Size size, double grow, double fade) {
    final depth = math.min(size.shortestSide * 0.22, 90.0) * grow;
    if (depth <= 0) return;
    final c = palette.edge.withValues(alpha: 0.45 * fade);
    final clear = palette.edge.withValues(alpha: 0);
    void band(Rect rect, Alignment from, Alignment to) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(begin: from, end: to, colors: [c, clear])
              .createShader(rect),
      );
    }

    final w = size.width;
    final h = size.height;
    band(Rect.fromLTWH(0, 0, w, depth), Alignment.topCenter,
        Alignment.bottomCenter);
    band(Rect.fromLTWH(0, h - depth, w, depth), Alignment.bottomCenter,
        Alignment.topCenter);
    band(Rect.fromLTWH(0, 0, depth, h), Alignment.centerLeft,
        Alignment.centerRight);
    band(Rect.fromLTWH(w - depth, 0, depth, h), Alignment.centerRight,
        Alignment.centerLeft);
  }

  void _paintCrystals(Canvas canvas, double grow, double fade) {
    final reach = grow * pattern.reach;
    final paths = [Path(), Path(), Path()];
    for (final s in pattern.segments) {
      if (reach <= s.d0) continue;
      final f = ((reach - s.d0) / (s.d1 - s.d0)).clamp(0.0, 1.0);
      final end = Offset.lerp(s.a, s.b, f)!;
      paths[s.depth]
        ..moveTo(s.a.dx, s.a.dy)
        ..lineTo(end.dx, end.dy);
    }
    const widths = [2.2, 1.4, 0.9];
    for (var d = 0; d < 3; d++) {
      // Wide faint stroke first as a glow, then the crisp crystal on top.
      canvas.drawPath(
        paths[d],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = widths[d] * 3
          ..color = palette.glow.withValues(alpha: 0.25 * fade),
      );
      canvas.drawPath(
        paths[d],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = widths[d]
          ..color = palette.frost.withValues(alpha: 0.9 * fade),
      );
    }
  }

  /// Ring, big snowflake and small flakes flying out from the centre.
  void _paintBurst(Canvas canvas, Size size, double t, double fade) {
    final b = _seg(t, 0.12, 0.75);
    if (b <= 0 || b >= 1) return;
    final center = size.center(Offset.zero);
    final shortSide = size.shortestSide;

    // Shock ring.
    final ring = Curves.easeOutCubic.transform(b);
    canvas.drawCircle(
      center,
      shortSide * 0.5 * ring,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - ring) + 0.5
        ..color = palette.frost.withValues(alpha: 0.6 * (1 - ring) * fade),
    );

    // Central flake: pops in, turns a little, then fades.
    final pop = Curves.easeOutBack.transform(_seg(t, 0.12, 0.4));
    final out = 1 - _seg(t, 0.45, 0.75);
    final bigAlpha = (pop.clamp(0.0, 1.0) * out * fade).clamp(0.0, 1.0);
    if (bigAlpha > 0) {
      _snowflake(
        canvas,
        center,
        math.min(shortSide * 0.16, 56.0) * pop,
        math.pi / 6 * b,
        palette.frost.withValues(alpha: bigAlpha),
        palette.glow.withValues(alpha: 0.4 * bigAlpha),
      );
    }

    // Small flakes.
    final fly = Curves.easeOutCubic.transform(b);
    final flakeAlpha = (1 - Curves.easeIn.transform(b)) * fade;
    for (final f in pattern.flakes) {
      final pos = center +
          Offset(math.cos(f.angle), math.sin(f.angle)) * (f.distance * fly);
      _snowflake(
        canvas,
        pos,
        f.size,
        f.spin * b,
        palette.frost.withValues(alpha: flakeAlpha),
        palette.glow.withValues(alpha: 0.4 * flakeAlpha),
      );
    }
  }

  /// Six arms, each with a small V near its tip.
  void _snowflake(Canvas canvas, Offset c, double r, double rotation,
      Color color, Color glow) {
    if (r <= 0) return;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = rotation + i * math.pi / 3;
      final dir = Offset(math.cos(a), math.sin(a));
      final tip = c + dir * r;
      path
        ..moveTo(c.dx, c.dy)
        ..lineTo(tip.dx, tip.dy);
      final joint = c + dir * (r * 0.6);
      for (final s in const [-1.0, 1.0]) {
        final ba = a + s * math.pi / 4;
        final end = joint + Offset(math.cos(ba), math.sin(ba)) * (r * 0.32);
        path
          ..moveTo(joint.dx, joint.dy)
          ..lineTo(end.dx, end.dy);
      }
    }
    final width = math.max(1.0, r * 0.11);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 3
        ..color = glow,
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_FrostPainter old) =>
      old.pattern != pattern || old.palette.frost != palette.frost;
}
