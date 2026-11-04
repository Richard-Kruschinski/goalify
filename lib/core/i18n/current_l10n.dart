import 'package:flutter/widgets.dart';

import '../../l10n/generated/app_localizations.dart';

/// Strings for code that runs without a [BuildContext], such as the timer
/// controllers that fill the live notification.
///
/// The app shell updates [_current] whenever the active locale changes (see
/// `MaterialApp.builder` in main.dart), so these texts follow the language
/// picked in the settings.
class CurrentL10n {
  CurrentL10n._();

  static AppLocalizations? _current;

  static void update(BuildContext context) {
    _current = AppLocalizations.of(context);
  }

  /// Active strings; English until the first frame has been built.
  static AppLocalizations get of =>
      _current ?? lookupAppLocalizations(const Locale('en'));
}
