import 'package:flutter/material.dart';

/// Monatsansicht, die beim Wischen dem Finger folgt und den Nachbarmonat
/// daneben zeigt. Loslassen über der Schwelle (oder schnelles Wischen)
/// schiebt den neuen Monat ganz herein, sonst federt die Ansicht zurück.
///
/// Ändert der Aufrufer [month] von außen (Pfeile, Monat anspringen), gleitet
/// der neue Monat aus der passenden Richtung herein.
class SwipeMonthView extends StatefulWidget {
  const SwipeMonthView({
    super.key,
    required this.month,
    required this.onMonthChanged,
    required this.builder,
  });

  /// Angezeigter Monat (Tag wird ignoriert).
  final DateTime month;

  /// Wird nach einem vollendeten Wisch mit dem neuen Monat aufgerufen.
  final ValueChanged<DateTime> onMonthChanged;

  /// Baut den Inhalt eines Monats. Wird während des Wischens auch für den
  /// Nachbarmonat aufgerufen.
  final Widget Function(BuildContext context, DateTime month) builder;

  @override
  State<SwipeMonthView> createState() => _SwipeMonthViewState();
}

class _SwipeMonthViewState extends State<SwipeMonthView>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 280);
  static const _commitFraction = 0.2;
  static const _flingVelocity = 450.0;

  /// Versatz des Hauptmonats in Breiten (-1 = ganz links raus, 1 = rechts raus).
  late final AnimationController _offset;
  late DateTime _shown;

  /// Monat neben dem Hauptmonat, wenn er nicht direkt angrenzt (Sprung).
  DateTime? _otherOverride;
  double _width = 1;

  @override
  void initState() {
    super.initState();
    _shown = _firstOf(widget.month);
    _offset = AnimationController.unbounded(vsync: this)
      ..addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(SwipeMonthView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _firstOf(widget.month);
    if (_sameMonth(target, _shown)) return;

    // Von außen gewechselt: neuer Monat gleitet aus seiner Richtung herein.
    final dir = target.isAfter(_shown) ? 1.0 : -1.0;
    final previous = _shown;
    _offset.stop();
    _shown = target;
    final adjacent = _sameMonth(_addMonths(target, dir > 0 ? -1 : 1), previous);
    _otherOverride = adjacent ? null : previous;
    _offset.value = dir;
    _offset
        .animateTo(0, duration: _duration, curve: Curves.easeOutCubic)
        .whenComplete(() => _otherOverride = null);
  }

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  static DateTime _firstOf(DateTime d) => DateTime(d.year, d.month, 1);
  static DateTime _addMonths(DateTime d, int n) =>
      DateTime(d.year, d.month + n, 1);
  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;

  void _onDragStart(DragStartDetails _) {
    // Laufende Animation anhalten, der Finger übernimmt ab der aktuellen Lage.
    _offset.stop();
    if (_otherOverride != null) {
      setState(() => _otherOverride = null);
    }
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _offset.value += (d.primaryDelta ?? 0) / _width;
  }

  void _onDragEnd(DragEndDetails d) {
    final v = _offset.value;
    final velocity = d.primaryVelocity ?? 0;
    double target = 0;
    if (velocity.abs() > _flingVelocity) {
      target = velocity < 0 ? -1 : 1;
    } else if (v.abs() > _commitFraction) {
      target = v < 0 ? -1 : 1;
    }
    // Schnelles Wischen gegen den aktuellen Versatz nicht durchschlagen lassen.
    if (target != 0 && v != 0 && target.sign != v.sign) target = 0;

    _offset
        .animateTo(target, duration: _duration, curve: Curves.easeOutCubic)
        .whenComplete(() {
          if (!mounted || target == 0 || _offset.value != target) return;
          final next = _addMonths(_shown, target < 0 ? 1 : -1);
          setState(() {
            _shown = next;
            _offset.value = 0;
          });
          widget.onMonthChanged(next);
        });
  }

  @override
  Widget build(BuildContext context) {
    final v = _offset.value;
    final children = <Widget>[];
    if (v != 0) {
      final other = _otherOverride ?? _addMonths(_shown, v < 0 ? 1 : -1);
      final otherOffset = v < 0 ? v + 1 : v - 1;
      children.add(_page(other, otherOffset));
    }
    children.add(_page(_shown, v));

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          _width = constraints.maxWidth;
        }
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: () => _onDragEnd(DragEndDetails()),
          child: ClipRect(
            child: Stack(alignment: Alignment.topCenter, children: children),
          ),
        );
      },
    );
  }

  Widget _page(DateTime month, double offset) {
    return FractionalTranslation(
      key: ValueKey(month),
      translation: Offset(offset, 0),
      child: IgnorePointer(
        ignoring: offset != 0,
        child: widget.builder(context, month),
      ),
    );
  }
}
