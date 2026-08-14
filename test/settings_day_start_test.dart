import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Goalify/core/settings/settings_controller.dart';
import 'package:Goalify/core/utils/day_cycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => DayCycle.setStartMinuteOfDay(DayCycle.defaultStartMinuteOfDay));

  test('defaults to 00:00 when nothing was ever set', () async {
    SharedPreferences.setMockInitialValues({});
    DayCycle.setStart(7, 45); // stale value from a previous run

    final settings = SettingsController();
    await settings.load();

    expect(settings.dayStartHour, 0);
    expect(settings.dayStartMinute, 0);
    expect(DayCycle.startMinuteOfDay, 0);
  });

  test('restores a stored start time', () async {
    SharedPreferences.setMockInitialValues({
      'settings_day_start_minute_v1': 2 * 60 + 30,
    });

    final settings = SettingsController();
    await settings.load();

    expect(settings.dayStartHour, 2);
    expect(settings.dayStartMinute, 30);
    expect(DayCycle.startHour, 2);
    expect(DayCycle.startMinute, 30);
  });

  test('migrates the old hour-only setting', () async {
    SharedPreferences.setMockInitialValues({'settings_day_start_hour_v1': 3});

    final settings = SettingsController();
    await settings.load();

    expect(settings.dayStartHour, 3);
    expect(settings.dayStartMinute, 0);
  });

  test('persists a change and drops the legacy key', () async {
    SharedPreferences.setMockInitialValues({'settings_day_start_hour_v1': 3});
    final settings = SettingsController();
    await settings.load();

    await settings.setDayStart(1, 15);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('settings_day_start_minute_v1'), 75);
    expect(prefs.getInt('settings_day_start_hour_v1'), isNull);
    expect(DayCycle.startMinuteOfDay, 75);
  });

  test('going back to 00:00 clears the stored value', () async {
    SharedPreferences.setMockInitialValues({
      'settings_day_start_minute_v1': 120,
    });
    final settings = SettingsController();
    await settings.load();

    await settings.setDayStart(0, 0);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('settings_day_start_minute_v1'), isNull);
    expect(DayCycle.startMinuteOfDay, 0);
  });
}
