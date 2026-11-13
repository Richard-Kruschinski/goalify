import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/duration_format.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/models/run.dart';

String formatKilometers(BuildContext context, double meters) => NumberFormat(
  '0.00',
  Localizations.localeOf(context).toString(),
).format(meters / 1000);

String formatPace(int? secondsPerKm) =>
    secondsPerKm == null ? '–' : formatClockDuration(secondsPerKm);

IconData runActivityIcon(RunActivity activity) => switch (activity) {
  RunActivity.run => Icons.directions_run,
  RunActivity.walk => Icons.directions_walk,
  RunActivity.bike => Icons.directions_bike,
};

String runActivityLabel(AppLocalizations l10n, RunActivity activity) =>
    switch (activity) {
      RunActivity.run => l10n.runActivityRun,
      RunActivity.walk => l10n.runActivityWalk,
      RunActivity.bike => l10n.runActivityBike,
    };
