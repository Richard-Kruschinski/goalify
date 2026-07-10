import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/i18n/task_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import 'package:flutter/services.dart'; // rootBundle, SystemChrome, DeviceOrientation
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/icon_mapper.dart'; // IconMapper für zentrale Icon-Verwaltung
import '../../../../core/widgets/gym_icons.dart'; // Custom Push/Pull/Cardio Icons
import '../../../../core/i18n/workout_translations.dart'; // Übersetzung der Asset-Workouts
import '../../../tasks/domain/usecases/daily_tasks_helper.dart'; // for markGymTaskDoneForToday
import '../../data/models/gym_models.dart';
import '../../data/repositories/gym_repository_impl.dart';
import '../../domain/repositories/gym_repository.dart';
import '../../domain/usecases/best_set_cache.dart';
import 'day_detail_screen.dart';
import 'full_screen_chart_page.dart';
import 'workout_calendar_page.dart';
import 'split_detail_screen.dart';
import '../widgets/workout_picker_sheet.dart';
import '../widgets/log_input_dialog.dart';
import '../widgets/color_picker_grid.dart';

enum ViewMode { byExercise, byDay, bySplit }

Future<bool> _showModernConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmButtonText,
  String? cancelButtonText,
  required Color iconColor,
  required IconData icon,
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDangerous 
                      ? AppColors.accentSoft(context)
                      : (AppColors.isDark(context) ? const Color(0xFF14273A) : const Color(0xFFE3F2FD)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    cancelButtonText ?? AppLocalizations.of(context).cancel,
                    style: TextStyle(color: AppColors.muted(context)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    confirmButtonText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return result ?? false;
}

/// Modern Confirmation Dialog with multiple options
Future<T?> _showModernConfirmationDialogWithOptions<T>({
  required BuildContext context,
  required String title,
  required String message,
  required Color iconColor,
  required IconData icon,
  bool isDangerous = false,
  required Map<String, T> options,
}) async {
  final result = await showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDangerous 
                      ? AppColors.accentSoft(context)
                      : (AppColors.isDark(context) ? const Color(0xFF14273A) : const Color(0xFFE3F2FD)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(context),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.muted(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ...List.generate(
                  options.entries.length,
                  (index) {
                    final entry = options.entries.elementAt(index);
                    final isFirst = index == 0;
                    final isLast = index == options.entries.length - 1;
                    
                    if (isFirst) {
                      return TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: Text(
                          entry.key,
                          style: TextStyle(color: AppColors.muted(context)),
                        ),
                      );
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, entry.value),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLast ? iconColor : AppColors.chip(context),
                          foregroundColor: isLast ? Colors.white : AppColors.muted(context),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  return result;
}

/// ===============================================================
/// Gym Screen
/// ===============================================================
class GymScreen extends StatefulWidget {
  const GymScreen({super.key});
  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  // All persistence goes through the repository abstraction so the storage
  // backend (local today, database/server later) can be swapped without
  // touching this screen.
  final GymRepository _repo = GymRepositoryImpl();

  // Available icons (loaded dynamically from IconMapper)
  late List<IconData> _availableIcons = [];

  ViewMode _mode = ViewMode.byExercise;

  // Workouts from JSON
  final List<Workout> _workouts = <Workout>[];

  // Logs & Order
  final Map<String, List<WorkoutLog>> _logs = <String, List<WorkoutLog>>{};
  List<String> _orderActive = <String>[];
  final Map<String, List<String>> _orderByDay = <String, List<String>>{};

  // Zuweisungen „Übung gehört zu Day”, auch ohne History
  final Map<String, List<String>> _assignmentsByDay = <String, List<String>>{};
  final Map<String, String> _exerciseNotesByWorkoutId = <String, String>{};
  final Map<String, Set<String>> _alternativeWorkoutIdsByDay = <String, Set<String>>{};

  // Reihenfolge der Workout-Days
  List<String> _orderDays = <String>[];

  // Splits (Splitname -> Workout-Days)
  final Map<String, List<String>> _splitsByName = <String, List<String>>{};
  List<String> _splitOrder = <String>[];

  // Kalender – pro Datum (yyyy-MM-dd) Liste der erledigten Workout-Days
  final Map<String, Set<String>> _calendarByDate = <String, Set<String>>{};
  // Farbe je Workout-Tag
  final Map<String, int> _dayColors = <String, int>{};
  // Icon je Workout-Tag (codePoint)
  final Map<String, int> _dayIcons = <String, int>{};
  // Custom Icons je Workout-Tag (file path)
  final Map<String, String> _dayCustomIcons = <String, String>{};
  // Creatine intake per date (yyyy-MM-dd)
  final Set<String> _creatineDates = <String>{};
  
  // Best-Set Cache pro Übung
  final BestSetCache _bestSetCache = BestSetCache();

  // Untranslated originals from workouts.json (English base)
  final List<Workout> _workoutsRaw = <Workout>[];
  String? _workoutLocale;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-translate the built-in workouts when the app language changes
    final lang = Localizations.localeOf(context).languageCode;
    if (_workoutLocale != null && _workoutLocale != lang) {
      _applyWorkoutLocale(lang);
    }
    _workoutLocale = lang;
  }

  Future<void> _bootstrap() async {
    await _loadWorkoutsFromAsset();
    _availableIcons = await IconMapper.getGymIcons();
    await _loadState();
    await _loadCalendar();
    await _loadCreatineIntake();
    await _loadBestSetCache();
    if (mounted) setState(() {});
  }

  // ----------------------------- Workouts (Asset) -----------------------------
  Future<void> _loadWorkoutsFromAsset() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/workouts.json');
      final list = (jsonDecode(jsonStr) as List)
          .map((e) => Workout.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _workoutsRaw
        ..clear()
        ..addAll(list);
      await _applyWorkoutLocale(_workoutLocale ??
          WidgetsBinding.instance.platformDispatcher.locale.languageCode);
    } catch (_) {
      // ignore
    }
  }

  Future<void> _applyWorkoutLocale(String langCode) async {
    final localized =
        await WorkoutTranslations.localize(_workoutsRaw, langCode);
    _workouts
      ..clear()
      ..addAll(localized);
    if (mounted) setState(() {});
  }

  // ----------------------------- Persistenter State -----------------------------
  Future<void> _loadState() async {
    // View mode
    final vm = await _repo.loadViewMode();
    if (vm == 'byDay') {
      _mode = ViewMode.byDay;
    } else if (vm == 'bySplit') {
      _mode = ViewMode.bySplit;
    } else {
      _mode = ViewMode.byExercise;
    }

    // Logs
    _logs
      ..clear()
      ..addAll(await _repo.loadLogs());

    // Order exercise
    _orderActive = await _repo.loadOrderActive();

    // Order per day
    _orderByDay
      ..clear()
      ..addAll(await _repo.loadOrderByDay());

    // Assignments
    _assignmentsByDay
      ..clear()
      ..addAll(await _repo.loadAssignments());

    // Exercise notes
    _exerciseNotesByWorkoutId
      ..clear()
      ..addAll(await _repo.loadExerciseNotes());

    // Day colors
    _dayColors
      ..clear()
      ..addAll(await _repo.loadDayColors());

    // Day icons
    _dayIcons
      ..clear()
      ..addAll(await _repo.loadDayIcons());

    // Day custom icons
    _dayCustomIcons
      ..clear()
      ..addAll(await _repo.loadDayCustomIcons());

    // Order der Days
    _orderDays = await _repo.loadOrderDays();

    // Splits
    _splitsByName
      ..clear()
      ..addAll(await _repo.loadSplits());

    _splitOrder = await _repo.loadSplitOrder();

    // Alternative exercise IDs per day
    _alternativeWorkoutIdsByDay
      ..clear()
      ..addAll(await _repo.loadAlternativeIdsByDay());

    _syncOrderDaysWithAssignments();
    _syncSplitsWithDays();
  }

  Future<void> _saveLogs() async {
    await _repo.saveLogs(_logs);
  }

  Future<void> _saveViewMode() async => _repo.saveViewMode(_mode.name);
  Future<void> _saveOrderActive() async =>
      _repo.saveOrderActive(_orderActive);
  Future<void> _saveAlternativeIds() async =>
      _repo.saveAlternativeIdsByDay(_alternativeWorkoutIdsByDay);
  Future<void> _saveOrderByDay() async => _repo.saveOrderByDay(_orderByDay);
  Future<void> _saveAssignments() async =>
      _repo.saveAssignments(_assignmentsByDay);
  Future<void> _saveExerciseNotes() async =>
      _repo.saveExerciseNotes(_exerciseNotesByWorkoutId);
  Future<void> _saveOrderDays() async => _repo.saveOrderDays(_orderDays);
  Future<void> _saveDayColors() async => _repo.saveDayColors(_dayColors);
  Future<void> _saveDayIcons() async => _repo.saveDayIcons(_dayIcons);
  Future<void> _saveDayCustomIcons() async =>
      _repo.saveDayCustomIcons(_dayCustomIcons);
  Future<void> _saveSplits() async => _repo.saveSplits(_splitsByName);
  Future<void> _saveSplitOrder() async => _repo.saveSplitOrder(_splitOrder);

  // ----------------------------- Kalender: Load/Save -----------------------------
  Future<void> _loadCalendar() async {
    _calendarByDate
      ..clear()
      ..addAll(await _repo.loadCalendar());
  }

  Future<void> _saveCalendar() async {
    await _repo.saveCalendar(_calendarByDate);
  }

  Future<void> _loadCreatineIntake() async {
    _creatineDates
      ..clear()
      ..addAll(await _repo.loadCreatineDates());
  }

  Future<void> _saveCreatineIntake() async {
    await _repo.saveCreatineDates(_creatineDates);
  }

  Future<void> _loadBestSetCache() async {
    _bestSetCache.loadFromMap(await _repo.loadBestSetCacheMap());
  }

  Future<void> _saveBestSetCache() async {
    await _repo.saveBestSetCacheMap(_bestSetCache.toMap());
  }

  String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool _isCreatineTakenOn(DateTime date) => _creatineDates.contains(_dateKey(date));

  Future<void> _setCreatineTaken(DateTime date, bool value) async {
    final key = _dateKey(date);
    if (value) {
      _creatineDates.add(key);
    } else {
      _creatineDates.remove(key);
    }
    await _saveCreatineIntake();
    await _syncDailyCreatineIfToday(date, value);
    if (mounted) setState(() {});
  }

  Future<void> _syncDailyCreatineIfToday(DateTime date, bool value) async {
    final todayKey = _dateKey(DateTime.now());
    final dateKey = _dateKey(date);
    if (dateKey != todayKey) return; // only adjust today's daily tasks

    bool changedKeep = false;
    bool changedOneOff = false;

    // Update keep tasks (daily_tasks_v1)
    final rawKeep = await _repo.loadDailyTasksRaw();
    if (rawKeep is List) {
      final updated = <Map<String, dynamic>>[];
      for (final e in rawKeep) {
        final m = Map<String, dynamic>.from(e as Map);
        final cat = (m['category'] as String?)?.toLowerCase().trim();
        if (cat == 'creatin' || cat == 'creatine') {
          if ((m['done'] ?? false) != value) {
            m['done'] = value;
            changedKeep = true;
          }
        }
        updated.add(m);
      }
      if (changedKeep) {
        await _repo.saveDailyTasksRaw(updated);
      }
    }

    // Update one-off tasks for today (daily_oneoff_by_date_v1)
    final rawOneOff = await _repo.loadDailyOneOffByDateRaw();
    if (rawOneOff is Map && rawOneOff.containsKey(dateKey)) {
      final list = rawOneOff[dateKey];
      if (list is List) {
        final updatedList = <Map<String, dynamic>>[];
        for (final e in list) {
          final m = Map<String, dynamic>.from(e as Map);
          final cat = (m['category'] as String?)?.toLowerCase().trim();
          if (cat == 'creatin' || cat == 'creatine') {
            if ((m['done'] ?? false) != value) {
              m['done'] = value;
              changedOneOff = true;
            }
          }
          updatedList.add(m);
        }
        if (changedOneOff) {
          rawOneOff[dateKey] = updatedList;
          await _repo.saveDailyOneOffByDateRaw(rawOneOff);
        }
      }
    }

    // Keep progress_history in sync when we changed any keep task
    if (changedKeep) {
      final map = await _repo.loadProgressHistory();
      int todayPts = 0;
      final keepRaw = await _repo.loadDailyTasksRaw();
      if (keepRaw is List) {
        for (final e in keepRaw) {
          final m = Map<String, dynamic>.from(e as Map);
          final keep = (m['keep'] ?? false) as bool;
          final done = (m['done'] ?? false) as bool;
          final pts = (m['points'] ?? 1) as int;
          if (keep && done) todayPts += pts;
        }
      }
      map[todayKey] = todayPts;
      await _repo.saveProgressHistory(map);
    }
  }

  bool _isDayMarkedOn(DateTime date, String dayName) {
    final key = _dateKey(date);
    final set = _calendarByDate[key];
    return set != null && set.contains(dayName);
  }

  Future<void> _setDayMarkedToday(String dayName, bool value) async {
    final now = DateTime.now();
    final key = _dateKey(now);
    final set = _calendarByDate.putIfAbsent(key, () => <String>{});
    if (value) {
      set.add(dayName);
      // Ensure the day has a color for calendar display
      if (!_dayColors.containsKey(dayName)) {
        final cs = Theme.of(context).colorScheme;
        _dayColors[dayName] = _resolveDayColor(dayName, cs).toARGB32();
        await _saveDayColors();
      }
      
      // Mark the gym task as done in daily screen
      await DailyTasksHelper.markGymTaskDoneForToday();
    } else {
      set.remove(dayName);
      if (set.isEmpty) _calendarByDate.remove(key);
    }
    await _saveCalendar();
    if (mounted) setState(() {});
  }

  Color _resolveDayColor(String day, ColorScheme cs) {
    final stored = _dayColors[day];
    if (stored != null) return Color(stored);
    final palette = Colors.primaries;
    final base = palette[day.hashCode.abs() % palette.length];
    return base.shade400;
  }

  Future<void> _setDayColor(String day, Color color) async {
    _dayColors[day] = color.toARGB32();
    await _saveDayColors();
    if (mounted) setState(() {});
  }

  Future<Color?> _pickColorForDay(String day) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.palette,
                      color: AppColors.accent(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).colorForDay(day),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink(context),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: AppColors.muted(context),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ColorPickerGrid(
                onColorSelected: (color) => Navigator.pop(ctx, color),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      await _setDayColor(day, selected);
    }
    return selected;
  }

  // ----------------------------- Helpers: Assignments -----------------------------
  void _ensureAssigned(String day, String workoutId) {
    final list = _assignmentsByDay.putIfAbsent(day, () => <String>[]);
    bool changed = false;
    if (!list.contains(workoutId)) {
      list.add(workoutId);
      changed = true;
      _saveAssignments();
    }
    final order = _orderByDay.putIfAbsent(day, () => <String>[]);
    if (!order.contains(workoutId)) {
      order.add(workoutId);
      _saveOrderByDay();
    }
    if (!_orderDays.contains(day)) {
      _orderDays.add(day);
      _saveOrderDays();
    }
    if (changed) setState(() {});
  }

  void _removeAssignmentForDay(String day, String workoutId) {
    final list = _assignmentsByDay[day];
    if (list == null) return;
    list.remove(workoutId);
    if (list.isEmpty) {
      _assignmentsByDay.remove(day);
      _orderDays.remove(day);
      _removeDayFromSplits(day);
      _saveOrderDays();
    }
    _saveAssignments();

    final order = _orderByDay[day];
    if (order != null) {
      order.remove(workoutId);
      if (order.isEmpty) _orderByDay.remove(day);
      _saveOrderByDay();
    }
    setState(() {});
  }

  void _removeDayFromSplits(String day) {
    bool changed = false;
    _splitsByName.forEach((_, days) {
      if (days.remove(day)) changed = true;
    });
    if (changed) {
      _saveSplits();
    }
  }

  Set<String> _assignedDaysForWorkout(String workoutId) {
    final out = <String>{};
    _assignmentsByDay.forEach((day, ids) {
      if (ids.contains(workoutId)) out.add(day);
    });
    return out;
  }

  // ----------------------------- Logik -----------------------------
  WorkoutLog? _getLatestLogFor(String workoutId) {
    final list = _logs[workoutId];
    if (list == null || list.isEmpty) return null;
    return list.last;
  }

  Set<String> _daysForWorkout(String workoutId) {
    final out = <String>{};
    final list = _logs[workoutId];
    if (list != null) {
      for (final l in list) {
        out.add(l.day);
      }
    }
    _assignmentsByDay.forEach((day, ids) {
      if (ids.contains(workoutId)) out.add(day);
    });
    return out;
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  String _formatSetValue(Workout workout, WorkoutSet set) {
    final u = workoutUnitsOf(AppLocalizations.of(context));
    if (isDurationWorkout(workout) && set.hasDuration) {
      return formatDurationShort(set.durationSeconds ?? 0, u);
    }
    return '${set.weightKg.toStringAsFixed(1)} ${u.kg} × ${set.reps}';
  }

  String _chartYAxisLabel(Workout workout) {
    final u = workoutUnitsOf(AppLocalizations.of(context));
    return isDurationWorkout(workout) ? u.secShort : u.kg;
  }

  void _addLog(String workoutId, WorkoutLog result) {
    final now = DateTime.now();
    final isToday = result.dateTime.year == now.year && 
                    result.dateTime.month == now.month && 
                    result.dateTime.day == now.day;
    
    setState(() {
      final list = _logs.putIfAbsent(workoutId, () => <WorkoutLog>[]);
      
      // Check if there's already an entry for the same day
      int existingIndex = -1;
      for (int i = 0; i < list.length; i++) {
        final log = list[i];
        if (log.dateTime.year == result.dateTime.year &&
            log.dateTime.month == result.dateTime.month &&
            log.dateTime.day == result.dateTime.day &&
            log.day == result.day) {
          existingIndex = i;
          break;
        }
      }
      
      if (existingIndex >= 0) {
        // Update existing entry for the same day
        list[existingIndex] = WorkoutLog(
          dateTime: result.dateTime,
          sets: result.sets,
          day: result.day,
        );
      } else {
        // Add new entry
        list.add(WorkoutLog(
          dateTime: result.dateTime,
          sets: result.sets,
          day: result.day,
        ));
      }
      
      _ensureAssigned(result.day, workoutId);
      
      // Aktualisiere Kalender mit dem Log-Datum
      final key = _dateKey(result.dateTime);
      final set = _calendarByDate.putIfAbsent(key, () => <String>{});
      set.add(result.day);
      // Ensure the day has a color for calendar display
      if (!_dayColors.containsKey(result.day)) {
        final cs = Theme.of(context).colorScheme;
        _dayColors[result.day] = _resolveDayColor(result.day, cs).toARGB32();
        _saveDayColors();
      }
      _saveCalendar();
      
      // Aktualisiere Best-Set-Cache für diese Übung
      final bestRecord = _bestSetCache.findBest(list);
      _bestSetCache.updateBest(workoutId, bestRecord);
    });
    _saveLogs();
    _saveBestSetCache(); // Speichere den aktualisieren Cache
    
    // Mark gym task as done in daily screen if logged today
    if (isToday) {
      DailyTasksHelper.markGymTaskDoneForToday();
    }
  }

  WorkoutLog? _latestForDay(String workoutId, String day) {
    final list = _logs[workoutId];
    if (list == null || list.isEmpty) return null;
    WorkoutLog? latest;
    for (final log in list) {
      if (log.day == day) {
        if (latest == null || log.dateTime.isAfter(latest.dateTime)) {
          latest = log;
        }
      }
    }
    return latest;
  }

  // ---------- Reihenfolge: Übungs-Ansicht ----------
  List<Workout> _getActiveWorkouts() {
    final idsWithLogs = _logs.keys.toSet();
    final idsWithAssign = <String>{
      for (final entry in _assignmentsByDay.entries) ...entry.value
    };
    final activeIds = {...idsWithLogs, ...idsWithAssign}.toList();

    final active =
    _workouts.where((w) => activeIds.contains(w.id)).toList(growable: false);

    bool changed = false;
    for (final id in activeIds) {
      if (!_orderActive.contains(id)) {
        _orderActive.add(id);
        changed = true;
      }
    }
    if (changed) _saveOrderActive();

    active.sort((a, b) =>
        _orderActive.indexOf(a.id).compareTo(_orderActive.indexOf(b.id)));
    return active;
  }

  void _reorderMainOnly(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final active = _getActiveWorkouts();
    if (active.isEmpty) return;

    final ids = active.map((w) => w.id).toList();
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);

    final setActive = ids.toSet();
    _orderActive.removeWhere(setActive.contains);
    _orderActive.insertAll(0, ids);

    _saveOrderActive();
    setState(() {});
  }

  // ---------- Nur zugewiesene Übungen für Day ----------
  List<Workout> _getAssignedWorkoutsForDayOrdered(String day) {
    final ids = _assignmentsByDay[day]?.toList() ?? <String>[];

    final order = List<String>.from(_orderByDay[day] ?? const []);
    bool changed = false;
    for (final id in ids) {
      if (!order.contains(id)) {
        order.add(id);
        changed = true;
      }
    }
    if (changed) {
      _orderByDay[day] = order;
      _saveOrderByDay();
    }

    final filtered =
    _workouts.where((w) => ids.contains(w.id)).toList(growable: false);
    filtered.sort(
            (a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    return filtered;
  }

  void _reorderDay(String day, List<String> newOrder) {
    _orderByDay[day] = newOrder;
    _saveOrderByDay();
    setState(() {});
  }

  // ---------- Day-Order (Gruppen-Reihenfolge) ----------
  void _syncOrderDaysWithAssignments() {
    final activeDays = _assignmentsByDay.keys.toList();

    bool changed = false;
    for (final d in activeDays) {
      if (!_orderDays.contains(d)) {
        _orderDays.add(d);
        changed = true;
      }
    }
    final activeSet = activeDays.toSet();
    final beforeLen = _orderDays.length;
    _orderDays.removeWhere((d) => !activeSet.contains(d));
    if (_orderDays.length != beforeLen) changed = true;

    if (changed) _saveOrderDays();
  }

  void _syncSplitsWithDays() {
    final availableDays = _assignmentsByDay.keys.toSet();
    bool splitsChanged = false;

    _splitsByName.forEach((_, days) {
      final before = days.length;
      days.removeWhere((d) => !availableDays.contains(d));
      if (days.length != before) splitsChanged = true;
    });

    bool orderChanged = false;
    for (final splitName in _splitsByName.keys) {
      if (!_splitOrder.contains(splitName)) {
        _splitOrder.add(splitName);
        orderChanged = true;
      }
    }
    final splitNamesSet = _splitsByName.keys.toSet();
    final beforeLen = _splitOrder.length;
    _splitOrder.removeWhere((s) => !splitNamesSet.contains(s));
    if (_splitOrder.length != beforeLen) orderChanged = true;

    if (splitsChanged) _saveSplits();
    if (orderChanged) _saveSplitOrder();
  }

  List<String> _getOrderedSplits() {
    _syncSplitsWithDays();
    return List<String>.from(_splitOrder);
  }

  void _reorderSplits(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final splits = _getOrderedSplits();
    if (splits.isEmpty) return;

    final moved = splits.removeAt(oldIndex);
    splits.insert(newIndex, moved);

    final setSplits = splits.toSet();
    _splitOrder.removeWhere(setSplits.contains);
    _splitOrder.insertAll(0, splits);

    _saveSplitOrder();
    setState(() {});
  }

  List<String> _getOrderedDays() {
    _syncOrderDaysWithAssignments();
    return List<String>.from(_orderDays);
  }

  void _reorderDays(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final days = _getOrderedDays();
    if (days.isEmpty) return;

    final moved = days.removeAt(oldIndex);
    days.insert(newIndex, moved);

    final setDays = days.toSet();
    _orderDays.removeWhere(setDays.contains);
    _orderDays.insertAll(0, days);

    _saveOrderDays();
    setState(() {});
  }

  // ----------------------------- Delete + Dialoge -----------------------------
  void _deleteWorkoutLogsAll(String workoutId) {
    setState(() {
      _logs.remove(workoutId);
      _bestSetCache.updateBest(workoutId, null); // Lösche Best-Set aus Cache
    });
    _saveLogs();
    _saveBestSetCache();
  }

  String _calendarTrackingKeyForLog(WorkoutLog log) =>
      '${_dateKey(log.dateTime)}|${log.day}';

  void _removeCalendarTrackingForDeletedLogs(List<WorkoutLog> deletedLogs) {
    if (deletedLogs.isEmpty) return;

    final deletedPairs = deletedLogs
        .map(_calendarTrackingKeyForLog)
        .toSet();

    final remainingPairs = <String>{};
    _logs.forEach((_, logList) {
      for (final log in logList) {
        remainingPairs.add(_calendarTrackingKeyForLog(log));
      }
    });

    for (final pair in deletedPairs) {
      if (remainingPairs.contains(pair)) continue;

      final separator = pair.indexOf('|');
      if (separator <= 0 || separator >= pair.length - 1) continue;

      final dateKey = pair.substring(0, separator);
      final day = pair.substring(separator + 1);

      final days = _calendarByDate[dateKey];
      if (days == null) continue;

      days.remove(day);
      if (days.isEmpty) _calendarByDate.remove(dateKey);
    }
  }

  void _deleteExerciseEverywhere(String workoutId, {bool removeTrackedCalendar = false}) {
    final deletedLogs = List<WorkoutLog>.from(_logs[workoutId] ?? const <WorkoutLog>[]);
    _logs.remove(workoutId);
    _bestSetCache.updateBest(workoutId, null); // Lösche Best-Set aus Cache
    _exerciseNotesByWorkoutId.remove(workoutId);

    if (removeTrackedCalendar) {
      _removeCalendarTrackingForDeletedLogs(deletedLogs);
    }

    _assignmentsByDay.forEach((day, list) => list.remove(workoutId));
    _assignmentsByDay.removeWhere((_, list) => list.isEmpty);

    _orderActive.remove(workoutId);
    _orderByDay.forEach((day, list) => list.remove(workoutId));
    _orderByDay.removeWhere((_, list) => list.isEmpty);

    _orderDays.removeWhere((d) => !_assignmentsByDay.containsKey(d));

    _saveLogs();
    _saveAssignments();
    _saveOrderActive();
    _saveOrderByDay();
    _saveOrderDays();
    _saveBestSetCache();
    _saveExerciseNotes();
    if (removeTrackedCalendar) {
      _saveCalendar();
    }

    setState(() {});
  }

  void _confirmClearHistoryAll(Workout w) async {
    final confirmed = await _showModernConfirmationDialog(
      context: context,
      title: AppLocalizations.of(context).clearAllHistoryTitle,
      message: AppLocalizations.of(context).clearAllHistoryMessage(w.name),
      confirmButtonText: AppLocalizations.of(context).delete,
      icon: Icons.delete_outline,
      iconColor: AppColors.accent(context),
      isDangerous: true,
    );

    if (confirmed) {
      _deleteWorkoutLogsAll(w.id);
    }
  }

  Future<void> _confirmDeleteExercise(Workout w) async {
    final result = await _showModernConfirmationDialogWithOptions<String>(
      context: context,
      title: AppLocalizations.of(context).removeWorkoutTitle(w.name),
      message: AppLocalizations.of(context).removeWorkoutMessage,
      icon: Icons.delete_forever,
      iconColor: AppColors.accent(context),
      isDangerous: true,
      options: {
        AppLocalizations.of(context).cancel: 'cancel',
        AppLocalizations.of(context).deleteOnly: 'delete_only',
        AppLocalizations.of(context).deletePlusCalendar: 'delete_all',
      },
    );

    if (result == 'delete_only') {
      _deleteExerciseEverywhere(w.id, removeTrackedCalendar: false);
    } else if (result == 'delete_all') {
      _deleteExerciseEverywhere(w.id, removeTrackedCalendar: true);
    }
  }

  Future<void> _openExerciseNoteDialog(Workout workout) async {
    final existing = _exerciseNotesByWorkoutId[workout.id] ?? '';
    final controller = TextEditingController(text: existing);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (AppColors.isDark(context) ? const Color(0xFF241F33) : const Color(0xFFEDE9FE)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.sticky_note_2_outlined,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).noteFor(workout.name),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 6,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).addNoteHint,
                  filled: true,
                  fillColor: (AppColors.isDark(context) ? const Color(0xFF23272D) : const Color(0xFFF8FAFC)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(AppLocalizations.of(context).cancel),
                  ),
                  if (existing.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, ''),
                      child: Text(
                        AppLocalizations.of(context).remove,
                        style: TextStyle(color: AppColors.accent(context)),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, controller.text),
                    child: Text(AppLocalizations.of(context).save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();
    if (result == null) return;

    final note = result.trim();
    setState(() {
      if (note.isEmpty) {
        _exerciseNotesByWorkoutId.remove(workout.id);
      } else {
        _exerciseNotesByWorkoutId[workout.id] = note;
      }
    });
    await _saveExerciseNotes();

    if (!mounted) return;
    final info = note.isEmpty ? AppLocalizations.of(context).noteRemoved : AppLocalizations.of(context).noteSaved;
    ScaffoldMessenger.of(context).showSingleSnackBar(SnackBar(content: Text(info)));
  }

  Future<void> _openWorkoutLongPressMenu(Workout w) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.show_chart),
              title: Text(AppLocalizations.of(context).showProgressChart),
              onTap: () => Navigator.pop(ctx, 'chart'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(AppLocalizations.of(context).deleteExerciseEllipsis),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'chart') {
      _openProgressChartDialog(w);
    } else if (action == 'delete') {
      _confirmDeleteExercise(w);
    }
  }

  Future<void> _showExerciseOptionsMenu(Workout w) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _openUnassignDialog(w);
                      },
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (AppColors.isDark(context) ? const Color(0xFF14273A) : const Color(0xFFE3F2FD)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.remove_circle_outline,
                                color: Color(0xFF2196F3),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).removeFromPlan,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).keepProgressHistory,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.border(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: AppColors.chip(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _openExerciseNoteDialog(w);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (AppColors.isDark(context) ? const Color(0xFF241F33) : const Color(0xFFEDE9FE)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.sticky_note_2_outlined,
                                color: Color(0xFF7C3AED),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).addNote,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _exerciseNotesByWorkoutId[w.id]?.isNotEmpty == true
                                        ? AppLocalizations.of(context).editExistingNote
                                        : AppLocalizations.of(context).saveNoteSubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.border(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: AppColors.chip(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmClearHistoryAll(w);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: AppColors.accent(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).clearAllHistoryAction,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).clearAllHistorySubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.border(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: AppColors.chip(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmDeleteExercise(w);
                      },
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_forever,
                                color: AppColors.accent(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).deleteExercise,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).deleteExerciseSubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteWorkoutLogsForDay(String workoutId, String day) {
    final list = _logs[workoutId];
    if (list == null) return;
    setState(() {
      list.removeWhere((log) => log.day == day);
      if (list.isEmpty) {
        _logs.remove(workoutId);
        _bestSetCache.updateBest(workoutId, null); // Lösche Best-Set aus Cache
      } else {
        // Aktualisiere Best-Set-Cache nach Löschen von Logs
        final bestRecord = _bestSetCache.findBest(list);
        _bestSetCache.updateBest(workoutId, bestRecord);
      }
    });
    _saveLogs();
    _saveBestSetCache();
  }

  Future<void> _confirmDeleteForDay(Workout w, String day) async {
    final confirmed = await _showModernConfirmationDialog(
      context: context,
      title: AppLocalizations.of(context).clearHistoryOnDay(w.name, day),
      message: AppLocalizations.of(context).onlyThisDayLogsDeleted,
      confirmButtonText: AppLocalizations.of(context).delete,
      icon: Icons.delete_outline,
      iconColor: AppColors.accent(context),
      isDangerous: true,
    );

    if (confirmed) {
      _deleteWorkoutLogsForDay(w.id, day);
    }
  }

  // Remove-from-plan Dialog (By Exercise)
  Future<void> _openUnassignDialog(Workout w) async {
    final assignedDays = _assignedDaysForWorkout(w.id).toList()..sort();
    if (assignedDays.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (AppColors.isDark(context) ? const Color(0xFF14273A) : const Color(0xFFE3F2FD)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFF2196F3),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context).exerciseNotAssigned,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).exerciseNotAssignedMessage,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    final selected = <String>{};
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (AppColors.isDark(context) ? const Color(0xFF14273A) : const Color(0xFFE3F2FD)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFF2196F3),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Remove "${w.name}"',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).chooseDaysToRemove,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted(context),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: assignedDays.map((d) {
                    final isSel = selected.contains(d);
                    return FilterChip(
                      label: Text(d),
                      selected: isSel,
                      selectedColor: const Color(0xFF2196F3),
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : AppColors.muted(context),
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSel ? Color(0xFF2196F3) : AppColors.border(context),
                      ),
                      onSelected: (v) => setS(() {
                        if (v) {
                          selected.add(d);
                        } else {
                          selected.remove(d);
                        }
                      }),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: Text(
                        AppLocalizations.of(context).cancel,
                        style: TextStyle(color: AppColors.muted(context)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                        for (final d in selected) {
                          _removeAssignmentForDay(d, w.id);
                        }
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: AppColors.chip(context),
                      ),
                      child: Text(
                        AppLocalizations.of(context).remove,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------- Rename Day -----------------------------
  Future<void> _renameDayDialog(String oldDayName) async {
    final controller = TextEditingController(text: oldDayName);
    
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppColors.accent(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).renameWorkoutDay,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).newName,
                  hintText: AppLocalizations.of(context).enterNewDayName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Navigator.pop(ctx, value.trim());
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isNotEmpty && value != oldDayName) {
                        Navigator.pop(ctx, value);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context).rename,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName == null || newName.isEmpty || newName == oldDayName) return;

    // Check if new name already exists
    if (_assignmentsByDay.containsKey(newName)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (AppColors.isDark(context) ? Color(0xFF332612) : Color(0xFFFFF3E0)),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Color(0xFFFF9800),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocalizations.of(context).nameAlreadyExists,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink(context),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).dayNameExistsMessage(newName),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.muted(context),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Always keep tracked history in sync with renamed workout days.
    await _performDayRename(oldDayName, newName, true);
  }

  Future<void> _performDayRename(String oldName, String newName, bool renameTracked) async {
    setState(() {
      // 1. Rename in assignments
      final assignments = _assignmentsByDay.remove(oldName);
      if (assignments != null) {
        _assignmentsByDay[newName] = assignments;
      }

      // 2. Rename in order by day
      final order = _orderByDay.remove(oldName);
      if (order != null) {
        _orderByDay[newName] = order;
      }

      // 3. Rename in order days list
      final dayIndex = _orderDays.indexOf(oldName);
      if (dayIndex >= 0) {
        _orderDays[dayIndex] = newName;
      }

      // 4. Rename in day colors
      final color = _dayColors.remove(oldName);
      if (color != null) {
        _dayColors[newName] = color;
      }

      // 5. Rename in day icons
      final icon = _dayIcons.remove(oldName);
      if (icon != null) {
        _dayIcons[newName] = icon;
      }

      // 6. Rename in day custom icons
      final customIcon = _dayCustomIcons.remove(oldName);
      if (customIcon != null) {
        _dayCustomIcons[newName] = customIcon;
      }

      // 7. Rename in splits
      _splitsByName.forEach((_, days) {
        for (int i = 0; i < days.length; i++) {
          if (days[i] == oldName) {
            days[i] = newName;
          }
        }
      });

      if (renameTracked) {
        // 8. Rename in calendar entries (tracked workouts)
        _calendarByDate.forEach((dateKey, daySet) {
          if (daySet.contains(oldName)) {
            daySet.remove(oldName);
            daySet.add(newName);
          }
        });

        // 9. Rename in workout logs and deduplicate potential day collisions.
        _logs.forEach((workoutId, logList) {
          final Map<String, WorkoutLog> byDateAndDay = <String, WorkoutLog>{};

          for (int i = 0; i < logList.length; i++) {
            final log = logList[i];
            final normalizedDay = log.day == oldName ? newName : log.day;
            final normalizedLog = log.day == oldName
                ? WorkoutLog(
                    dateTime: log.dateTime,
                    day: newName,
                    sets: log.sets,
                  )
                : log;

            final dateKey = _dateKey(log.dateTime);
            final uniqueKey = '$dateKey|$normalizedDay';
            final existing = byDateAndDay[uniqueKey];

            if (existing == null || normalizedLog.dateTime.isAfter(existing.dateTime)) {
              byDateAndDay[uniqueKey] = normalizedLog;
            }
          }

          final deduped = byDateAndDay.values.toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          logList
            ..clear()
            ..addAll(deduped);
        });
      }
    });

    // Save all changes
    await _saveAssignments();
    await _saveOrderByDay();
    await _saveOrderDays();
    await _saveDayColors();
    await _saveDayIcons();
    await _saveDayCustomIcons();
    await _saveSplits();
    if (renameTracked) {
      await _saveCalendar();
      await _saveLogs();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(content: Text(
          AppLocalizations.of(context).renamedTo(oldName, newName) +
              (renameTracked ? AppLocalizations.of(context).includingTracked : ''),
        )),
      );
    }
  }

  // ----------------------------- Day Icon Management -----------------------------
  IconData _getDayIcon(String day) {
    final stored = _dayIcons[day];
    if (stored != null) {
      // Find icon in available icons by codePoint
      try {
        return _availableIcons.firstWhere(
          (icon) => icon.codePoint == stored,
          orElse: () => Icons.event_note,
        );
      } catch (_) {
        return Icons.event_note;
      }
    }
    return Icons.event_note;
  }

  Widget _getDayIconWidget(String day) {
    final customPath = _dayCustomIcons[day];
    if (customPath != null && customPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(customPath),
          fit: BoxFit.cover,
        ),
      );
    }
    final stored = _dayIcons[day];
    if (GymIcons.isCustom(stored)) {
      return GymIcons.icon(
        stored!,
        color: AppColors.accent(context),
        size: 24,
      );
    }
    return Icon(
      _getDayIcon(day),
      color: AppColors.accent(context),
      size: 24,
    );
  }

  Future<void> _pickCustomIcon(String day, BuildContext dialogContext) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'day_icon_${day.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final filePath = '${directory.path}/$fileName';
        
        final savedImage = await File(image.path).copy(filePath);
        
        setState(() {
          _dayCustomIcons[day] = savedImage.path;
          // Remove standard icon when custom image is set
          _dayIcons.remove(day);
        });
        
        await _saveDayCustomIcons();
        await _saveDayIcons();
        
        if (dialogContext.mounted) {
          Navigator.pop(dialogContext);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSingleSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).customIconSaved)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSingleSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).errorSavingImage(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _showDayOptionsMenu(String day) async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _renameDayDialog(day);
                      },
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (AppColors.isDark(context) ? const Color(0xFF14273A) : const Color(0xFFE3F2FD)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Color(0xFF2196F3),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).rename,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).renameDaySubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.border(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: AppColors.chip(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _changeIconDialog(day);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.emoji_emotions,
                                color: AppColors.accent(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).changeIcon,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).changeIconDialogSubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: AppColors.border(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    color: AppColors.chip(context),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmDeleteWorkoutDay(day);
                      },
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.accentSoft(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.delete_outline,
                                color: AppColors.accent(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).deleteWorkoutDay,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).deleteWorkoutDaySubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.muted(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteWorkoutDay(String day) async {
    final removeTracked = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: AppColors.accent(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).deleteDayQuestion(day),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).deleteDayMessage,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, null),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context).cancel,
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    child: Text(
                      AppLocalizations.of(context).deleteOnlyDay,
                      style: TextStyle(color: AppColors.muted(context), fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context).deletePlusTracked,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (removeTracked == null) return;
    await _deleteWorkoutDay(day, removeTrackedHistory: removeTracked);
  }

  Future<void> _deleteWorkoutDay(String day, {required bool removeTrackedHistory}) async {
    _assignmentsByDay.remove(day);
    _orderByDay.remove(day);
    _orderDays.remove(day);
    _dayColors.remove(day);
    _dayIcons.remove(day);
    _dayCustomIcons.remove(day);
    _removeDayFromSplits(day);

    if (removeTrackedHistory) {
      _calendarByDate.forEach((_, days) => days.remove(day));
      _calendarByDate.removeWhere((_, days) => days.isEmpty);

      _logs.forEach((workoutId, list) {
        list.removeWhere((log) => log.day == day);
      });
      _logs.removeWhere((_, list) => list.isEmpty);
    }

    await _saveAssignments();
    await _saveOrderByDay();
    await _saveOrderDays();
    await _saveDayColors();
    await _saveDayIcons();
    await _saveDayCustomIcons();
    if (removeTrackedHistory) {
      await _saveCalendar();
      await _saveLogs();
    }

    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSingleSnackBar(
      SnackBar(
        content: Text(
          removeTrackedHistory
              ? AppLocalizations.of(context).dayDeletedTracked(day)
              : AppLocalizations.of(context).dayDeleted(day),
        ),
      ),
    );
  }

  Future<void> _changeIconDialog(String day) async {
    final selectedCode = await showDialog<int>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.emoji_emotions,
                      color: AppColors.accent(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).chooseAnIcon,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink(context),
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.close,
                          color: AppColors.muted(context),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                  ),
                  itemCount: GymIcons.all.length + _availableIcons.length + 1,
                  itemBuilder: (_, index) {
                    // Custom Push/Pull/Cardio icons first
                    if (index < GymIcons.all.length) {
                      final code = GymIcons.all[index];
                      final isSelected = _dayIcons[day] == code;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(ctx, code),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentSoft(context)
                                  : AppColors.bg(context),
                              borderRadius: BorderRadius.circular(14),
                              border: isSelected
                                  ? Border.all(color: AppColors.accent(context), width: 2.5)
                                  : Border.all(color: AppColors.border(context), width: 1),
                            ),
                            child: GymIcons.icon(
                              code,
                              size: 28,
                              color: isSelected
                                  ? AppColors.accent(context)
                                  : AppColors.muted(context),
                            ),
                          ),
                        ),
                      );
                    }

                    // Plus button at the end
                    if (index == GymIcons.all.length + _availableIcons.length) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _pickCustomIcon(day, ctx),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.bg(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.border(context),
                                width: 2.5,
                              ),
                            ),
                            child: Icon(
                              Icons.add,
                              color: AppColors.accent(context),
                              size: 32,
                            ),
                          ),
                        ),
                      );
                    }

                    final icon = _availableIcons[index - GymIcons.all.length];
                    final isSelected =
                        (_dayIcons[day] ?? Icons.event_note.codePoint) == icon.codePoint;

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, icon.codePoint),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.accentSoft(context) 
                                : AppColors.bg(context),
                            borderRadius: BorderRadius.circular(14),
                            border: isSelected 
                                ? Border.all(color: AppColors.accent(context), width: 2.5)
                                : Border.all(color: AppColors.border(context), width: 1),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected 
                                ? AppColors.accent(context) 
                                : AppColors.muted(context),
                            size: 28,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedCode != null) {
      setState(() {
        _dayIcons[day] = selectedCode;
        // Remove custom icon when switching to predefined icon
        _dayCustomIcons.remove(day);
      });
      await _saveDayIcons();
      await _saveDayCustomIcons();
    }
  }

  // ----------------------------- Charts -----------------------------
  void _openProgressChartDialog(Workout w, { String? filterByDay }) {
    final isDuration = isDurationWorkout(w);

    final allLogs = List<WorkoutLog>.from(_logs[w.id] ?? const <WorkoutLog>[]);
    // Filtere nach Tag, wenn filterByDay angegeben ist
    final logs = filterByDay != null
        ? allLogs.where((log) => log.day == filterByDay).toList()
        : allLogs;
    if (logs.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart, color: AppColors.accent(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).noDataYetTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context).startTrackingMessage,
            style: TextStyle(color: AppColors.muted(context)),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).gotIt),
            ),
          ],
        ),
      );
      return;
    }
    logs.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    
    // Hole den besten Satz aus dem Cache
    final bestSet = _bestSetCache.getBest(w.id);
    
    final int maxSets = logs.fold<int>(
      0,
      (m, l) => math.max(m, l.sets.length),
    );
    final List<int> seriesSetIndices = <int>[];
    final List<List<FlSpot>> multiSeriesSpots = <List<FlSpot>>[];

    for (int setIndex = 0; setIndex < maxSets; setIndex++) {
      final series = <FlSpot>[];
      for (final log in logs) {
        if (log.sets.length <= setIndex) continue;
        final set = log.sets[setIndex];
        final value = isDuration
            ? (set.durationSeconds ?? 0).toDouble()
            : set.weightKg;
        if (value <= 0) continue;
        series.add(FlSpot(
          log.dateTime.millisecondsSinceEpoch.toDouble(),
          value,
        ));
      }
      if (series.isNotEmpty) {
        seriesSetIndices.add(setIndex);
        multiSeriesSpots.add(series);
      }
    }

    final allSpots = multiSeriesSpots.expand((s) => s).toList();

    if (allSpots.isEmpty) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bg(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart, color: AppColors.accent(context)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).noDataYetTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            AppLocalizations.of(context).startTrackingMessage,
            style: TextStyle(color: AppColors.muted(context)),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).gotIt),
            ),
          ],
        ),
      );
      return;
    }

    final double minX = allSpots.map((s) => s.x).reduce(math.min);
    final double maxX = allSpots.map((s) => s.x).reduce(math.max);

    double niceNum(double range, {required bool round}) {
      if (range <= 0) return 1;
      final double exp =
      math.pow(10, (math.log(range) / math.ln10).floor()).toDouble();
      final double f = range / exp; // 1..10
      double nf;
      if (round) {
        if (f < 1.5) {
          nf = 1;
        } else if (f < 3) {
          nf = 2;
        } else if (f < 7) {
          nf = 5;
        } else {
          nf = 10;
        }
      } else {
        if (f <= 1) {
          nf = 1;
        } else if (f <= 2) {
          nf = 2;
        } else if (f <= 5) {
          nf = 5;
        } else {
          nf = 10;
        }
      }
      return nf * exp;
    }

    double rawMinY = (allSpots.map((s) => s.y).reduce(math.min) as num).toDouble();
    double rawMaxY = (allSpots.map((s) => s.y).reduce(math.max) as num).toDouble();
    if (rawMinY == rawMaxY) {
      rawMinY -= 1;
      rawMaxY += 1;
    }
    if (isDuration && rawMinY < 0) rawMinY = 0;

    const targetLines = 5;
    final niceRange = niceNum(rawMaxY - rawMinY, round: false);
    final yInterval = niceNum(niceRange / (targetLines - 1), round: true);
    final minY = (rawMinY / yInterval).floor() * yInterval;
    final maxY = (rawMaxY / yInterval).ceil() * yInterval;

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    String fmtTooltip(DateTime d) => fmtDate(d);
    WorkoutLog? logForSpotX(double x) {
      final target = x.round();
      for (final log in logs) {
        if (log.dateTime.millisecondsSinceEpoch == target) {
          return log;
        }
      }
      return null;
    }

    final chartUnits = workoutUnitsOf(AppLocalizations.of(context));
    String valueLabelForSet(double y, WorkoutLog? log, int setIndex) {
      if (isDuration) return formatDurationShort(y.round(), chartUnits);
      final reps = (log != null && setIndex >= 0 && setIndex < log.sets.length)
          ? log.sets[setIndex].reps
          : 0;
      return '${y.toStringAsFixed(1)} ${chartUnits.kg} x $reps';
    }

    Color seriesColor(int index) {
      final palette = Colors.primaries;
      return palette[index % palette.length].shade400;
    }
    
    // Prüfe ob ein Punkt der beste ist
    bool isBestSet(FlSpot spot) {
      if (bestSet == null) return false;
      
      final log = logForSpotX(spot.x);
      if (log == null) return false;
      
      // Der beste ist wenn:
      // 1. Das maxWeight gleich ist wie bestSet.maxWeight
      // 2. AND die Reps gleich sind OR
      // 3. Das Datum aus dem Log gleich ist wie bestSet.dateTime
      
      final isSameWeight = (log.maxWeightKg - bestSet.maxWeight).abs() < 0.01;
      final isSameDate = log.dateTime.year == bestSet.dateTime.year &&
                         log.dateTime.month == bestSet.dateTime.month &&
                         log.dateTime.day == bestSet.dateTime.day;
      
      if (isDuration) {
        return isSameDate;
      }
      
      return isSameWeight && isSameDate;
    }

    const double kLeftAxisSpaceToLine = 4;
    const double kLeftAxisReserved = 38;
    const double kLeftAxisNamePadding = 12;
    const double kFirstDateLeftPad = 8;
    const double kLastDateRightPad = 14;
    const double kBottomReserved = 30;

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bg(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.accentSoft(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.show_chart, color: AppColors.accent(context)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).progressFor(w.name),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).fullScreen,
              icon: const Icon(Icons.fullscreen),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullScreenChartPage(
                      title: w.name,
                      logs: logs,
                          isDurationBased: isDuration,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        content: SizedBox(
          width: 560,
          height: 300,
          child: LineChart(
            LineChartData(
              minX: minX,
              maxX: maxX,
              minY: minY.toDouble(),
              maxY: maxY.toDouble(),
              backgroundColor: Colors.transparent,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yInterval,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: const Color(0x22000000),
                  strokeWidth: 1,
                  dashArray: const [6, 6],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppColors.border(context)),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  axisNameWidget: Padding(
                    padding: const EdgeInsets.only(right: kLeftAxisNamePadding),
                    child: Text(_chartYAxisLabel(w),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  axisNameSize: 26,
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: kLeftAxisReserved,
                    interval: yInterval,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      space: kLeftAxisSpaceToLine,
                      child: Text(value.toStringAsFixed(0)),
                    ),
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: kBottomReserved,
                    interval: (maxX - minX) == 0 ? 1 : (maxX - minX),
                    getTitlesWidget: (value, meta) {
                      const eps = 0.5;
                      final bool isFirst = (value - minX).abs() < eps;
                      final bool isLast = (value - maxX).abs() < eps;

                      if ((maxX - minX).abs() < eps) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                        return SideTitleWidget(
                          meta: meta,
                          space: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(fmtDate(dt), style: const TextStyle(fontSize: 11)),
                          ),
                        );
                      }
                      if (!isFirst && !isLast) return const SizedBox.shrink();

                      final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final EdgeInsets pad = isFirst
                          ? const EdgeInsets.only(left: kFirstDateLeftPad)
                          : const EdgeInsets.only(right: kLastDateRightPad);

                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Padding(
                          padding: pad,
                          child: Text(
                            fmtDate(dt),
                            style: const TextStyle(fontSize: 11),
                            textAlign: isFirst ? TextAlign.left : TextAlign.right,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipColor: (_) => AppColors.card(context),
                  tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  getTooltipItems: (touchedSpots) => touchedSpots.map((t) {
                    final dt = DateTime.fromMillisecondsSinceEpoch(t.x.round());
                    final dateStr = fmtTooltip(dt);
                    final setIndex = seriesSetIndices[t.barIndex];
                    final log = logForSpotX(t.x);
                    final valueStr = valueLabelForSet(t.y, log, setIndex);
                    
                    final isBest = isBestSet(FlSpot(t.x, t.y));

                    return LineTooltipItem(
                      '$dateStr\n',
                      TextStyle(color: AppColors.ink(context), fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: isBest
                            ? AppLocalizations.of(context).setLabelBest(setIndex + 1, valueStr)
                            : AppLocalizations.of(context).setLabel(setIndex + 1, valueStr),
                          style: TextStyle(
                            color: AppColors.ink(context),
                            fontWeight: FontWeight.w500,
                            backgroundColor: isBest ? const Color(0xFFFFD700).withValues(alpha: 0.3) : null,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              lineBarsData: List<LineChartBarData>.generate(
                multiSeriesSpots.length,
                (i) {
                  final color = seriesColor(i);
                  return LineChartBarData(
                    spots: multiSeriesSpots[i],
                    isCurved: false,
                    barWidth: 2.6,
                    color: color,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        final isBest = isBestSet(spot);
                        
                        if (isBest) {
                          // Gold-Punkt für den besten Satz
                          return FlDotCirclePainter(
                            radius: 5.0,
                            color: const Color(0xFFFFD700), // Gold
                            strokeWidth: 2.0,
                            strokeColor: const Color(0xFFFFA500), // Orange border
                          );
                        }
                        
                        // Normale Punkte
                        return FlDotCirclePainter(
                          radius: 3.0,
                          color: color,
                          strokeWidth: 1.2,
                          strokeColor: color.withValues(alpha: 0.5),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------- UI -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(context),
            Expanded(
              child: _mode == ViewMode.byExercise
                  ? _buildWorkoutListBody()
                  : _mode == ViewMode.byDay
                      ? _buildDayListBody()
                      : _buildSplitListBody(),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildModernFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      color: AppColors.accent(context),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).gymTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink(context),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: AppLocalizations.of(context).calendarTitle,
                    icon: Icon(Icons.calendar_month, color: AppColors.muted(context)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WorkoutCalendarPage(
                            calendarByDate: _calendarByDate,
                            dayColors: _dayColors,
                            isCreatineTaken: _isCreatineTakenOn,
                            onToggleCreatine: _setCreatineTaken,
                          ),
                        ),
                      );
                    },
                  ),
                  _buildViewModeMenu(),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.chip(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _mode = ViewMode.byExercise);
                _saveViewMode();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == ViewMode.byExercise
                      ? AppColors.card(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _mode == ViewMode.byExercise
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.list,
                      size: 18,
                      color: _mode == ViewMode.byExercise
                          ? AppColors.accent(context)
                          : AppColors.muted(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).exercisesTab,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mode == ViewMode.byExercise
                            ? AppColors.ink(context)
                            : AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _mode = ViewMode.byDay);
                _saveViewMode();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == ViewMode.byDay
                      ? AppColors.card(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _mode == ViewMode.byDay
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.view_day,
                      size: 18,
                      color: _mode == ViewMode.byDay
                          ? AppColors.accent(context)
                          : AppColors.muted(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).workoutsLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mode == ViewMode.byDay
                            ? AppColors.ink(context)
                            : AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _mode = ViewMode.bySplit);
                _saveViewMode();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _mode == ViewMode.bySplit
                      ? AppColors.card(context)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _mode == ViewMode.bySplit
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_tree,
                      size: 18,
                      color: _mode == ViewMode.bySplit
                          ? AppColors.accent(context)
                          : AppColors.muted(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).splitsTab,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _mode == ViewMode.bySplit
                            ? AppColors.ink(context)
                            : AppColors.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeMenu() => PopupMenuButton<int>(
    tooltip: AppLocalizations.of(context).moreOptions,
    icon: Icon(Icons.more_horiz, color: AppColors.muted(context)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    onSelected: (v) {
      // Kann für zusätzliche Optionen verwendet werden
    },
    itemBuilder: (_) => const [],
  );

  Widget _buildModernFAB() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent(context), Color(0xFFEF5350)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent(context).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _mode == ViewMode.bySplit ? _onAddSplitPressed : _onAddPressed,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBody() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.chip(context),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.fitness_center,
            size: 64,
            color: AppColors.faint(context),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context).noWorkoutsYet,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.ink(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context).addFirstExercise,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.faint(context),
          ),
        ),
      ],
    ),
  );

  // Übungs-Ansicht
  Widget _buildWorkoutListBody() {
    final active = _getActiveWorkouts();
    if (active.isEmpty) return _buildEmptyBody();

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: active.length,
      onReorder: _reorderMainOnly,
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) {
        final w = active[i];
        final latest = _getLatestLogFor(w.id);
        return _buildModernWorkoutCard(w, i, latest);
      },
    );
  }

  Widget _buildModernWorkoutCard(Workout w, int index, WorkoutLog? latest) {
    return Container(
      key: ValueKey('ex_${w.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final days = _daysForWorkout(w.id).toList()..sort();
            final outcome = await _openLogDialog(
              w,
              latest: latest,
              contextDay: null,
              availableDays: days,
              creationMode: false,
            );
            if (outcome == null) return;
            if (outcome.log != null) _addLog(w.id, outcome.log!);
          },
          onLongPress: () => _openWorkoutLongPressMenu(w),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_indicator,
                    color: AppColors.border(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(5.0),
                  child: w.icon != null
                      ? Icon(
                          w.icon!,
                          color: AppColors.accent(context),
                          size: 24,
                        )
                      : w.iconPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                w.iconPath!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              Icons.fitness_center,
                              color: AppColors.accent(context),
                              size: 24,
                            ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestSummaryText(w, latest, workoutUnitsOf(AppLocalizations.of(context))),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.history, color: AppColors.muted(context)),
                  onPressed: () => _openHistoryDialog(w),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).moreOptions,
                  icon: Icon(Icons.more_vert, color: AppColors.muted(context)),
                  onPressed: () {
                    _showExerciseOptionsMenu(w);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Day-Ansicht
  Widget _buildDayListBody() {
    final days = _getOrderedDays();
    if (days.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.chip(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today,
                size: 64,
                color: AppColors.faint(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noWorkoutDaysYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).addExercisesToCreateDays,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.faint(context),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: days.length,
      onReorder: _reorderDays,
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) {
        final day = days[i];
        final count = _assignmentsByDay[day]?.length ?? 0;
        return _buildModernDayCard(day, i, count);
      },
    );
  }

  Widget _buildModernDayCard(String day, int index, int count) {
    return Container(
      key: ValueKey('day_$day'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDayDetail(day),
          onLongPress: () => _showDayOptionsMenu(day),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_indicator,
                    color: AppColors.border(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _getDayIconWidget(day),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context).exerciseCount(count),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.faint(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitListBody() {
    final splits = _getOrderedSplits();
    if (splits.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.chip(context),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_tree,
                size: 64,
                color: AppColors.faint(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noSplitsYet,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.ink(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).tapPlusForSplits,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.faint(context),
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: splits.length,
      onReorder: _reorderSplits,
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) {
        final splitName = splits[i];
        final count = _splitsByName[splitName]?.length ?? 0;
        return _buildModernSplitCard(splitName, i, count);
      },
    );
  }

  Widget _buildModernSplitCard(String splitName, int index, int count) {
    return Container(
      key: ValueKey('split_$splitName'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openSplitDetail(splitName),
          onLongPress: () => _showSplitOptionsMenu(splitName),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_indicator,
                    color: AppColors.border(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_tree,
                    color: AppColors.accent(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        splitName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count workout day${count == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.faint(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSplitDetail(String splitName) {
    final splitDays = _splitsByName[splitName] ?? const <String>[];
    final days = splitDays
        .where(_assignmentsByDay.containsKey)
        .toList(growable: false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SplitDetailScreen(
          splitName: splitName,
          days: days,
          dayExerciseCount: (day) => _assignmentsByDay[day]?.length ?? 0,
          dayIconBuilder: _getDayIconWidget,
          onOpenDay: _openDayDetail,
          onReorderDays: (newOrder) => _reorderSplitDays(splitName, newOrder),
        ),
      ),
    );
  }

  void _reorderSplitDays(String splitName, List<String> newOrder) {
    setState(() {
      _splitsByName[splitName] = List<String>.from(newOrder, growable: true);
    });
    _saveSplits();
  }

  Future<void> _showSplitOptionsMenu(String splitName) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    splitName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink(context),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    color: (AppColors.isDark(context) ? const Color(0xFF23272D) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          onTap: () => Navigator.pop(ctx, 'edit'),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppColors.muted(context)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).editSplit,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: AppColors.faint(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Divider(height: 1, color: AppColors.border(context)),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                          onTap: () => Navigator.pop(ctx, 'delete'),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, color: AppColors.accent(context)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context).deleteSplit,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accent(context),
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: AppColors.faint(context)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (action == 'edit') {
      await _editSplit(splitName);
    } else if (action == 'delete') {
      await _deleteSplit(splitName);
    }
  }

  Future<void> _onAddSplitPressed() async {
    final availableDays = _getOrderedDays();
    if (availableDays.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSingleSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).createDaysFirst)),
      );
      return;
    }

    final result = await _openSplitEditor(availableDays: availableDays);
    if (result == null) return;

    setState(() {
      _splitsByName[result.name] = List<String>.from(result.days, growable: true);
      if (!_splitOrder.contains(result.name)) {
        _splitOrder.add(result.name);
      }
    });
    await _saveSplits();
    await _saveSplitOrder();
  }

  Future<void> _editSplit(String splitName) async {
    final availableDays = _getOrderedDays();
    final initialDays = _splitsByName[splitName] ?? const <String>[];

    final result = await _openSplitEditor(
      availableDays: availableDays,
      initialName: splitName,
      initialDays: initialDays,
    );
    if (result == null) return;

    setState(() {
      if (result.name != splitName) {
        _splitsByName.remove(splitName);
        final idx = _splitOrder.indexOf(splitName);
        if (idx >= 0) {
          _splitOrder[idx] = result.name;
        } else if (!_splitOrder.contains(result.name)) {
          _splitOrder.add(result.name);
        }
      }
      _splitsByName[result.name] = List<String>.from(result.days, growable: true);
    });
    await _saveSplits();
    await _saveSplitOrder();
  }

  Future<void> _deleteSplit(String splitName) async {
    final confirmed = await _showModernConfirmationDialog(
      context: context,
      title: AppLocalizations.of(context).deleteSplitQuestion(splitName),
      message: AppLocalizations.of(context).deleteSplitMessage,
      confirmButtonText: AppLocalizations.of(context).delete,
      icon: Icons.delete_outline,
      iconColor: AppColors.accent(context),
      isDangerous: true,
    );

    if (!confirmed) return;

    setState(() {
      _splitsByName.remove(splitName);
      _splitOrder.remove(splitName);
    });
    await _saveSplits();
    await _saveSplitOrder();
  }

  Future<SplitEditorResult?> _openSplitEditor({
    required List<String> availableDays,
    String? initialName,
    List<String> initialDays = const [],
  }) async {
    final existingName = initialName;
    final controller = TextEditingController(text: initialName ?? '');
    final selected = <String>{...initialDays};

    final result = await showDialog<SplitEditorResult>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 620, maxWidth: 560),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft(context),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_tree,
                        color: AppColors.accent(context),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        existingName == null ? AppLocalizations.of(context).createSplit : AppLocalizations.of(context).editSplit,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink(context),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).splitName,
                    hintText: AppLocalizations.of(context).splitNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).selectWorkoutDays,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted(context),
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableDays.length,
                    itemBuilder: (_, i) {
                      final day = availableDays[i];
                      final checked = selected.contains(day);
                      return CheckboxListTile(
                        dense: true,
                        value: checked,
                        activeColor: AppColors.accent(context),
                        contentPadding: EdgeInsets.zero,
                        title: Text(day),
                        onChanged: (v) {
                          setS(() {
                            if (v == true) {
                              selected.add(day);
                            } else {
                              selected.remove(day);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppLocalizations.of(context).cancel),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final name = controller.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSingleSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).enterSplitName)),
                          );
                          return;
                        }
                        if (selected.isEmpty) {
                          ScaffoldMessenger.of(context).showSingleSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).selectAtLeastOneDay)),
                          );
                          return;
                        }

                        final nameTaken = _splitsByName.containsKey(name) && name != existingName;
                        if (nameTaken) {
                          ScaffoldMessenger.of(context).showSingleSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context).splitExists(name))),
                          );
                          return;
                        }

                        Navigator.pop(
                          ctx,
                          SplitEditorResult(
                            name: name,
                            days: availableDays.where(selected.contains).toList(growable: true),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent(context),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(existingName == null ? 'Create' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    controller.dispose();
    return result;
  }

  void _openDayDetail(String day) {
    final ordered = _getAssignedWorkoutsForDayOrdered(day);
    final stripe = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DayDetailScreen(
          day: day,
          orderedWorkouts: ordered,
          latestForDay: _latestForDay,
          onEdit: (w, latest) async {
            final outcome = await _openLogDialog(
              w,
              latest: latest,
              contextDay: day,
              availableDays: const [],
              creationMode: false,
            );
            if (outcome == null) return;
            if (outcome.log != null) _addLog(w.id, outcome.log!);
          },
          onRefresh: () => setState(() {}),
          onShowHistory: _openHistoryDialog,
          onShowChart: (w) => _openProgressChartDialog(w, filterByDay: day),
          onDeleteForDay: (w) => _confirmDeleteForDay(w, day),
          onDeleteAll: _confirmClearHistoryAll,
          onUnassignFromDay: (w) => _removeAssignmentForDay(day, w.id),
          onEditNote: _openExerciseNoteDialog,
          onReorder: (ids) => _reorderDay(day, ids),
          stripeColor: stripe,
          // Checkbox oben rechts
          isDoneToday: () => _isDayMarkedOn(DateTime.now(), day),
          onToggleDoneToday: (v) => _setDayMarkedToday(day, v),
          dayColor: _resolveDayColor(day, cs),
          onPickColor: () => _pickColorForDay(day),
          alternativeWorkoutIds: Set<String>.from(_alternativeWorkoutIdsByDay[day] ?? {}),
          onToggleAlternative: (id) {
            setState(() {
              final daySet = _alternativeWorkoutIdsByDay.putIfAbsent(day, () => {});
              if (daySet.contains(id)) {
                daySet.remove(id);
              } else {
                daySet.add(id);
              }
            });
            _saveAlternativeIds();
          },
        ),
      ),
    );
  }

  void _openHistoryDialog(Workout w) {
    showDialog<void>(context: context, builder: (_) => _buildHistoryDialog(w));
  }

  Widget _buildHistoryDialog(Workout w) {
    final list = _logs[w.id] ?? <WorkoutLog>[];
    final isDuration = isDurationWorkout(w);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (list.isEmpty) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          decoration: BoxDecoration(
            color: (AppColors.isDark(context) ? const Color(0xFF22262B) : const Color(0xFFFAFAFC)),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (AppColors.isDark(context) ? const Color(0xFF272B31) : const Color(0xFFF1F3F7)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.history_rounded, color: Color(0xFF4B5565)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context).noHistoryTitle,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).noHistoryMessage,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).gotIt),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final history = List<WorkoutLog>.from(list)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final bestSet = _bestSetCache.getBest(w.id) ?? _bestSetCache.findBest(list);

    bool isBestWorkout(WorkoutLog log) {
      if (bestSet == null) return false;

      final isSameDate = log.dateTime.year == bestSet.dateTime.year &&
          log.dateTime.month == bestSet.dateTime.month &&
          log.dateTime.day == bestSet.dateTime.day;

      if (!isSameDate) return false;
      if (isDuration) return true;

      final sameWeight = (log.maxWeightKg - bestSet.maxWeight).abs() < 0.01;
      final sameReps = log.heaviestSetReps == bestSet.maxReps;
      return sameWeight && sameReps;
    }

    final estimatedHeight = 180 + (history.length * 118);
    final dialogHeight = estimatedHeight.clamp(260, 560).toDouble();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        height: dialogHeight,
        constraints: const BoxConstraints(maxWidth: 680),
        decoration: BoxDecoration(
          color: (AppColors.isDark(context) ? const Color(0xFF22262B) : const Color(0xFFFAFAFC)),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 34,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (AppColors.isDark(context) ? const Color(0xFF272B31) : const Color(0xFFF1F3F7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded, color: Color(0xFF4B5565)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'History – ${w.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).logCount(history.length),
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final log = history[i];
                    final best = isBestWorkout(log);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: best
                            ? (AppColors.isDark(context) ? const Color(0xFF2E2712) : const Color(0xFFFFF8E1))
                            : AppColors.card(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: best ? Color(0xFFE7B835) : AppColors.border(context),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                best ? Icons.emoji_events_rounded : Icons.history_rounded,
                                color: best ? const Color(0xFFC58A00) : const Color(0xFF7A828F),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${AppLocalizations.of(context).setsCount(log.setCount)} • ${_formatDate(log.dateTime)}',
                                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              if (best)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (AppColors.isDark(context) ? const Color(0xFF3A3012) : const Color(0xFFFFE9A8)),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: const Color(0xFFE7B835)),
                                  ),
                                  child: Text(
                                    AppLocalizations.of(context).bestWorkout,
                                    style: tt.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF7A5900),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            log.day,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: log.sets
                                .map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.card(context),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.border(context)),
                                      ),
                                      child: Text(
                                        _formatSetValue(w, s),
                                        style: tt.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF3F495A),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAddPressed() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WorkoutPickerSheet(
        workouts: _workouts,
        latestFor: _getLatestLogFor,
        onAddOrUpdate: (w) async {
          final days = _daysForWorkout(w.id).toList()..sort();
          final outcome = await _openLogDialog(
            w,
            latest: _getLatestLogFor(w.id),
            contextDay: null,
            availableDays: days,
            creationMode: true,
          );
          if (outcome == null) return;

          if (outcome.log != null) {
            _addLog(w.id, outcome.log!);
          } else if (outcome.assignDay != null) {
            _ensureAssigned(outcome.assignDay!, w.id);
            setState(() {});
          }
        },
      ),
    );
  }

  Future<LogOutcome?> _openLogDialog(
      Workout w, {
        WorkoutLog? latest,
        String? contextDay,
        List<String> availableDays = const [],
        bool creationMode = false,
      }) {
    return showDialog<LogOutcome>(
      context: context,
      builder: (_) => LogInputDialog(
        workout: w,
        latest: latest,
        contextDay: contextDay,
        availableDays: availableDays,
        creationMode: creationMode,
      ),
    );
  }
}

/// ===============================================================
/// Bottom Sheet: Suche + Liste + Beschreibung
/// ===============================================================