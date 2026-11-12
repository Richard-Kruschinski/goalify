import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Clock face whose hand turns once per [revolution] (the target rest), so a
/// glance shows how much of the planned rest is over. Repaints every frame
/// for a smooth hand; with reduced motion it only follows the parent rebuilds.
class RestClockIcon extends StatefulWidget {
  const RestClockIcon({
    required this.elapsed,
    required this.revolution,
    required this.color,
    this.size = 28,
    super.key,
  });

  /// Read on every frame, so the hand follows the real clock.
  final Duration Function() elapsed;
  final Duration revolution;
  final Color color;
  final double size;

  /// Hand position after [elapsed], as a fraction of one turn (0 = 12 o'clock).
  static double turnFraction(Duration elapsed, Duration revolution) {
    if (revolution <= Duration.zero) return 0;
    return (elapsed.inMicroseconds / revolution.inMicroseconds) % 1;
  }

  @override
  State<RestClockIcon> createState() => _RestClockIconState();
}

class _RestClockIconState extends State<RestClockIcon> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((_) => setState(() {}));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate && !_ticker.isActive) _ticker.start();
    if (!animate && _ticker.isActive) _ticker.stop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(widget.size),
      painter: _ClockPainter(
        turn: RestClockIcon.turnFraction(widget.elapsed(), widget.revolution),
        color: widget.color,
      ),
    );
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.turn, required this.color});

  final double turn;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final stroke = radius * 0.16;
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius - stroke / 2, paint);

    // 12 o'clock mark: where a full rest starts and ends.
    final markTop = center.dy - radius + stroke * 1.9;
    canvas.drawLine(
      Offset(center.dx, markTop),
      Offset(center.dx, markTop + radius * 0.18),
      paint..strokeWidth = stroke * 0.7,
    );

    final angle = turn * 2 * math.pi - math.pi / 2;
    final handLength = radius * 0.55;
    canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * handLength,
      paint..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.turn != turn || old.color != color;
}
