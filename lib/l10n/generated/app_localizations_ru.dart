// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Goalify';

  @override
  String get hello => 'Привет';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsSubtitle => 'Тёмная тема, язык и другое';

  @override
  String get appearanceSection => 'Оформление';

  @override
  String get themeSystem => 'Системная';

  @override
  String get themeSystemDescription => 'Следовать настройке устройства';

  @override
  String get themeLight => 'Светлая';

  @override
  String get themeLightDescription => 'Всегда использовать светлую тему';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeDarkDescription => 'Всегда использовать тёмную тему';

  @override
  String get dayStartSection => 'Начало дня';

  @override
  String get dayStartDescription =>
      'Время, когда начинается новый день. Ежедневные задачи, отслеживание тренировок и креатина, а также графики прогресса переходят на следующий день только в это время.';

  @override
  String get soundsSection => 'Звуки';

  @override
  String get soundsEnabledTitle => 'Звуковые эффекты';

  @override
  String get soundsEnabledDescription => 'Воспроизводить звуки при действиях';

  @override
  String get soundVolume => 'Громкость';

  @override
  String get soundEventDailyTaskCompleted => 'Задача выполнена';

  @override
  String get languageSection => 'Язык';

  @override
  String get languageSystem => 'Системный';

  @override
  String get languageSystemDescription => 'Следовать языку устройства';

  @override
  String get searchHint => 'Поиск';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get functionsTitle => 'Функции';

  @override
  String get comingSoon => 'Скоро';

  @override
  String get pomodoroTimer => 'Таймер Помодоро';

  @override
  String pomodoroCardRunning(String time) {
    return 'Таймер идёт: $time';
  }

  @override
  String get pomodoroCardSubtitle =>
      'Работайте сфокусированными интервалами с перерывами';

  @override
  String get distractionBlockerTitle => 'Блокировка отвлечений';

  @override
  String blockerCardActive(String duration) {
    return 'Активно: $duration';
  }

  @override
  String get blockerCardSubtitle =>
      'Блокируйте отвлекающие приложения и сохраняйте фокус';

  @override
  String get musicTimerTitle => 'Музыкальный таймер';

  @override
  String musicTimerCardRunning(String time) {
    return 'Таймер: $time';
  }

  @override
  String get musicTimerCardSubtitle =>
      'Слушайте музыку с таймером обратного отсчёта';

  @override
  String get intervalTimerTitle => 'Интервальный таймер';

  @override
  String intervalCardRunning(String label, String time) {
    return 'Идёт: $label • $time';
  }

  @override
  String get intervalCardSubtitle =>
      'Создайте профиль задач с перерывами между ними';

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get close => 'Закрыть';

  @override
  String get progressTitle => 'Прогресс';

  @override
  String get reload => 'Обновить';

  @override
  String get moreOptions => 'Ещё опции';

  @override
  String get clearHistory => 'Очистить историю';

  @override
  String get clearHistoryDescription =>
      'Удалить все сохранённые данные прогресса';

  @override
  String get points => 'Очки';

  @override
  String get ratio => 'Показатель';

  @override
  String get rangeWeek => 'Неделя';

  @override
  String get rangeMonth => 'Месяц';

  @override
  String get rangeYear => 'Год';

  @override
  String get noDataYet => 'Пока нет данных';

  @override
  String get resetProgressTitle => 'Сбросить прогресс?';

  @override
  String get resetProgressMessage =>
      'Все сохранённые дневные очки будут удалены. Это действие нельзя отменить.';

  @override
  String get currentRatio => 'Текущий показатель';

  @override
  String get avgRatio => 'Средний показатель';

  @override
  String get avgPerDay => 'В среднем за день';

  @override
  String currentRange(String label) {
    return 'Сейчас: $label';
  }

  @override
  String ptsValue(String value) {
    return '$value очк.';
  }

  @override
  String get weeklyReview => 'Итоги недели';

  @override
  String get vsLastWeek => 'к прошлой неделе';

  @override
  String get focusTime => 'Время фокуса';

  @override
  String get blockerTime => 'Время блокировки';

  @override
  String get tasksDone => 'Выполнено задач';

  @override
  String get workoutsLabel => 'Тренировки';

  @override
  String get congratsTitle => 'ПОЗДРАВЛЯЕМ!';

  @override
  String get congratsSubtitle => 'Вы выполнили все задачи на сегодня';

  @override
  String get congratsMessage => 'Отлично — продолжайте в том же духе!';

  @override
  String get showProgress => 'Показать прогресс';

  @override
  String get todayTitle => 'Сегодня';

  @override
  String get historyReadOnly => 'История (только чтение)';

  @override
  String get futureReadOnly => 'Будущее (только чтение)';

  @override
  String get viewByDate => 'Просмотр по дате';

  @override
  String get backToToday => 'Назад к сегодня';

  @override
  String get pickAnotherDate => 'Выбрать другую дату';

  @override
  String get resetAll => 'Сбросить всё';

  @override
  String get sortTasks => 'Сортировка задач';

  @override
  String get sortManual => 'Свой порядок';

  @override
  String get sortAlphabetical => 'По алфавиту';

  @override
  String get sortByStreak => 'По серии';

  @override
  String get sortByPoints => 'По очкам';

  @override
  String get sortByType => 'По типу';

  @override
  String get noTasksYet => 'Пока нет задач';

  @override
  String get addTaskToStart => 'Добавьте задачу, чтобы начать';

  @override
  String get freezeHelp =>
      'Freeze-токен: защищает серию повторяющейся задачи на СЕГОДНЯ без её выполнения. Удерживайте задачу и выберите «Заморозить на сегодня». Стоит 1 токен.';

  @override
  String get cannotCreatePastTasks =>
      'Нельзя создавать задачи для прошедших дат.';

  @override
  String get cannotModifyPastTasks => 'Нельзя изменять задачи прошедших дат.';

  @override
  String get cannotModifyFutureTasks => 'Нельзя изменять задачи будущих дат.';

  @override
  String get recurringOnlyToday =>
      'Повторяющиеся задачи можно отмечать только за сегодня.';

  @override
  String get cannotDeletePastTasks => 'Нельзя удалять задачи прошедших дат.';

  @override
  String get pastTasksReadOnly =>
      'Задачи прошедших дат доступны только для чтения.';

  @override
  String get checklistNote => 'Заметка-чеклист';

  @override
  String get checklistEmpty => 'Пока нет пунктов. Добавьте ниже.';

  @override
  String get deleteItem => 'Удалить пункт';

  @override
  String get addChecklistItemHint => 'Добавить пункт...';

  @override
  String get saveChecklist => 'Сохранить чеклист';

  @override
  String get taskActions => 'Действия с задачей';

  @override
  String get edit => 'Изменить';

  @override
  String get editTaskSubtitle => 'Изменить название, описание или категорию';

  @override
  String get changeIcon => 'Сменить иконку';

  @override
  String get changeIconSubtitle => 'Выберите свою или готовую иконку';

  @override
  String get checklistNoteSubtitle => 'Добавьте пункты с чекбоксами к задаче';

  @override
  String get duplicate => 'Дублировать';

  @override
  String get duplicateSubtitle => 'Скопировать задачу сразу ниже';

  @override
  String get freezeForToday => 'Заморозить на сегодня';

  @override
  String get alreadyFrozen => 'Уже заморожено';

  @override
  String get protectYourStreak => 'Защитите свою серию';

  @override
  String get noTokensLeft => 'Токенов не осталось';

  @override
  String get moveToTop => 'Переместить наверх';

  @override
  String get moveToTopSubtitle => 'Закрепить эту задачу сверху';

  @override
  String get showHighestStreak => 'Показать лучшую серию';

  @override
  String get showHighestStreakSubtitle => 'Ваш лучший результат по этой задаче';

  @override
  String get resetCurrentStreak => 'Сбросить текущую серию';

  @override
  String get resetCurrentStreakSubtitle => 'Очистить текущий прогресс серии';

  @override
  String get resetBestStreak => 'Сбросить лучшую серию';

  @override
  String get resetBestStreakSubtitle => 'Удалить ваш лучший результат';

  @override
  String get deleteTaskSubtitle => 'Удалить задачу навсегда';

  @override
  String get chooseAnIcon => 'Выберите иконку';

  @override
  String get customIconSaved => 'Своя иконка сохранена!';

  @override
  String errorSavingImage(String error) {
    return 'Ошибка сохранения изображения: $error';
  }

  @override
  String get highestStreak => 'Лучшая серия';

  @override
  String bestStreakIs(String label) {
    return 'Ваша лучшая серия по этой задаче — $label.';
  }

  @override
  String get noStreakYet => 'Серий пока нет.';

  @override
  String streakDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String streakCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Серия: $count дня',
      many: 'Серия: $count дней',
      few: 'Серия: $count дня',
      one: 'Серия: $count день',
    );
    return '$_temp0';
  }

  @override
  String streakCycleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count раз(а) подряд',
      one: '1 раз подряд',
    );
    return '$_temp0';
  }

  @override
  String streakCycleUnitCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count цикла',
      many: '$count циклов',
      few: '$count цикла',
      one: '$count цикл',
    );
    return '$_temp0';
  }

  @override
  String get frozenTodayLabel => 'Заморожено сегодня';

  @override
  String recurringDot(String label) {
    return 'Повтор · $label';
  }

  @override
  String get dailyLabel => 'Ежедневно';

  @override
  String limitedDays(String done, String total) {
    return '$done/$total дн.';
  }

  @override
  String get repeatWeekly => 'Еженедельно';

  @override
  String get repeatBiweekly => 'Раз в 2 недели';

  @override
  String get repeatMonthly => 'Ежемесячно';

  @override
  String everyNDays(int n) {
    return 'Каждые $n дн.';
  }

  @override
  String everyNDaysShort(int n) {
    return 'Каждые $n д.';
  }

  @override
  String get newTask => 'Новая задача';

  @override
  String get editTaskTitle => 'Изменить задачу';

  @override
  String get save => 'Сохранить';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get taskName => 'Название задачи';

  @override
  String get taskNameHint => 'напр. Выпить 2 л воды';

  @override
  String get required => 'Обязательно';

  @override
  String get descriptionOptional => 'Описание (необязательно)';

  @override
  String get category => 'Категория';

  @override
  String get categoryOptional => 'Категория (необязательно)';

  @override
  String get categoryGym => 'Спортзал';

  @override
  String get categoryWork => 'Работа';

  @override
  String get categoryStudy => 'Учёба';

  @override
  String get categoryLeisure => 'Отдых';

  @override
  String get categorySkill => 'Навык';

  @override
  String get categoryChores => 'Быт';

  @override
  String get categoryCreatine => 'Креатин';

  @override
  String get recurringLabel => 'Повторяющаяся';

  @override
  String get xTimes => 'X раз';

  @override
  String get howManyDays => 'Сколько дней?';

  @override
  String get sameAsCycleHint =>
      'Совпадает с длиной цикла — эквивалент ежедневной задачи.';

  @override
  String get repeatsAfterCompletion => 'Повторяется после завершения';

  @override
  String get chooseWeekdays => 'Выберите дни недели';

  @override
  String get weekdaysOptionalHint =>
      'Необязательно — оставьте пустым, чтобы показывать каждый день';

  @override
  String get repeatPattern => 'Шаблон повторения';

  @override
  String get scheduledDate => 'Запланированная дата';

  @override
  String get createTask => 'Создать задачу';

  @override
  String get customRepeatInterval => 'Свой интервал повторения';

  @override
  String get howManyDaysBetween => 'Сколько дней между повторениями?';

  @override
  String get daysUnit => 'дн.';

  @override
  String get invalidNumber => 'Введите корректное число (не меньше 1)';

  @override
  String get never => 'Никогда';

  @override
  String get customDaysOption => 'Свои дни...';

  @override
  String get targetDays => 'Целевые дни';

  @override
  String alreadyDoneCycle(String done, String total) {
    return 'Уже выполнено: $done/$total дн. в этом цикле';
  }

  @override
  String get keepForFuture => 'Сохранить на будущие дни';

  @override
  String get keepForFutureSubtitle => 'Превратить в повторяющуюся задачу';

  @override
  String get gymTitle => 'Спортзал';

  @override
  String get navDaily => 'Ежедневно';

  @override
  String get calendarTitle => 'Календарь';

  @override
  String get exercisesTab => 'Упражнения';

  @override
  String get splitsTab => 'Сплиты';

  @override
  String get create => 'Создать';

  @override
  String get remove => 'Убрать';

  @override
  String get rename => 'Переименовать';

  @override
  String get gotIt => 'Понятно';

  @override
  String get fullScreen => 'Во весь экран';

  @override
  String get noWorkoutsYet => 'Пока нет упражнений';

  @override
  String get addFirstExercise => 'Добавьте первое упражнение, чтобы начать';

  @override
  String get noWorkoutDaysYet => 'Пока нет тренировочных дней';

  @override
  String get addExercisesToCreateDays =>
      'Добавьте упражнения, чтобы создать тренировочные дни';

  @override
  String get noSplitsYet => 'Пока нет сплитов';

  @override
  String get tapPlusForSplits => 'Нажмите +, чтобы сгруппировать дни в сплиты';

  @override
  String colorForDay(String day) {
    return 'Цвет для «$day»';
  }

  @override
  String get clearAllHistoryTitle => 'Очистить всю историю?';

  @override
  String clearAllHistoryMessage(String name) {
    return 'Вся история для «$name» будет удалена.\nНазначения в плане тренировок сохранятся.';
  }

  @override
  String removeWorkoutTitle(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get removeWorkoutMessage =>
      'Все записи будут удалены, а упражнение убрано из всех планов.\n\nУдалить также прошлые записи из календаря?';

  @override
  String get deleteOnly => 'Только удалить';

  @override
  String get deletePlusCalendar => 'Удалить + календарь';

  @override
  String noteFor(String name) {
    return 'Заметка для «$name»';
  }

  @override
  String get addNoteHint => 'Добавьте заметку к упражнению...';

  @override
  String get noteRemoved => 'Заметка удалена.';

  @override
  String get noteSaved => 'Заметка сохранена.';

  @override
  String get showProgressChart => 'Показать график прогресса';

  @override
  String get deleteExerciseEllipsis => 'Удалить упражнение…';

  @override
  String get removeFromPlan => 'Убрать из этого плана';

  @override
  String get keepProgressHistory => 'Сохранить историю прогресса';

  @override
  String get addNote => 'Добавить заметку';

  @override
  String get editExistingNote => 'Изменить заметку';

  @override
  String get saveNoteSubtitle => 'Сохранить заметку к упражнению';

  @override
  String get clearAllHistoryAction => 'Очистить всю историю';

  @override
  String get clearAllHistorySubtitle => 'Удалить все записи упражнения';

  @override
  String get deleteExercise => 'Удалить упражнение';

  @override
  String get deleteExerciseSubtitle => 'Убрать из плана и истории';

  @override
  String clearHistoryOnDay(String name, String day) {
    return 'Очистить историю «$name» в день $day?';
  }

  @override
  String get exerciseNotAssigned => 'Упражнение не назначено';

  @override
  String get exerciseNotAssignedMessage =>
      'Это упражнение ещё не входит ни в один план.';

  @override
  String removeNameTitle(String name) {
    return 'Удалить «$name»';
  }

  @override
  String get chooseDaysToRemove =>
      'Выберите дни для удаления (история сохранится):';

  @override
  String get renameWorkoutDay => 'Переименовать день';

  @override
  String get newName => 'Новое имя';

  @override
  String get enterNewDayName => 'Введите новое название дня';

  @override
  String get nameAlreadyExists => 'Имя уже существует';

  @override
  String dayNameExistsMessage(String name) {
    return 'День с названием «$name» уже существует. Выберите другое имя.';
  }

  @override
  String renamedTo(String oldName, String newName) {
    return '«$oldName» переименован в «$newName»';
  }

  @override
  String get includingTracked => ' (включая записи тренировок)';

  @override
  String get renameDaySubtitle => 'Изменить название дня';

  @override
  String get changeIconDialogSubtitle =>
      'Выберите другую иконку или изображение';

  @override
  String get deleteWorkoutDay => 'Удалить день';

  @override
  String get deleteWorkoutDaySubtitle =>
      'Убрать день из плана (опционально: удалить историю)';

  @override
  String deleteDayQuestion(String day) {
    return 'Удалить день «$day»?';
  }

  @override
  String get deleteDayMessage =>
      'Удалить также прошлые записи (календарь/история)?';

  @override
  String get deleteOnlyDay => 'Удалить только день';

  @override
  String get deletePlusTracked => 'Удалить + записи';

  @override
  String dayDeletedTracked(String day) {
    return 'День «$day» удалён (включая историю).';
  }

  @override
  String dayDeleted(String day) {
    return 'День «$day» удалён.';
  }

  @override
  String get noDataYetTitle => 'Данных пока нет';

  @override
  String get startTrackingMessage =>
      'Начните отслеживать тренировки, чтобы увидеть график прогресса.';

  @override
  String progressFor(String name) {
    return 'Прогресс – $name';
  }

  @override
  String setLabel(int n, String value) {
    return 'Подход $n: $value';
  }

  @override
  String setLabelBest(int n, String value) {
    return 'Подход $n: $value ✨ ЛУЧШИЙ';
  }

  @override
  String get editSplit => 'Изменить сплит';

  @override
  String get deleteSplit => 'Удалить сплит';

  @override
  String get createDaysFirst =>
      'Сначала создайте тренировочные дни, затем добавьте сплит.';

  @override
  String deleteSplitQuestion(String name) {
    return 'Удалить сплит «$name»?';
  }

  @override
  String get deleteSplitMessage =>
      'Будет удалён только сплит. Дни и записи тренировок сохранятся.';

  @override
  String get createSplit => 'Создать сплит';

  @override
  String get splitName => 'Название сплита';

  @override
  String get splitNameHint => 'напр. PPL, Верх/Низ';

  @override
  String get selectWorkoutDays => 'Выберите дни тренировок';

  @override
  String get enterSplitName => 'Введите название сплита.';

  @override
  String get selectAtLeastOneDay => 'Выберите хотя бы один день.';

  @override
  String splitExists(String name) {
    return 'Сплит с названием «$name» уже существует.';
  }

  @override
  String get noHistoryTitle => 'Нет истории';

  @override
  String get noHistoryMessage =>
      'Записей пока нет. Начните вести журнал, чтобы увидеть историю.';

  @override
  String historyFor(String name) {
    return 'История – $name';
  }

  @override
  String logCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return '$_temp0';
  }

  @override
  String setsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count подхода',
      many: '$count подходов',
      few: '$count подхода',
      one: '$count подход',
    );
    return '$_temp0';
  }

  @override
  String get bestWorkout => 'Лучшая тренировка';

  @override
  String get onlyThisDayLogsDeleted =>
      'Будут удалены только записи этого упражнения за этот день.';

  @override
  String get deleteTodayLogsOnly => 'Удалить только записи за сегодня';

  @override
  String get alternatives => 'Альтернативы';

  @override
  String get noExercisesToday => 'Сегодня нет упражнений';

  @override
  String get addOrAssignExercises =>
      'Добавьте или назначьте упражнения на этот день';

  @override
  String get pickColorForDay => 'Выберите цвет для этого дня';

  @override
  String get doneToday => 'Выполнено сегодня';

  @override
  String get history => 'История';

  @override
  String get removeLogsFromDate => 'Удалить записи за эту дату';

  @override
  String get setAsMain => 'Сделать основным упражнением';

  @override
  String get markAsAlternative => 'Отметить как альтернативу';

  @override
  String get moveBackToMainList => 'Вернуть в основной список';

  @override
  String get moveToSeparateSection => 'Переместить в отдельный раздел';

  @override
  String get deleteAllLogs => 'Удалить все записи';

  @override
  String get removeAllProgress => 'Удалить весь прогресс упражнения';

  @override
  String get invalidMonth => 'Месяц должен быть от 1 до 12';

  @override
  String get invalidYear => 'Год должен быть больше 0';

  @override
  String get goToMonth => 'Перейти к месяцу';

  @override
  String get selectDateHint => 'Выберите дату или нажмите на месяц';

  @override
  String get yearHint => 'напр. 2026';

  @override
  String get go => 'Перейти';

  @override
  String get creatineTaken => 'Креатин принят';

  @override
  String get showRedDot => 'Показывать красную точку в календаре';

  @override
  String get noWorkoutsMarked => 'Тренировки не отмечены';

  @override
  String get swipeHint => 'Свайп, стрелки или нажмите на месяц';

  @override
  String get searchWorkoutHint => 'Поиск упражнения... (название или мышца)';

  @override
  String get add => 'Добавить';

  @override
  String get update => 'Обновить';

  @override
  String exerciseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count упражнения',
      many: '$count упражнений',
      few: '$count упражнения',
      one: '$count упражнение',
    );
    return '$_temp0';
  }

  @override
  String get noSplitDays => 'В этом сплите нет дней';

  @override
  String get selectWorkoutDayError =>
      'Выберите или введите тренировочный день.';

  @override
  String setDropsetTimeError(int set, int drop) {
    return 'Подход $set, дропсет $drop: введите время в секундах (> 0).';
  }

  @override
  String setTimeError(int set) {
    return 'Подход $set: введите время в секундах (> 0).';
  }

  @override
  String setDropsetWeightError(int set, int drop, String rule) {
    return 'Подход $set, дропсет $drop: введите корректный вес ($rule).';
  }

  @override
  String setWeightError(int set, String rule) {
    return 'Подход $set: введите корректный вес ($rule).';
  }

  @override
  String setDropsetRepsError(int set, int drop) {
    return 'Подход $set, дропсет $drop: введите корректные повторы (> 0).';
  }

  @override
  String setRepsError(int set) {
    return 'Подход $set: введите корректные повторы (> 0).';
  }

  @override
  String get chooseDayForGroup =>
      'Выберите день, чтобы отнести упражнение к группе.';

  @override
  String get workoutDay => 'Тренировочный день';

  @override
  String get customManualEntry => 'Свой (ввод вручную)';

  @override
  String get workoutDayOptional => 'День (необязательно)';

  @override
  String get workoutDayRequired => 'День (обязательно)';

  @override
  String get dayHintCustom => 'напр. Push3';

  @override
  String get dayHint => 'напр. Push / Pull / Leg …';

  @override
  String get sets => 'Подходы';

  @override
  String get addSet => 'Добавить подход';

  @override
  String get timeSeconds => 'Время (секунды)';

  @override
  String egHint(String value) {
    return 'напр. $value';
  }

  @override
  String get removeSet => 'Убрать подход';

  @override
  String dropsetTimeSeconds(int n) {
    return 'Дропсет $n: время (сек)';
  }

  @override
  String get removeDropset => 'Убрать дропсет';

  @override
  String get addDropset => 'Добавить дропсет';

  @override
  String get weightKg => 'Вес (кг)';

  @override
  String get reps => 'Повторы';

  @override
  String dropsetWeightKg(int n) {
    return 'Дропсет $n: вес (кг)';
  }

  @override
  String get standardLabel => 'Стандарт';

  @override
  String get weight => 'Вес';

  @override
  String get dateLabel => 'Дата';

  @override
  String get filter => 'Фильтр';

  @override
  String get exitFullScreen => 'Выйти из полноэкранного режима';

  @override
  String get noDataForFilter => 'Нет данных для этого фильтра.';

  @override
  String get filterBy => 'Фильтровать по:';

  @override
  String get showStrongestSet => 'Показать лучший подход';

  @override
  String get multipleGraphs => 'Несколько графиков (по подходам)';

  @override
  String get multipleGraphsSubtitle =>
      'Переключает между одним графиком и линиями по подходам';

  @override
  String get minWeightEnter => 'Введите минимальный вес';

  @override
  String get weightHintKg => 'напр. 80,5 кг';

  @override
  String get chooseDateRange => 'Выберите период';

  @override
  String get apply => 'Применить';

  @override
  String setN(int n) {
    return 'Подход $n';
  }

  @override
  String weightOfSet(int n) {
    return 'Вес подхода $n';
  }

  @override
  String dropsetOfSet(int d, int set) {
    return 'Дропсет $d подхода $set';
  }

  @override
  String get unitKg => 'кг';

  @override
  String get unitReps => 'повт.';

  @override
  String get unitMin => 'мин';

  @override
  String get unitSec => 'с';

  @override
  String get unitHour => 'ч';

  @override
  String get dropsetLabel => 'Дропсет';

  @override
  String get noProgressYet => 'Прогресса пока нет';

  @override
  String get updateLabel => 'Обновление';

  @override
  String get setsWord => 'подходов';

  @override
  String get noProfileCreated => 'Профиль не создан';

  @override
  String pauseBefore(String name) {
    return 'Перерыв перед $name';
  }

  @override
  String get profileClassic => 'Классический';

  @override
  String get profileShort => 'Короткий';

  @override
  String get profileLong => 'Длинный';

  @override
  String get profileIntense => 'Интенсивный';

  @override
  String get pomodoroFocus => 'Фокус';

  @override
  String profileDurations(String work, String short, String long) {
    return '$work работа • $short перерыв • $long длинный перерыв';
  }

  @override
  String get statusActive => 'АКТИВНО';

  @override
  String get statusInactive => 'НЕАКТИВНО';

  @override
  String get toggleOn => 'ВКЛ';

  @override
  String get toggleOff => 'ВЫКЛ';

  @override
  String get blockerCurrentSession => 'Текущая сессия';

  @override
  String get appsCurrentlyBlocked => 'Приложения сейчас заблокированы';

  @override
  String get appsNotBlocked => 'Приложения не заблокированы';

  @override
  String distractionAttemptsPrevented(int count) {
    return 'Предотвращено отвлечений: $count';
  }

  @override
  String get toggleToStartBlocking =>
      'Включите переключатель ниже, чтобы блокировать отвлекающие приложения';

  @override
  String get todaysStatistics => 'Статистика за сегодня';

  @override
  String get totalBlockingTime => 'Общее время блокировки';

  @override
  String get appsBeingBlocked => 'Блокируемые приложения';

  @override
  String get attemptsPrevented => 'Предотвращено попыток отвлечься';

  @override
  String get howItWorks => 'Как это работает';

  @override
  String get blockerHowItWorksText =>
      'Когда блокировка активна, вы не сможете открывать отвлекающие приложения. Она работает, пока вы не выключите её вручную.';

  @override
  String get requiresAccessibility =>
      'Требуется разрешение специальных возможностей';

  @override
  String get blockedApps => 'Заблокированные приложения';

  @override
  String get blockedAppsCategories => 'Соцсети, игры, покупки и развлечения';

  @override
  String get requiresScreenTime =>
      'Требуется разрешение «Экранное время» iOS (iOS 16 и новее)';

  @override
  String get blockedAppsSelectionIos =>
      'Вы сами выбираете блокируемые приложения и категории через системный диалог iOS';

  @override
  String get chooseAppsToBlock => 'Выбрать приложения';

  @override
  String get screenTimePermissionDenied =>
      'Доступ к «Экранному времени» отклонён. Разрешите его в Настройках > Экранное время.';

  @override
  String get noAppsSelectedForBlocking =>
      'Приложения не выбраны. Сначала выберите приложения для блокировки.';

  @override
  String get blockerStartFailed =>
      'Не удалось запустить блокировщик. Проверьте разрешения.';

  @override
  String get blockerIosVersionUnsupported =>
      'Для блокировки приложений требуется iOS 16 или новее.';

  @override
  String get done => 'Готово';

  @override
  String get timerActiveCaps => '🎵 ТАЙМЕР АКТИВЕН 🎵';

  @override
  String get setTimerCaps => '⏱️ УСТАНОВИТЕ ТАЙМЕР';

  @override
  String get musicWillStop => 'Музыка остановится автоматически';

  @override
  String get musicTimerIdleHint => 'Выберите длительность ниже';

  @override
  String get timeRemaining => 'Осталось времени';

  @override
  String get stopTimerCaps => 'ОСТАНОВИТЬ ТАЙМЕР';

  @override
  String get startTimerCaps => 'ЗАПУСТИТЬ ТАЙМЕР';

  @override
  String get minutesUnit => 'минут';

  @override
  String get quickPresets => 'Быстрые пресеты';

  @override
  String get musicTimerHowItWorks =>
      'Установите таймер, который автоматически поставит музыку на паузу через заданное время. Работает с любыми приложениями: YouTube, Spotify и другими. Идеально, чтобы засыпать под музыку или ограничить время прослушивания.';

  @override
  String get worksWithAllMediaApps => 'Работает со всеми медиа-приложениями';

  @override
  String get defaultProfilesNotEditable =>
      'Стандартные профили нельзя изменять или удалять.';

  @override
  String get editProfile => 'Изменить профиль';

  @override
  String get profileName => 'Название профиля';

  @override
  String get profileNameHint => 'напр. Мой фокус';

  @override
  String get workDuration => 'Длительность работы';

  @override
  String get minutesLabel => 'Минуты';

  @override
  String get shortBreak => 'Короткий перерыв';

  @override
  String get longBreak => 'Длинный перерыв';

  @override
  String get cyclesBeforeLongBreak => 'Циклов до длинного перерыва';

  @override
  String get numberLabel => 'Число';

  @override
  String get blockApps => 'Блокировать приложения';

  @override
  String get blockAppsSubtitle =>
      'Блокировать отвлекающие приложения во время работы';

  @override
  String get enterProfileName => 'Введите название профиля';

  @override
  String get profileUpdated => 'Профиль обновлён';

  @override
  String get deleteProfile => 'Удалить профиль';

  @override
  String deleteProfileConfirm(String name) {
    return 'Удалить профиль «$name»? Это действие нельзя отменить.';
  }

  @override
  String get profileDeleted => 'Профиль удалён';

  @override
  String get notificationsRequired => 'Нужны уведомления';

  @override
  String get notificationsRequiredText =>
      'Чтобы информировать вас во время фокус-сессий, Goalify нужны разрешения на уведомления.';

  @override
  String get allow => 'Разрешить';

  @override
  String get later => 'Позже';

  @override
  String get accessibilityRequired => 'Нужны специальные возможности';

  @override
  String get accessibilityRequiredText =>
      'Чтобы блокировать отвлекающие приложения, Goalify нужны разрешения специальных возможностей.';

  @override
  String get appBlockingNotSupported =>
      'Блокировка приложений не поддерживается';

  @override
  String get appBlockingNotSupportedText =>
      'Блокировка приложений не поддерживается на iOS. Таймер Помодоро будет работать, но другие приложения не будут блокироваться.';

  @override
  String get selectTimerProfile => 'Выберите профиль таймера';

  @override
  String get createCustomProfile => 'Создать свой профиль';

  @override
  String get enterValidDurations =>
      'Введите корректные значения длительностей и циклов';

  @override
  String profileCreated(String name) {
    return 'Профиль «$name» создан';
  }

  @override
  String cycleOf(int n) {
    return 'Цикл $n/4';
  }

  @override
  String get running => 'Идёт';

  @override
  String get paused => 'Пауза';

  @override
  String get ready => 'Готов';

  @override
  String get notificationPermissionRequired =>
      'Требуется разрешение на уведомления. Разрешите их в настройках.';

  @override
  String get focusModeActive => 'Режим фокуса активен';

  @override
  String get otherAppsBlocked => 'Другие приложения заблокированы';

  @override
  String get todaysProgress => 'Прогресс за сегодня';

  @override
  String get sessions => 'Сессии';

  @override
  String get thisWeek => 'На этой неделе';

  @override
  String get cycles => 'Циклы';

  @override
  String get dailyFocusScore => 'Дневной фокус-рейтинг';

  @override
  String get scoreExcellent => 'Отлично! Так держать!';

  @override
  String get scoreGreat => 'Отличный прогресс сегодня!';

  @override
  String get scoreGood => 'Хорошее начало!';

  @override
  String get scoreGetFocused => 'Пора сосредоточиться!';

  @override
  String get deleteTaskAction => 'Удалить задачу';

  @override
  String get taskLabel => 'Задача';

  @override
  String get durationMinutes => 'Длительность (минуты)';

  @override
  String get decimalsAllowed => 'Можно дробные, напр. 0.5 = 30 секунд.';

  @override
  String get decimalsAllowedShort => 'Можно дробные (0.5 = 30 секунд).';

  @override
  String get pauseBeforeTask => 'Перерыв перед задачей (минуты)';

  @override
  String get pauseBeforeThisTask => 'Перерыв перед этой задачей (минуты)';

  @override
  String get alwaysZeroFirst => 'Для первой задачи всегда 0.';

  @override
  String get ignoredForFirst => 'Игнорируется для первой задачи.';

  @override
  String get enterValidValues => 'Введите корректные значения.';

  @override
  String get saveProfile => 'Сохранить профиль';

  @override
  String get noSavedProfiles => 'Сохранённых профилей пока нет.';

  @override
  String profileLoaded(String name) {
    return 'Профиль «$name» загружен.';
  }

  @override
  String get intervalProfileNameHint => 'напр. Кикбоксинг 12 раундов';

  @override
  String get createTaskFirst => 'Сначала создайте хотя бы одну задачу.';

  @override
  String profileSaved(String name) {
    return 'Профиль «$name» сохранён.';
  }

  @override
  String get enterValidTaskDuration =>
      'Введите корректную задачу и длительность в минутах.';

  @override
  String taskOf(int current, int total) {
    return 'Задача $current / $total';
  }

  @override
  String get focusNow => 'Фокус';

  @override
  String get recovery => 'Отдых';

  @override
  String get pause => 'Пауза';

  @override
  String get resume => 'Продолжить';

  @override
  String get start => 'Старт';

  @override
  String get reset => 'Сброс';

  @override
  String get createProfile => 'Создать профиль';

  @override
  String get createProfileSubtitle =>
      'Задайте задачу, длительность и необязательный перерыв перед следующей задачей.';

  @override
  String get taskHint => 'напр. Скакалка';

  @override
  String get durationHint => 'напр. 0.5';

  @override
  String get addTask => 'Добавить задачу';

  @override
  String get tasksInProfile => 'Задачи в профиле';

  @override
  String get clear => 'Очистить';

  @override
  String get noTasksAdded => 'Задачи ещё не добавлены.';

  @override
  String durationValue(String value) {
    return 'Длительность: $value';
  }

  @override
  String pauseDuration(String pause, String value) {
    return 'Перерыв: $pause • Длительность: $value';
  }

  @override
  String get sequence => 'Последовательность';
}
