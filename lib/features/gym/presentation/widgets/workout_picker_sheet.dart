import 'package:flutter/material.dart';
import '../../data/models/gym_models.dart';

/// ===============================================================
/// Bottom Sheet: Suche + Liste + Beschreibung
/// ===============================================================
class WorkoutPickerSheet extends StatefulWidget {
  const WorkoutPickerSheet({
    super.key,
    required this.workouts,
    required this.latestFor,
    required this.onAddOrUpdate,
  });

  final List<Workout> workouts;
  final WorkoutLog? Function(String id) latestFor;
  final Future<void> Function(Workout workout) onAddOrUpdate;

  @override
  State<WorkoutPickerSheet> createState() => _WorkoutPickerSheetState();
}

class _WorkoutPickerSheetState extends State<WorkoutPickerSheet> {
  String _query = '';

  List<Workout> _applyFilter() {
    final String lower = _query.toLowerCase();
    final List<Workout> filtered = <Workout>[];
    for (final Workout workout in widget.workouts) {
      final byName = workout.name.toLowerCase().contains(lower);
      final byMuscle = workout.muscles.any((m) => m.toLowerCase().contains(lower));
      if (byName || byMuscle) {
        filtered.add(workout);
      }
    }
    return filtered;
  }

  Widget _buildGrabber() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search workout... (name or muscle)',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF6F7789)),
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
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
          ),
        ),
        onChanged: (String value) => setState(() => _query = value),
      ),
    );
  }

  Widget _buildWorkoutCard(Workout workout) {
    final WorkoutLog? latest = widget.latestFor(workout.id);
    final String subtitle = latestUpdateText(workout, latest);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: workout.iconPath != null
              ? Padding( // Exercise Icon as Image
                  padding: const EdgeInsets.all(5.0),
                  child: Image.asset(
                    workout.iconPath!,
                    fit: BoxFit.contain,
                  ),
                )
              : Icon(workout.icon ?? Icons.fitness_center, color: const Color(0xFFE53935)),
        ),
        title: Text(
          workout.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1D1F),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: Color(0xFF6F7789)),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              workout.description,
              style: const TextStyle(color: Color(0xFF6F7789)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onAddOrUpdate(workout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(latest == null ? 'Add' : 'Update'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Workout> filtered = _applyFilter();

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (BuildContext context, ScrollController controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: <Widget>[
                const SizedBox(height: 8),
                _buildGrabber(),
                const SizedBox(height: 12),
                _buildSearchField(),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: filtered.length,
                    itemBuilder: (_, int index) =>
                        _buildWorkoutCard(filtered[index]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

