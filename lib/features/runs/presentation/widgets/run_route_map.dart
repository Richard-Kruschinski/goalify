import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:latlong2/latlong.dart' hide Path;

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/run.dart';
import 'map_circle_button.dart';
import 'run_map_style.dart';

/// Draws a route on a dark vector map. With [follow] the map keeps the
/// [currentPosition] centered until the user pans it; otherwise it fits the
/// whole route.
class RunRouteMap extends StatefulWidget {
  const RunRouteMap({
    super.key,
    required this.segments,
    this.currentPosition,
    this.follow = false,
    this.bottomInset = 0,
    this.controlsTopInset = 0,
  });

  final List<List<RoutePoint>> segments;
  final LatLng? currentPosition;
  final bool follow;

  /// Height covered by widgets floating over the bottom of the map; the
  /// credits button sits above it.
  final double bottomInset;

  /// Space above the compass for buttons the page floats in the top right.
  final double controlsTopInset;

  @override
  State<RunRouteMap> createState() => _RunRouteMapState();
}

class _RunRouteMapState extends State<RunRouteMap>
    with SingleTickerProviderStateMixin {
  static const _followZoom = 17.0;

  final _mapController = MapController();
  final _style = RunMapStyle.load();
  bool _mapReady = false;
  bool _userMoved = false;

  /// Map rotation in degrees; the compass needle follows it.
  double _rotation = 0;

  late final _flight = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..addListener(_onFlightTick);
  late final _flightCurve = CurvedAnimation(
    parent: _flight,
    curve: Curves.easeInOutCubic,
  );
  LatLng _flightFrom = const LatLng(0, 0);
  LatLng _flightTo = const LatLng(0, 0);
  double _flightFromZoom = _followZoom;
  double _flightToZoom = _followZoom;
  double _flightFromRotation = 0;
  double _flightRotationDelta = 0;

  /// Compass direction the phone points to, for the cone on the live map.
  double? _heading;
  StreamSubscription<CompassEvent>? _headingEvents;

  /// flutter_compass has no web or desktop implementation.
  static bool get _hasCompass =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (widget.follow && _hasCompass) {
      _headingEvents = FlutterCompass.events?.listen(
        _onHeading,
        onError: (Object error) =>
            debugPrint('RunRouteMap: compass failed: $error'),
      );
    }
  }

  void _onHeading(CompassEvent event) {
    final heading = event.heading;
    if (heading == null) return;
    // The sensor jitters; redraw only on a visible change.
    final previous = _heading;
    if (previous != null && (heading - previous).abs() < 2) return;
    setState(() => _heading = heading);
  }

  @override
  void dispose() {
    _headingEvents?.cancel();
    _flight.dispose();
    super.dispose();
  }

  List<LatLng> get _allPoints => [
    for (final segment in widget.segments)
      for (final p in segment) p.position,
  ];

  @override
  void didUpdateWidget(RunRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final position = widget.currentPosition;
    if (!widget.follow || _userMoved || !_mapReady || position == null) return;
    if (position == oldWidget.currentPosition) return;
    if (_flight.isAnimating) {
      _flightTo = position; // land on where the runner is now
    } else {
      _mapController.move(position, _mapController.camera.zoom);
    }
  }

  /// Glides back to the runner instead of jumping: pan and zoom together.
  void _recenter() {
    final position = widget.currentPosition;
    if (position == null) return;
    setState(() => _userMoved = false);
    _flyTo(position, _followZoom, _mapController.camera.rotation);
  }

  /// Turns the map back so north is up, staying where it is.
  void _faceNorth() {
    final camera = _mapController.camera;
    _flyTo(camera.center, camera.zoom, 0);
  }

  void _flyTo(LatLng center, double zoom, double rotation) {
    final camera = _mapController.camera;
    _flightFrom = camera.center;
    _flightFromZoom = camera.zoom;
    _flightFromRotation = camera.rotation;
    _flightTo = center;
    _flightToZoom = zoom;
    // Shortest way round: from 350° to 0° turns 10°, not 350°.
    _flightRotationDelta = (rotation - camera.rotation + 540) % 360 - 180;
    _flight.forward(from: 0);
  }

  void _onFlightTick() {
    final t = _flightCurve.value;
    _mapController.moveAndRotate(
      LatLng(
        _flightFrom.latitude + (_flightTo.latitude - _flightFrom.latitude) * t,
        _flightFrom.longitude +
            (_flightTo.longitude - _flightFrom.longitude) * t,
      ),
      _flightFromZoom + (_flightToZoom - _flightFromZoom) * t,
      _flightFromRotation + _flightRotationDelta * t,
    );
  }

  /// Zoom at which one world (256 px wide at zoom 0, doubling per level)
  /// covers the longer side of the map.
  static double _minZoomFor(Size size) =>
      math.max(0, math.log(math.max(size.width, size.height) / 256) / math.ln2);

  @override
  Widget build(BuildContext context) {
    final points = _allPoints;
    final accent = AppColors.accent(context);
    final position = widget.currentPosition;
    final routes = [
      for (final segment in widget.segments)
        if (segment.length >= 2) [for (final p in segment) p.position],
    ];
    return Stack(
      children: [
        FutureBuilder<vt.Style?>(
          future: _style,
          builder: (context, snapshot) => LayoutBuilder(
            builder: (context, constraints) {
              final style = snapshot.data;
              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  backgroundColor: RunMapStyle.background,
                  // The map repeats the world to the left and right, so it
                  // wraps around. Zoomed out further than one world per
                  // screen, those copies would show side by side.
                  minZoom: _minZoomFor(constraints.biggest),
                  cameraConstraint: const CameraConstraint.containLatitude(),
                  initialCenter:
                      position ??
                      (points.isEmpty ? const LatLng(0, 0) : points.last),
                  initialZoom: _followZoom,
                  initialCameraFit: widget.follow || points.isEmpty
                      ? null
                      : CameraFit.coordinates(
                          coordinates: points,
                          padding: const EdgeInsets.all(48),
                          maxZoom: _followZoom,
                        ),
                  onMapReady: () => _mapReady = true,
                  // onPositionChanged skips pure rotations (the compass
                  // button only turns the map), so the needle listens to
                  // every map event instead.
                  onMapEvent: (event) {
                    final rotation = event.camera.rotation;
                    if (rotation != _rotation) {
                      setState(() => _rotation = rotation);
                    }
                  },
                  onPositionChanged: (camera, hasGesture) {
                    if (hasGesture) _flight.stop(); // the finger wins
                    if (hasGesture && widget.follow && !_userMoved) {
                      setState(() => _userMoved = true);
                    }
                  },
                ),
                children: [
                  if (style != null)
                    vt.VectorTileLayer(
                      theme: style.theme,
                      tileProviders: style.providers,
                      rasterSources: style.rasterSources,
                      sprites: style.sprites,
                      glyphs: style.glyphs,
                      // Screen mode keeps names upright when the map turns;
                      // baked into the tiles they would turn with it. Web
                      // keeps tile mode: screen mode drew no labels there.
                      labelMode: kIsWeb
                          ? vt.LabelMode.tile
                          : vt.LabelMode.screen,
                    ),
                  PolylineLayer(
                    polylines: [
                      // Wide, faint copy underneath: the glow around the route.
                      for (final route in routes)
                        Polyline(
                          points: route,
                          strokeWidth: 16,
                          color: accent.withValues(alpha: 0.25),
                        ),
                      for (final route in routes)
                        Polyline(points: route, strokeWidth: 5, color: accent),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      if (points.isNotEmpty)
                        Marker(
                          point: points.first,
                          width: 20,
                          height: 20,
                          child: _Dot(fill: Colors.white, ring: accent),
                        ),
                      if (position != null)
                        Marker(
                          point: position,
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_heading != null)
                                CustomPaint(
                                  size: const Size.square(120),
                                  painter: _HeadingConePainter(
                                    headingDegrees: _heading!,
                                    color: accent,
                                  ),
                                ),
                              SizedBox.square(
                                dimension: 24,
                                child: _Dot(
                                  fill: accent,
                                  ring: Colors.white,
                                  glow: accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (style != null)
                    // An (i) button that opens the credits, instead of a text
                    // line too long for a phone screen.
                    Padding(
                      padding: EdgeInsets.only(bottom: widget.bottomInset),
                      child: RichAttributionWidget(
                        alignment: AttributionAlignment.bottomLeft,
                        attributions: [
                          for (final attribution in style.attributions)
                            TextSourceAttribution(attribution.text),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        Positioned(
          // Top corner: the live page floats its stats card at the bottom.
          // Below the status bar where the map reaches the screen top.
          right: 16,
          top: 16 + MediaQuery.paddingOf(context).top + widget.controlsTopInset,
          child: Column(
            children: [
              MapCircleButton(
                tooltip: AppLocalizations.of(context).runFaceNorth,
                onPressed: _faceNorth,
                // Layers turn by the same angle, so the needle keeps
                // pointing at the map's north.
                child: Transform.rotate(
                  angle: _rotation * math.pi / 180,
                  child: Icon(Icons.navigation, color: accent),
                ),
              ),
              if (_userMoved) ...[
                const SizedBox(height: 8),
                MapCircleButton(
                  onPressed: _recenter,
                  child: Icon(Icons.my_location, color: accent),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Fading wedge from the position dot towards where the phone points.
/// Markers turn with the map, so the angle is relative to map north.
class _HeadingConePainter extends CustomPainter {
  _HeadingConePainter({required this.headingDegrees, required this.color});

  static const _halfAngle = math.pi / 6; // 60° wide in total

  final double headingDegrees;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    // 0° is north = straight up, which is -90° in canvas angles.
    final direction = headingDegrees * math.pi / 180 - math.pi / 2;
    final cone = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(rect, direction - _halfAngle, 2 * _halfAngle, false)
      ..close();
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.55), color.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawPath(cone, paint);
  }

  @override
  bool shouldRepaint(_HeadingConePainter old) =>
      old.headingDegrees != headingDegrees || old.color != color;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.fill, required this.ring, this.glow});

  final Color fill;
  final Color ring;
  final Color? glow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 4),
        boxShadow: [
          if (glow != null)
            BoxShadow(
              color: glow!.withValues(alpha: 0.6),
              blurRadius: 14,
              spreadRadius: 4,
            ),
        ],
      ),
    );
  }
}
