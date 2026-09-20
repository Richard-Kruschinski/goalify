import 'package:flutter/material.dart';

/// Custom gym icons (Push / Pull / Cardio) drawn with CustomPainter.
/// They are stored in the day-icon map using negative sentinel codes,
/// which can never collide with Material IconData codePoints.
class GymIcons {
  static const int push = -1;
  static const int pull = -2;
  static const int cardio = -3;

  static const List<int> all = [push, pull, cardio];

  static bool isCustom(int? code) => code != null && code < 0;

  static Widget icon(int code, {double size = 24, required Color color}) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CustomPaint(
          size: Size.square(size),
          painter: _GymIconPainter(code: code, color: color),
        ),
      ),
    );
  }
}

class _GymIconPainter extends CustomPainter {
  const _GymIconPainter({required this.code, required this.color});

  final int code;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // All shapes are defined on a 64x64 grid.
    canvas.scale(size.shortestSide / 64);

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;

    switch (code) {
      case GymIcons.push:
        _paintPush(canvas, stroke, fill);
        break;
      case GymIcons.pull:
        _paintPull(canvas, stroke, fill);
        break;
      case GymIcons.cardio:
        _paintCardio(canvas, stroke);
        break;
    }
  }

  // Bench bar at the bottom, arrow pressing up and away.
  void _paintPush(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawRRect(
      RRect.fromLTRBR(17, 49, 47, 54.5, const Radius.circular(2.75)),
      fill,
    );
    final arrow = Path()
      ..moveTo(32, 9)
      ..lineTo(45, 25.5)
      ..lineTo(38.2, 25.5)
      ..lineTo(38.2, 42)
      ..lineTo(25.8, 42)
      ..lineTo(25.8, 25.5)
      ..lineTo(19, 25.5)
      ..close();
    canvas.drawPath(arrow, stroke);
  }

  // Bar at the top, arrow pulling down (lat pulldown).
  void _paintPull(Canvas canvas, Paint stroke, Paint fill) {
    canvas.drawRRect(
      RRect.fromLTRBR(17, 9.5, 47, 15, const Radius.circular(2.75)),
      fill,
    );
    final arrow = Path()
      ..moveTo(32, 55)
      ..lineTo(19, 38.5)
      ..lineTo(25.8, 38.5)
      ..lineTo(25.8, 22)
      ..lineTo(38.2, 22)
      ..lineTo(38.2, 38.5)
      ..lineTo(45, 38.5)
      ..close();
    canvas.drawPath(arrow, stroke);
  }

  // Heart outline with a pulse line.
  void _paintCardio(Canvas canvas, Paint stroke) {
    final heart = Path()
      ..moveTo(32, 52)
      ..cubicTo(21, 43.5, 13, 36, 13, 27)
      ..cubicTo(13, 20, 18, 15, 24.2, 15)
      ..cubicTo(27.6, 15, 30.6, 16.7, 32, 19.5)
      ..cubicTo(33.4, 16.7, 36.4, 15, 39.8, 15)
      ..cubicTo(46, 15, 51, 20, 51, 27)
      ..cubicTo(51, 36, 43, 43.5, 32, 52)
      ..close();
    canvas.drawPath(heart, stroke);

    final pulse = Path()
      ..moveTo(20.5, 29.5)
      ..lineTo(26.5, 29.5)
      ..lineTo(29.5, 24)
      ..lineTo(34.5, 35)
      ..lineTo(37.5, 29.5)
      ..lineTo(43.5, 29.5);
    canvas.drawPath(pulse, stroke);
  }

  @override
  bool shouldRepaint(_GymIconPainter oldDelegate) =>
      oldDelegate.code != code || oldDelegate.color != color;
}
