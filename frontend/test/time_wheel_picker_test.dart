import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/widgets/time_wheel_picker.dart';

Widget _host({
  required int hour,
  required int minute,
  required void Function(int, int) onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: TimeWheelPicker(
          initialHour: hour,
          initialMinute: minute,
          onChanged: onChanged,
        ),
      ),
    ),
  );
}

/// Mirrors the settings screen: every reported value is stored and pushed back
/// into the picker on the following rebuild.
class _ControlledHost extends StatefulWidget {
  const _ControlledHost({required this.onChanged});

  final void Function(int, int) onChanged;

  @override
  State<_ControlledHost> createState() => _ControlledHostState();
}

class _ControlledHostState extends State<_ControlledHost> {
  int _hour = 6;
  int _minute = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: TimeWheelPicker(
            initialHour: _hour,
            initialMinute: _minute,
            onChanged: (h, m) {
              setState(() {
                _hour = h;
                _minute = m;
              });
              widget.onChanged(h, m);
            },
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('renders the selected time zero-padded', (tester) async {
    await tester.pumpWidget(_host(hour: 6, minute: 0, onChanged: (_, _) {}));
    await tester.pumpAndSettle();

    expect(find.text('06'), findsWidgets);
    expect(find.text('00'), findsWidgets);
    expect(find.text(':'), findsOneWidget);
  });

  testWidgets('shows consecutive neighbours, not every second value',
      (tester) async {
    await tester.pumpWidget(_host(hour: 6, minute: 30, onChanged: (_, _) {}));
    await tester.pumpAndSettle();

    // Direct neighbours of the centred values must be on screen.
    expect(find.text('05'), findsWidgets);
    expect(find.text('07'), findsWidgets);
    expect(find.text('29'), findsWidgets);
    expect(find.text('31'), findsWidgets);
  });

  testWidgets('each notch advances by exactly one value', (tester) async {
    final reported = <int>[];
    await tester.pumpWidget(_host(
      hour: 6,
      minute: 0,
      onChanged: (h, _) => reported.add(h),
    ));
    await tester.pumpAndSettle();

    final hourWheel = find.byType(ListWheelScrollView).first;
    for (var i = 0; i < 3; i++) {
      await tester.drag(hourWheel, const Offset(0, -52));
      await tester.pumpAndSettle();
    }

    expect(reported, [7, 8, 9]);
  });

  testWidgets('scrolling the left wheel changes the hour', (tester) async {
    int? hour;
    int? minute;
    await tester.pumpWidget(_host(
      hour: 6,
      minute: 0,
      onChanged: (h, m) {
        hour = h;
        minute = m;
      },
    ));
    await tester.pumpAndSettle();

    final wheels = find.byType(ListWheelScrollView);
    expect(wheels, findsNWidgets(2));

    // Dragging up moves to later values; one item extent = one hour.
    await tester.drag(wheels.first, const Offset(0, -52));
    await tester.pumpAndSettle();

    expect(hour, 7);
    expect(minute, 0);
  });

  testWidgets('scrolling the right wheel changes the minute', (tester) async {
    int? hour;
    int? minute;
    await tester.pumpWidget(_host(
      hour: 6,
      minute: 0,
      onChanged: (h, m) {
        hour = h;
        minute = m;
      },
    ));
    await tester.pumpAndSettle();

    // Dragging down wraps 00 backwards to 59.
    await tester
        .drag(find.byType(ListWheelScrollView).last, const Offset(0, 52));
    await tester.pumpAndSettle();

    expect(hour, 6);
    expect(minute, 59);
  });

  testWidgets('dragging inside a scrolling page turns the wheel, not the page',
      (tester) async {
    // The settings screen is a ListView, so the wheel sits in a second
    // vertical scrollable - the finger has to reach the wheel.
    final reported = <int>[];
    final pageCtrl = ScrollController();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: pageCtrl,
          children: [
            const SizedBox(height: 300),
            TimeWheelPicker(
              initialHour: 6,
              initialMinute: 0,
              onChanged: (h, _) => reported.add(h),
            ),
            const SizedBox(height: 900),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byType(ListWheelScrollView).first,
      const Offset(0, -52),
    );
    await tester.pumpAndSettle();

    expect(reported, [7]);
    expect(pageCtrl.offset, 0, reason: 'the page must not have scrolled');
  });

  testWidgets('a rebuild carrying the reported value never moves the wheel',
      (tester) async {
    final reported = <int>[];
    await tester
        .pumpWidget(_ControlledHost(onChanged: (h, _) => reported.add(h)));
    await tester.pumpAndSettle();

    final hourWheel = find.byType(ListWheelScrollView).first;

    // Three separate notches, each one followed by a parent rebuild that feeds
    // the new value straight back in. Nothing may bounce back.
    await tester.drag(hourWheel, const Offset(0, -52));
    await tester.pumpAndSettle();
    await tester.drag(hourWheel, const Offset(0, -52));
    await tester.pumpAndSettle();
    await tester.drag(hourWheel, const Offset(0, -52));
    await tester.pumpAndSettle();

    expect(reported, [7, 8, 9]);

    // And a fling has to keep its momentum instead of being pulled back.
    await tester.fling(hourWheel, const Offset(0, -300), 1200);
    await tester.pumpAndSettle();

    expect(reported.last, greaterThan(9));
  });
}
