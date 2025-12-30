import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'progress_screen.dart';

class CongratsScreen extends StatefulWidget {
  const CongratsScreen({
    super.key,
    this.title = 'CONGRATS!',
    this.subtitle = 'You finished all tasks for today',
    this.detail = 'Well done — keep up the streaks!',
    this.onSeeProgress,
  });

  final String title;
  final String subtitle;
  final String detail;
  final VoidCallback? onSeeProgress;

  @override
  State<CongratsScreen> createState() => _CongratsScreenState();
}

class _CongratsScreenState extends State<CongratsScreen>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scale;
  late final AnimationController _twinkle;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))..play();

    // "Groß aufploppen" – leichte Überschwingung
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();

    // kleines Funkeln auf der Trophäe
    _twinkle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scale.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scaleAnim = CurvedAnimation(
      parent: _scale,
      curve: Curves.easeOutBack, // pop!
    );

    return Scaffold(
      backgroundColor: const Color(0xCC000000),
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: ScaleTransition(
                scale: scaleAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _GoldTrophy(size: 140, twinkle: _twinkle),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE53935).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1D1F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.detail,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE0E0E0)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Close'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                if (widget.onSeeProgress != null) {
                                  widget.onSeeProgress!.call();
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => const ProgressScreen()),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text(
                                'See progress',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                numberOfParticles: 22,
                emissionFrequency: 0.07,
                gravity: 0.35,
                minBlastForce: 6,
                maxBlastForce: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Goldene Trophäe mit Verlauf + leichtem Glanz/Funkeln
class _GoldTrophy extends StatelessWidget {
  const _GoldTrophy({
    required this.size,
    required this.twinkle,
  });

  final double size;
  final AnimationController twinkle;

  @override
  Widget build(BuildContext context) {
    // Warme Goldtöne
    const gold = [
      Color(0xFFFFF7C2), // hell
      Color(0xFFFFE082),
      Color(0xFFFFC107),
      Color(0xFFFFA000), // dunkel
    ];

    return Stack(
      alignment: Alignment.center,
      children: [
        // weiches Glühen hinter der Trophäe
        Container(
          width: size + 46,
          height: size + 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFF3E0).withValues(alpha: 0.8),
                const Color(0x00FFF3E0),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
        // Icon mit Gold-Verlauf
        ShaderMask(
          shaderCallback: (rect) =>
              const LinearGradient(colors: gold, begin: Alignment.topLeft, end: Alignment.bottomRight)
                  .createShader(rect),
          blendMode: BlendMode.srcIn,
          child: Icon(
            Icons.emoji_events_rounded,
            size: size,
          ),
        ),
        // kleines “twinkle” – bewegt sich sanft hoch/runter
        AnimatedBuilder(
          animation: twinkle,
          builder: (_, __) {
            final dy = (twinkle.value - 0.5) * 8; // -4..+4 px
            return Transform.translate(
              offset: Offset(0, dy),
              child: Icon(
                Icons.star_rounded,
                size: size * 0.18,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            );
          },
        ),
      ],
    );
  }
}
