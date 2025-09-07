import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

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
    final cs = Theme.of(context).colorScheme;

    final scaleAnim = CurvedAnimation(
      parent: _scale,
      curve: Curves.easeOutBack, // pop!
    );

    return Scaffold(
      backgroundColor: Colors.black54, // dimmer, damit es “vorne” wirkt
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Zentrale Karte
          ScaleTransition(
            scale: scaleAnim,
            child: Center(
              child: Container(
                // groß & mittig
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Goldene Trophäe
                    _GoldTrophy(
                      size: 140,
                      twinkle: _twinkle,
                    ),
                    const SizedBox(height: 16),
                    // Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.detail,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onSeeProgress?.call();
                          },
                          child: const Text('See progress'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Konfetti im ganzen Screen
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
                const Color(0xFFFFF3E0).withOpacity(0.8),
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
                color: Colors.white.withOpacity(0.85),
              ),
            );
          },
        ),
      ],
    );
  }
}
