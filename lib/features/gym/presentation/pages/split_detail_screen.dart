import 'package:flutter/material.dart';

class SplitDetailScreen extends StatefulWidget {
  final String splitName;
  final List<String> days;
  final int Function(String day) dayExerciseCount;
  final Widget Function(String day) dayIconBuilder;
  final void Function(String day) onOpenDay;
  final void Function(List<String> newOrder) onReorderDays;

  const SplitDetailScreen({
    super.key,
    required this.splitName,
    required this.days,
    required this.dayExerciseCount,
    required this.dayIconBuilder,
    required this.onOpenDay,
    required this.onReorderDays,
  });

  @override
  State<SplitDetailScreen> createState() => _SplitDetailScreenState();
}

class _SplitDetailScreenState extends State<SplitDetailScreen> {
  late List<String> _days;

  @override
  void initState() {
    super.initState();
    _days = List<String>.from(widget.days);
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final moved = _days.removeAt(oldIndex);
      _days.insert(newIndex, moved);
    });
    widget.onReorderDays(List<String>.from(_days, growable: false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    child: const Icon(Icons.arrow_back, color: Color(0xFF6F7789)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.splitName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1D1F),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _days.isEmpty
                  ? const Center(
                      child: Text(
                        'No workout days in this split',
                        style: TextStyle(color: Color(0xFF6F7789)),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _days.length,
                      onReorder: _onReorder,
                      buildDefaultDragHandles: false,
                      itemBuilder: (_, i) {
                        final day = _days[i];
                        final count = widget.dayExerciseCount(day);
                        return Container(
                          key: ValueKey('split_day_${widget.splitName}_$day'),
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => widget.onOpenDay(day),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: i,
                                      child: const Icon(
                                        Icons.drag_indicator,
                                        color: Color(0xFFD1D5DB),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: widget.dayIconBuilder(day),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            day,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF1A1D1F),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$count exercise${count == 1 ? '' : 's'}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF6F7789),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ],
                                ),
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
    );
  }
}
