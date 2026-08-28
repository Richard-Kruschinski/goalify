import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/i18n/task_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gym_models.dart';
import '../widgets/weight_settings_tile.dart';

// ===============================================================
// DayDetailScreen mit Checkbox oben rechts („heute erledigt“)
// ===============================================================
class DayDetailScreen extends StatefulWidget {
  final String day;
  final List<Workout> orderedWorkouts;
  final WorkoutLog? Function(String workoutId, String day) latestForDay;
  final Future<void> Function(Workout workout, WorkoutLog? latestForThisDay)
  onEdit;
  final void Function(Workout workout) onShowHistory;
  final void Function(Workout workout) onShowChart;
  final void Function(Workout workout) onDeleteForDay;
  final void Function(Workout workout) onDeleteAll;
  final void Function(Workout workout) onUnassignFromDay;
  final Future<void> Function(Workout workout) onEditNote;
  final Future<void> Function(Workout workout) onEditWeightSettings;
  /// Bar weight / tracking mode currently stored for an exercise.
  final ExerciseWeightSettings Function(Workout workout) weightSettingsFor;
  final void Function(List<String> newOrder) onReorder;
  final Color stripeColor;
  final VoidCallback? onRefresh;

  final bool Function() isDoneToday;
  final Future<void> Function(bool value) onToggleDoneToday;
  final Color dayColor;
  final Future<Color?> Function() onPickColor;
  final Set<String> alternativeWorkoutIds;
  final void Function(String workoutId) onToggleAlternative;

  const DayDetailScreen({
    super.key,
    required this.day,
    required this.orderedWorkouts,
    required this.latestForDay,
    required this.onEdit,
    required this.onShowHistory,
    required this.onShowChart,
    required this.onDeleteForDay,
    required this.onDeleteAll,
    required this.onUnassignFromDay,
    required this.onEditNote,
    required this.onEditWeightSettings,
    required this.weightSettingsFor,
    required this.onReorder,
    required this.stripeColor,
    this.onRefresh,
    required this.isDoneToday,
    required this.onToggleDoneToday,
    required this.dayColor,
    required this.onPickColor,
    required this.alternativeWorkoutIds,
    required this.onToggleAlternative,
  });

  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  late List<Workout> _list;
  late bool _checkedToday;
  late Color _currentColor;
  late Set<String> _alternativeIds;

  @override
  void initState() {
    super.initState();
    _list = List<Workout>.from(widget.orderedWorkouts);
    _checkedToday = widget.isDoneToday();
    _currentColor = widget.dayColor;
    _alternativeIds = Set<String>.from(widget.alternativeWorkoutIds);
  }

  void _onReorderMain(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final mainIds = _list
        .where((w) => !_alternativeIds.contains(w.id))
        .map((w) => w.id)
        .toList();
    final moved = mainIds.removeAt(oldIndex);
    mainIds.insert(newIndex, moved);

    final altWorkouts = _list.where((w) => _alternativeIds.contains(w.id)).toList();
    final mainWorkouts = mainIds.map((id) => _list.firstWhere((w) => w.id == id)).toList();

    setState(() {
      _list
        ..clear()
        ..addAll(mainWorkouts)
        ..addAll(altWorkouts);
    });
    widget.onReorder(_list.map((w) => w.id).toList());
  }

  void _onReorderAlternatives(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final altIds = _list
        .where((w) => _alternativeIds.contains(w.id))
        .map((w) => w.id)
        .toList();
    final moved = altIds.removeAt(oldIndex);
    altIds.insert(newIndex, moved);

    final mainWorkouts = _list.where((w) => !_alternativeIds.contains(w.id)).toList();
    final altWorkouts = altIds.map((id) => _list.firstWhere((w) => w.id == id)).toList();

    setState(() {
      _list
        ..clear()
        ..addAll(mainWorkouts)
        ..addAll(altWorkouts);
    });
    widget.onReorder(_list.map((w) => w.id).toList());
  }

  Widget _buildAlternativesDivider() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: AppColors.border(context))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              AppLocalizations.of(context).alternatives,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.faint(context),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: AppColors.border(context))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainExercises = _list.where((w) => !_alternativeIds.contains(w.id)).toList();
    final altExercises = _list.where((w) => _alternativeIds.contains(w.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernDayHeader(context),
            Expanded(
              child: _list.isEmpty
                  ? _buildModernEmptyDay()
                  : CustomScrollView(
                      slivers: [
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(20, 16, 20, altExercises.isEmpty ? 100 : 0),
                          sliver: SliverReorderableList(
                            itemCount: mainExercises.length,
                            onReorder: _onReorderMain,
                            itemBuilder: (_, i) {
                              final workout = mainExercises[i];
                              final latest = widget.latestForDay(workout.id, widget.day);
                              return _buildModernDayExerciseCard(workout, i, latest);
                            },
                          ),
                        ),
                        if (altExercises.isNotEmpty) ...[
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: _buildAlternativesDivider(),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                            sliver: SliverReorderableList(
                              itemCount: altExercises.length,
                              onReorder: _onReorderAlternatives,
                              itemBuilder: (_, i) {
                                final workout = altExercises[i];
                                final latest = widget.latestForDay(workout.id, widget.day);
                                return _buildModernDayExerciseCard(workout, i, latest, isAlternative: true);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernEmptyDay() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 8),
          Icon(Icons.fitness_center, size: 64, color: AppColors.faint(context)),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).noExercisesToday,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink(context)),
          ),
          SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).addOrAssignExercises,
            style: TextStyle(fontSize: 14, color: AppColors.faint(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDayHeader(BuildContext context) {
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
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.arrow_back, color: AppColors.muted(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.day,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.ink(context),
              ),
            ),
          ),
          // Color picker button
          IconButton(
            tooltip: AppLocalizations.of(context).pickColorForDay,
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: _currentColor,
              child: const Icon(Icons.palette, size: 16, color: Colors.white),
            ),
            onPressed: () async {
              final chosen = await widget.onPickColor();
              if (chosen != null) setState(() => _currentColor = chosen);
            },
          ),
          const SizedBox(width: 4),
          // Done today pill
          GestureDetector(
            onTap: () async {
              final nv = !_checkedToday;
              await widget.onToggleDoneToday(nv);
              setState(() => _checkedToday = nv);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _checkedToday ? (AppColors.isDark(context) ? Color(0xFF15291C) : Color(0xFFE8F5E9)) : AppColors.chip(context),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _checkedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: _checkedToday ? Color(0xFF4CAF50) : AppColors.muted(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context).doneToday,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _checkedToday ? Color(0xFF4CAF50) : AppColors.muted(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDayExerciseCard(Workout w, int index, WorkoutLog? latest, {bool isAlternative = false}) {
    return Container(
      key: ValueKey(isAlternative ? 'day_alt_${w.id}' : 'day_${w.id}'),
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
            await widget.onEdit(w, latest);
            if (widget.onRefresh != null) {
              widget.onRefresh!();
              setState(() {}); // Refresh UI
            }
          },
          onLongPress: () => widget.onShowChart(w),
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
                  child: w.iconPath != null
                      ? Padding( // Exercise Icon as Image
                          padding: const EdgeInsets.all(5.0),
                          child: Image.asset(
                            w.iconPath!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Icon(w.icon ?? Icons.fitness_center, color: AppColors.accent(context), size: 24),
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
                        style: TextStyle(fontSize: 13, color: AppColors.muted(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).history,
                  onPressed: () => widget.onShowHistory(w),
                  icon: Icon(Icons.history, color: AppColors.muted(context)),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context).moreOptions,
                  icon: Icon(Icons.more_vert, color: AppColors.muted(context)),
                  onPressed: () {
                    _showExerciseOptionsMenuForDay(w);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExerciseOptionsMenuForDay(Workout w) async {
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
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onDeleteForDay(w);
                      },
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                                    AppLocalizations.of(context).deleteTodayLogsOnly,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).removeLogsFromDate,
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
                        await widget.onEditNote(w);
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
                                  SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).saveNoteSubtitle,
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
                  WeightSettingsTile(
                    settings: widget.weightSettingsFor(w),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await widget.onEditWeightSettings(w);
                      if (mounted) setState(() {});
                    },
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
                        final isAlt = _alternativeIds.contains(w.id);
                        setState(() {
                          if (isAlt) {
                            _alternativeIds.remove(w.id);
                          } else {
                            _alternativeIds.add(w.id);
                          }
                        });
                        widget.onToggleAlternative(w.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (AppColors.isDark(context) ? const Color(0xFF332612) : const Color(0xFFFFF3E0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _alternativeIds.contains(w.id)
                                    ? Icons.star_rounded
                                    : Icons.swap_horiz_rounded,
                                color: const Color(0xFFFF9800),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _alternativeIds.contains(w.id)
                                        ? AppLocalizations.of(context).setAsMain
                                        : AppLocalizations.of(context).markAsAlternative,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _alternativeIds.contains(w.id)
                                        ? AppLocalizations.of(context).moveBackToMainList
                                        : AppLocalizations.of(context).moveToSeparateSection,
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
                        widget.onUnassignFromDay(w);
                        setState(() {
                          _list.removeWhere((x) => x.id == w.id);
                        });
                      },
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
                                  const SizedBox(height: 4),
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
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onDeleteAll(w);
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
                                    AppLocalizations.of(context).deleteAllLogs,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).removeAllProgress,
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
}