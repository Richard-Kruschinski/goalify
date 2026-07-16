import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global app settings (theme mode, language), persisted via SharedPreferences.
///
/// Adding a new language:
/// 1. Create lib/l10n/app_<code>.arb with the translations
/// 2. Add an entry to [supportedLanguages] below
/// That's it - the settings screen and MaterialApp pick it up automatically.
class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.nativeName,
    required this.flagCountryCode,
    required this.materialLocale,
  });

  /// Two-letter language code, must match the app_<code>.arb file.
  final String code;

  /// The language's name in that language (shown in the picker).
  final String nativeName;

  /// ISO country code for the flag shown in the language dropdown
  /// (rendered via the country_flags package, works on all platforms).
  final String flagCountryCode;

  /// Locale passed to MaterialApp. Country codes are chosen so weeks
  /// start on Monday (e.g. en_GB instead of en_US).
  final Locale materialLocale;
}

class SettingsController extends ChangeNotifier {
  static const _themeModeKey = 'settings_theme_mode_v1';
  static const _languageKey = 'settings_language_v1';

  static const List<AppLanguage> supportedLanguages = [
    AppLanguage(code: 'de', nativeName: 'Deutsch', flagCountryCode: 'DE', materialLocale: Locale('de', 'DE')),
    AppLanguage(code: 'en', nativeName: 'English', flagCountryCode: 'GB', materialLocale: Locale('en', 'GB')),
    AppLanguage(code: 'ru', nativeName: 'Русский', flagCountryCode: 'RU', materialLocale: Locale('ru', 'RU')),
  ];

  ThemeMode _themeMode = ThemeMode.system;
  String? _languageCode; // null = follow system

  ThemeMode get themeMode => _themeMode;

  /// Selected language code, or null when following the system language.
  String? get languageCode => _languageCode;

  /// Locale for MaterialApp; null lets Flutter resolve the device locale.
  Locale? get locale {
    final code = _languageCode;
    if (code == null) return null;
    for (final lang in supportedLanguages) {
      if (lang.code == code) return lang.materialLocale;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    switch (prefs.getString(_themeModeKey)) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    final lang = prefs.getString(_languageKey);
    if (lang != null && supportedLanguages.any((l) => l.code == lang)) {
      _languageCode = lang;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    switch (mode) {
      case ThemeMode.light:
        await prefs.setString(_themeModeKey, 'light');
        break;
      case ThemeMode.dark:
        await prefs.setString(_themeModeKey, 'dark');
        break;
      case ThemeMode.system:
        await prefs.remove(_themeModeKey);
        break;
    }
  }

  /// Pass null to follow the system language.
  Future<void> setLanguageCode(String? code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_languageKey);
    } else {
      await prefs.setString(_languageKey, code);
    }
  }
}
