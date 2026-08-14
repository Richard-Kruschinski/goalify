import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/i18n/task_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/day_cycle.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../data/models/daily_task.dart';
import '../../../../core/widgets/weekday_picker.dart';

class TaskFormData {
  final String title;
  final String? description;
  final String? category;
  final int points;
  final bool keep;
  final TaskRepeatPattern repeatPattern;
  final int customDays;
  final List<int> weeklyDays;
  final int? targetCount;
  final int? limitedCycleIntervalDays;

  const TaskFormData({
    required this.title,
    this.description,
    this.category,
    required this.points,
    required this.keep,
    required this.repeatPattern,
    required this.customDays,
    required this.weeklyDays,
    this.targetCount,
    this.limitedCycleIntervalDays,
  });
}

class EditDailyTaskSheet extends StatefulWidget {
  final DailyTask task;
  const EditDailyTaskSheet({super.key, required this.task});

  @override
  State<EditDailyTaskSheet> createState() => _EditDailyTaskSheetState();
}

class _EditDailyTaskSheetState extends State<EditDailyTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  String? _category;
  int _points = 1;
  bool _keep = false;

  // Repeat pattern fields
  late TaskRepeatPattern _repeatPattern;
  late int _customDays;
  late Set<int> _weeklyDays;

  // Limited task fields
  int _targetCount = 2;
  int? _limitedCycleIntervalDays;

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
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description ?? '');
    _category = widget.task.category;
    _points = widget.task.points > 0 ? widget.task.points : 1;
    _keep = widget.task.keep;
    _repeatPattern = widget.task.repeatPattern;
    _customDays = widget.task.customDays;
    _weeklyDays = widget.task.weeklyDays.isNotEmpty
      ? widget.task.weeklyDays.toSet()
      : (widget.task.isLimited ? <int>{} : <int>{DayCycle.today().weekday});
    _targetCount = widget.task.targetCount ?? 2;
    _limitedCycleIntervalDays = widget.task.limitedCycleIntervalDays;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<int?> _showCustomDaysDialog() async {
    final controller = TextEditingController(text: _customDays.toString());
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: AppColors.card(context),
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
                  color: AppColors.accentSoft(context),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule,
                  size: 40,
                  color: AppColors.accent(context),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                AppLocalizations.of(context).customRepeatInterval,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                AppLocalizations.of(context).howManyDaysBetween,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.muted(context),
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
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent(context),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bg(context),
                  hintText: '7',
                  hintStyle: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent(context).withOpacity(0.3),
                  ),
                  suffixIcon: Padding(
                    padding: EdgeInsets.only(right: 16, top: 12),
                    child: Text(
                      AppLocalizations.of(context).daysUnit,
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.muted(context),
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
                    borderSide: BorderSide(color: AppColors.accent(context), width: 2),
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
                        side: BorderSide(color: AppColors.border(context), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        AppLocalizations.of(context).cancel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted(context),
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
                          ScaffoldMessenger.of(context).showSingleSnackBar(
                            SnackBar(
                              content: Text(AppLocalizations.of(context).invalidNumber),
                              backgroundColor: AppColors.accent(context),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent(context),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        AppLocalizations.of(context).confirm,
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final isLimited = widget.task.isLimited;
    final weeklyDays = isLimited && _limitedCycleIntervalDays != null
        ? _weeklyDays.toList()
        : (!isLimited && (_repeatPattern == TaskRepeatPattern.weekly_days ||
            _repeatPattern == TaskRepeatPattern.biweekly))
          ? (_weeklyDays.isEmpty ? <int>{DayCycle.today().weekday}.toList() : _weeklyDays.toList())
          : const <int>[];
    Navigator.pop(
      context,
      TaskFormData(
        title: _titleCtrl.text.trim(),
        description:
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        category: (_category?.trim().isEmpty ?? true) ? null : _category!.trim(),
        points: (_keep && !isLimited) || (isLimited && _limitedCycleIntervalDays != null) ? _points : 0,
        keep: _keep,
        repeatPattern: isLimited ? TaskRepeatPattern.daily : _repeatPattern,
        customDays: isLimited ? 1 : _customDays,
        weeklyDays: weeklyDays,
        targetCount: isLimited ? _targetCount : null,
        limitedCycleIntervalDays: isLimited ? _limitedCycleIntervalDays : null,
      ),
    );
  }

  List<Widget> _buildLimitedCycleChips() {
    final l10n = AppLocalizations.of(context);
    final fixedOptions = <(int?, String)>[
      (null, l10n.never),
      (7, l10n.repeatWeekly),
      (14, l10n.repeatBiweekly),
      (30, l10n.repeatMonthly),
    ];
    final fixedValues = fixedOptions.map((o) => o.$1).toList();
    final isCustom = _limitedCycleIntervalDays != null &&
        !fixedValues.contains(_limitedCycleIntervalDays);

    return <Widget>[
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
              color: selected ? AppColors.accent(context) : AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? AppColors.accent(context) : AppColors.border(context),
                width: 1.5,
              ),
            ),
            child: Text(
              opt.$2,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : AppColors.muted(context),
              ),
            ),
          ),
        );
      }),
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
            color: isCustom ? AppColors.accent(context) : AppColors.card(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCustom ? AppColors.accent(context) : AppColors.border(context),
              width: 1.5,
            ),
          ),
          child: Text(
            isCustom ? 'Every ${_limitedCycleIntervalDays}d' : AppLocalizations.of(context).customDaysOption,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isCustom ? Colors.white : AppColors.muted(context),
            ),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg(context),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentSoft(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit, color: AppColors.accent(context), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).editTaskTitle,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink(context),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  )
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).taskName,
                  filled: true,
                  fillColor: AppColors.card(context),
                  prefixIcon: Icon(Icons.check_circle_outline, color: AppColors.muted(context)),
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
                validator: (v) => (v == null || v.trim().isEmpty) ? AppLocalizations.of(context).required : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).descriptionOptional,
                  filled: true,
                  fillColor: AppColors.card(context),
                  prefixIcon: Icon(Icons.notes, color: AppColors.muted(context)),
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
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context).category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted(context),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _category,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).categoryOptional,
                  filled: true,
                  fillColor: AppColors.card(context),
                  prefixIcon: Icon(Icons.category_outlined, color: AppColors.muted(context)),
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
                onChanged: (v) => _category = v,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestedCategories.map((c) {
                  final selected = _category == c;
                  return GestureDetector(
                    onTap: () => setState(() => _category = selected ? null : c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent(context) : AppColors.card(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.accent(context) : AppColors.border(context),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        localizedCategory(AppLocalizations.of(context), c),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : AppColors.muted(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (widget.task.isLimited) ...[
                // Limited task: show progress and target count editor
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.flag, size: 20, color: AppColors.accent(context)),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).targetDays,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink(context),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _targetCount > 1
                                ? () => setState(() => _targetCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.accent(context),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft(context),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_targetCount',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent(context),
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
                            color: AppColors.accent(context),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          AppLocalizations.of(context).alreadyDoneCycle(
                              '${widget.task.completedCount}', '${widget.task.targetCount}'),
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted(context),
                          ),
                        ),
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
                            AppLocalizations.of(context).sameAsCycleHint,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFFF9800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).repeatsAfterCompletion,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted(context),
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
                  Text(
                    AppLocalizations.of(context).chooseWeekdays,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).weekdaysOptionalHint,
                    style: TextStyle(fontSize: 12, color: AppColors.faint(context)),
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
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 20, color: Color(0xFFFF9800)),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).points,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink(context),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (AppColors.isDark(context) ? const Color(0xFF332612) : const Color(0xFFFFF3E0)),
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
                          activeColor: AppColors.accent(context),
                          inactiveColor: AppColors.accentSoft(context),
                          onChanged: (v) => setState(() => _points = v.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
              if (_keep) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card(context),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, size: 20, color: Color(0xFFFF9800)),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).points,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink(context),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (AppColors.isDark(context) ? const Color(0xFF332612) : const Color(0xFFFFF3E0)),
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
                        activeColor: AppColors.accent(context),
                        inactiveColor: AppColors.accentSoft(context),
                        onChanged: (v) => setState(() => _points = v.round()),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(AppLocalizations.of(context).keepForFuture),
                  subtitle: Text(AppLocalizations.of(context).keepForFutureSubtitle),
                  activeColor: AppColors.accent(context),
                  value: _keep,
                  onChanged: (v) => setState(() => _keep = v),
                ),
              ),
              // Repeat pattern selector (only for recurring tasks)
              if (_keep) ...[
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).repeatPattern,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted(context),
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
                              _weeklyDays = <int>{DayCycle.today().weekday};
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
                          color: selected ? AppColors.accent(context) : AppColors.card(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? AppColors.accent(context) : AppColors.border(context),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          pattern == TaskRepeatPattern.custom && _repeatPattern == TaskRepeatPattern.custom
                              ? 'Every $_customDays days'
                              : localizedPatternLabel(AppLocalizations.of(context), pattern, _customDays),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: selected ? Colors.white : AppColors.muted(context),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_repeatPattern == TaskRepeatPattern.weekly_days ||
                  _repeatPattern == TaskRepeatPattern.biweekly) ...[
                  const SizedBox(height: 14),
                  Text(
                    AppLocalizations.of(context).chooseWeekdays,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  WeekdayPicker(
                    selectedDays: _weeklyDays,
                    onChanged: (days) => setState(() => _weeklyDays = days),
                  ),
                ],
              ],
              ], // end else (non-limited) block
              const SizedBox(height: 20),
              Row(
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
                      child: Text(
                        AppLocalizations.of(context).save,
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
}