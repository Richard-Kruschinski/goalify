import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/core/utils/day_cycle.dart';
import 'package:Goalify/features/gym/presentation/pages/workout_calendar_page.dart';
import 'package:Goalify/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('day sheet shows the icon of the workout day', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final today = DayCycle.today();
    const iconKey = Key('day-icon');
    Color? usedColor;
    String? usedDay;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: WorkoutCalendarPage(
          calendarByDate: {
            DayCycle.todayKey(): {'Push'},
          },
          dayColors: const {'Push': 0xFFFFC107},
          dayIconBuilder: (day, color) {
            usedDay = day;
            usedColor = color;
            return const SizedBox(key: iconKey);
          },
          isCreatineTaken: (_) => false,
          onToggleCreatine: (_, _) async {},
        ),
      ),
    );

    await tester.tap(find.text('${today.day}'));
    await tester.pumpAndSettle();

    expect(find.byKey(iconKey), findsOneWidget);
    expect(usedDay, 'Push');
    expect(usedColor, Colors.white);
  });
}
