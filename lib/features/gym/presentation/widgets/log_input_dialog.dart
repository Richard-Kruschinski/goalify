import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/gym_models.dart';

const List<String> kSuggestedWorkdays = <String>[
  'Push', 'Pull', 'Leg', 'Arm', 'Upper Body', 'Lower Body',
];

/// ===============================================================
/// Helper Klasse für Set Input Fields (mit Dropset-Support)
/// ===============================================================
class _SetInputField {
  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController durationController;
  final List<_SetInputField> dropsets; // Dropsets dieses Sets

  _SetInputField({
    double weightKg = 0,
    int reps = 0,
    int? durationSeconds,
    List<_SetInputField>? dropsets,
    bool showZeroWeight = false,
  })
      : weightController = TextEditingController(
            text: (weightKg > 0 || (showZeroWeight && weightKg == 0))
                ? weightKg.toStringAsFixed(1)
                : ''),
        repsController = TextEditingController(text: reps > 0 ? reps.toString() : ''),
        durationController = TextEditingController(
            text: (durationSeconds ?? 0) > 0 ? durationSeconds.toString() : ''),
        dropsets = dropsets ?? [];

  void dispose() {
    weightController.dispose();
    repsController.dispose();
    durationController.dispose();
    for (final dropset in dropsets) {
      dropset.dispose();
    }
  }
}

/// ===============================================================
/// Dialog: Day selection + Werte
/// ===============================================================
class LogInputDialog extends StatefulWidget {
  const LogInputDialog({
    required this.workout,
    this.latest,
    this.contextDay,
    this.availableDays = const [],
    this.creationMode = false,
    super.key,
  });

  final Workout workout;
  final WorkoutLog? latest;
  final String? contextDay;
  final List<String> availableDays;
  final bool creationMode;

  @override
  State<LogInputDialog> createState() => _LogInputDialogState();
}

class _LogInputDialogState extends State<LogInputDialog> {
  late final TextEditingController _dayController;
  final List<_SetInputField> _setFields = [];
  String? _chipDay;

  bool get _dayLocked => widget.contextDay != null;
  bool get isDurationWorkout => widget.workout.isDurationBased;
  bool get _allowsZeroWeight =>
      widget.workout.id == 'pull_ups' ||
      widget.workout.id == 'pull_ups_machine' ||
      widget.workout.id == 'dips' ||
      widget.workout.id == 'box_jumps';

  @override
  void initState() {
    super.initState();
    _dayController = TextEditingController();

    if (widget.latest != null && widget.latest!.sets.isNotEmpty) {
      // Populate from latest
      for (final set in widget.latest!.sets) {
        _setFields.add(_createSetInputField(set));
      }
      if (!_dayLocked) _dayController.text = widget.latest!.day;
    } else {
      // Start with one empty set
      _setFields.add(_SetInputField(
        weightKg: 0,
        reps: 0,
        durationSeconds: isDurationWorkout ? 0 : null,
      ));
    }

    if (_dayLocked) {
      _chipDay = widget.contextDay;
    }
  }

  // Konvertiert WorkoutSet zu _SetInputField (mit Dropsets)
  _SetInputField _createSetInputField(WorkoutSet set) {
    final dropsets = set.dropsets
        .map((d) => _createSetInputField(d))
        .toList();
    return _SetInputField(
      weightKg: set.weightKg,
      reps: set.reps,
      durationSeconds: set.durationSeconds,
      dropsets: dropsets,
      showZeroWeight: _allowsZeroWeight,
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    for (final field in _setFields) {
      field.dispose();
    }
    super.dispose();
  }

  void _onChipSelected(String day) {
    setState(() {
      _chipDay = day;
      if (_dayController.text.trim().isNotEmpty) _dayController.clear();
    });
  }

  String _resolveChosenDay() {
    if (_dayLocked) return widget.contextDay!;
    final typed = _dayController.text.trim();
    if (typed.isNotEmpty) return typed;
    if (_chipDay != null) return _chipDay!.trim();
    return '';
  }

  bool _anyNumberFilled() {
    bool checkField(_SetInputField field) {
      if (isDurationWorkout) {
        if (field.durationController.text.trim().isNotEmpty) return true;
      } else {
        if (field.weightController.text.trim().isNotEmpty ||
            field.repsController.text.trim().isNotEmpty) {
          return true;
        }
      }
      // Check dropsets
      return field.dropsets.any((d) => checkField(d));
    }

    return _setFields.any((f) => checkField(f));
  }

  bool _validateForTracking() {
    final day = _resolveChosenDay();

    if (day.isEmpty && !_dayLocked) {
      _showSnackBar(AppLocalizations.of(context).selectWorkoutDayError);
      return false;
    }

    // Validiere alle Sets (inkl. Dropsets)
    bool validateField(int setNum, int dropsetNum, _SetInputField field) {
      if (isDurationWorkout) {
        final duration = int.tryParse(field.durationController.text);
        if (duration == null || duration <= 0) {
          if (dropsetNum > 0) {
            _showSnackBar(AppLocalizations.of(context).setDropsetTimeError(setNum, dropsetNum));
          } else {
            _showSnackBar(AppLocalizations.of(context).setTimeError(setNum));
          }
          return false;
        }
      } else {
        final kg = double.tryParse(field.weightController.text.replaceAll(',', '.'));
        final reps = int.tryParse(field.repsController.text);

        if (kg == null || (_allowsZeroWeight ? kg < 0 : kg <= 0)) {
          final weightRule = _allowsZeroWeight ? '>= 0' : '> 0';
          if (dropsetNum > 0) {
            _showSnackBar(AppLocalizations.of(context).setDropsetWeightError(setNum, dropsetNum, weightRule));
          } else {
            _showSnackBar(AppLocalizations.of(context).setWeightError(setNum, weightRule));
          }
          return false;
        }
        if (reps == null || reps <= 0) {
          if (dropsetNum > 0) {
            _showSnackBar(AppLocalizations.of(context).setDropsetRepsError(setNum, dropsetNum));
          } else {
            _showSnackBar(AppLocalizations.of(context).setRepsError(setNum));
          }
          return false;
        }
      }

      // Validiere Dropsets rekursiv
      for (int i = 0; i < field.dropsets.length; i++) {
        if (!validateField(setNum, i + 1, field.dropsets[i])) {
          return false;
        }
      }

      return true;
    }

    for (int i = 0; i < _setFields.length; i++) {
      if (!validateField(i + 1, 0, _setFields[i])) {
        return false;
      }
    }

    return true;
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSingleSnackBar(SnackBar(content: Text(msg)));
  }

  void _addSet() {
    setState(() {
      if (isDurationWorkout) {
        // Leeres Set ohne vorgefüllte Werte
        _setFields.add(_SetInputField(durationSeconds: 0));
        return;
      }

      // Leeres Set ohne vorgefüllte Werte
      _setFields.add(_SetInputField(weightKg: 0, reps: 0));
    });
  }

  void _removeSet(int index) {
    setState(() {
      _setFields[index].dispose();
      _setFields.removeAt(index);
    });
  }

  // Konvertiert _SetInputField zu WorkoutSet mit Dropsets
  WorkoutSet _convertSetInputFieldToWorkoutSet(_SetInputField field) {
    if (isDurationWorkout) {
      final duration = int.parse(field.durationController.text);
      final dropsets = field.dropsets
          .map((d) => _convertSetInputFieldToWorkoutSet(d))
          .toList();
      return WorkoutSet(
        weightKg: 0,
        reps: 0,
        durationSeconds: duration,
        dropsets: dropsets,
      );
    } else {
      final kg = double.parse(field.weightController.text.replaceAll(',', '.'));
      final reps = int.parse(field.repsController.text);
      final dropsets = field.dropsets
          .map((d) => _convertSetInputFieldToWorkoutSet(d))
          .toList();
      return WorkoutSet(weightKg: kg, reps: reps, dropsets: dropsets);
    }
  }

  void _submit() {
    if (widget.creationMode && !_anyNumberFilled()) {
      final day = _resolveChosenDay();
      if (day.isEmpty && !_dayLocked) {
        _showSnackBar(AppLocalizations.of(context).chooseDayForGroup);
        return;
      }
      Navigator.pop<LogOutcome>(context, LogOutcome(assignDay: day));
      return;
    }

    if (!_validateForTracking()) return;

    final day = _resolveChosenDay();
    final sets = <WorkoutSet>[];

    for (final field in _setFields) {
      sets.add(_convertSetInputFieldToWorkoutSet(field));
    }

    Navigator.pop<LogOutcome>(
      context,
      LogOutcome(
        log: WorkoutLog(
          dateTime: DateTime.now(),
          day: day,
          sets: sets,
        ),
      ),
    );
  }

  Widget _buildDayInput(BuildContext context) {
    if (_dayLocked) return const SizedBox.shrink();

    final hasKnownDays = widget.availableDays.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (hasKnownDays) ...[
          Text(
            AppLocalizations.of(context).workoutDay,
            style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted(context)),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: widget.availableDays
                .map((d) => ChoiceChip(
              label: Text(d),
              selected:
              _chipDay == d && _dayController.text.trim().isEmpty,
              onSelected: (_) => _onChipSelected(d),
            ))
                .toList(),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _dayController,
          decoration: InputDecoration(
            labelText: hasKnownDays
              ? AppLocalizations.of(context).customManualEntry
              : (widget.creationMode
              ? AppLocalizations.of(context).workoutDayOptional
              : AppLocalizations.of(context).workoutDayRequired),
            hintText: hasKnownDays ? AppLocalizations.of(context).dayHintCustom : AppLocalizations.of(context).dayHint,
            filled: true,
            fillColor: AppColors.card(context),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.accent(context), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: kSuggestedWorkdays.map((d) {
              final selected =
                  _chipDay == d && _dayController.text.trim().isEmpty;
              return ChoiceChip(
                label: Text(d),
                selected: selected,
                onSelected: (_) => _onChipSelected(d),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSetFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).sets,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.muted(context)),
        ),
        const SizedBox(height: 8),
        ..._setFields.asMap().entries.map((entry) {
          final index = entry.key;
          final field = entry.value;
          return _buildSetRow(index, field);
        }),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _addSet,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent(context),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add),
          label: Text(AppLocalizations.of(context).addSet),
        ),
      ],
    );
  }

  Widget _buildSetRow(int index, _SetInputField field) {
    final dropsetsCount = field.dropsets.length;

    if (isDurationWorkout) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: field.durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).timeSeconds,
                      hintText: AppLocalizations.of(context).egHint('60'),
                      filled: true,
                      fillColor: AppColors.card(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_setFields.length > 1)
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.accent(context)),
                    onPressed: () => _removeSet(index),
                    tooltip: AppLocalizations.of(context).removeSet,
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
            // Dropsets anzeigen
            if (dropsetsCount > 0) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(dropsetsCount, (dropsetIndex) {
                    final dropset = field.dropsets[dropsetIndex];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward, size: 20, color: AppColors.accent(context)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: dropset.durationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context).dropsetTimeSeconds(dropsetIndex + 1),
                                hintText: AppLocalizations.of(context).egHint('60'),
                                filled: true,
                                fillColor: AppColors.card(context),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close, color: AppColors.accent(context)),
                            onPressed: () {
                              setState(() {
                                dropset.dispose();
                                field.dropsets.removeAt(dropsetIndex);
                              });
                            },
                            tooltip: AppLocalizations.of(context).removeDropset,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
            // Add Dropset Button
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const SizedBox(width: 24),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        field.dropsets.add(_SetInputField(durationSeconds: 0));
                      });
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppLocalizations.of(context).addDropset),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: field.weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).weightKg,
                    hintText: AppLocalizations.of(context).egHint('80'),
                    filled: true,
                    fillColor: AppColors.card(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: field.repsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).reps,
                    hintText: AppLocalizations.of(context).egHint('8'),
                    filled: true,
                    fillColor: AppColors.card(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_setFields.length > 1)
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.accent(context)),
                  onPressed: () => _removeSet(index),
                  tooltip: AppLocalizations.of(context).removeSet,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          // Dropsets anzeigen
          if (dropsetsCount > 0) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(dropsetsCount, (dropsetIndex) {
                  final dropset = field.dropsets[dropsetIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 20, color: AppColors.accent(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: dropset.weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).dropsetWeightKg(dropsetIndex + 1),
                              hintText: AppLocalizations.of(context).egHint('70'),
                              filled: true,
                              fillColor: AppColors.card(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: dropset.repsController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context).reps,
                              hintText: AppLocalizations.of(context).egHint('10'),
                              filled: true,
                              fillColor: AppColors.card(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppColors.accent(context), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.accent(context)),
                          onPressed: () {
                            setState(() {
                              dropset.dispose();
                              field.dropsets.removeAt(dropsetIndex);
                            });
                          },
                          tooltip: AppLocalizations.of(context).removeDropset,
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
          // Add Dropset Button
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(width: 24),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      field.dropsets.add(_SetInputField(weightKg: 0, reps: 0));
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(AppLocalizations.of(context).addDropset),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentSoft(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.fitness_center, color: AppColors.accent(context)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.workout.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildDayInput(context),
            const SizedBox(height: 16),
            _buildSetFields(),
          ],
        ),
      ),
      actions: <Widget>[
        SizedBox(
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent(context),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.creationMode ? 'Save' : AppLocalizations.of(context).update),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}