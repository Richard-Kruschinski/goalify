import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('ru'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Goalify'**
  String get appTitle;

  /// No description provided for @hello.
  ///
  /// In en, this message translates to:
  /// **'Hello'**
  String get hello;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get settingsTitle;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Dark mode, language & more'**
  String get settingsSubtitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow device setting'**
  String get themeSystemDescription;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use the light theme'**
  String get themeLightDescription;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Always use the dark theme'**
  String get themeDarkDescription;

  /// No description provided for @dayStartSection.
  ///
  /// In en, this message translates to:
  /// **'Start of day'**
  String get dayStartSection;

  /// No description provided for @dayStartDescription.
  ///
  /// In en, this message translates to:
  /// **'The time at which a new day begins. Daily tasks, gym and creatine tracking and the progress charts only roll over to the next day at this time.'**
  String get dayStartDescription;

  /// No description provided for @soundsSection.
  ///
  /// In en, this message translates to:
  /// **'Sounds'**
  String get soundsSection;

  /// No description provided for @soundsEnabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Sound effects'**
  String get soundsEnabledTitle;

  /// No description provided for @soundsEnabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Play sounds for actions'**
  String get soundsEnabledDescription;

  /// No description provided for @soundVolume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get soundVolume;

  /// No description provided for @soundEventDailyTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get soundEventDailyTaskCompleted;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Follow device language'**
  String get languageSystemDescription;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchHint;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @functionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Functions'**
  String get functionsTitle;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get comingSoon;

  /// No description provided for @pomodoroTimer.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro Timer'**
  String get pomodoroTimer;

  /// No description provided for @pomodoroCardRunning.
  ///
  /// In en, this message translates to:
  /// **'Timer running: {time}'**
  String pomodoroCardRunning(String time);

  /// No description provided for @pomodoroCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Work in focused intervals with breaks'**
  String get pomodoroCardSubtitle;

  /// No description provided for @distractionBlockerTitle.
  ///
  /// In en, this message translates to:
  /// **'Distraction Blocker'**
  String get distractionBlockerTitle;

  /// No description provided for @blockerCardActive.
  ///
  /// In en, this message translates to:
  /// **'Active: {duration}'**
  String blockerCardActive(String duration);

  /// No description provided for @blockerCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Block distracting apps and stay focused'**
  String get blockerCardSubtitle;

  /// No description provided for @musicTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Music Timer'**
  String get musicTimerTitle;

  /// No description provided for @musicTimerCardRunning.
  ///
  /// In en, this message translates to:
  /// **'Timer: {time}'**
  String musicTimerCardRunning(String time);

  /// No description provided for @musicTimerCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Play music with a countdown timer'**
  String get musicTimerCardSubtitle;

  /// No description provided for @intervalTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Interval Timer'**
  String get intervalTimerTitle;

  /// No description provided for @intervalCardRunning.
  ///
  /// In en, this message translates to:
  /// **'Running: {label} • {time}'**
  String intervalCardRunning(String label, String time);

  /// No description provided for @intervalCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a task profile with breaks between tasks'**
  String get intervalCardSubtitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @clearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get clearHistory;

  /// No description provided for @clearHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Remove all stored progress data'**
  String get clearHistoryDescription;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @ratio.
  ///
  /// In en, this message translates to:
  /// **'Ratio'**
  String get ratio;

  /// No description provided for @rangeWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get rangeWeek;

  /// No description provided for @rangeMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get rangeMonth;

  /// No description provided for @rangeYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get rangeYear;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @resetProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset progress?'**
  String get resetProgressTitle;

  /// No description provided for @resetProgressMessage.
  ///
  /// In en, this message translates to:
  /// **'All stored daily points will be removed. This cannot be undone.'**
  String get resetProgressMessage;

  /// No description provided for @currentRatio.
  ///
  /// In en, this message translates to:
  /// **'Current ratio'**
  String get currentRatio;

  /// No description provided for @avgRatio.
  ///
  /// In en, this message translates to:
  /// **'Avg ratio'**
  String get avgRatio;

  /// No description provided for @avgPerDay.
  ///
  /// In en, this message translates to:
  /// **'Avg per day'**
  String get avgPerDay;

  /// No description provided for @currentRange.
  ///
  /// In en, this message translates to:
  /// **'Current {label}'**
  String currentRange(String label);

  /// No description provided for @ptsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} pts'**
  String ptsValue(String value);

  /// No description provided for @weeklyReview.
  ///
  /// In en, this message translates to:
  /// **'Weekly Review'**
  String get weeklyReview;

  /// No description provided for @vsLastWeek.
  ///
  /// In en, this message translates to:
  /// **'vs. last week'**
  String get vsLastWeek;

  /// No description provided for @focusTime.
  ///
  /// In en, this message translates to:
  /// **'Focus time'**
  String get focusTime;

  /// No description provided for @blockerTime.
  ///
  /// In en, this message translates to:
  /// **'Blocker time'**
  String get blockerTime;

  /// No description provided for @tasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks done'**
  String get tasksDone;

  /// No description provided for @workoutsLabel.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workoutsLabel;

  /// No description provided for @congratsTitle.
  ///
  /// In en, this message translates to:
  /// **'CONGRATS!'**
  String get congratsTitle;

  /// No description provided for @congratsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You finished all tasks for today'**
  String get congratsSubtitle;

  /// No description provided for @congratsMessage.
  ///
  /// In en, this message translates to:
  /// **'Well done — keep up the streaks!'**
  String get congratsMessage;

  /// No description provided for @showProgress.
  ///
  /// In en, this message translates to:
  /// **'Show progress'**
  String get showProgress;

  /// No description provided for @todayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// No description provided for @historyReadOnly.
  ///
  /// In en, this message translates to:
  /// **'History (read-only)'**
  String get historyReadOnly;

  /// No description provided for @futureReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Future (read-only)'**
  String get futureReadOnly;

  /// No description provided for @viewByDate.
  ///
  /// In en, this message translates to:
  /// **'View by date'**
  String get viewByDate;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get backToToday;

  /// No description provided for @pickAnotherDate.
  ///
  /// In en, this message translates to:
  /// **'Pick another date'**
  String get pickAnotherDate;

  /// No description provided for @resetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all'**
  String get resetAll;

  /// No description provided for @sortTasks.
  ///
  /// In en, this message translates to:
  /// **'Sort tasks'**
  String get sortTasks;

  /// No description provided for @sortManual.
  ///
  /// In en, this message translates to:
  /// **'Custom order'**
  String get sortManual;

  /// No description provided for @sortAlphabetical.
  ///
  /// In en, this message translates to:
  /// **'Alphabetical'**
  String get sortAlphabetical;

  /// No description provided for @sortByStreak.
  ///
  /// In en, this message translates to:
  /// **'By streak'**
  String get sortByStreak;

  /// No description provided for @sortByPoints.
  ///
  /// In en, this message translates to:
  /// **'By points'**
  String get sortByPoints;

  /// No description provided for @sortByType.
  ///
  /// In en, this message translates to:
  /// **'Group by type'**
  String get sortByType;

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @addTaskToStart.
  ///
  /// In en, this message translates to:
  /// **'Add a task to get started'**
  String get addTaskToStart;

  /// No description provided for @freezeHelp.
  ///
  /// In en, this message translates to:
  /// **'Freeze token: protects a keep-task streak for TODAY without checking it off. Long-press a keep-task and choose \"Freeze for today\". Costs 1 token.'**
  String get freezeHelp;

  /// No description provided for @cannotCreatePastTasks.
  ///
  /// In en, this message translates to:
  /// **'Cannot create tasks for past dates.'**
  String get cannotCreatePastTasks;

  /// No description provided for @cannotModifyPastTasks.
  ///
  /// In en, this message translates to:
  /// **'Cannot modify tasks from past dates.'**
  String get cannotModifyPastTasks;

  /// No description provided for @cannotModifyFutureTasks.
  ///
  /// In en, this message translates to:
  /// **'Cannot modify tasks from future dates.'**
  String get cannotModifyFutureTasks;

  /// No description provided for @recurringOnlyToday.
  ///
  /// In en, this message translates to:
  /// **'Recurring tasks can only be checked for today.'**
  String get recurringOnlyToday;

  /// No description provided for @cannotDeletePastTasks.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete tasks from past dates.'**
  String get cannotDeletePastTasks;

  /// No description provided for @pastTasksReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Tasks from past dates are read-only.'**
  String get pastTasksReadOnly;

  /// No description provided for @checklistNote.
  ///
  /// In en, this message translates to:
  /// **'Checklist note'**
  String get checklistNote;

  /// No description provided for @checklistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No checklist items yet. Add one below.'**
  String get checklistEmpty;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete item'**
  String get deleteItem;

  /// No description provided for @addChecklistItemHint.
  ///
  /// In en, this message translates to:
  /// **'Add checklist item...'**
  String get addChecklistItemHint;

  /// No description provided for @saveChecklist.
  ///
  /// In en, this message translates to:
  /// **'Save checklist'**
  String get saveChecklist;

  /// No description provided for @taskActions.
  ///
  /// In en, this message translates to:
  /// **'Task actions'**
  String get taskActions;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update title, description or category'**
  String get editTaskSubtitle;

  /// No description provided for @changeIcon.
  ///
  /// In en, this message translates to:
  /// **'Change icon'**
  String get changeIcon;

  /// No description provided for @changeIconSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a custom or predefined icon'**
  String get changeIconSubtitle;

  /// No description provided for @checklistNoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add checkbox items to this task'**
  String get checklistNoteSubtitle;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @duplicateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy this task right below'**
  String get duplicateSubtitle;

  /// No description provided for @freezeForToday.
  ///
  /// In en, this message translates to:
  /// **'Freeze for today'**
  String get freezeForToday;

  /// No description provided for @alreadyFrozen.
  ///
  /// In en, this message translates to:
  /// **'Already frozen'**
  String get alreadyFrozen;

  /// No description provided for @protectYourStreak.
  ///
  /// In en, this message translates to:
  /// **'Protect your streak'**
  String get protectYourStreak;

  /// No description provided for @noTokensLeft.
  ///
  /// In en, this message translates to:
  /// **'No tokens left'**
  String get noTokensLeft;

  /// No description provided for @moveToTop.
  ///
  /// In en, this message translates to:
  /// **'Move to top'**
  String get moveToTop;

  /// No description provided for @moveToTopSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pin this recurring task to the top'**
  String get moveToTopSubtitle;

  /// No description provided for @showHighestStreak.
  ///
  /// In en, this message translates to:
  /// **'Show highest streak'**
  String get showHighestStreak;

  /// No description provided for @showHighestStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See your all-time best for this task'**
  String get showHighestStreakSubtitle;

  /// No description provided for @resetCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Reset current streak'**
  String get resetCurrentStreak;

  /// No description provided for @resetCurrentStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear today\'s streak progress'**
  String get resetCurrentStreakSubtitle;

  /// No description provided for @resetBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Reset best streak'**
  String get resetBestStreak;

  /// No description provided for @resetBestStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove your all-time best streak'**
  String get resetBestStreakSubtitle;

  /// No description provided for @deleteTaskSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this task permanently'**
  String get deleteTaskSubtitle;

  /// No description provided for @chooseAnIcon.
  ///
  /// In en, this message translates to:
  /// **'Choose an Icon'**
  String get chooseAnIcon;

  /// No description provided for @customIconSaved.
  ///
  /// In en, this message translates to:
  /// **'Custom icon saved!'**
  String get customIconSaved;

  /// No description provided for @errorSavingImage.
  ///
  /// In en, this message translates to:
  /// **'Error saving image: {error}'**
  String errorSavingImage(String error);

  /// No description provided for @highestStreak.
  ///
  /// In en, this message translates to:
  /// **'Highest streak'**
  String get highestStreak;

  /// No description provided for @bestStreakIs.
  ///
  /// In en, this message translates to:
  /// **'Your best streak for this task is {label}.'**
  String bestStreakIs(String label);

  /// No description provided for @noStreakYet.
  ///
  /// In en, this message translates to:
  /// **'No streak recorded yet.'**
  String get noStreakYet;

  /// No description provided for @streakDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String streakDayCount(int count);

  /// No description provided for @streakCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} days streak}}'**
  String streakCount(int count);

  /// No description provided for @streakCycleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1x in a row} other{{count}x in a row}}'**
  String streakCycleCount(int count);

  /// No description provided for @streakCycleUnitCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 cycle} other{{count} cycles}}'**
  String streakCycleUnitCount(int count);

  /// No description provided for @frozenTodayLabel.
  ///
  /// In en, this message translates to:
  /// **'Frozen today'**
  String get frozenTodayLabel;

  /// No description provided for @recurringDot.
  ///
  /// In en, this message translates to:
  /// **'Recurring · {label}'**
  String recurringDot(String label);

  /// No description provided for @dailyLabel.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get dailyLabel;

  /// No description provided for @limitedDays.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} days'**
  String limitedDays(String done, String total);

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get repeatWeekly;

  /// No description provided for @repeatBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Biweekly'**
  String get repeatBiweekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get repeatMonthly;

  /// No description provided for @everyNDays.
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String everyNDays(int n);

  /// No description provided for @everyNDaysShort.
  ///
  /// In en, this message translates to:
  /// **'Every {n}d'**
  String everyNDaysShort(int n);

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @editTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get editTaskTitle;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @taskName.
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskName;

  /// No description provided for @taskNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Drink 2L water'**
  String get taskNameHint;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @categoryOptional.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get categoryOptional;

  /// No description provided for @categoryGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get categoryGym;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get categoryStudy;

  /// No description provided for @categoryLeisure.
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get categoryLeisure;

  /// No description provided for @categorySkill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get categorySkill;

  /// No description provided for @categoryChores.
  ///
  /// In en, this message translates to:
  /// **'Chores'**
  String get categoryChores;

  /// No description provided for @categoryCreatine.
  ///
  /// In en, this message translates to:
  /// **'Creatine'**
  String get categoryCreatine;

  /// No description provided for @recurringLabel.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringLabel;

  /// No description provided for @xTimes.
  ///
  /// In en, this message translates to:
  /// **'X-Times'**
  String get xTimes;

  /// No description provided for @howManyDays.
  ///
  /// In en, this message translates to:
  /// **'How many days?'**
  String get howManyDays;

  /// No description provided for @sameAsCycleHint.
  ///
  /// In en, this message translates to:
  /// **'Same as cycle length — equivalent to a daily recurring task.'**
  String get sameAsCycleHint;

  /// No description provided for @repeatsAfterCompletion.
  ///
  /// In en, this message translates to:
  /// **'Repeats after completion'**
  String get repeatsAfterCompletion;

  /// No description provided for @chooseWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Choose weekdays'**
  String get chooseWeekdays;

  /// No description provided for @weekdaysOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Optional – leave empty to show every day'**
  String get weekdaysOptionalHint;

  /// No description provided for @repeatPattern.
  ///
  /// In en, this message translates to:
  /// **'Repeat Pattern'**
  String get repeatPattern;

  /// No description provided for @scheduledDate.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Date'**
  String get scheduledDate;

  /// No description provided for @createTask.
  ///
  /// In en, this message translates to:
  /// **'Create Task'**
  String get createTask;

  /// No description provided for @customRepeatInterval.
  ///
  /// In en, this message translates to:
  /// **'Custom Repeat Interval'**
  String get customRepeatInterval;

  /// No description provided for @howManyDaysBetween.
  ///
  /// In en, this message translates to:
  /// **'How many days between each repeat?'**
  String get howManyDaysBetween;

  /// No description provided for @daysUnit.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get daysUnit;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number (1 or greater)'**
  String get invalidNumber;

  /// No description provided for @never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get never;

  /// No description provided for @customDaysOption.
  ///
  /// In en, this message translates to:
  /// **'Custom days...'**
  String get customDaysOption;

  /// No description provided for @targetDays.
  ///
  /// In en, this message translates to:
  /// **'Target Days'**
  String get targetDays;

  /// No description provided for @alreadyDoneCycle.
  ///
  /// In en, this message translates to:
  /// **'Already done: {done}/{total} days this cycle'**
  String alreadyDoneCycle(String done, String total);

  /// No description provided for @keepForFuture.
  ///
  /// In en, this message translates to:
  /// **'Keep for future days'**
  String get keepForFuture;

  /// No description provided for @keepForFutureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Turn into a recurring task'**
  String get keepForFutureSubtitle;

  /// No description provided for @gymTitle.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get gymTitle;

  /// No description provided for @navDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get navDaily;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @exercisesTab.
  ///
  /// In en, this message translates to:
  /// **'Exercises'**
  String get exercisesTab;

  /// No description provided for @splitsTab.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get splitsTab;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @noWorkoutsYet.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get noWorkoutsYet;

  /// No description provided for @addFirstExercise.
  ///
  /// In en, this message translates to:
  /// **'Add your first exercise to get started'**
  String get addFirstExercise;

  /// No description provided for @noWorkoutDaysYet.
  ///
  /// In en, this message translates to:
  /// **'No workout days yet'**
  String get noWorkoutDaysYet;

  /// No description provided for @addExercisesToCreateDays.
  ///
  /// In en, this message translates to:
  /// **'Add exercises to create workout days'**
  String get addExercisesToCreateDays;

  /// No description provided for @noSplitsYet.
  ///
  /// In en, this message translates to:
  /// **'No splits yet'**
  String get noSplitsYet;

  /// No description provided for @tapPlusForSplits.
  ///
  /// In en, this message translates to:
  /// **'Tap + to group workout days in splits'**
  String get tapPlusForSplits;

  /// No description provided for @colorForDay.
  ///
  /// In en, this message translates to:
  /// **'Color for \"{day}\"'**
  String colorForDay(String day);

  /// No description provided for @clearAllHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear all history?'**
  String get clearAllHistoryTitle;

  /// No description provided for @clearAllHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove the complete history for \"{name}\".\nAssignments in your workout plan remain.'**
  String clearAllHistoryMessage(String name);

  /// No description provided for @removeWorkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String removeWorkoutTitle(String name);

  /// No description provided for @removeWorkoutMessage.
  ///
  /// In en, this message translates to:
  /// **'This will delete all logs and remove the exercise from every workout plan.\n\nAlso remove tracked past entries from the calendar?'**
  String get removeWorkoutMessage;

  /// No description provided for @deleteOnly.
  ///
  /// In en, this message translates to:
  /// **'Delete only'**
  String get deleteOnly;

  /// No description provided for @deletePlusCalendar.
  ///
  /// In en, this message translates to:
  /// **'Delete + Calendar'**
  String get deletePlusCalendar;

  /// No description provided for @noteFor.
  ///
  /// In en, this message translates to:
  /// **'Note for \"{name}\"'**
  String noteFor(String name);

  /// No description provided for @addNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Add a note for this exercise...'**
  String get addNoteHint;

  /// No description provided for @noteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Note removed.'**
  String get noteRemoved;

  /// No description provided for @noteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved.'**
  String get noteSaved;

  /// No description provided for @showProgressChart.
  ///
  /// In en, this message translates to:
  /// **'Show progress chart'**
  String get showProgressChart;

  /// No description provided for @deleteExerciseEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise…'**
  String get deleteExerciseEllipsis;

  /// No description provided for @removeFromPlan.
  ///
  /// In en, this message translates to:
  /// **'Remove from this plan'**
  String get removeFromPlan;

  /// No description provided for @keepProgressHistory.
  ///
  /// In en, this message translates to:
  /// **'Keep progress history'**
  String get keepProgressHistory;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add note'**
  String get addNote;

  /// No description provided for @editExistingNote.
  ///
  /// In en, this message translates to:
  /// **'Edit existing note'**
  String get editExistingNote;

  /// No description provided for @saveNoteSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a note for this exercise'**
  String get saveNoteSubtitle;

  /// No description provided for @clearAllHistoryAction.
  ///
  /// In en, this message translates to:
  /// **'Clear all history'**
  String get clearAllHistoryAction;

  /// No description provided for @clearAllHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all logs for this exercise'**
  String get clearAllHistorySubtitle;

  /// No description provided for @deleteExercise.
  ///
  /// In en, this message translates to:
  /// **'Delete exercise'**
  String get deleteExercise;

  /// No description provided for @deleteExerciseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from plan and history'**
  String get deleteExerciseSubtitle;

  /// No description provided for @clearHistoryOnDay.
  ///
  /// In en, this message translates to:
  /// **'Clear history for \"{name}\" on {day}?'**
  String clearHistoryOnDay(String name, String day);

  /// No description provided for @exerciseNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Exercise not assigned'**
  String get exerciseNotAssigned;

  /// No description provided for @exerciseNotAssignedMessage.
  ///
  /// In en, this message translates to:
  /// **'This exercise is not part of any workout plan yet.'**
  String get exerciseNotAssignedMessage;

  /// No description provided for @removeNameTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"'**
  String removeNameTitle(String name);

  /// No description provided for @chooseDaysToRemove.
  ///
  /// In en, this message translates to:
  /// **'Choose days to remove (history stays):'**
  String get chooseDaysToRemove;

  /// No description provided for @renameWorkoutDay.
  ///
  /// In en, this message translates to:
  /// **'Rename Workout Day'**
  String get renameWorkoutDay;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newName;

  /// No description provided for @enterNewDayName.
  ///
  /// In en, this message translates to:
  /// **'Enter new workout day name'**
  String get enterNewDayName;

  /// No description provided for @nameAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'Name already exists'**
  String get nameAlreadyExists;

  /// No description provided for @dayNameExistsMessage.
  ///
  /// In en, this message translates to:
  /// **'A workout day named \"{name}\" already exists. Please choose a different name.'**
  String dayNameExistsMessage(String name);

  /// No description provided for @renamedTo.
  ///
  /// In en, this message translates to:
  /// **'Renamed \"{oldName}\" to \"{newName}\"'**
  String renamedTo(String oldName, String newName);

  /// No description provided for @includingTracked.
  ///
  /// In en, this message translates to:
  /// **' (including tracked workouts)'**
  String get includingTracked;

  /// No description provided for @renameDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Change the workout day name'**
  String get renameDaySubtitle;

  /// No description provided for @changeIconDialogSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a different icon or image'**
  String get changeIconDialogSubtitle;

  /// No description provided for @deleteWorkoutDay.
  ///
  /// In en, this message translates to:
  /// **'Delete Workout Day'**
  String get deleteWorkoutDay;

  /// No description provided for @deleteWorkoutDaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this day from plan (optional: remove tracked history)'**
  String get deleteWorkoutDaySubtitle;

  /// No description provided for @deleteDayQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete workout day \"{day}\"?'**
  String deleteDayQuestion(String day);

  /// No description provided for @deleteDayMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you also want to remove tracked entries from the past (calendar/history)?'**
  String get deleteDayMessage;

  /// No description provided for @deleteOnlyDay.
  ///
  /// In en, this message translates to:
  /// **'Delete only day'**
  String get deleteOnlyDay;

  /// No description provided for @deletePlusTracked.
  ///
  /// In en, this message translates to:
  /// **'Delete + tracked'**
  String get deletePlusTracked;

  /// No description provided for @dayDeletedTracked.
  ///
  /// In en, this message translates to:
  /// **'Workout day \"{day}\" deleted (including tracked history).'**
  String dayDeletedTracked(String day);

  /// No description provided for @dayDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workout day \"{day}\" deleted.'**
  String dayDeleted(String day);

  /// No description provided for @noDataYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Data Yet'**
  String get noDataYetTitle;

  /// No description provided for @startTrackingMessage.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your workouts to see your progress chart here.'**
  String get startTrackingMessage;

  /// No description provided for @progressFor.
  ///
  /// In en, this message translates to:
  /// **'Progress – {name}'**
  String progressFor(String name);

  /// No description provided for @setLabel.
  ///
  /// In en, this message translates to:
  /// **'Set {n}: {value}'**
  String setLabel(int n, String value);

  /// No description provided for @setLabelBest.
  ///
  /// In en, this message translates to:
  /// **'Set {n}: {value} ✨ BEST'**
  String setLabelBest(int n, String value);

  /// No description provided for @editSplit.
  ///
  /// In en, this message translates to:
  /// **'Edit split'**
  String get editSplit;

  /// No description provided for @deleteSplit.
  ///
  /// In en, this message translates to:
  /// **'Delete split'**
  String get deleteSplit;

  /// No description provided for @createDaysFirst.
  ///
  /// In en, this message translates to:
  /// **'Create workout days first before adding a split.'**
  String get createDaysFirst;

  /// No description provided for @deleteSplitQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete split \"{name}\"?'**
  String deleteSplitQuestion(String name);

  /// No description provided for @deleteSplitMessage.
  ///
  /// In en, this message translates to:
  /// **'Only the split will be removed. Workout days and tracked exercises remain unchanged.'**
  String get deleteSplitMessage;

  /// No description provided for @createSplit.
  ///
  /// In en, this message translates to:
  /// **'Create Split'**
  String get createSplit;

  /// No description provided for @splitName.
  ///
  /// In en, this message translates to:
  /// **'Split name'**
  String get splitName;

  /// No description provided for @splitNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. PPL, Upper/Lower'**
  String get splitNameHint;

  /// No description provided for @selectWorkoutDays.
  ///
  /// In en, this message translates to:
  /// **'Select workout days'**
  String get selectWorkoutDays;

  /// No description provided for @enterSplitName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a split name.'**
  String get enterSplitName;

  /// No description provided for @selectAtLeastOneDay.
  ///
  /// In en, this message translates to:
  /// **'Select at least one workout day.'**
  String get selectAtLeastOneDay;

  /// No description provided for @splitExists.
  ///
  /// In en, this message translates to:
  /// **'A split named \"{name}\" already exists.'**
  String splitExists(String name);

  /// No description provided for @noHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'No History'**
  String get noHistoryTitle;

  /// No description provided for @noHistoryMessage.
  ///
  /// In en, this message translates to:
  /// **'No tracked workouts yet. Start logging to see your history here.'**
  String get noHistoryMessage;

  /// No description provided for @historyFor.
  ///
  /// In en, this message translates to:
  /// **'History – {name}'**
  String historyFor(String name);

  /// No description provided for @logCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 log} other{{count} logs}}'**
  String logCount(int count);

  /// No description provided for @setsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 set} other{{count} sets}}'**
  String setsCount(int count);

  /// No description provided for @bestWorkout.
  ///
  /// In en, this message translates to:
  /// **'Best Workout'**
  String get bestWorkout;

  /// No description provided for @onlyThisDayLogsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Only this exercise\'s logs for this day will be deleted.'**
  String get onlyThisDayLogsDeleted;

  /// No description provided for @deleteTodayLogsOnly.
  ///
  /// In en, this message translates to:
  /// **'Delete today\'s logs only'**
  String get deleteTodayLogsOnly;

  /// No description provided for @alternatives.
  ///
  /// In en, this message translates to:
  /// **'Alternatives'**
  String get alternatives;

  /// No description provided for @noExercisesToday.
  ///
  /// In en, this message translates to:
  /// **'No exercises today'**
  String get noExercisesToday;

  /// No description provided for @addOrAssignExercises.
  ///
  /// In en, this message translates to:
  /// **'Add or assign exercises to this day'**
  String get addOrAssignExercises;

  /// No description provided for @pickColorForDay.
  ///
  /// In en, this message translates to:
  /// **'Pick color for this day'**
  String get pickColorForDay;

  /// No description provided for @doneToday.
  ///
  /// In en, this message translates to:
  /// **'Done today'**
  String get doneToday;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @removeLogsFromDate.
  ///
  /// In en, this message translates to:
  /// **'Remove logs from this date'**
  String get removeLogsFromDate;

  /// No description provided for @setAsMain.
  ///
  /// In en, this message translates to:
  /// **'Set as main exercise'**
  String get setAsMain;

  /// No description provided for @markAsAlternative.
  ///
  /// In en, this message translates to:
  /// **'Mark as alternative'**
  String get markAsAlternative;

  /// No description provided for @moveBackToMainList.
  ///
  /// In en, this message translates to:
  /// **'Move back to the main list'**
  String get moveBackToMainList;

  /// No description provided for @moveToSeparateSection.
  ///
  /// In en, this message translates to:
  /// **'Move to a separate section'**
  String get moveToSeparateSection;

  /// No description provided for @deleteAllLogs.
  ///
  /// In en, this message translates to:
  /// **'Delete all logs'**
  String get deleteAllLogs;

  /// No description provided for @removeAllProgress.
  ///
  /// In en, this message translates to:
  /// **'Remove all progress for this exercise'**
  String get removeAllProgress;

  /// No description provided for @invalidMonth.
  ///
  /// In en, this message translates to:
  /// **'Month must be between 1 and 12'**
  String get invalidMonth;

  /// No description provided for @invalidYear.
  ///
  /// In en, this message translates to:
  /// **'Year must be greater than 0'**
  String get invalidYear;

  /// No description provided for @goToMonth.
  ///
  /// In en, this message translates to:
  /// **'Go to month'**
  String get goToMonth;

  /// No description provided for @selectDateHint.
  ///
  /// In en, this message translates to:
  /// **'Select a date or tap month to jump'**
  String get selectDateHint;

  /// No description provided for @yearHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 2026'**
  String get yearHint;

  /// No description provided for @go.
  ///
  /// In en, this message translates to:
  /// **'Go'**
  String get go;

  /// No description provided for @creatineTaken.
  ///
  /// In en, this message translates to:
  /// **'Creatine taken'**
  String get creatineTaken;

  /// No description provided for @showRedDot.
  ///
  /// In en, this message translates to:
  /// **'Show red dot in calendar'**
  String get showRedDot;

  /// No description provided for @noWorkoutsMarked.
  ///
  /// In en, this message translates to:
  /// **'No workouts marked'**
  String get noWorkoutsMarked;

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe, use arrows, or tap month to jump'**
  String get swipeHint;

  /// No description provided for @searchWorkoutHint.
  ///
  /// In en, this message translates to:
  /// **'Search workout... (name or muscle)'**
  String get searchWorkoutHint;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @exerciseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 exercise} other{{count} exercises}}'**
  String exerciseCount(int count);

  /// No description provided for @noSplitDays.
  ///
  /// In en, this message translates to:
  /// **'No workout days in this split'**
  String get noSplitDays;

  /// No description provided for @selectWorkoutDayError.
  ///
  /// In en, this message translates to:
  /// **'Please select or enter a workout day.'**
  String get selectWorkoutDayError;

  /// No description provided for @setDropsetTimeError.
  ///
  /// In en, this message translates to:
  /// **'Set {set} Dropset {drop}: Enter a valid time in seconds (> 0).'**
  String setDropsetTimeError(int set, int drop);

  /// No description provided for @setTimeError.
  ///
  /// In en, this message translates to:
  /// **'Set {set}: Enter a valid time in seconds (> 0).'**
  String setTimeError(int set);

  /// No description provided for @setDropsetWeightError.
  ///
  /// In en, this message translates to:
  /// **'Set {set} Dropset {drop}: Enter a valid weight ({rule}).'**
  String setDropsetWeightError(int set, int drop, String rule);

  /// No description provided for @setWeightError.
  ///
  /// In en, this message translates to:
  /// **'Set {set}: Enter a valid weight ({rule}).'**
  String setWeightError(int set, String rule);

  /// No description provided for @setDropsetRepsError.
  ///
  /// In en, this message translates to:
  /// **'Set {set} Dropset {drop}: Enter valid reps (> 0).'**
  String setDropsetRepsError(int set, int drop);

  /// No description provided for @setRepsError.
  ///
  /// In en, this message translates to:
  /// **'Set {set}: Enter valid reps (> 0).'**
  String setRepsError(int set);

  /// No description provided for @chooseDayForGroup.
  ///
  /// In en, this message translates to:
  /// **'Choose a workout day to assign this exercise to a group.'**
  String get chooseDayForGroup;

  /// No description provided for @workoutDay.
  ///
  /// In en, this message translates to:
  /// **'Workout day'**
  String get workoutDay;

  /// No description provided for @customManualEntry.
  ///
  /// In en, this message translates to:
  /// **'Custom (manual entry)'**
  String get customManualEntry;

  /// No description provided for @workoutDayOptional.
  ///
  /// In en, this message translates to:
  /// **'Workout day (optional)'**
  String get workoutDayOptional;

  /// No description provided for @workoutDayRequired.
  ///
  /// In en, this message translates to:
  /// **'Workout day (required)'**
  String get workoutDayRequired;

  /// No description provided for @dayHintCustom.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push3'**
  String get dayHintCustom;

  /// No description provided for @dayHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Push / Pull / Leg …'**
  String get dayHint;

  /// No description provided for @sets.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get sets;

  /// No description provided for @addSet.
  ///
  /// In en, this message translates to:
  /// **'Add set'**
  String get addSet;

  /// No description provided for @timeSeconds.
  ///
  /// In en, this message translates to:
  /// **'Time (seconds)'**
  String get timeSeconds;

  /// No description provided for @egHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. {value}'**
  String egHint(String value);

  /// No description provided for @removeSet.
  ///
  /// In en, this message translates to:
  /// **'Remove set'**
  String get removeSet;

  /// No description provided for @dropsetTimeSeconds.
  ///
  /// In en, this message translates to:
  /// **'Dropset {n} Time (seconds)'**
  String dropsetTimeSeconds(int n);

  /// No description provided for @removeDropset.
  ///
  /// In en, this message translates to:
  /// **'Remove dropset'**
  String get removeDropset;

  /// No description provided for @addDropset.
  ///
  /// In en, this message translates to:
  /// **'Add dropset'**
  String get addDropset;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @reps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get reps;

  /// No description provided for @dropsetWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Dropset {n} Weight (kg)'**
  String dropsetWeightKg(int n);

  /// No description provided for @standardLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get standardLabel;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @exitFullScreen.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullScreen;

  /// No description provided for @noDataForFilter.
  ///
  /// In en, this message translates to:
  /// **'No data for this filter.'**
  String get noDataForFilter;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by:'**
  String get filterBy;

  /// No description provided for @showStrongestSet.
  ///
  /// In en, this message translates to:
  /// **'Show strongest set'**
  String get showStrongestSet;

  /// No description provided for @multipleGraphs.
  ///
  /// In en, this message translates to:
  /// **'Multiple graphs (per set)'**
  String get multipleGraphs;

  /// No description provided for @multipleGraphsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switches between one graph and multiple set lines'**
  String get multipleGraphsSubtitle;

  /// No description provided for @minWeightEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter minimum weight'**
  String get minWeightEnter;

  /// No description provided for @weightHintKg.
  ///
  /// In en, this message translates to:
  /// **'e.g. 80.5 kg'**
  String get weightHintKg;

  /// No description provided for @chooseDateRange.
  ///
  /// In en, this message translates to:
  /// **'Choose date range'**
  String get chooseDateRange;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @setN.
  ///
  /// In en, this message translates to:
  /// **'Set {n}'**
  String setN(int n);

  /// No description provided for @weightOfSet.
  ///
  /// In en, this message translates to:
  /// **'Weight of set {n}'**
  String weightOfSet(int n);

  /// No description provided for @dropsetOfSet.
  ///
  /// In en, this message translates to:
  /// **'Dropset {d} of set {set}'**
  String dropsetOfSet(int d, int set);

  /// No description provided for @unitKg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// No description provided for @unitReps.
  ///
  /// In en, this message translates to:
  /// **'reps'**
  String get unitReps;

  /// No description provided for @unitMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMin;

  /// No description provided for @unitSec.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get unitSec;

  /// No description provided for @unitHour.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get unitHour;

  /// No description provided for @dropsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Dropset'**
  String get dropsetLabel;

  /// No description provided for @noProgressYet.
  ///
  /// In en, this message translates to:
  /// **'No progress yet'**
  String get noProgressYet;

  /// No description provided for @updateLabel.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateLabel;

  /// No description provided for @setsWord.
  ///
  /// In en, this message translates to:
  /// **'Sets'**
  String get setsWord;

  /// No description provided for @noProfileCreated.
  ///
  /// In en, this message translates to:
  /// **'No profile created'**
  String get noProfileCreated;

  /// No description provided for @pauseBefore.
  ///
  /// In en, this message translates to:
  /// **'Pause before {name}'**
  String pauseBefore(String name);

  /// No description provided for @profileClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get profileClassic;

  /// No description provided for @profileShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get profileShort;

  /// No description provided for @profileLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get profileLong;

  /// No description provided for @profileIntense.
  ///
  /// In en, this message translates to:
  /// **'Intense'**
  String get profileIntense;

  /// No description provided for @pomodoroFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get pomodoroFocus;

  /// No description provided for @profileDurations.
  ///
  /// In en, this message translates to:
  /// **'{work} work • {short} break • {long} long break'**
  String profileDurations(String work, String short, String long);

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'INACTIVE'**
  String get statusInactive;

  /// No description provided for @toggleOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get toggleOn;

  /// No description provided for @toggleOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get toggleOff;

  /// No description provided for @blockerCurrentSession.
  ///
  /// In en, this message translates to:
  /// **'Current Session'**
  String get blockerCurrentSession;

  /// No description provided for @appsCurrentlyBlocked.
  ///
  /// In en, this message translates to:
  /// **'Apps are currently blocked'**
  String get appsCurrentlyBlocked;

  /// No description provided for @appsNotBlocked.
  ///
  /// In en, this message translates to:
  /// **'Apps are not blocked'**
  String get appsNotBlocked;

  /// No description provided for @distractionAttemptsPrevented.
  ///
  /// In en, this message translates to:
  /// **'{count} distraction attempts prevented'**
  String distractionAttemptsPrevented(int count);

  /// No description provided for @toggleToStartBlocking.
  ///
  /// In en, this message translates to:
  /// **'Toggle the switch below to start blocking distracting apps'**
  String get toggleToStartBlocking;

  /// No description provided for @todaysStatistics.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Statistics'**
  String get todaysStatistics;

  /// No description provided for @totalBlockingTime.
  ///
  /// In en, this message translates to:
  /// **'Total Blocking Time'**
  String get totalBlockingTime;

  /// No description provided for @appsBeingBlocked.
  ///
  /// In en, this message translates to:
  /// **'Apps Being Blocked'**
  String get appsBeingBlocked;

  /// No description provided for @attemptsPrevented.
  ///
  /// In en, this message translates to:
  /// **'Distraction Attempts Prevented'**
  String get attemptsPrevented;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @blockerHowItWorksText.
  ///
  /// In en, this message translates to:
  /// **'When active, the Distraction Blocker prevents you from opening distracting apps. It will stay active until you manually turn it off.'**
  String get blockerHowItWorksText;

  /// No description provided for @requiresAccessibility.
  ///
  /// In en, this message translates to:
  /// **'Requires Accessibility permission'**
  String get requiresAccessibility;

  /// No description provided for @blockedApps.
  ///
  /// In en, this message translates to:
  /// **'Blocked Apps'**
  String get blockedApps;

  /// No description provided for @blockedAppsCategories.
  ///
  /// In en, this message translates to:
  /// **'Social Media, Games, Shopping, and Entertainment apps'**
  String get blockedAppsCategories;

  /// No description provided for @requiresScreenTime.
  ///
  /// In en, this message translates to:
  /// **'Requires the iOS Screen Time permission (iOS 16 or newer)'**
  String get requiresScreenTime;

  /// No description provided for @blockedAppsSelectionIos.
  ///
  /// In en, this message translates to:
  /// **'You choose which apps and categories get blocked via the iOS system picker'**
  String get blockedAppsSelectionIos;

  /// No description provided for @chooseAppsToBlock.
  ///
  /// In en, this message translates to:
  /// **'Choose apps'**
  String get chooseAppsToBlock;

  /// No description provided for @screenTimePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Screen Time access was declined. Please allow it in Settings > Screen Time.'**
  String get screenTimePermissionDenied;

  /// No description provided for @noAppsSelectedForBlocking.
  ///
  /// In en, this message translates to:
  /// **'No apps selected. Please choose the apps you want to block first.'**
  String get noAppsSelectedForBlocking;

  /// No description provided for @blockerStartFailed.
  ///
  /// In en, this message translates to:
  /// **'The blocker could not be started. Please check the permissions.'**
  String get blockerStartFailed;

  /// No description provided for @blockerIosVersionUnsupported.
  ///
  /// In en, this message translates to:
  /// **'App blocking requires iOS 16 or newer.'**
  String get blockerIosVersionUnsupported;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @timerActiveCaps.
  ///
  /// In en, this message translates to:
  /// **'🎵 TIMER ACTIVE 🎵'**
  String get timerActiveCaps;

  /// No description provided for @setTimerCaps.
  ///
  /// In en, this message translates to:
  /// **'⏱️ SET TIMER'**
  String get setTimerCaps;

  /// No description provided for @musicWillStop.
  ///
  /// In en, this message translates to:
  /// **'Music will stop automatically'**
  String get musicWillStop;

  /// No description provided for @musicTimerIdleHint.
  ///
  /// In en, this message translates to:
  /// **'Pick a duration below to start'**
  String get musicTimerIdleHint;

  /// No description provided for @timeRemaining.
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get timeRemaining;

  /// No description provided for @stopTimerCaps.
  ///
  /// In en, this message translates to:
  /// **'STOP TIMER'**
  String get stopTimerCaps;

  /// No description provided for @startTimerCaps.
  ///
  /// In en, this message translates to:
  /// **'START TIMER'**
  String get startTimerCaps;

  /// No description provided for @minutesUnit.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get minutesUnit;

  /// No description provided for @quickPresets.
  ///
  /// In en, this message translates to:
  /// **'Quick Presets'**
  String get quickPresets;

  /// No description provided for @musicTimerHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'Set a timer to automatically pause your music after a specific duration. Works with any music app including YouTube, Spotify, and more. Perfect for falling asleep to music or limiting listening time.'**
  String get musicTimerHowItWorks;

  /// No description provided for @worksWithAllMediaApps.
  ///
  /// In en, this message translates to:
  /// **'Works with all media apps'**
  String get worksWithAllMediaApps;

  /// No description provided for @defaultProfilesNotEditable.
  ///
  /// In en, this message translates to:
  /// **'Default profiles cannot be edited or deleted.'**
  String get defaultProfilesNotEditable;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. My Focus'**
  String get profileNameHint;

  /// No description provided for @workDuration.
  ///
  /// In en, this message translates to:
  /// **'Work Duration'**
  String get workDuration;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get minutesLabel;

  /// No description provided for @shortBreak.
  ///
  /// In en, this message translates to:
  /// **'Short Break'**
  String get shortBreak;

  /// No description provided for @longBreak.
  ///
  /// In en, this message translates to:
  /// **'Long Break'**
  String get longBreak;

  /// No description provided for @cyclesBeforeLongBreak.
  ///
  /// In en, this message translates to:
  /// **'Cycles before Long Break'**
  String get cyclesBeforeLongBreak;

  /// No description provided for @numberLabel.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get numberLabel;

  /// No description provided for @blockApps.
  ///
  /// In en, this message translates to:
  /// **'Block Apps'**
  String get blockApps;

  /// No description provided for @blockAppsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Block distracting apps during work sessions'**
  String get blockAppsSubtitle;

  /// No description provided for @enterProfileName.
  ///
  /// In en, this message translates to:
  /// **'Please enter a profile name'**
  String get enterProfileName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile successfully updated'**
  String get profileUpdated;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete Profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the profile \"{name}\"? This action cannot be undone.'**
  String deleteProfileConfirm(String name);

  /// No description provided for @profileDeleted.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted'**
  String get profileDeleted;

  /// No description provided for @notificationsRequired.
  ///
  /// In en, this message translates to:
  /// **'Notifications Required'**
  String get notificationsRequired;

  /// No description provided for @notificationsRequiredText.
  ///
  /// In en, this message translates to:
  /// **'To keep you informed during focus sessions, Goalify needs notification permissions.'**
  String get notificationsRequiredText;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @accessibilityRequired.
  ///
  /// In en, this message translates to:
  /// **'Accessibility Required'**
  String get accessibilityRequired;

  /// No description provided for @accessibilityRequiredText.
  ///
  /// In en, this message translates to:
  /// **'To block distracting apps during focus sessions, Goalify needs accessibility permissions.'**
  String get accessibilityRequiredText;

  /// No description provided for @appBlockingNotSupported.
  ///
  /// In en, this message translates to:
  /// **'App Blocking Not Supported'**
  String get appBlockingNotSupported;

  /// No description provided for @appBlockingNotSupportedText.
  ///
  /// In en, this message translates to:
  /// **'App blocking is not supported on iOS. You can still use the Pomodoro timer, but other apps won\'t be blocked.'**
  String get appBlockingNotSupportedText;

  /// No description provided for @selectTimerProfile.
  ///
  /// In en, this message translates to:
  /// **'Select Timer Profile'**
  String get selectTimerProfile;

  /// No description provided for @createCustomProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Custom Profile'**
  String get createCustomProfile;

  /// No description provided for @enterValidDurations.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid values for all durations and cycles'**
  String get enterValidDurations;

  /// No description provided for @profileCreated.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" created'**
  String profileCreated(String name);

  /// No description provided for @cycleOf.
  ///
  /// In en, this message translates to:
  /// **'Cycle {n}/4'**
  String cycleOf(int n);

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission required. Please allow notifications in settings.'**
  String get notificationPermissionRequired;

  /// No description provided for @focusModeActive.
  ///
  /// In en, this message translates to:
  /// **'Focus Mode Active'**
  String get focusModeActive;

  /// No description provided for @otherAppsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Other apps are blocked'**
  String get otherAppsBlocked;

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @cycles.
  ///
  /// In en, this message translates to:
  /// **'Cycles'**
  String get cycles;

  /// No description provided for @dailyFocusScore.
  ///
  /// In en, this message translates to:
  /// **'Daily Focus Score'**
  String get dailyFocusScore;

  /// No description provided for @scoreExcellent.
  ///
  /// In en, this message translates to:
  /// **'Excellent! Keep it up!'**
  String get scoreExcellent;

  /// No description provided for @scoreGreat.
  ///
  /// In en, this message translates to:
  /// **'Great progress today!'**
  String get scoreGreat;

  /// No description provided for @scoreGood.
  ///
  /// In en, this message translates to:
  /// **'Good start!'**
  String get scoreGood;

  /// No description provided for @scoreGetFocused.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get focused!'**
  String get scoreGetFocused;

  /// No description provided for @deleteTaskAction.
  ///
  /// In en, this message translates to:
  /// **'Delete Task'**
  String get deleteTaskAction;

  /// No description provided for @taskLabel.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get taskLabel;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get durationMinutes;

  /// No description provided for @decimalsAllowed.
  ///
  /// In en, this message translates to:
  /// **'Decimals allowed, e.g. 0.5 = 30 seconds.'**
  String get decimalsAllowed;

  /// No description provided for @decimalsAllowedShort.
  ///
  /// In en, this message translates to:
  /// **'Decimals allowed (0.5 = 30 seconds).'**
  String get decimalsAllowedShort;

  /// No description provided for @pauseBeforeTask.
  ///
  /// In en, this message translates to:
  /// **'Pause before task (minutes)'**
  String get pauseBeforeTask;

  /// No description provided for @pauseBeforeThisTask.
  ///
  /// In en, this message translates to:
  /// **'Pause before this task (minutes)'**
  String get pauseBeforeThisTask;

  /// No description provided for @alwaysZeroFirst.
  ///
  /// In en, this message translates to:
  /// **'Always 0 for the first task.'**
  String get alwaysZeroFirst;

  /// No description provided for @ignoredForFirst.
  ///
  /// In en, this message translates to:
  /// **'Ignored for the first task.'**
  String get ignoredForFirst;

  /// No description provided for @enterValidValues.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid values.'**
  String get enterValidValues;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @noSavedProfiles.
  ///
  /// In en, this message translates to:
  /// **'No saved profiles yet.'**
  String get noSavedProfiles;

  /// No description provided for @profileLoaded.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" loaded.'**
  String profileLoaded(String name);

  /// No description provided for @intervalProfileNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Kickboxing 12 Rounds'**
  String get intervalProfileNameHint;

  /// No description provided for @createTaskFirst.
  ///
  /// In en, this message translates to:
  /// **'Create at least one task first.'**
  String get createTaskFirst;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile \"{name}\" saved.'**
  String profileSaved(String name);

  /// No description provided for @enterValidTaskDuration.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid task and duration in minutes.'**
  String get enterValidTaskDuration;

  /// No description provided for @taskOf.
  ///
  /// In en, this message translates to:
  /// **'Task {current} / {total}'**
  String taskOf(int current, int total);

  /// No description provided for @focusNow.
  ///
  /// In en, this message translates to:
  /// **'Focus now'**
  String get focusNow;

  /// No description provided for @recovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recovery;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @createProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Profile'**
  String get createProfile;

  /// No description provided for @createProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set task, duration and optional break before each next task.'**
  String get createProfileSubtitle;

  /// No description provided for @taskHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Jump rope'**
  String get taskHint;

  /// No description provided for @durationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 0.5'**
  String get durationHint;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTask;

  /// No description provided for @tasksInProfile.
  ///
  /// In en, this message translates to:
  /// **'Tasks in profile'**
  String get tasksInProfile;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @noTasksAdded.
  ///
  /// In en, this message translates to:
  /// **'No tasks added yet.'**
  String get noTasksAdded;

  /// No description provided for @durationValue.
  ///
  /// In en, this message translates to:
  /// **'Duration: {value}'**
  String durationValue(String value);

  /// No description provided for @pauseDuration.
  ///
  /// In en, this message translates to:
  /// **'Pause: {pause} • Duration: {value}'**
  String pauseDuration(String pause, String value);

  /// No description provided for @sequence.
  ///
  /// In en, this message translates to:
  /// **'Sequence'**
  String get sequence;

  /// No description provided for @weightSettings.
  ///
  /// In en, this message translates to:
  /// **'Weight settings'**
  String get weightSettings;

  /// No description provided for @weightSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set the bar weight for this exercise'**
  String get weightSettingsSubtitle;

  /// No description provided for @weightSettingsFor.
  ///
  /// In en, this message translates to:
  /// **'Weight settings — {name}'**
  String weightSettingsFor(String name);

  /// No description provided for @barWeightKg.
  ///
  /// In en, this message translates to:
  /// **'Bar weight (kg)'**
  String get barWeightKg;

  /// No description provided for @barWeightExplain.
  ///
  /// In en, this message translates to:
  /// **'Enter what the empty bar weighs, e.g. 20. Leave empty if the exercise has no bar.'**
  String get barWeightExplain;

  /// No description provided for @trackedIncludesBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Tracked weight includes the bar'**
  String get trackedIncludesBarTitle;

  /// No description provided for @barPlusPlates.
  ///
  /// In en, this message translates to:
  /// **'Bar {bar} + {plates} {unit}'**
  String barPlusPlates(String bar, String plates, String unit);

  /// No description provided for @applyBarWeightToPastTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to past entries?'**
  String get applyBarWeightToPastTitle;

  /// No description provided for @applyBarWeightToPastMessage.
  ///
  /// In en, this message translates to:
  /// **'The bar weight is now {newValue} kg. Should the {count} entries logged so far be recalculated with it?'**
  String applyBarWeightToPastMessage(String newValue, int count);

  /// No description provided for @onlyNewEntries.
  ///
  /// In en, this message translates to:
  /// **'Only new entries'**
  String get onlyNewEntries;

  /// No description provided for @recalculatePast.
  ///
  /// In en, this message translates to:
  /// **'Recalculate past'**
  String get recalculatePast;

  /// No description provided for @barWeightSaved.
  ///
  /// In en, this message translates to:
  /// **'Bar weight saved: {value} kg'**
  String barWeightSaved(String value);

  /// No description provided for @barWeightCurrent.
  ///
  /// In en, this message translates to:
  /// **'Bar: {value} kg'**
  String barWeightCurrent(String value);

  /// No description provided for @barWeightRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bar weight removed'**
  String get barWeightRemoved;

  /// No description provided for @pastEntriesRecalculated.
  ///
  /// In en, this message translates to:
  /// **'{count} past entries recalculated'**
  String pastEntriesRecalculated(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
