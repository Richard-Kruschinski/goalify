import 'package:flutter/material.dart';

/// Shows [first] or [second] in the same slot, always as tall as the taller
/// of the two, so whatever sits below does not jump when they swap
/// (whatever the language or text size).
class EqualHeightSwap extends StatelessWidget {
  const EqualHeightSwap({
    required this.showFirst,
    required this.first,
    required this.second,
    super.key,
  });

  final bool showFirst;
  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _slot(first, visible: showFirst),
          _slot(second, visible: !showFirst),
        ],
      ),
    );
  }

  static Widget _slot(Widget child, {required bool visible}) => Visibility(
        visible: visible,
        maintainSize: true,
        maintainAnimation: true,
        maintainState: true,
        child: child,
      );
}
