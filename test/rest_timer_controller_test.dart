import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Goalify/features/gym/presentation/controllers/rest_timer_controller.dart';
import 'package:Goalify/l10n/generated/app_localizations.dart';

void main() {
  late DateTime now;
  late RestTimerController timer;

  setUp(() {
    now = DateTime(2026, 11, 12, 18);
    timer = RestTimerController(autoOffMinutes: () => 15, clock: () => now);
  });

  tearDown(() => timer.dispose());

  int? trackSet({int setNumber = 1, int? targetSets, int? targetRest, String? next}) =>
      timer.startRest(
        workoutId: 'bench',
        workoutName: 'Bench press',
        setNumber: setNumber,
        targetSets: targetSets,
        targetRestSeconds: targetRest,
        nextExerciseName: next,
      );

  test('starts at 0:00 and counts up from the start time', () {
    trackSet();
    now = now.add(const Duration(seconds: 75));
    expect(timer.elapsed, const Duration(seconds: 75));
  });

  test('a new set restarts at 0:00 and returns the finished rest', () {
    expect(trackSet(), isNull);
    now = now.add(const Duration(seconds: 90));
    expect(trackSet(setNumber: 2), 90);
    expect(timer.elapsed, Duration.zero);
  });

  test('target reached after the target rest', () {
    trackSet(targetRest: 90);
    now = now.add(const Duration(seconds: 89));
    expect(timer.targetReached, isFalse);
    now = now.add(const Duration(seconds: 1));
    expect(timer.targetReached, isTrue);
  });

  test('stops itself after the auto-off time', () {
    trackSet();
    now = now.add(const Duration(minutes: 15));
    timer.tick();
    expect(timer.session, isNull);
  });

  test('a rest past the auto-off time is not recorded', () {
    trackSet();
    now = now.add(const Duration(minutes: 20));
    expect(trackSet(setNumber: 2), isNull);
  });

  group('switched off in the settings', () {
    late bool enabled;
    late RestTimerController switchable;

    setUp(() {
      enabled = false;
      switchable = RestTimerController(
        autoOffMinutes: () => 15,
        isEnabled: () => enabled,
        clock: () => now,
      );
    });

    tearDown(() => switchable.dispose());

    int? save() => switchable.startRest(
          workoutId: 'bench',
          workoutName: 'Bench press',
          setNumber: 1,
        );

    test('a saved set starts no timer', () {
      expect(save(), isNull);
      expect(switchable.session, isNull);
    });

    test('switching off stops a running timer on the next tick', () {
      enabled = true;
      save();
      enabled = false;
      switchable.tick();
      expect(switchable.session, isNull);
    });
  });

  test('stop ends the rest', () {
    trackSet();
    timer.stop();
    expect(timer.session, isNull);
    expect(timer.elapsed, Duration.zero);
  });

  group('describeRest', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('shows the set progress', () {
      trackSet(setNumber: 2, targetSets: 3);
      expect(describeRest(timer.session!, l10n), 'Bench press · Set 2 of 3');
    });

    test('shows the next exercise after the last set', () {
      trackSet(setNumber: 3, targetSets: 3, next: 'Curls');
      expect(describeRest(timer.session!, l10n), 'Bench press done · Up next: Curls');
    });

    test('says the workout is complete when nothing is left', () {
      trackSet(setNumber: 3, targetSets: 3);
      expect(describeRest(timer.session!, l10n), 'Bench press done · Workout complete');
    });

    test('counts sets without a target', () {
      trackSet(setNumber: 4);
      expect(describeRest(timer.session!, l10n), 'Bench press · Set 4');
    });
  });
}
