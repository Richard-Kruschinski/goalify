import 'package:flutter/material.dart';
import '../../data/models/daily_task.dart';
import 'weekday_picker.dart';
import 'modern_date_picker_dialog.dart';

class CreateResult {
  final DailyTask task;
  final String? dateKey; // only for keep=false
  const CreateResult(this.task, this.dateKey);
}

class CreateDailyTaskSheet extends StatefulWidget {
  final String defaultDateKey; // suggested date for one-offs
  const CreateDailyTaskSheet({super.key, required this.defaultDateKey});

  @override
  State<CreateDailyTaskSheet> createState() => _CreateDailyTaskSheetState();
}

class _CreateDailyTaskSheetState extends State<CreateDailyTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _category;
  int _points = 1;
  bool _keep = false;
  bool _isLimited = false;
  int _targetCount = 2;
  int? _limitedCycleIntervalDays; // null = permanent; >0 = recurring cycle

  // Repeat pattern fields
  TaskRepeatPattern _repeatPattern = TaskRepeatPattern.daily;
  int _customDays = 1;
  Set<int> _weeklyDays = <int>{};

  late DateTime _scheduledDate;

  // Max targetCount when specific weekdays are chosen: weekdays × weeks-in-cycle
  int get _weekdayMaxCount {
    final weeksInCycle = ((_limitedCycleIntervalDays ?? 7) / 7).floor().clamp(1, 999);
    return _weeklyDays.length * weeksInCycle;
  }

  static const _suggestedCategories = [
    'Gym',
    'Work',
    'Study',
    'Leisure',
    'Skill',
    'Chores',
    'Creatine',
  ];

  @override
  void initState() {
    super.initState();
    // parse default dateKey
    final parts = widget.defaultDateKey.split('-').map(int.parse).toList();
    _scheduledDate = DateTime(parts[0], parts[1], parts[2]);
    _weeklyDays = <int>{_scheduledDate.weekday};
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String _dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  bool _isPastDate(DateTime dt) => _dateOnly(dt).isBefore(_dateOnly(DateTime.now()));

  Future<int?> _showCustomDaysDialog() async {
    final controller = TextEditingController(text: _customDays.toString());
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 40,
                  color: Color(0xFFE53935),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              const Text(
                'Custom Repeat Interval',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              const Text(
                'How many days between each repeat?',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6F7789),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Input Field
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  hintText: '7',
                  hintStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE53935).withOpacity(0.3),
                  ),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(right: 16, top: 12),
                    child: Text(
                      'days',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6F7789),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                ),
              ),
              const SizedBox(height: 28),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6F7789),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value > 0) {
                          Navigator.pop(context, value);
                        } else {
                          // Show error feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid number (1 or greater)'),
                              backgroundColor: Color(0xFFE53935),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  

  List<Widget> _buildLimitedCycleChips() {
    const fixedOptions = <(int?, String)>[
      (null, 'Never'),
      (7, 'Weekly'),
      (14, '2 Weeks'),
      (30, 'Monthly'),
    ];
    final fixedValues = fixedOptions.map((o) => o.$1).toList();
    final isCustom = _limitedCycleIntervalDays != null &&
        !fixedValues.contains(_limitedCycleIntervalDays);

    final chips = <Widget>[
      ...fixedOptions.map((opt) {
        final selected = _limitedCycleIntervalDays == opt.$1;
        return GestureDetector(
          onTap: () => setState(() {
            _limitedCycleIntervalDays = opt.$1;
            if (opt.$1 != null && _targetCount > opt.$1!) _targetCount = opt.$1!;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE53935) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                width: 1.5,
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF6F7789),
              ),
            ),
          ),
        );
      }),
      // Custom chip
      GestureDetector(
        onTap: () async {
          final days = await _showCustomDaysDialog();
          if (days != null && days > 0) {
            setState(() {
              _limitedCycleIntervalDays = days;
              if (_targetCount > days) _targetCount = days;
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isCustom ? const Color(0xFFE53935) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustom ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: Text(
            isCustom ? 'Every ${_limitedCycleIntervalDays}d' : 'Custom days...',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCustom ? Colors.white : const Color(0xFF6F7789),
            ),
          ),
        ),
      ),
    ];
    return chips;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (!_keep && !_isLimited && _isPastDate(_scheduledDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Cannot create tasks for past dates.'),
        ),
      );
      return;
    }

    final effectiveKeep = _keep || _isLimited;
    final t = DailyTask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: (_category?.trim().isEmpty ?? true) ? null : _category!.trim(),
      points: (effectiveKeep && !_isLimited) || (_isLimited && _limitedCycleIntervalDays != null) ? _points : 0,
      keep: effectiveKeep,
      repeatPattern: effectiveKeep && !_isLimited ? _repeatPattern : TaskRepeatPattern.daily,
      customDays: effectiveKeep && !_isLimited ? _customDays : 1,
      repeatStartKey: effectiveKeep ? widget.defaultDateKey : null,
      weeklyDays: _isLimited && _limitedCycleIntervalDays != null
        ? _weeklyDays.toList()
        : (effectiveKeep && !_isLimited
          ? ((_repeatPattern == TaskRepeatPattern.weekly_days ||
              _repeatPattern == TaskRepeatPattern.biweekly)
            ? (_weeklyDays.isEmpty ? <int>{_scheduledDate.weekday}.toList() : _weeklyDays.toList())
            : const <int>[])
          : const <int>[]),
      targetCount: _isLimited ? _targetCount : null,
      completedCount: 0,
      limitedCycleIntervalDays: _isLimited ? _limitedCycleIntervalDays : null,
      limitedCycleStartKey: _isLimited ? widget.defaultDateKey : null,
    );

    Navigator.pop(context, CreateResult(t, effectiveKeep ? null : _dateKey(_scheduledDate)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_task, color: Color(0xFFE53935), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'New Task',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1D1F),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Color(0xFF6F7789)),
                  )
                ],
              ),
              const SizedBox(height: 24),
              // Task Name
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Task Name',
                  hintText: 'e.g. Drink 2L water',
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
                  prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF6F7789)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              // Description
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
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
                  prefixIcon: const Icon(Icons.notes, color: Color(0xFF6F7789)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              // Category
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6F7789),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedCategories.map((c) {
                  final selected = _category == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category = selected ? null : c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFE53935) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : const Color(0xFF6F7789),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              // Task Type Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _keep = false; _isLimited = false; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_keep && !_isLimited ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 18,
                                color: !_keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Daily',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: !_keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _keep = true; _isLimited = false; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _keep && !_isLimited ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.repeat,
                                size: 18,
                                color: _keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Recurring',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _keep && !_isLimited ? Colors.white : const Color(0xFF6F7789),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() { _keep = false; _isLimited = true; _weeklyDays = {}; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLimited ? const Color(0xFFE53935) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag,
                                size: 18,
                                color: _isLimited ? Colors.white : const Color(0xFF6F7789),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'X-Times',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isLimited ? Colors.white : const Color(0xFF6F7789),
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
              if (_isLimited) ...[
                const SizedBox(height: 16),
                // Target count stepper
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, color: Color(0xFFE53935), size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'How many days?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1D1F),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _targetCount > 1
                            ? () => setState(() => _targetCount--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFFE53935),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_targetCount',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE53935),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: (_weeklyDays.isNotEmpty && _weeklyDays.length < 7
                            ? _targetCount >= _weekdayMaxCount
                            : _limitedCycleIntervalDays != null && _targetCount >= _limitedCycleIntervalDays!)
                            ? null
                            : () => setState(() => _targetCount++),
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
                if (_limitedCycleIntervalDays != null && _targetCount == _limitedCycleIntervalDays &&
                    !(_weeklyDays.isNotEmpty && _weeklyDays.length < 7))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 14, color: Color(0xFFFF9800)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Same as cycle length — equivalent to a daily recurring task.',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFFF9800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // Cycle / reset options
                const Text(
                  'Repeats after completion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7789),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildLimitedCycleChips(),
                ),
                if (_limitedCycleIntervalDays != null) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Choose weekdays',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6F7789),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Optional – leave empty to show every day',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(height: 8),
                  WeekdayPicker(
                    selectedDays: _weeklyDays,
                    onChanged: (days) => setState(() {
                      _weeklyDays = days;
                      if (days.isNotEmpty && days.length < 7) {
                        final weeksInCycle = ((_limitedCycleIntervalDays ?? 7) / 7).floor().clamp(1, 999);
                        final newMax = days.length * weeksInCycle;
                        if (_targetCount > newMax) _targetCount = newMax;
                      }
                    }),
                  ),
                ],
              ],
              if ((_keep && !_isLimited) || (_isLimited && _limitedCycleIntervalDays != null)) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Color(0xFFFF9800)),
                          const SizedBox(width: 8),
                          const Text(
                            'Points',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1D1F),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$_points',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF9800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: 1.0 * _points,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        activeColor: const Color(0xFFE53935),
                        inactiveColor: const Color(0xFFFFEBEE),
                        onChanged: (v) => setState(() => _points = v.round()),
                      ),
                    ],
                  ),
                ),
              ],
              // Repeat pattern selector (only for recurring tasks)
              if (_keep) ...[
                const SizedBox(height: 20),
                const Text(
                  'Repeat Pattern',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6F7789),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: TaskRepeatPattern.values.map((pattern) {
                    final selected = _repeatPattern == pattern;
                    return GestureDetector(
                      onTap: () async {
                        if (pattern == TaskRepeatPattern.weekly_days ||
                            pattern == TaskRepeatPattern.biweekly) {
                          setState(() {
                            _repeatPattern = pattern;
                            if (_weeklyDays.isEmpty) {
                              _weeklyDays = <int>{_scheduledDate.weekday};
                            }
                          });
                          return;
                        }
                        if (pattern == TaskRepeatPattern.custom) {
                          final customDays = await _showCustomDaysDialog();
                          if (customDays != null && customDays > 0) {
                            setState(() {
                              _repeatPattern = pattern;
                              _customDays = customDays;
                            });
                          }
                        } else {
                          setState(() => _repeatPattern = pattern);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFE53935) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFFE53935) : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          pattern == TaskRepeatPattern.custom && _repeatPattern == TaskRepeatPattern.custom
                              ? 'Every $_customDays days'
                              : pattern.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : const Color(0xFF6F7789),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_repeatPattern == TaskRepeatPattern.weekly_days ||
                  _repeatPattern == TaskRepeatPattern.biweekly) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Choose weekdays',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6F7789),
                    ),
                  ),
                  const SizedBox(height: 8),
                  WeekdayPicker(
                    selectedDays: _weeklyDays,
                    onChanged: (days) => setState(() => _weeklyDays = days),
                  ),
                ],
              ],
              if (!_keep && !_isLimited) ...[
                const SizedBox(height: 16),
                // Date picker only for one-offs
                GestureDetector(
                  onTap: () async {
                    await showDialog<void>(
                      context: context,
                      builder: (dialogContext) => ModernDatePickerDialog(
                        initialDate: _scheduledDate,
                        onDateSelected: (picked) {
                          if (_isPastDate(picked)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                duration: Duration(seconds: 2),
                                content: Text('Cannot create tasks for past dates.'),
                              ),
                            );
                            return;
                          }
                          setState(() => _scheduledDate = picked);
                          Navigator.of(dialogContext).pop();
                        },
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFE53935)),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Scheduled Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6F7789),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1D1F),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Create Button
              SizedBox(
                width: double.infinity,
                height: 52,
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
                  child: const Text(
                    'Create Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// Edit bottom sheet (keep flag not moved between models here)
/// ===============================================================
