import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'progress_screen.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/tool_hue.dart';

/// Shown once all of today's tasks are done.
///
/// The color comes from the app itself: confetti and the medal ring use the
/// hues of every part of the day (tomato focus, violet blocker, amber music,
/// green intervals, frost blue), and the medal carries the day's count.
class CongratsScreen extends StatefulWidget {
  const CongratsScreen({
    super.key,
    this.title,
    this.subtitle,
    this.detail,
    this.tasksDone,
    this.onSeeProgress,
  });

  /// Fall back to the localized defaults when null.
  final String? title;
  final String? subtitle;
  final String? detail;

  /// Tasks finished today, shown on the medal; a trophy when null.
  final int? tasksDone;
  final VoidCallback? onSeeProgress;

  @override
  State<CongratsScreen> createState() => _CongratsScreenState();
}

class _CongratsScreenState extends State<CongratsScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _left;
  late final ConfettiController _right;
  late final ConfettiController _top;
  late final AnimationController _enter;
  late final AnimationController _medal;

  @override
  void initState() {
    super.initState();
    _left = ConfettiController(duration: const Duration(milliseconds: 1600));
    _right = ConfettiController(duration: const Duration(milliseconds: 1600));
    _top = ConfettiController(duration: const Duration(seconds: 3));
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _medal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Side cannons first, then the medal lands and the shower follows.
    _left.play();
    _right.play();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _medal.forward();
    });
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _top.play();
    });
  }

  @override
  void dispose() {
    _left.dispose();
    _right.dispose();
    _top.dispose();
    _enter.dispose();
    _medal.dispose();
    super.dispose();
  }

  /// Every hue of the app, vivid enough to read on the dimmed backdrop.
  static const List<Color> _party = [
    Color(0xFFE5534B), // focus tomato
    Color(0xFF9D86E3), // blocker violet
    Color(0xFFE7B23F), // music amber
    Color(0xFF5BB57A), // interval green
    Color(0xFF6A9FD8), // frost blue
  ];

  Widget _cannon(ConfettiController c, Alignment at, double direction) {
    return Align(
      alignment: at,
      child: ConfettiWidget(
        confettiController: c,
        blastDirectionality: BlastDirectionality.directional,
        blastDirection: direction,
        colors: _party,
        numberOfParticles: 24,
        emissionFrequency: 0.22,
        minBlastForce: 40,
        maxBlastForce: 80,
        gravity: 0.22,
        minimumSize: const Size(8, 5),
        maximumSize: const Size(16, 8),
        shouldLoop: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = AppColors.isDark(context);
    final amber = ToolHue.music.of(context);
    final fade = CurvedAnimation(parent: _enter, curve: Curves.easeOutCubic);
    final medalIn = CurvedAnimation(parent: _medal, curve: Curves.easeOutBack);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      body: Stack(
        children: [
          // Confetti behind and in front of the card.
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  _cannon(_left, Alignment.bottomLeft, -math.pi / 3),
                  _cannon(_right, Alignment.bottomRight, -2 * math.pi / 3),
                  Align(
                    alignment: Alignment.topCenter,
                    child: ConfettiWidget(
                      confettiController: _top,
                      blastDirectionality: BlastDirectionality.explosive,
                      colors: _party,
                      numberOfParticles: 18,
                      emissionFrequency: 0.12,
                      gravity: 0.18,
                      minimumSize: const Size(6, 4),
                      maximumSize: const Size(12, 6),
                      shouldLoop: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(fade),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  constraints: const BoxConstraints(maxWidth: 380),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(24),
                    border: dark ? Border.all(color: AppColors.border(context)) : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // The moment: a medal in a warm band, ringed by every
                      // color of the day.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        color: amber.withValues(alpha: dark ? 0.14 : 0.12),
                        child: Center(
                          child: AnimatedBuilder(
                            animation: medalIn,
                            builder: (context, child) => Transform.rotate(
                              angle: (1 - medalIn.value) * -0.5,
                              child: Transform.scale(
                                scale: 0.4 + 0.6 * medalIn.value,
                                child: Opacity(
                                  opacity: _medal.value.clamp(0.0, 1.0),
                                  child: child,
                                ),
                              ),
                            ),
                            child: _Medal(
                              colors: _party,
                              gold: amber,
                              count: widget.tasksDone,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          children: [
                            Text(
                              widget.title ?? l10n.congratsTitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.subtitle ?? l10n.congratsSubtitle,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.ink(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.detail ?? l10n.congratsMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: AppColors.muted(context),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // A strip of the day's colors under the text.
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final c in _party)
                                  Container(
                                    width: 24,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: c,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                if (widget.onSeeProgress != null) {
                                  widget.onSeeProgress!.call();
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ProgressScreen(),
                                    ),
                                  );
                                }
                              },
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: AppColors.accent(context),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(l10n.showProgress),
                            ),
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                foregroundColor: AppColors.muted(context),
                              ),
                              child: Text(l10n.close),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rosette medal drawn in code: two ribbon tails, a ring of colored
/// segments and a gold disc with the day's count (or a trophy).
class _Medal extends StatelessWidget {
  const _Medal({required this.colors, required this.gold, this.count});

  final List<Color> colors;
  final Color gold;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final onGold = AppColors.isDark(context) ? AppColors.darkBg : Colors.white;
    return SizedBox(
      width: 136,
      height: 152,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _MedalPainter(colors: colors, gold: gold)),
          ),
          Positioned(
            top: 0,
            child: SizedBox(
              width: 136,
              height: 136,
              child: Center(
                child: count == null
                    ? Icon(Icons.emoji_events_rounded, size: 44, color: onGold)
                    : TweenAnimationBuilder<int>(
                        tween: IntTween(begin: 0, end: count!),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => Text(
                          '$value',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w600,
                            color: onGold,
                            height: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MedalPainter extends CustomPainter {
  _MedalPainter({required this.colors, required this.gold});

  final List<Color> colors;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.width / 2);
    final outer = size.width / 2;

    // Ribbon tails behind the medal, in the first two colors.
    void tail(double dx, Color color) {
      final path = Path()
        ..moveTo(center.dx + dx - 14, center.dy + 20)
        ..lineTo(center.dx + dx + 14, center.dy + 20)
        ..lineTo(center.dx + dx * 1.9 + 14, size.height)
        ..lineTo(center.dx + dx * 1.9, size.height - 10)
        ..lineTo(center.dx + dx * 1.9 - 14, size.height)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    tail(-20, colors[0]);
    tail(20, colors[1]);

    // Ring of colored segments with small gaps.
    const segments = 15;
    const gap = 0.06;
    final ringWidth = outer * 0.2;
    final ringRect = Rect.fromCircle(
      center: center,
      radius: outer - ringWidth / 2,
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth;
    const sweep = 2 * math.pi / segments;
    for (var i = 0; i < segments; i++) {
      ring.color = colors[i % colors.length];
      canvas.drawArc(ringRect, -math.pi / 2 + i * sweep + gap / 2, sweep - gap, false, ring);
    }

    // Gold disc: a soft tone shift inside the amber.
    final discRadius = outer - ringWidth - 4;
    final hsl = HSLColor.fromColor(gold);
    final disc = Paint()
      ..shader = RadialGradient(
        colors: [
          hsl.withLightness((hsl.lightness + 0.08).clamp(0.0, 1.0)).toColor(),
          hsl.withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0)).toColor(),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: discRadius));
    canvas.drawCircle(center, discRadius, disc);
    canvas.drawCircle(
      center,
      discRadius - 6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant _MedalPainter old) =>
      old.gold != gold || old.colors != colors;
}
