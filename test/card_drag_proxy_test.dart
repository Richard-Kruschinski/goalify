import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/widgets/card_drag_proxy.dart';

void main() {
  // A list card: 80 px high plus a 12 px gap below it, like the task cards.
  Widget card() => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 80,
        color: Colors.white,
      );

  Future<Size> shadowSizeWhileDragged(WidgetTester tester, ReorderItemProxyDecorator decorator) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: decorator(card(), 0, const AlwaysStoppedAnimation(1)),
          ),
        ),
      ),
    );
    final shadow = find.byWidgetPredicate(
      (w) => w is DecoratedBox && (w.decoration as BoxDecoration).boxShadow?.isNotEmpty == true,
    );
    return tester.getSize(shadow);
  }

  testWidgets('the drag shadow covers the card, not the gap below it', (tester) async {
    final size = await shadowSizeWhileDragged(tester, cardDragProxy());
    expect(size, const Size(300, 80));
  });

  testWidgets('works with other gaps, e.g. the interval timer tasks', (tester) async {
    final size = await shadowSizeWhileDragged(
      tester,
      cardDragProxy(margin: const EdgeInsets.only(bottom: 10)),
    );
    expect(size, const Size(300, 82));
  });
}
