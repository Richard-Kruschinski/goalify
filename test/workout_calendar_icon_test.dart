import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/utils/day_cycle.dart';
import 'package:Goalify/features/gym/presentation/pages/workout_calendar_page.dart';
import 'package:Goalify/l10n/generated/app_localizations.dart';

Widget _calendar({
  Widget Function(String day, Color color)? dayIconBuilder,
  void Function(String day)? onOpenDay,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: WorkoutCalendarPage(
      calendarByDate: {
        DayCycle.todayKey(): {'Push'},
      },
      dayColors: const {'Push': 0xFFFFC107},
      dayIconBuilder: dayIconBuilder ?? (_, _) => const SizedBox.shrink(),
      onOpenDay: onOpenDay ?? (_) {},
      isCreatineTaken: (_) => false,
      onToggleCreatine: (_, _) async {},
    ),
  );
}

void main() {

  testWidgets('day sheet shows the icon of the workout day', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    const iconKey = Key('day-icon');
    Color? usedColor;
    String? usedDay;

    await tester.pumpWidget(_calendar(dayIconBuilder: (day, color) {
      usedDay = day;
      usedColor = color;
      return const SizedBox(key: iconKey);
    }));

    await tester.tap(find.text('${DayCycle.today().day}'));
    await tester.pumpAndSettle();

    expect(find.byKey(iconKey), findsOneWidget);
    expect(usedDay, 'Push');
    expect(usedColor, Colors.white);
  });

  testWidgets('tapping a workout in the day sheet opens it', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final opened = <String>[];
    await tester.pumpWidget(_calendar(onOpenDay: opened.add));

    await tester.tap(find.text('${DayCycle.today().day}'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    expect(opened, ['Push']);
    expect(find.text('Push'), findsNothing, reason: 'the sheet closes');
  });
}
