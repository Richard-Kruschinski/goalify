// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Goalify';

  @override
  String get hello => 'Hallo';

  @override
  String get settingsTitle => 'Optionen';

  @override
  String get settingsSubtitle => 'Dark Mode, Sprache & mehr';

  @override
  String get appearanceSection => 'Erscheinungsbild';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDescription => 'Folgt der Geräte-Einstellung';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeLightDescription => 'Immer das helle Design verwenden';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeDarkDescription => 'Immer das dunkle Design verwenden';

  @override
  String get languageSection => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSystemDescription => 'Folgt der Gerätesprache';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get functionsTitle => 'Funktionen';

  @override
  String get comingSoon => 'Bald verfügbar';

  @override
  String get pomodoroTimer => 'Pomodoro-Timer';

  @override
  String pomodoroCardRunning(String time) {
    return 'Timer läuft: $time';
  }

  @override
  String get pomodoroCardSubtitle =>
      'Arbeite in fokussierten Intervallen mit Pausen';

  @override
  String get distractionBlockerTitle => 'Ablenkungs-Blocker';

  @override
  String blockerCardActive(String duration) {
    return 'Aktiv: $duration';
  }

  @override
  String get blockerCardSubtitle =>
      'Blockiere ablenkende Apps und bleib fokussiert';

  @override
  String get musicTimerTitle => 'Musik-Timer';

  @override
  String musicTimerCardRunning(String time) {
    return 'Timer: $time';
  }

  @override
  String get musicTimerCardSubtitle => 'Musik mit Countdown-Timer abspielen';

  @override
  String get intervalTimerTitle => 'Intervall-Timer';

  @override
  String intervalCardRunning(String label, String time) {
    return 'Läuft: $label • $time';
  }

  @override
  String get intervalCardSubtitle =>
      'Erstelle ein Aufgaben-Profil mit Pausen zwischen den Aufgaben';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get close => 'Schließen';

  @override
  String get progressTitle => 'Fortschritt';

  @override
  String get reload => 'Neu laden';

  @override
  String get moreOptions => 'Mehr Optionen';

  @override
  String get clearHistory => 'Verlauf löschen';

  @override
  String get clearHistoryDescription =>
      'Alle gespeicherten Fortschrittsdaten entfernen';

  @override
  String get points => 'Punkte';

  @override
  String get ratio => 'Quote';

  @override
  String get rangeWeek => 'Woche';

  @override
  String get rangeMonth => 'Monat';

  @override
  String get rangeYear => 'Jahr';

  @override
  String get noDataYet => 'Noch keine Daten';

  @override
  String get resetProgressTitle => 'Fortschritt zurücksetzen?';

  @override
  String get resetProgressMessage =>
      'Alle gespeicherten Tagespunkte werden entfernt. Das kann nicht rückgängig gemacht werden.';

  @override
  String get currentRatio => 'Aktuelle Quote';

  @override
  String get avgRatio => 'Ø Quote';

  @override
  String get avgPerDay => 'Ø pro Tag';

  @override
  String currentRange(String label) {
    return 'Aktuell: $label';
  }

  @override
  String ptsValue(String value) {
    return '$value Pkt.';
  }

  @override
  String get weeklyReview => 'Wochenrückblick';

  @override
  String get vsLastWeek => 'vs. letzte Woche';

  @override
  String get focusTime => 'Fokuszeit';

  @override
  String get blockerTime => 'Blocker-Zeit';

  @override
  String get tasksDone => 'Erledigte Aufgaben';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get congratsTitle => 'GLÜCKWUNSCH!';

  @override
  String get congratsSubtitle => 'Du hast alle Aufgaben für heute erledigt';

  @override
  String get congratsMessage => 'Stark – halte deine Streaks am Laufen!';

  @override
  String get showProgress => 'Fortschritt anzeigen';

  @override
  String get todayTitle => 'Heute';

  @override
  String get historyReadOnly => 'Verlauf (schreibgeschützt)';

  @override
  String get futureReadOnly => 'Zukunft (schreibgeschützt)';

  @override
  String get viewByDate => 'Nach Datum ansehen';

  @override
  String get backToToday => 'Zurück zu Heute';

  @override
  String get pickAnotherDate => 'Anderes Datum wählen';

  @override
  String get resetAll => 'Alle zurücksetzen';

  @override
  String get noTasksYet => 'Noch keine Aufgaben';

  @override
  String get addTaskToStart => 'Füge eine Aufgabe hinzu, um zu starten';

  @override
  String get freezeHelp =>
      'Freeze-Token: schützt die Streak einer wiederkehrenden Aufgabe für HEUTE, ohne sie abzuhaken. Halte eine wiederkehrende Aufgabe gedrückt und wähle \"Für heute einfrieren\". Kostet 1 Token.';

  @override
  String get cannotCreatePastTasks =>
      'Für vergangene Tage können keine Aufgaben erstellt werden.';

  @override
  String get cannotModifyPastTasks =>
      'Aufgaben vergangener Tage können nicht geändert werden.';

  @override
  String get cannotModifyFutureTasks =>
      'Aufgaben zukünftiger Tage können nicht geändert werden.';

  @override
  String get recurringOnlyToday =>
      'Wiederkehrende Aufgaben können nur für heute abgehakt werden.';

  @override
  String get cannotDeletePastTasks =>
      'Aufgaben vergangener Tage können nicht gelöscht werden.';

  @override
  String get pastTasksReadOnly =>
      'Aufgaben vergangener Tage sind schreibgeschützt.';

  @override
  String get checklistNote => 'Checklisten-Notiz';

  @override
  String get checklistEmpty => 'Noch keine Einträge. Füge unten einen hinzu.';

  @override
  String get deleteItem => 'Eintrag löschen';

  @override
  String get addChecklistItemHint => 'Eintrag hinzufügen...';

  @override
  String get saveChecklist => 'Checkliste speichern';

  @override
  String get taskActions => 'Aufgaben-Aktionen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editTaskSubtitle => 'Titel, Beschreibung oder Kategorie ändern';

  @override
  String get changeIcon => 'Icon ändern';

  @override
  String get changeIconSubtitle => 'Eigenes oder vordefiniertes Icon wählen';

  @override
  String get checklistNoteSubtitle =>
      'Abhakbare Einträge zu dieser Aufgabe hinzufügen';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String get duplicateSubtitle => 'Diese Aufgabe direkt darunter kopieren';

  @override
  String get freezeForToday => 'Für heute einfrieren';

  @override
  String get alreadyFrozen => 'Bereits eingefroren';

  @override
  String get protectYourStreak => 'Schütze deine Streak';

  @override
  String get noTokensLeft => 'Keine Tokens übrig';

  @override
  String get moveToTop => 'Nach oben verschieben';

  @override
  String get moveToTopSubtitle => 'Diese wiederkehrende Aufgabe oben anpinnen';

  @override
  String get showHighestStreak => 'Beste Streak anzeigen';

  @override
  String get showHighestStreakSubtitle =>
      'Deinen Allzeit-Bestwert für diese Aufgabe ansehen';

  @override
  String get resetCurrentStreak => 'Aktuelle Streak zurücksetzen';

  @override
  String get resetCurrentStreakSubtitle =>
      'Aktuellen Streak-Fortschritt löschen';

  @override
  String get resetBestStreak => 'Beste Streak zurücksetzen';

  @override
  String get resetBestStreakSubtitle => 'Deinen Allzeit-Bestwert entfernen';

  @override
  String get deleteTaskSubtitle => 'Diese Aufgabe dauerhaft entfernen';

  @override
  String get chooseAnIcon => 'Icon auswählen';

  @override
  String get customIconSaved => 'Eigenes Icon gespeichert!';

  @override
  String errorSavingImage(String error) {
    return 'Fehler beim Speichern des Bildes: $error';
  }

  @override
  String get highestStreak => 'Beste Streak';

  @override
  String bestStreakIs(String label) {
    return 'Deine beste Streak für diese Aufgabe ist $label.';
  }

  @override
  String get noStreakYet => 'Noch keine Streak aufgezeichnet.';

  @override
  String streakDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String streakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage Streak',
      one: '1 Tag Streak',
    );
    return '$_temp0';
  }

  @override
  String get frozenTodayLabel => 'Heute eingefroren';

  @override
  String recurringDot(String label) {
    return 'Wiederholend · $label';
  }

  @override
  String get dailyLabel => 'Täglich';

  @override
  String limitedDays(String done, String total) {
    return '$done/$total Tage';
  }

  @override
  String get repeatWeekly => 'Wöchentlich';

  @override
  String get repeatBiweekly => 'Alle 2 Wochen';

  @override
  String get repeatMonthly => 'Monatlich';

  @override
  String everyNDays(int n) {
    return 'Alle $n Tage';
  }

  @override
  String everyNDaysShort(int n) {
    return 'Alle $n T.';
  }

  @override
  String get newTask => 'Neue Aufgabe';

  @override
  String get editTaskTitle => 'Aufgabe bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get taskName => 'Aufgabenname';

  @override
  String get taskNameHint => 'z. B. 2L Wasser trinken';

  @override
  String get required => 'Pflichtfeld';

  @override
  String get descriptionOptional => 'Beschreibung (optional)';

  @override
  String get category => 'Kategorie';

  @override
  String get categoryOptional => 'Kategorie (optional)';

  @override
  String get categoryGym => 'Gym';

  @override
  String get categoryWork => 'Arbeit';

  @override
  String get categoryStudy => 'Lernen';

  @override
  String get categoryLeisure => 'Freizeit';

  @override
  String get categorySkill => 'Skill';

  @override
  String get categoryChores => 'Haushalt';

  @override
  String get categoryCreatine => 'Kreatin';

  @override
  String get recurringLabel => 'Wiederholend';

  @override
  String get xTimes => 'X-Mal';

  @override
  String get howManyDays => 'Wie viele Tage?';

  @override
  String get sameAsCycleHint =>
      'Entspricht der Zykluslänge – gleichwertig zu einer täglichen Aufgabe.';

  @override
  String get repeatsAfterCompletion => 'Wiederholt sich nach Abschluss';

  @override
  String get chooseWeekdays => 'Wochentage wählen';

  @override
  String get weekdaysOptionalHint =>
      'Optional – leer lassen, um jeden Tag anzuzeigen';

  @override
  String get repeatPattern => 'Wiederholungsmuster';

  @override
  String get scheduledDate => 'Geplantes Datum';

  @override
  String get createTask => 'Aufgabe erstellen';

  @override
  String get customRepeatInterval => 'Eigenes Wiederholungs-Intervall';

  @override
  String get howManyDaysBetween =>
      'Wie viele Tage zwischen den Wiederholungen?';

  @override
  String get daysUnit => 'Tage';

  @override
  String get invalidNumber => 'Bitte gib eine gültige Zahl ein (mindestens 1)';

  @override
  String get never => 'Nie';

  @override
  String get customDaysOption => 'Eigene Tage...';

  @override
  String get targetDays => 'Ziel-Tage';

  @override
  String alreadyDoneCycle(String done, String total) {
    return 'Bereits erledigt: $done/$total Tage in diesem Zyklus';
  }

  @override
  String get keepForFuture => 'Für zukünftige Tage behalten';

  @override
  String get keepForFutureSubtitle =>
      'In eine wiederkehrende Aufgabe umwandeln';

  @override
  String get gymTitle => 'Gym';

  @override
  String get navDaily => 'Täglich';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String get exercisesTab => 'Übungen';

  @override
  String get splitsTab => 'Splits';

  @override
  String get create => 'Erstellen';

  @override
  String get remove => 'Entfernen';

  @override
  String get rename => 'Umbenennen';

  @override
  String get gotIt => 'Alles klar';

  @override
  String get fullScreen => 'Vollbild';

  @override
  String get noWorkoutsYet => 'Noch keine Übungen';

  @override
  String get addFirstExercise => 'Füge deine erste Übung hinzu, um zu starten';

  @override
  String get noWorkoutDaysYet => 'Noch keine Workout-Tage';

  @override
  String get addExercisesToCreateDays =>
      'Füge Übungen hinzu, um Workout-Tage zu erstellen';

  @override
  String get noSplitsYet => 'Noch keine Splits';

  @override
  String get tapPlusForSplits =>
      'Tippe auf +, um Workout-Tage in Splits zu gruppieren';

  @override
  String colorForDay(String day) {
    return 'Farbe für \"$day\"';
  }

  @override
  String get clearAllHistoryTitle => 'Gesamten Verlauf löschen?';

  @override
  String clearAllHistoryMessage(String name) {
    return 'Der komplette Verlauf für \"$name\" wird entfernt.\nZuordnungen im Trainingsplan bleiben bestehen.';
  }

  @override
  String removeWorkoutTitle(String name) {
    return '\"$name\" entfernen?';
  }

  @override
  String get removeWorkoutMessage =>
      'Alle Logs werden gelöscht und die Übung aus jedem Trainingsplan entfernt.\n\nAuch getrackte Einträge aus dem Kalender entfernen?';

  @override
  String get deleteOnly => 'Nur löschen';

  @override
  String get deletePlusCalendar => 'Löschen + Kalender';

  @override
  String noteFor(String name) {
    return 'Notiz für \"$name\"';
  }

  @override
  String get addNoteHint => 'Notiz für diese Übung hinzufügen...';

  @override
  String get noteRemoved => 'Notiz entfernt.';

  @override
  String get noteSaved => 'Notiz gespeichert.';

  @override
  String get showProgressChart => 'Fortschritts-Diagramm anzeigen';

  @override
  String get deleteExerciseEllipsis => 'Übung löschen…';

  @override
  String get removeFromPlan => 'Aus diesem Plan entfernen';

  @override
  String get keepProgressHistory => 'Fortschritts-Verlauf behalten';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get editExistingNote => 'Vorhandene Notiz bearbeiten';

  @override
  String get saveNoteSubtitle => 'Notiz für diese Übung speichern';

  @override
  String get clearAllHistoryAction => 'Gesamten Verlauf löschen';

  @override
  String get clearAllHistorySubtitle => 'Alle Logs dieser Übung entfernen';

  @override
  String get deleteExercise => 'Übung löschen';

  @override
  String get deleteExerciseSubtitle => 'Aus Plan und Verlauf entfernen';

  @override
  String clearHistoryOnDay(String name, String day) {
    return 'Verlauf für \"$name\" am Tag $day löschen?';
  }

  @override
  String get exerciseNotAssigned => 'Übung nicht zugeordnet';

  @override
  String get exerciseNotAssignedMessage =>
      'Diese Übung ist noch in keinem Trainingsplan.';

  @override
  String removeNameTitle(String name) {
    return '\"$name\" entfernen';
  }

  @override
  String get chooseDaysToRemove =>
      'Tage zum Entfernen wählen (Verlauf bleibt):';

  @override
  String get renameWorkoutDay => 'Workout-Tag umbenennen';

  @override
  String get newName => 'Neuer Name';

  @override
  String get enterNewDayName => 'Neuen Namen für den Workout-Tag eingeben';

  @override
  String get nameAlreadyExists => 'Name existiert bereits';

  @override
  String dayNameExistsMessage(String name) {
    return 'Ein Workout-Tag namens \"$name\" existiert bereits. Bitte wähle einen anderen Namen.';
  }

  @override
  String renamedTo(String oldName, String newName) {
    return '\"$oldName\" in \"$newName\" umbenannt';
  }

  @override
  String get includingTracked => ' (inklusive getrackter Workouts)';

  @override
  String get renameDaySubtitle => 'Namen des Workout-Tags ändern';

  @override
  String get changeIconDialogSubtitle => 'Anderes Icon oder Bild wählen';

  @override
  String get deleteWorkoutDay => 'Workout-Tag löschen';

  @override
  String get deleteWorkoutDaySubtitle =>
      'Diesen Tag aus dem Plan entfernen (optional: getrackten Verlauf löschen)';

  @override
  String deleteDayQuestion(String day) {
    return 'Workout-Tag \"$day\" löschen?';
  }

  @override
  String get deleteDayMessage =>
      'Sollen auch getrackte Einträge aus der Vergangenheit entfernt werden (Kalender/Verlauf)?';

  @override
  String get deleteOnlyDay => 'Nur Tag löschen';

  @override
  String get deletePlusTracked => 'Löschen + getrackt';

  @override
  String dayDeletedTracked(String day) {
    return 'Workout-Tag \"$day\" gelöscht (inklusive getracktem Verlauf).';
  }

  @override
  String dayDeleted(String day) {
    return 'Workout-Tag \"$day\" gelöscht.';
  }

  @override
  String get noDataYetTitle => 'Noch keine Daten';

  @override
  String get startTrackingMessage =>
      'Beginne mit dem Tracken deiner Workouts, um hier dein Fortschritts-Diagramm zu sehen.';

  @override
  String progressFor(String name) {
    return 'Fortschritt – $name';
  }

  @override
  String setLabel(int n, String value) {
    return 'Satz $n: $value';
  }

  @override
  String setLabelBest(int n, String value) {
    return 'Satz $n: $value ✨ BEST';
  }

  @override
  String get editSplit => 'Split bearbeiten';

  @override
  String get deleteSplit => 'Split löschen';

  @override
  String get createDaysFirst =>
      'Erstelle zuerst Workout-Tage, bevor du einen Split hinzufügst.';

  @override
  String deleteSplitQuestion(String name) {
    return 'Split \"$name\" löschen?';
  }

  @override
  String get deleteSplitMessage =>
      'Nur der Split wird entfernt. Workout-Tage und getrackte Übungen bleiben unverändert.';

  @override
  String get createSplit => 'Split erstellen';

  @override
  String get splitName => 'Split-Name';

  @override
  String get splitNameHint => 'z. B. PPL, Upper/Lower';

  @override
  String get selectWorkoutDays => 'Workout-Tage auswählen';

  @override
  String get enterSplitName => 'Bitte gib einen Split-Namen ein.';

  @override
  String get selectAtLeastOneDay => 'Wähle mindestens einen Workout-Tag.';

  @override
  String splitExists(String name) {
    return 'Ein Split namens \"$name\" existiert bereits.';
  }

  @override
  String get noHistoryTitle => 'Kein Verlauf';

  @override
  String get noHistoryMessage =>
      'Noch keine getrackten Workouts. Beginne mit dem Loggen, um hier deinen Verlauf zu sehen.';

  @override
  String historyFor(String name) {
    return 'Verlauf – $name';
  }

  @override
  String logCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Logs',
      one: '1 Log',
    );
    return '$_temp0';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Sätze',
      one: '1 Satz',
    );
    return '$_temp0';
  }

  @override
  String get bestWorkout => 'Bestes Workout';

  @override
  String get onlyThisDayLogsDeleted =>
      'Nur die Logs dieser Übung an diesem Tag werden gelöscht.';

  @override
  String get deleteTodayLogsOnly => 'Nur heutige Logs löschen';

  @override
  String get alternatives => 'Alternativen';

  @override
  String get noExercisesToday => 'Heute keine Übungen';

  @override
  String get addOrAssignExercises =>
      'Füge diesem Tag Übungen hinzu oder ordne sie zu';

  @override
  String get pickColorForDay => 'Farbe für diesen Tag wählen';

  @override
  String get doneToday => 'Heute erledigt';

  @override
  String get history => 'Verlauf';

  @override
  String get removeLogsFromDate => 'Logs von diesem Datum entfernen';

  @override
  String get setAsMain => 'Als Hauptübung setzen';

  @override
  String get markAsAlternative => 'Als Alternative markieren';

  @override
  String get moveBackToMainList => 'Zurück in die Hauptliste verschieben';

  @override
  String get moveToSeparateSection => 'In separaten Bereich verschieben';

  @override
  String get deleteAllLogs => 'Alle Logs löschen';

  @override
  String get removeAllProgress => 'Allen Fortschritt dieser Übung entfernen';

  @override
  String get invalidMonth => 'Monat muss zwischen 1 und 12 liegen';

  @override
  String get invalidYear => 'Jahr muss größer als 0 sein';

  @override
  String get goToMonth => 'Zum Monat springen';

  @override
  String get selectDateHint => 'Datum wählen oder Monat antippen zum Springen';

  @override
  String get yearHint => 'z. B. 2026';

  @override
  String get go => 'Los';

  @override
  String get creatineTaken => 'Kreatin genommen';

  @override
  String get showRedDot => 'Roten Punkt im Kalender anzeigen';

  @override
  String get noWorkoutsMarked => 'Keine Workouts markiert';

  @override
  String get swipeHint => 'Wischen, Pfeile nutzen oder Monat antippen';

  @override
  String get searchWorkoutHint => 'Übung suchen... (Name oder Muskel)';

  @override
  String get add => 'Hinzufügen';

  @override
  String get update => 'Aktualisieren';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Übungen',
      one: '1 Übung',
    );
    return '$_temp0';
  }

  @override
  String get noSplitDays => 'Keine Workout-Tage in diesem Split';

  @override
  String get selectWorkoutDayError =>
      'Bitte wähle oder gib einen Workout-Tag ein.';

  @override
  String setDropsetTimeError(int set, int drop) {
    return 'Satz $set Dropset $drop: Gib eine gültige Zeit in Sekunden ein (> 0).';
  }

  @override
  String setTimeError(int set) {
    return 'Satz $set: Gib eine gültige Zeit in Sekunden ein (> 0).';
  }

  @override
  String setDropsetWeightError(int set, int drop, String rule) {
    return 'Satz $set Dropset $drop: Gib ein gültiges Gewicht ein ($rule).';
  }

  @override
  String setWeightError(int set, String rule) {
    return 'Satz $set: Gib ein gültiges Gewicht ein ($rule).';
  }

  @override
  String setDropsetRepsError(int set, int drop) {
    return 'Satz $set Dropset $drop: Gib gültige Wiederholungen ein (> 0).';
  }

  @override
  String setRepsError(int set) {
    return 'Satz $set: Gib gültige Wiederholungen ein (> 0).';
  }

  @override
  String get chooseDayForGroup =>
      'Wähle einen Workout-Tag, um die Übung einer Gruppe zuzuordnen.';

  @override
  String get workoutDay => 'Workout-Tag';

  @override
  String get customManualEntry => 'Eigener (manuelle Eingabe)';

  @override
  String get workoutDayOptional => 'Workout-Tag (optional)';

  @override
  String get workoutDayRequired => 'Workout-Tag (erforderlich)';

  @override
  String get dayHintCustom => 'z. B. Push3';

  @override
  String get dayHint => 'z. B. Push / Pull / Leg …';

  @override
  String get sets => 'Sätze';

  @override
  String get addSet => 'Satz hinzufügen';

  @override
  String get timeSeconds => 'Zeit (Sekunden)';

  @override
  String egHint(String value) {
    return 'z. B. $value';
  }

  @override
  String get removeSet => 'Satz entfernen';

  @override
  String dropsetTimeSeconds(int n) {
    return 'Dropset $n Zeit (Sekunden)';
  }

  @override
  String get removeDropset => 'Dropset entfernen';

  @override
  String get addDropset => 'Dropset hinzufügen';

  @override
  String get weightKg => 'Gewicht (kg)';

  @override
  String get reps => 'Wdh.';

  @override
  String dropsetWeightKg(int n) {
    return 'Dropset $n Gewicht (kg)';
  }

  @override
  String get standardLabel => 'Standard';

  @override
  String get weight => 'Gewicht';

  @override
  String get dateLabel => 'Datum';

  @override
  String get filter => 'Filtern';

  @override
  String get exitFullScreen => 'Vollbild verlassen';

  @override
  String get noDataForFilter => 'Keine Daten für diesen Filter.';

  @override
  String get filterBy => 'Filtern nach:';

  @override
  String get showStrongestSet => 'Zeige stärksten Satz';

  @override
  String get multipleGraphs => 'Mehrere Graphen (pro Satz)';

  @override
  String get multipleGraphsSubtitle =>
      'Schaltet zwischen einem Graphen und mehreren Satz-Linien um';

  @override
  String get minWeightEnter => 'Mindestgewicht eingeben';

  @override
  String get weightHintKg => 'z. B. 80,5 kg';

  @override
  String get chooseDateRange => 'Datumsbereich wählen';

  @override
  String get apply => 'Anwenden';

  @override
  String setN(int n) {
    return 'Satz $n';
  }

  @override
  String weightOfSet(int n) {
    return 'Gewicht von Satz $n';
  }

  @override
  String dropsetOfSet(int d, int set) {
    return 'Dropset $d von Satz $set';
  }

  @override
  String get unitKg => 'kg';

  @override
  String get unitReps => 'Wdh.';

  @override
  String get unitMin => 'Min.';

  @override
  String get unitSec => 'Sek.';

  @override
  String get unitHour => 'Std.';

  @override
  String get dropsetLabel => 'Dropset';

  @override
  String get noProgressYet => 'Noch kein Fortschritt';

  @override
  String get updateLabel => 'Update';

  @override
  String get setsWord => 'Sätze';

  @override
  String get noProfileCreated => 'Kein Profil erstellt';

  @override
  String pauseBefore(String name) {
    return 'Pause vor $name';
  }

  @override
  String get profileClassic => 'Klassisch';

  @override
  String get profileShort => 'Kurz';

  @override
  String get profileLong => 'Lang';

  @override
  String get profileIntense => 'Intensiv';

  @override
  String get pomodoroFocus => 'Fokus';

  @override
  String profileDurations(String work, String short, String long) {
    return '$work Arbeit • $short Pause • $long lange Pause';
  }

  @override
  String get statusActive => 'AKTIV';

  @override
  String get statusInactive => 'INAKTIV';

  @override
  String get toggleOn => 'AN';

  @override
  String get toggleOff => 'AUS';

  @override
  String get blockerCurrentSession => 'Aktuelle Sitzung';

  @override
  String get appsCurrentlyBlocked => 'Apps sind derzeit blockiert';

  @override
  String get toggleToStartBlocking =>
      'Aktiviere den Schalter unten, um ablenkende Apps zu blockieren';

  @override
  String get todaysStatistics => 'Heutige Statistik';

  @override
  String get totalBlockingTime => 'Gesamte Blockier-Zeit';

  @override
  String get appsBeingBlocked => 'Blockierte Apps';

  @override
  String get attemptsPrevented => 'Verhinderte Ablenkungsversuche';

  @override
  String get howItWorks => 'So funktioniert es';

  @override
  String get blockerHowItWorksText =>
      'Wenn aktiv, verhindert der Ablenkungs-Blocker das Öffnen ablenkender Apps. Er bleibt aktiv, bis du ihn manuell ausschaltest.';

  @override
  String get requiresAccessibility => 'Benötigt Bedienungshilfen-Berechtigung';

  @override
  String get blockedApps => 'Blockierte Apps';

  @override
  String get blockedAppsCategories =>
      'Social Media, Spiele, Shopping und Unterhaltungs-Apps';

  @override
  String get timerActiveCaps => '🎵 TIMER AKTIV 🎵';

  @override
  String get setTimerCaps => '⏱️ TIMER STELLEN';

  @override
  String get musicWillStop => 'Die Musik stoppt automatisch';

  @override
  String get timeRemaining => 'Verbleibende Zeit';

  @override
  String get stopTimerCaps => 'TIMER STOPPEN';

  @override
  String get startTimerCaps => 'TIMER STARTEN';

  @override
  String get minutesUnit => 'Minuten';

  @override
  String get quickPresets => 'Schnellauswahl';

  @override
  String get musicTimerHowItWorks =>
      'Stelle einen Timer, der deine Musik nach einer bestimmten Zeit automatisch pausiert. Funktioniert mit jeder Musik-App wie YouTube, Spotify und mehr. Perfekt zum Einschlafen mit Musik oder zum Begrenzen der Hörzeit.';

  @override
  String get worksWithAllMediaApps => 'Funktioniert mit allen Medien-Apps';

  @override
  String get defaultProfilesNotEditable =>
      'Standard-Profile können nicht bearbeitet oder gelöscht werden.';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get profileName => 'Profil-Name';

  @override
  String get profileNameHint => 'z. B. Mein Fokus';

  @override
  String get workDuration => 'Arbeitsdauer';

  @override
  String get minutesLabel => 'Minuten';

  @override
  String get shortBreak => 'Kurze Pause';

  @override
  String get longBreak => 'Lange Pause';

  @override
  String get cyclesBeforeLongBreak => 'Zyklen bis zur langen Pause';

  @override
  String get numberLabel => 'Anzahl';

  @override
  String get blockApps => 'Apps blockieren';

  @override
  String get blockAppsSubtitle =>
      'Ablenkende Apps während Arbeitsphasen blockieren';

  @override
  String get enterProfileName => 'Bitte gib einen Profil-Namen ein';

  @override
  String get profileUpdated => 'Profil erfolgreich aktualisiert';

  @override
  String get deleteProfile => 'Profil löschen';

  @override
  String deleteProfileConfirm(String name) {
    return 'Möchtest du das Profil \"$name\" wirklich löschen? Das kann nicht rückgängig gemacht werden.';
  }

  @override
  String get profileDeleted => 'Profil gelöscht';

  @override
  String get notificationsRequired => 'Benachrichtigungen erforderlich';

  @override
  String get notificationsRequiredText =>
      'Um dich während Fokus-Sitzungen zu informieren, benötigt Goalify die Benachrichtigungs-Berechtigung.';

  @override
  String get allow => 'Erlauben';

  @override
  String get later => 'Später';

  @override
  String get accessibilityRequired => 'Bedienungshilfen erforderlich';

  @override
  String get accessibilityRequiredText =>
      'Um ablenkende Apps während Fokus-Sitzungen zu blockieren, benötigt Goalify die Bedienungshilfen-Berechtigung.';

  @override
  String get appBlockingNotSupported => 'App-Blockierung nicht unterstützt';

  @override
  String get appBlockingNotSupportedText =>
      'App-Blockierung wird unter iOS nicht unterstützt. Du kannst den Pomodoro-Timer trotzdem nutzen, andere Apps werden jedoch nicht blockiert.';

  @override
  String get selectTimerProfile => 'Timer-Profil wählen';

  @override
  String get createCustomProfile => 'Eigenes Profil erstellen';

  @override
  String get enterValidDurations =>
      'Bitte gib gültige Werte für alle Dauern und Zyklen ein';

  @override
  String profileCreated(String name) {
    return 'Profil \"$name\" erstellt';
  }

  @override
  String cycleOf(int n) {
    return 'Zyklus $n/4';
  }

  @override
  String get running => 'Läuft';

  @override
  String get paused => 'Pausiert';

  @override
  String get ready => 'Bereit';

  @override
  String get notificationPermissionRequired =>
      'Benachrichtigungs-Berechtigung erforderlich. Bitte erlaube Benachrichtigungen in den Einstellungen.';

  @override
  String get focusModeActive => 'Fokus-Modus aktiv';

  @override
  String get otherAppsBlocked => 'Andere Apps sind blockiert';

  @override
  String get todaysProgress => 'Heutiger Fortschritt';

  @override
  String get sessions => 'Sitzungen';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get cycles => 'Zyklen';

  @override
  String get dailyFocusScore => 'Täglicher Fokus-Score';

  @override
  String get scoreExcellent => 'Exzellent! Weiter so!';

  @override
  String get scoreGreat => 'Starker Fortschritt heute!';

  @override
  String get scoreGood => 'Guter Start!';

  @override
  String get scoreGetFocused => 'Los, fokussier dich!';

  @override
  String get deleteTaskAction => 'Aufgabe löschen';

  @override
  String get taskLabel => 'Aufgabe';

  @override
  String get durationMinutes => 'Dauer (Minuten)';

  @override
  String get decimalsAllowed =>
      'Dezimalzahlen erlaubt, z. B. 0.5 = 30 Sekunden.';

  @override
  String get decimalsAllowedShort =>
      'Dezimalzahlen erlaubt (0.5 = 30 Sekunden).';

  @override
  String get pauseBeforeTask => 'Pause vor der Aufgabe (Minuten)';

  @override
  String get pauseBeforeThisTask => 'Pause vor dieser Aufgabe (Minuten)';

  @override
  String get alwaysZeroFirst => 'Für die erste Aufgabe immer 0.';

  @override
  String get ignoredForFirst => 'Wird für die erste Aufgabe ignoriert.';

  @override
  String get enterValidValues => 'Bitte gib gültige Werte ein.';

  @override
  String get saveProfile => 'Profil speichern';

  @override
  String get noSavedProfiles => 'Noch keine gespeicherten Profile.';

  @override
  String profileLoaded(String name) {
    return 'Profil \"$name\" geladen.';
  }

  @override
  String get intervalProfileNameHint => 'z. B. Kickboxen 12 Runden';

  @override
  String get createTaskFirst => 'Erstelle zuerst mindestens eine Aufgabe.';

  @override
  String profileSaved(String name) {
    return 'Profil \"$name\" gespeichert.';
  }

  @override
  String get enterValidTaskDuration =>
      'Bitte gib eine gültige Aufgabe und Dauer in Minuten ein.';

  @override
  String taskOf(int current, int total) {
    return 'Aufgabe $current / $total';
  }

  @override
  String get focusNow => 'Jetzt fokussieren';

  @override
  String get recovery => 'Erholung';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get start => 'Start';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get createProfile => 'Profil erstellen';

  @override
  String get createProfileSubtitle =>
      'Lege Aufgabe, Dauer und optionale Pause vor jeder nächsten Aufgabe fest.';

  @override
  String get taskHint => 'z. B. Seilspringen';

  @override
  String get durationHint => 'z. B. 0.5';

  @override
  String get addTask => 'Aufgabe hinzufügen';

  @override
  String get tasksInProfile => 'Aufgaben im Profil';

  @override
  String get clear => 'Leeren';

  @override
  String get noTasksAdded => 'Noch keine Aufgaben hinzugefügt.';

  @override
  String durationValue(String value) {
    return 'Dauer: $value';
  }

  @override
  String pauseDuration(String pause, String value) {
    return 'Pause: $pause • Dauer: $value';
  }

  @override
  String get sequence => 'Reihenfolge';
}
