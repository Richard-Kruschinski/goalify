import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/gym_models.dart';

/// Whether [workout] matches a search [query] by name or by one of its
/// muscles, ignoring case. An empty query matches everything.
bool workoutMatchesQuery(Workout workout, String query) {
  final lower = query.trim().toLowerCase();
  if (lower.isEmpty) return true;
  if (workout.name.toLowerCase().contains(lower)) return true;
  return workout.muscles.any((m) => m.toLowerCase().contains(lower));
}

/// Search field for exercise lists (name or muscle), with a clear button
/// once something is typed.
class WorkoutSearchField extends StatefulWidget {
  const WorkoutSearchField({super.key, required this.onChanged, this.initialQuery = ''});

  final ValueChanged<String> onChanged;
  final String initialQuery;

  @override
  State<WorkoutSearchField> createState() => _WorkoutSearchFieldState();
}

class _WorkoutSearchFieldState extends State<WorkoutSearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).searchWorkoutHint,
        filled: true,
        fillColor: AppColors.card(context),
        prefixIcon: Icon(Icons.search, color: AppColors.muted(context)),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (_, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(Icons.close, color: AppColors.muted(context)),
                  onPressed: _clear,
                ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
      onChanged: widget.onChanged,
    );
  }
}
