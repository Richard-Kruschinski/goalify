import 'package:flutter/material.dart';

/// `proxyDecorator` for a [ReorderableListView] whose items are cards with a
/// gap below them ([margin]).
///
/// The default decorator lifts the whole item, gap included, so the drag
/// shadow sticks out below the card. This one draws the shadow only inside
/// [margin], in the card's own [borderRadius].
ReorderItemProxyDecorator cardDragProxy({
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
  EdgeInsets margin = const EdgeInsets.only(bottom: 12),
}) {
  return (child, index, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) {
          final lift = Curves.easeInOut.transform(animation.value);
          return Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: margin,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: borderRadius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18 * lift),
                            blurRadius: 16 * lift,
                            offset: Offset(0, 6 * lift),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                child!,
              ],
            ),
          );
        },
      );
}
