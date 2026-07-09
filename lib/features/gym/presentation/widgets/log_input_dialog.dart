import 'package:flutter/material.dart';
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
      _showSnackBar('Please select or enter a workout day.');
      return false;
    }

    // Validiere alle Sets (inkl. Dropsets)
    bool validateField(int setNum, int dropsetNum, _SetInputField field) {
      if (isDurationWorkout) {
        final duration = int.tryParse(field.durationController.text);
        if (duration == null || duration <= 0) {
          if (dropsetNum > 0) {
            _showSnackBar('Set $setNum Dropset $dropsetNum: Enter a valid time in seconds (> 0).');
          } else {
            _showSnackBar('Set $setNum: Enter a valid time in seconds (> 0).');
          }
          return false;
        }
      } else {
        final kg = double.tryParse(field.weightController.text.replaceAll(',', '.'));
        final reps = int.tryParse(field.repsController.text);

        if (kg == null || (_allowsZeroWeight ? kg < 0 : kg <= 0)) {
          final weightRule = _allowsZeroWeight ? '>= 0' : '> 0';
          if (dropsetNum > 0) {
            _showSnackBar('Set $setNum Dropset $dropsetNum: Enter a valid weight ($weightRule).');
          } else {
            _showSnackBar('Set $setNum: Enter a valid weight ($weightRule).');
          }
          return false;
        }
        if (reps == null || reps <= 0) {
          if (dropsetNum > 0) {
            _showSnackBar('Set $setNum Dropset $dropsetNum: Enter valid reps (> 0).');
          } else {
            _showSnackBar('Set $setNum: Enter valid reps (> 0).');
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
        _showSnackBar('Choose a workout day to assign this exercise to a group.');
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
          const Text(
            'Workout day',
            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6F7789)),
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
              ? 'Custom (manual entry)'
              : (widget.creationMode
              ? 'Workout day (optional)'
              : 'Workout day (required)'),
            hintText: hasKnownDays ? 'e.g. Push3' : 'e.g. Push / Pull / Leg …',
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
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
        const Text(
          'Sets',
          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6F7789)),
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
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add set'),
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
                      labelText: 'Time (seconds)',
                      hintText: 'e.g. 60',
                      filled: true,
                      fillColor: Colors.white,
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
                        borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_setFields.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                    onPressed: () => _removeSet(index),
                    tooltip: 'Remove set',
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
                          const Icon(Icons.arrow_downward, size: 20, color: Color(0xFFE53935)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: dropset.durationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Dropset ${dropsetIndex + 1} Time (seconds)',
                                hintText: 'e.g. 60',
                                filled: true,
                                fillColor: Colors.white,
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
                                  borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                            onPressed: () {
                              setState(() {
                                dropset.dispose();
                                field.dropsets.removeAt(dropsetIndex);
                              });
                            },
                            tooltip: 'Remove dropset',
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
                    label: const Text('Add dropset'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFE53935),
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
                    labelText: 'Weight (kg)',
                    hintText: 'e.g. 80',
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
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
                    labelText: 'Reps',
                    hintText: 'e.g. 8',
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_setFields.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                  onPressed: () => _removeSet(index),
                  tooltip: 'Remove set',
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
                        const Icon(Icons.arrow_downward, size: 20, color: Color(0xFFE53935)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: dropset.weightController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Dropset ${dropsetIndex + 1} Weight (kg)',
                              hintText: 'e.g. 70',
                              filled: true,
                              fillColor: Colors.white,
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
                                borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
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
                              labelText: 'Reps',
                              hintText: 'e.g. 10',
                              filled: true,
                              fillColor: Colors.white,
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
                                borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFFE53935)),
                          onPressed: () {
                            setState(() {
                              dropset.dispose();
                              field.dropsets.removeAt(dropsetIndex);
                            });
                          },
                          tooltip: 'Remove dropset',
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
                  label: const Text('Add dropset'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
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
      backgroundColor: const Color(0xFFF5F7FA),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.fitness_center, color: Color(0xFFE53935)),
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
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(widget.creationMode ? 'Save' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

