// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Goalify';

  @override
  String get hello => 'Hello';

  @override
  String get settingsTitle => 'Options';

  @override
  String get settingsSubtitle => 'Dark mode, language & more';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDescription => 'Follow device setting';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDescription => 'Always use the light theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDescription => 'Always use the dark theme';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageSystemDescription => 'Follow device language';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get functionsTitle => 'Functions';

  @override
  String get comingSoon => 'Coming Soon';

  @override
  String get pomodoroTimer => 'Pomodoro Timer';

  @override
  String pomodoroCardRunning(String time) {
    return 'Timer running: $time';
  }

  @override
  String get pomodoroCardSubtitle => 'Work in focused intervals with breaks';

  @override
  String get distractionBlockerTitle => 'Distraction Blocker';

  @override
  String blockerCardActive(String duration) {
    return 'Active: $duration';
  }

  @override
  String get blockerCardSubtitle => 'Block distracting apps and stay focused';

  @override
  String get musicTimerTitle => 'Music Timer';

  @override
  String musicTimerCardRunning(String time) {
    return 'Timer: $time';
  }

  @override
  String get musicTimerCardSubtitle => 'Play music with a countdown timer';

  @override
  String get intervalTimerTitle => 'Interval Timer';

  @override
  String intervalCardRunning(String label, String time) {
    return 'Running: $label • $time';
  }

  @override
  String get intervalCardSubtitle =>
      'Create a task profile with breaks between tasks';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get progressTitle => 'Progress';

  @override
  String get reload => 'Reload';

  @override
  String get moreOptions => 'More options';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get clearHistoryDescription => 'Remove all stored progress data';

  @override
  String get points => 'Points';

  @override
  String get ratio => 'Ratio';

  @override
  String get rangeWeek => 'Week';

  @override
  String get rangeMonth => 'Month';

  @override
  String get rangeYear => 'Year';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get resetProgressTitle => 'Reset progress?';

  @override
  String get resetProgressMessage =>
      'All stored daily points will be removed. This cannot be undone.';

  @override
  String get currentRatio => 'Current ratio';

  @override
  String get avgRatio => 'Avg ratio';

  @override
  String get avgPerDay => 'Avg per day';

  @override
  String currentRange(String label) {
    return 'Current $label';
  }

  @override
  String ptsValue(String value) {
    return '$value pts';
  }

  @override
  String get weeklyReview => 'Weekly Review';

  @override
  String get vsLastWeek => 'vs. last week';

  @override
  String get focusTime => 'Focus time';

  @override
  String get blockerTime => 'Blocker time';

  @override
  String get tasksDone => 'Tasks done';

  @override
  String get workoutsLabel => 'Workouts';

  @override
  String get congratsTitle => 'CONGRATS!';

  @override
  String get congratsSubtitle => 'You finished all tasks for today';

  @override
  String get congratsMessage => 'Well done — keep up the streaks!';

  @override
  String get showProgress => 'Show progress';

  @override
  String get todayTitle => 'Today';

  @override
  String get historyReadOnly => 'History (read-only)';

  @override
  String get futureReadOnly => 'Future (read-only)';

  @override
  String get viewByDate => 'View by date';

  @override
  String get backToToday => 'Back to Today';

  @override
  String get pickAnotherDate => 'Pick another date';

  @override
  String get resetAll => 'Reset all';

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get addTaskToStart => 'Add a task to get started';

  @override
  String get freezeHelp =>
      'Freeze token: protects a keep-task streak for TODAY without checking it off. Long-press a keep-task and choose \"Freeze for today\". Costs 1 token.';

  @override
  String get cannotCreatePastTasks => 'Cannot create tasks for past dates.';

  @override
  String get cannotModifyPastTasks => 'Cannot modify tasks from past dates.';

  @override
  String get cannotModifyFutureTasks =>
      'Cannot modify tasks from future dates.';

  @override
  String get recurringOnlyToday =>
      'Recurring tasks can only be checked for today.';

  @override
  String get cannotDeletePastTasks => 'Cannot delete tasks from past dates.';

  @override
  String get pastTasksReadOnly => 'Tasks from past dates are read-only.';

  @override
  String get checklistNote => 'Checklist note';

  @override
  String get checklistEmpty => 'No checklist items yet. Add one below.';

  @override
  String get deleteItem => 'Delete item';

  @override
  String get addChecklistItemHint => 'Add checklist item...';

  @override
  String get saveChecklist => 'Save checklist';

  @override
  String get taskActions => 'Task actions';

  @override
  String get edit => 'Edit';

  @override
  String get editTaskSubtitle => 'Update title, description or category';

  @override
  String get changeIcon => 'Change icon';

  @override
  String get changeIconSubtitle => 'Choose a custom or predefined icon';

  @override
  String get checklistNoteSubtitle => 'Add checkbox items to this task';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get duplicateSubtitle => 'Copy this task right below';

  @override
  String get freezeForToday => 'Freeze for today';

  @override
  String get alreadyFrozen => 'Already frozen';

  @override
  String get protectYourStreak => 'Protect your streak';

  @override
  String get noTokensLeft => 'No tokens left';

  @override
  String get moveToTop => 'Move to top';

  @override
  String get moveToTopSubtitle => 'Pin this recurring task to the top';

  @override
  String get showHighestStreak => 'Show highest streak';

  @override
  String get showHighestStreakSubtitle =>
      'See your all-time best for this task';

  @override
  String get resetCurrentStreak => 'Reset current streak';

  @override
  String get resetCurrentStreakSubtitle => 'Clear today\'s streak progress';

  @override
  String get resetBestStreak => 'Reset best streak';

  @override
  String get resetBestStreakSubtitle => 'Remove your all-time best streak';

  @override
  String get deleteTaskSubtitle => 'Remove this task permanently';

  @override
  String get chooseAnIcon => 'Choose an Icon';

  @override
  String get customIconSaved => 'Custom icon saved!';

  @override
  String errorSavingImage(String error) {
    return 'Error saving image: $error';
  }

  @override
  String get highestStreak => 'Highest streak';

  @override
  String bestStreakIs(String label) {
    return 'Your best streak for this task is $label.';
  }

  @override
  String get noStreakYet => 'No streak recorded yet.';

  @override
  String streakDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String streakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get frozenTodayLabel => 'Frozen today';

  @override
  String recurringDot(String label) {
    return 'Recurring · $label';
  }

  @override
  String get dailyLabel => 'Daily';

  @override
  String limitedDays(String done, String total) {
    return '$done/$total days';
  }

  @override
  String get repeatWeekly => 'Weekly';

  @override
  String get repeatBiweekly => 'Biweekly';

  @override
  String get repeatMonthly => 'Monthly';

  @override
  String everyNDays(int n) {
    return 'Every $n days';
  }

  @override
  String everyNDaysShort(int n) {
    return 'Every ${n}d';
  }

  @override
  String get newTask => 'New Task';

  @override
  String get editTaskTitle => 'Edit Task';

  @override
  String get save => 'Save';

  @override
  String get confirm => 'Confirm';

  @override
  String get taskName => 'Task Name';

  @override
  String get taskNameHint => 'e.g. Drink 2L water';

  @override
  String get required => 'Required';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get category => 'Category';

  @override
  String get categoryOptional => 'Category (optional)';

  @override
  String get categoryGym => 'Gym';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryStudy => 'Study';

  @override
  String get categoryLeisure => 'Leisure';

  @override
  String get categorySkill => 'Skill';

  @override
  String get categoryChores => 'Chores';

  @override
  String get categoryCreatine => 'Creatine';

  @override
  String get recurringLabel => 'Recurring';

  @override
  String get xTimes => 'X-Times';

  @override
  String get howManyDays => 'How many days?';

  @override
  String get sameAsCycleHint =>
      'Same as cycle length — equivalent to a daily recurring task.';

  @override
  String get repeatsAfterCompletion => 'Repeats after completion';

  @override
  String get chooseWeekdays => 'Choose weekdays';

  @override
  String get weekdaysOptionalHint => 'Optional – leave empty to show every day';

  @override
  String get repeatPattern => 'Repeat Pattern';

  @override
  String get scheduledDate => 'Scheduled Date';

  @override
  String get createTask => 'Create Task';

  @override
  String get customRepeatInterval => 'Custom Repeat Interval';

  @override
  String get howManyDaysBetween => 'How many days between each repeat?';

  @override
  String get daysUnit => 'days';

  @override
  String get invalidNumber => 'Please enter a valid number (1 or greater)';

  @override
  String get never => 'Never';

  @override
  String get customDaysOption => 'Custom days...';

  @override
  String get targetDays => 'Target Days';

  @override
  String alreadyDoneCycle(String done, String total) {
    return 'Already done: $done/$total days this cycle';
  }

  @override
  String get keepForFuture => 'Keep for future days';

  @override
  String get keepForFutureSubtitle => 'Turn into a recurring task';

  @override
  String get gymTitle => 'Gym';

  @override
  String get navDaily => 'Daily';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get exercisesTab => 'Exercises';

  @override
  String get splitsTab => 'Splits';

  @override
  String get create => 'Create';

  @override
  String get remove => 'Remove';

  @override
  String get rename => 'Rename';

  @override
  String get gotIt => 'Got it';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get noWorkoutsYet => 'No workouts yet';

  @override
  String get addFirstExercise => 'Add your first exercise to get started';

  @override
  String get noWorkoutDaysYet => 'No workout days yet';

  @override
  String get addExercisesToCreateDays => 'Add exercises to create workout days';

  @override
  String get noSplitsYet => 'No splits yet';

  @override
  String get tapPlusForSplits => 'Tap + to group workout days in splits';

  @override
  String colorForDay(String day) {
    return 'Color for \"$day\"';
  }

  @override
  String get clearAllHistoryTitle => 'Clear all history?';

  @override
  String clearAllHistoryMessage(String name) {
    return 'This will remove the complete history for \"$name\".\nAssignments in your workout plan remain.';
  }

  @override
  String removeWorkoutTitle(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String get removeWorkoutMessage =>
      'This will delete all logs and remove the exercise from every workout plan.\n\nAlso remove tracked past entries from the calendar?';

  @override
  String get deleteOnly => 'Delete only';

  @override
  String get deletePlusCalendar => 'Delete + Calendar';

  @override
  String noteFor(String name) {
    return 'Note for \"$name\"';
  }

  @override
  String get addNoteHint => 'Add a note for this exercise...';

  @override
  String get noteRemoved => 'Note removed.';

  @override
  String get noteSaved => 'Note saved.';

  @override
  String get showProgressChart => 'Show progress chart';

  @override
  String get deleteExerciseEllipsis => 'Delete exercise…';

  @override
  String get removeFromPlan => 'Remove from this plan';

  @override
  String get keepProgressHistory => 'Keep progress history';

  @override
  String get addNote => 'Add note';

  @override
  String get editExistingNote => 'Edit existing note';

  @override
  String get saveNoteSubtitle => 'Save a note for this exercise';

  @override
  String get clearAllHistoryAction => 'Clear all history';

  @override
  String get clearAllHistorySubtitle => 'Remove all logs for this exercise';

  @override
  String get deleteExercise => 'Delete exercise';

  @override
  String get deleteExerciseSubtitle => 'Remove from plan and history';

  @override
  String clearHistoryOnDay(String name, String day) {
    return 'Clear history for \"$name\" on $day?';
  }

  @override
  String get exerciseNotAssigned => 'Exercise not assigned';

  @override
  String get exerciseNotAssignedMessage =>
      'This exercise is not part of any workout plan yet.';

  @override
  String removeNameTitle(String name) {
    return 'Remove \"$name\"';
  }

  @override
  String get chooseDaysToRemove => 'Choose days to remove (history stays):';

  @override
  String get renameWorkoutDay => 'Rename Workout Day';

  @override
  String get newName => 'New name';

  @override
  String get enterNewDayName => 'Enter new workout day name';

  @override
  String get nameAlreadyExists => 'Name already exists';

  @override
  String dayNameExistsMessage(String name) {
    return 'A workout day named \"$name\" already exists. Please choose a different name.';
  }

  @override
  String renamedTo(String oldName, String newName) {
    return 'Renamed \"$oldName\" to \"$newName\"';
  }

  @override
  String get includingTracked => ' (including tracked workouts)';

  @override
  String get renameDaySubtitle => 'Change the workout day name';

  @override
  String get changeIconDialogSubtitle => 'Choose a different icon or image';

  @override
  String get deleteWorkoutDay => 'Delete Workout Day';

  @override
  String get deleteWorkoutDaySubtitle =>
      'Remove this day from plan (optional: remove tracked history)';

  @override
  String deleteDayQuestion(String day) {
    return 'Delete workout day \"$day\"?';
  }

  @override
  String get deleteDayMessage =>
      'Do you also want to remove tracked entries from the past (calendar/history)?';

  @override
  String get deleteOnlyDay => 'Delete only day';

  @override
  String get deletePlusTracked => 'Delete + tracked';

  @override
  String dayDeletedTracked(String day) {
    return 'Workout day \"$day\" deleted (including tracked history).';
  }

  @override
  String dayDeleted(String day) {
    return 'Workout day \"$day\" deleted.';
  }

  @override
  String get noDataYetTitle => 'No Data Yet';

  @override
  String get startTrackingMessage =>
      'Start tracking your workouts to see your progress chart here.';

  @override
  String progressFor(String name) {
    return 'Progress – $name';
  }

  @override
  String setLabel(int n, String value) {
    return 'Set $n: $value';
  }

  @override
  String setLabelBest(int n, String value) {
    return 'Set $n: $value ✨ BEST';
  }

  @override
  String get editSplit => 'Edit split';

  @override
  String get deleteSplit => 'Delete split';

  @override
  String get createDaysFirst =>
      'Create workout days first before adding a split.';

  @override
  String deleteSplitQuestion(String name) {
    return 'Delete split \"$name\"?';
  }

  @override
  String get deleteSplitMessage =>
      'Only the split will be removed. Workout days and tracked exercises remain unchanged.';

  @override
  String get createSplit => 'Create Split';

  @override
  String get splitName => 'Split name';

  @override
  String get splitNameHint => 'e.g. PPL, Upper/Lower';

  @override
  String get selectWorkoutDays => 'Select workout days';

  @override
  String get enterSplitName => 'Please enter a split name.';

  @override
  String get selectAtLeastOneDay => 'Select at least one workout day.';

  @override
  String splitExists(String name) {
    return 'A split named \"$name\" already exists.';
  }

  @override
  String get noHistoryTitle => 'No History';

  @override
  String get noHistoryMessage =>
      'No tracked workouts yet. Start logging to see your history here.';

  @override
  String historyFor(String name) {
    return 'History – $name';
  }

  @override
  String logCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count logs',
      one: '1 log',
    );
    return '$_temp0';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sets',
      one: '1 set',
    );
    return '$_temp0';
  }

  @override
  String get bestWorkout => 'Best Workout';

  @override
  String get onlyThisDayLogsDeleted =>
      'Only this exercise\'s logs for this day will be deleted.';

  @override
  String get deleteTodayLogsOnly => 'Delete today\'s logs only';

  @override
  String get alternatives => 'Alternatives';

  @override
  String get noExercisesToday => 'No exercises today';

  @override
  String get addOrAssignExercises => 'Add or assign exercises to this day';

  @override
  String get pickColorForDay => 'Pick color for this day';

  @override
  String get doneToday => 'Done today';

  @override
  String get history => 'History';

  @override
  String get removeLogsFromDate => 'Remove logs from this date';

  @override
  String get setAsMain => 'Set as main exercise';

  @override
  String get markAsAlternative => 'Mark as alternative';

  @override
  String get moveBackToMainList => 'Move back to the main list';

  @override
  String get moveToSeparateSection => 'Move to a separate section';

  @override
  String get deleteAllLogs => 'Delete all logs';

  @override
  String get removeAllProgress => 'Remove all progress for this exercise';

  @override
  String get invalidMonth => 'Month must be between 1 and 12';

  @override
  String get invalidYear => 'Year must be greater than 0';

  @override
  String get goToMonth => 'Go to month';

  @override
  String get selectDateHint => 'Select a date or tap month to jump';

  @override
  String get yearHint => 'e.g. 2026';

  @override
  String get go => 'Go';

  @override
  String get creatineTaken => 'Creatine taken';

  @override
  String get showRedDot => 'Show red dot in calendar';

  @override
  String get noWorkoutsMarked => 'No workouts marked';

  @override
  String get swipeHint => 'Swipe, use arrows, or tap month to jump';

  @override
  String get searchWorkoutHint => 'Search workout... (name or muscle)';

  @override
  String get add => 'Add';

  @override
  String get update => 'Update';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count exercises',
      one: '1 exercise',
    );
    return '$_temp0';
  }

  @override
  String get noSplitDays => 'No workout days in this split';

  @override
  String get selectWorkoutDayError => 'Please select or enter a workout day.';

  @override
  String setDropsetTimeError(int set, int drop) {
    return 'Set $set Dropset $drop: Enter a valid time in seconds (> 0).';
  }

  @override
  String setTimeError(int set) {
    return 'Set $set: Enter a valid time in seconds (> 0).';
  }

  @override
  String setDropsetWeightError(int set, int drop, String rule) {
    return 'Set $set Dropset $drop: Enter a valid weight ($rule).';
  }

  @override
  String setWeightError(int set, String rule) {
    return 'Set $set: Enter a valid weight ($rule).';
  }

  @override
  String setDropsetRepsError(int set, int drop) {
    return 'Set $set Dropset $drop: Enter valid reps (> 0).';
  }

  @override
  String setRepsError(int set) {
    return 'Set $set: Enter valid reps (> 0).';
  }

  @override
  String get chooseDayForGroup =>
      'Choose a workout day to assign this exercise to a group.';

  @override
  String get workoutDay => 'Workout day';

  @override
  String get customManualEntry => 'Custom (manual entry)';

  @override
  String get workoutDayOptional => 'Workout day (optional)';

  @override
  String get workoutDayRequired => 'Workout day (required)';

  @override
  String get dayHintCustom => 'e.g. Push3';

  @override
  String get dayHint => 'e.g. Push / Pull / Leg …';

  @override
  String get sets => 'Sets';

  @override
  String get addSet => 'Add set';

  @override
  String get timeSeconds => 'Time (seconds)';

  @override
  String egHint(String value) {
    return 'e.g. $value';
  }

  @override
  String get removeSet => 'Remove set';

  @override
  String dropsetTimeSeconds(int n) {
    return 'Dropset $n Time (seconds)';
  }

  @override
  String get removeDropset => 'Remove dropset';

  @override
  String get addDropset => 'Add dropset';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get reps => 'Reps';

  @override
  String dropsetWeightKg(int n) {
    return 'Dropset $n Weight (kg)';
  }

  @override
  String get standardLabel => 'Standard';

  @override
  String get weight => 'Weight';

  @override
  String get dateLabel => 'Date';

  @override
  String get filter => 'Filter';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String get noDataForFilter => 'No data for this filter.';

  @override
  String get filterBy => 'Filter by:';

  @override
  String get showStrongestSet => 'Show strongest set';

  @override
  String get multipleGraphs => 'Multiple graphs (per set)';

  @override
  String get multipleGraphsSubtitle =>
      'Switches between one graph and multiple set lines';

  @override
  String get minWeightEnter => 'Enter minimum weight';

  @override
  String get weightHintKg => 'e.g. 80.5 kg';

  @override
  String get chooseDateRange => 'Choose date range';

  @override
  String get apply => 'Apply';

  @override
  String setN(int n) {
    return 'Set $n';
  }

  @override
  String weightOfSet(int n) {
    return 'Weight of set $n';
  }

  @override
  String dropsetOfSet(int d, int set) {
    return 'Dropset $d of set $set';
  }

  @override
  String get unitKg => 'kg';

  @override
  String get unitReps => 'reps';

  @override
  String get unitMin => 'min';

  @override
  String get unitSec => 's';

  @override
  String get unitHour => 'h';

  @override
  String get dropsetLabel => 'Dropset';

  @override
  String get noProgressYet => 'No progress yet';

  @override
  String get updateLabel => 'Update';

  @override
  String get setsWord => 'Sets';

  @override
  String get noProfileCreated => 'No profile created';

  @override
  String pauseBefore(String name) {
    return 'Pause before $name';
  }

  @override
  String get profileClassic => 'Classic';

  @override
  String get profileShort => 'Short';

  @override
  String get profileLong => 'Long';

  @override
  String get profileIntense => 'Intense';

  @override
  String get pomodoroFocus => 'Focus';

  @override
  String profileDurations(String work, String short, String long) {
    return '$work work • $short break • $long long break';
  }

  @override
  String get statusActive => 'ACTIVE';

  @override
  String get statusInactive => 'INACTIVE';

  @override
  String get toggleOn => 'ON';

  @override
  String get toggleOff => 'OFF';

  @override
  String get blockerCurrentSession => 'Current Session';

  @override
  String get appsCurrentlyBlocked => 'Apps are currently blocked';

  @override
  String get appsNotBlocked => 'Apps are not blocked';

  @override
  String distractionAttemptsPrevented(int count) {
    return '$count distraction attempts prevented';
  }

  @override
  String get toggleToStartBlocking =>
      'Toggle the switch below to start blocking distracting apps';

  @override
  String get todaysStatistics => 'Today\'s Statistics';

  @override
  String get totalBlockingTime => 'Total Blocking Time';

  @override
  String get appsBeingBlocked => 'Apps Being Blocked';

  @override
  String get attemptsPrevented => 'Distraction Attempts Prevented';

  @override
  String get howItWorks => 'How it works';

  @override
  String get blockerHowItWorksText =>
      'When active, the Distraction Blocker prevents you from opening distracting apps. It will stay active until you manually turn it off.';

  @override
  String get requiresAccessibility => 'Requires Accessibility permission';

  @override
  String get blockedApps => 'Blocked Apps';

  @override
  String get blockedAppsCategories =>
      'Social Media, Games, Shopping, and Entertainment apps';

  @override
  String get timerActiveCaps => '🎵 TIMER ACTIVE 🎵';

  @override
  String get setTimerCaps => '⏱️ SET TIMER';

  @override
  String get musicWillStop => 'Music will stop automatically';

  @override
  String get timeRemaining => 'Time Remaining';

  @override
  String get stopTimerCaps => 'STOP TIMER';

  @override
  String get startTimerCaps => 'START TIMER';

  @override
  String get minutesUnit => 'minutes';

  @override
  String get quickPresets => 'Quick Presets';

  @override
  String get musicTimerHowItWorks =>
      'Set a timer to automatically pause your music after a specific duration. Works with any music app including YouTube, Spotify, and more. Perfect for falling asleep to music or limiting listening time.';

  @override
  String get worksWithAllMediaApps => 'Works with all media apps';

  @override
  String get defaultProfilesNotEditable =>
      'Default profiles cannot be edited or deleted.';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get profileName => 'Profile Name';

  @override
  String get profileNameHint => 'e.g. My Focus';

  @override
  String get workDuration => 'Work Duration';

  @override
  String get minutesLabel => 'Minutes';

  @override
  String get shortBreak => 'Short Break';

  @override
  String get longBreak => 'Long Break';

  @override
  String get cyclesBeforeLongBreak => 'Cycles before Long Break';

  @override
  String get numberLabel => 'Number';

  @override
  String get blockApps => 'Block Apps';

  @override
  String get blockAppsSubtitle => 'Block distracting apps during work sessions';

  @override
  String get enterProfileName => 'Please enter a profile name';

  @override
  String get profileUpdated => 'Profile successfully updated';

  @override
  String get deleteProfile => 'Delete Profile';

  @override
  String deleteProfileConfirm(String name) {
    return 'Are you sure you want to delete the profile \"$name\"? This action cannot be undone.';
  }

  @override
  String get profileDeleted => 'Profile deleted';

  @override
  String get notificationsRequired => 'Notifications Required';

  @override
  String get notificationsRequiredText =>
      'To keep you informed during focus sessions, Goalify needs notification permissions.';

  @override
  String get allow => 'Allow';

  @override
  String get later => 'Later';

  @override
  String get accessibilityRequired => 'Accessibility Required';

  @override
  String get accessibilityRequiredText =>
      'To block distracting apps during focus sessions, Goalify needs accessibility permissions.';

  @override
  String get appBlockingNotSupported => 'App Blocking Not Supported';

  @override
  String get appBlockingNotSupportedText =>
      'App blocking is not supported on iOS. You can still use the Pomodoro timer, but other apps won\'t be blocked.';

  @override
  String get selectTimerProfile => 'Select Timer Profile';

  @override
  String get createCustomProfile => 'Create Custom Profile';

  @override
  String get enterValidDurations =>
      'Please enter valid values for all durations and cycles';

  @override
  String profileCreated(String name) {
    return 'Profile \"$name\" created';
  }

  @override
  String cycleOf(int n) {
    return 'Cycle $n/4';
  }

  @override
  String get running => 'Running';

  @override
  String get paused => 'Paused';

  @override
  String get ready => 'Ready';

  @override
  String get notificationPermissionRequired =>
      'Notification permission required. Please allow notifications in settings.';

  @override
  String get focusModeActive => 'Focus Mode Active';

  @override
  String get otherAppsBlocked => 'Other apps are blocked';

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String get sessions => 'Sessions';

  @override
  String get thisWeek => 'This Week';

  @override
  String get cycles => 'Cycles';

  @override
  String get dailyFocusScore => 'Daily Focus Score';

  @override
  String get scoreExcellent => 'Excellent! Keep it up!';

  @override
  String get scoreGreat => 'Great progress today!';

  @override
  String get scoreGood => 'Good start!';

  @override
  String get scoreGetFocused => 'Let\'s get focused!';

  @override
  String get deleteTaskAction => 'Delete Task';

  @override
  String get taskLabel => 'Task';

  @override
  String get durationMinutes => 'Duration (minutes)';

  @override
  String get decimalsAllowed => 'Decimals allowed, e.g. 0.5 = 30 seconds.';

  @override
  String get decimalsAllowedShort => 'Decimals allowed (0.5 = 30 seconds).';

  @override
  String get pauseBeforeTask => 'Pause before task (minutes)';

  @override
  String get pauseBeforeThisTask => 'Pause before this task (minutes)';

  @override
  String get alwaysZeroFirst => 'Always 0 for the first task.';

  @override
  String get ignoredForFirst => 'Ignored for the first task.';

  @override
  String get enterValidValues => 'Please enter valid values.';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get noSavedProfiles => 'No saved profiles yet.';

  @override
  String profileLoaded(String name) {
    return 'Profile \"$name\" loaded.';
  }

  @override
  String get intervalProfileNameHint => 'e.g. Kickboxing 12 Rounds';

  @override
  String get createTaskFirst => 'Create at least one task first.';

  @override
  String profileSaved(String name) {
    return 'Profile \"$name\" saved.';
  }

  @override
  String get enterValidTaskDuration =>
      'Please enter a valid task and duration in minutes.';

  @override
  String taskOf(int current, int total) {
    return 'Task $current / $total';
  }

  @override
  String get focusNow => 'Focus now';

  @override
  String get recovery => 'Recovery';

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get start => 'Start';

  @override
  String get reset => 'Reset';

  @override
  String get createProfile => 'Create Profile';

  @override
  String get createProfileSubtitle =>
      'Set task, duration and optional break before each next task.';

  @override
  String get taskHint => 'e.g. Jump rope';

  @override
  String get durationHint => 'e.g. 0.5';

  @override
  String get addTask => 'Add task';

  @override
  String get tasksInProfile => 'Tasks in profile';

  @override
  String get clear => 'Clear';

  @override
  String get noTasksAdded => 'No tasks added yet.';

  @override
  String durationValue(String value) {
    return 'Duration: $value';
  }

  @override
  String pauseDuration(String pause, String value) {
    return 'Pause: $pause • Duration: $value';
  }

  @override
  String get sequence => 'Sequence';
}
