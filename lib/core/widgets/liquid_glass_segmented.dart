import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/app_colors.dart';

/// One segment of a [LiquidGlassSegmented].
class LiquidGlassSegment<T> {
  const LiquidGlassSegment({
    required this.value,
    required this.icon,
    required this.label,
  });

  final T value;
  final IconData icon;
  final String label;
}

/// Segmented pill whose selection is a clear "liquid glass" capsule.
///
/// The capsule centre is flat clear glass; along its edge the glass bends
/// what lies below inwards, plus a faint tint, a bright edge on top and a
/// soft shadow. Tap a segment or drag the capsule: while it moves it grows
/// past the track and bends more, on landing it shrinks back.
///
/// The bending is done per pixel by `shaders/liquid_glass.frag` on a
/// snapshot of the track's icons and labels (not on the backdrop, which
/// sampled the wrong spot on Windows). Without the shader the capsule is
/// plain clear glass.
class LiquidGlassSegmented<T> extends StatefulWidget {
  const LiquidGlassSegmented({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    this.selectedIconColor,
  });

  final List<LiquidGlassSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  /// Icon beside the label and 48 px high instead of icon above and 64 px.
  final bool compact;

  /// Icon colour of the selected segment; defaults to the text colour.
  final Color? selectedIconColor;

  @override
  State<LiquidGlassSegmented<T>> createState() =>
      _LiquidGlassSegmentedState<T>();
}

class _LiquidGlassSegmentedState<T> extends State<LiquidGlassSegmented<T>>
    with TickerProviderStateMixin {
  static const _curve = Curves.easeOutCubic;

  double get _height => widget.compact ? 48 : 64;
  static const double _inset = 4;

  /// How much bigger the capsule gets while it moves; it then sticks out of
  /// the track like the iOS glass controls.
  static const double _liftScale = 1.11;

  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  )..addStatusListener(_onSlideStatus);

  /// 0 = resting (smaller) capsule, 1 = lifted (bigger) capsule.
  late final AnimationController _lift = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  /// Slide from [_from] to [_to] in segment units.
  double _from = 0;
  double _to = 0;

  /// Set while the finger drags the capsule, in segment units.
  double? _dragPosition;

  /// The track's icons and labels; the capsule bends a snapshot of them.
  final GlobalKey _contentKey = GlobalKey();
  final _ContentSnapshot _snapshot = _ContentSnapshot();
  ui.FragmentShader? _shader;

  int get _selectedIndex {
    final i = widget.segments.indexWhere((s) => s.value == widget.selected);
    return i < 0 ? 0 : i;
  }

  double get _position =>
      _dragPosition ??
      ui.lerpDouble(_from, _to, _curve.transform(_slide.value))!;

  @override
  void initState() {
    super.initState();
    _from = _to = _selectedIndex.toDouble();
    _loadShader();
  }

  Future<void> _loadShader() async {
    final program = await _LiquidGlassProgram.load();
    if (!mounted || program == null) return;
    setState(() => _shader = program.fragmentShader());
  }

  @override
  void didUpdateWidget(covariant LiquidGlassSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _selectedIndex.toDouble();
    if (target != _to && _dragPosition == null) _glideTo(target);
  }

  void _glideTo(double target) {
    _from = _position;
    _to = target;
    _lift.animateTo(1, curve: _curve);
    _slide.forward(from: 0);
  }

  void _onSlideStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _dragPosition == null) {
      _lift.animateBack(0, curve: _curve);
    }
  }

  void _onDragStart(DragStartDetails _) {
    _slide.stop();
    _dragPosition = _position;
    _lift.animateTo(1, curve: _curve);
  }

  void _onDragUpdate(DragUpdateDetails details, double segmentWidth) {
    setState(() {
      _dragPosition = (_dragPosition! + details.delta.dx / segmentWidth)
          .clamp(0.0, widget.segments.length - 1.0);
    });
  }

  void _onDragEnd(DragEndDetails details, double segmentWidth) {
    // A quick flick carries the capsule a little further.
    final fling = details.velocity.pixelsPerSecond.dx / segmentWidth * 0.08;
    final target = (_dragPosition! + fling)
        .round()
        .clamp(0, widget.segments.length - 1);
    _from = _dragPosition!;
    _to = target.toDouble();
    _dragPosition = null;
    _slide.forward(from: 0);
    if (target != _selectedIndex) {
      widget.onChanged(widget.segments[target].value);
    }
  }

  @override
  void dispose() {
    _slide.dispose();
    _lift.dispose();
    _snapshot.dispose();
    _shader?.dispose();
    super.dispose();
  }

  Widget _contentRow(double position, Color ink, Color muted) {
    final selectedIcon = widget.selectedIconColor ?? ink;
    double away(int i) => ((position - i).abs()).clamp(0.0, 1.0);
    return Row(
      children: [
        for (int i = 0; i < widget.segments.length; i++)
          Expanded(
            child: _SegmentContent(
              segment: widget.segments[i],
              compact: widget.compact,
              color: Color.lerp(ink, muted, away(i))!,
              iconColor: Color.lerp(selectedIcon, muted, away(i))!,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark(context);
    final ink = AppColors.ink(context);
    final muted = AppColors.muted(context);
    final track = dark ? AppColors.card(context) : AppColors.chip(context);
    final count = widget.segments.length;

    return SizedBox(
      height: _height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowWidth = constraints.maxWidth - 2 * _inset;
          final segmentWidth = rowWidth / count;

          return GestureDetector(
            // Count the drag from the touch-down point, so the capsule
            // follows the whole finger movement.
            dragStartBehavior: DragStartBehavior.down,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, segmentWidth),
            onHorizontalDragEnd: (d) => _onDragEnd(d, segmentWidth),
            child: AnimatedBuilder(
              animation: Listenable.merge([_slide, _lift]),
              builder: (context, _) {
                final position = _position;
                final lift = _lift.value;
                final scale = ui.lerpDouble(1, _liftScale, lift)!;
                final capsule = Rect.fromCenter(
                  center: Offset(
                    _inset + segmentWidth * (position + 0.5),
                    _height / 2,
                  ),
                  width: segmentWidth * scale,
                  height: (_height - 2 * _inset) * scale,
                );
                final content = _contentRow(position, ink, muted);
                final sizeFactor = (_height - 2 * _inset) / 56;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Track
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          color: track,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      left: _inset,
                      right: _inset,
                      child: RepaintBoundary(key: _contentKey, child: content),
                    ),
                    // Glass capsule
                    Positioned.fromRect(
                      rect: capsule,
                      child: IgnorePointer(
                        child: _GlassCapsule(
                          dark: dark,
                          lift: lift,
                          refraction: _shader == null
                              ? null
                              : _RefractionPainter(
                                  shader: _shader!,
                                  contentKey: _contentKey,
                                  snapshot: _snapshot,
                                  devicePixelRatio:
                                      MediaQuery.devicePixelRatioOf(context),
                                  // Where the snapshot sits, capsule-local.
                                  contentRect: Rect.fromLTWH(
                                    _inset - capsule.left,
                                    -capsule.top,
                                    rowWidth,
                                    _height,
                                  ),
                                  trackColor: track,
                                  // Tuned for the 56 px capsule, scaled
                                  // for smaller ones (compact).
                                  bezel: ui.lerpDouble(12, 14, lift)! * sizeFactor,
                                  depth: ui.lerpDouble(4.5, 6, lift)! * sizeFactor,
                                ),
                        ),
                      ),
                    ),
                    // Tap targets on top of everything
                    Positioned.fill(
                      left: _inset,
                      right: _inset,
                      child: Row(
                        children: [
                          for (int i = 0; i < count; i++)
                            Expanded(
                              child: Semantics(
                                button: true,
                                selected: i == _selectedIndex,
                                label: widget.segments[i].label,
                                excludeSemantics: true,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => widget
                                      .onChanged(widget.segments[i].value),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SegmentContent extends StatelessWidget {
  const _SegmentContent({
    required this.segment,
    required this.compact,
    required this.color,
    required this.iconColor,
  });

  final LiquidGlassSegment segment;
  final bool compact;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      segment.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 14 : 12.5,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
    if (compact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(segment.icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(child: label),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(segment.icon, size: 22, color: iconColor),
        const SizedBox(height: 3),
        label,
      ],
    );
  }
}

/// The capsule itself: shadow outside, refracted content, faint tint and
/// rim light.
class _GlassCapsule extends StatelessWidget {
  const _GlassCapsule({
    required this.dark,
    required this.lift,
    required this.refraction,
  });

  final bool dark;

  /// 0 = resting, 1 = lifted while moving.
  final double lift;

  /// Paints the bent content; null = plain clear glass.
  final CustomPainter? refraction;

  @override
  Widget build(BuildContext context) {
    // Barely-there tint so the capsule reads as clear glass.
    final topAlpha = dark
        ? ui.lerpDouble(0.10, 0.06, lift)!
        : ui.lerpDouble(0.12, 0.06, lift)!;
    final bottomAlpha = dark
        ? ui.lerpDouble(0.04, 0.02, lift)!
        : ui.lerpDouble(0.04, 0.02, lift)!;

    return CustomPaint(
      painter: _OuterShadowPainter(dark: dark),
      foregroundPainter: _RimPainter(dark: dark),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: StadiumBorder()),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: topAlpha),
                Colors.white.withValues(alpha: bottomAlpha),
              ],
            ),
          ),
          child: CustomPaint(
            painter: refraction,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Holds the latest snapshot of the track content. The previous one is only
/// released once a newer frame has been drawn.
class _ContentSnapshot {
  ui.Image? _image;

  void replace(ui.Image image) {
    _image?.dispose();
    _image = image;
  }

  void dispose() {
    _image?.dispose();
    _image = null;
  }
}

/// Paints the whole capsule interior from a snapshot of the track content,
/// so the unbent original underneath never shows through twice.
class _RefractionPainter extends CustomPainter {
  _RefractionPainter({
    required this.shader,
    required this.contentKey,
    required this.snapshot,
    required this.devicePixelRatio,
    required this.contentRect,
    required this.trackColor,
    required this.bezel,
    required this.depth,
  });

  final ui.FragmentShader shader;
  final GlobalKey contentKey;
  final _ContentSnapshot snapshot;
  final double devicePixelRatio;
  final Rect contentRect;
  final Color trackColor;
  final double bezel;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final boundary = contentKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return;
    // The track content is painted earlier in the same Stack, so its layer
    // is up to date here.
    final image = boundary.toImageSync(pixelRatio: devicePixelRatio);
    snapshot.replace(image);

    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, contentRect.left)
      ..setFloat(3, contentRect.top)
      ..setFloat(4, contentRect.width)
      ..setFloat(5, contentRect.height)
      ..setFloat(6, bezel)
      ..setFloat(7, depth)
      ..setFloat(8, trackColor.r * trackColor.a)
      ..setFloat(9, trackColor.g * trackColor.a)
      ..setFloat(10, trackColor.b * trackColor.a)
      ..setFloat(11, trackColor.a)
      ..setImageSampler(0, image);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  // Content colours change with the capsule position, so every frame needs
  // a fresh snapshot.
  @override
  bool shouldRepaint(_RefractionPainter old) => true;
}

/// Loads the lens shader once; null if it cannot be loaded, the capsule is
/// then plain clear glass.
class _LiquidGlassProgram {
  static Future<ui.FragmentProgram?>? _future;

  static Future<ui.FragmentProgram?> load() {
    return _future ??= () async {
      try {
        return await ui.FragmentProgram.fromAsset('shaders/liquid_glass.frag');
      } on Exception catch (e) {
        debugPrint('Liquid glass shader not available: $e');
        return null;
      }
    }();
  }
}

/// Soft drop shadow painted only outside the capsule, so it does not darken
/// the glass from behind.
class _OuterShadowPainter extends CustomPainter {
  const _OuterShadowPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(40))
      ..addRRect(shape);

    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
      shape.shift(const Offset(0, 4)),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.45 : 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawRRect(
      shape.shift(const Offset(0, 1)),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.30 : 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter old) => old.dark != dark;
}

/// Thin specular edge: bright along the top, fading at the sides, with a
/// faint bounce light along the bottom.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(
      rect.deflate(0.5),
      Radius.circular(size.height / 2),
    );

    // White highlights vanish on a light track. A faint dark inner edge
    // gives the glass its thickness there, so the white rim reads again.
    if (!dark) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.deflate(1.5),
          Radius.circular(size.height / 2 - 1.5),
        ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.0),
              Colors.black.withValues(alpha: 0.06),
              Colors.black.withValues(alpha: 0.10),
            ],
            stops: const [0.15, 0.5, 1.0],
          ).createShader(rect),
      );
    }

    final top = dark ? 0.55 : 1.0;
    final bottom = dark ? 0.18 : 0.6;
    canvas.drawRRect(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: top),
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: 0.0),
            Colors.white.withValues(alpha: bottom),
          ],
          stops: const [0.0, 0.42, 0.6, 1.0],
        ).createShader(rect),
    );

    // Short highlight sheen just under the top edge.
    final sheen = Rect.fromLTWH(
      size.height * 0.45,
      1.5,
      size.width - size.height * 0.9,
      size.height * 0.28,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheen, Radius.circular(sheen.height / 2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.0),
                ]
              : [
                  // Slightly cool white, so it shows on the grey track.
                  const Color(0xFFF8FBFF).withValues(alpha: 0.95),
                  const Color(0xFFF8FBFF).withValues(alpha: 0.0),
                ],
        ).createShader(sheen),
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) => old.dark != dark;
}
