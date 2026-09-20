import 'package:flutter/material.dart';

String? _activeSnackBarText;

/// Shows SnackBars without stacking them in a queue.
///
/// - Tapping the same trigger repeatedly shows the message only once:
///   while a message is visible, identical messages are ignored.
/// - A different message replaces the current one immediately instead of
///   being queued behind it.
extension SingleSnackBar on ScaffoldMessengerState {
  void showSingleSnackBar(SnackBar snackBar) {
    final content = snackBar.content;
    final text = content is Text ? content.data : null;

    // Same message already on screen – ignore spam taps.
    if (text != null && text == _activeSnackBarText) return;

    clearSnackBars();
    _activeSnackBarText = text;
    showSnackBar(snackBar).closed.then((_) {
      if (_activeSnackBarText == text) _activeSnackBarText = null;
    });
  }
}
