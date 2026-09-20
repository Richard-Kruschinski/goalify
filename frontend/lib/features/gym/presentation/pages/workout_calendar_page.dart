import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/i18n/task_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/day_cycle.dart';
import 'package:flutter/services.dart';

/// ===============================================================
/// KOMPAKTER MONATSKALENDER – lokalisiert (z. B. „Oktober 2025“)
/// ===============================================================
class WorkoutCalendarPage extends StatefulWidget {
  final Map<String, Set<String>> calendarByDate;
  final Map<String, int> dayColors;
  final bool Function(DateTime date) isCreatineTaken;
  final Future<void> Function(DateTime date, bool value) onToggleCreatine;
  const WorkoutCalendarPage({
    super.key,
    required this.calendarByDate,
    required this.dayColors,
    required this.isCreatineTaken,
    required this.onToggleCreatine,
  });

  @override
  State<WorkoutCalendarPage> createState() => _WorkoutCalendarPageState();
}

class _WorkoutCalendarPageState extends State<WorkoutCalendarPage> {
  late DateTime _currentMonth;
  double? _dragStartX;
  bool _dragHandled = false;
  bool _showChips = true; // toggle between chips and count badge

  @override
  void initState() {
    super.initState();
    final now = DayCycle.today();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  String _dateKey(DateTime dt) => DayCycle.dateKey(dt);

  int _daysInMonth(DateTime month) {
    final next = DateTime(month.year, month.month + 1, 1);
    return next.subtract(const Duration(days: 1)).day;
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  Future<void> _jumpToMonthYear() async {
    final monthController = TextEditingController(text: _currentMonth.month.toString());
    final yearController = TextEditingController(text: _currentMonth.year.toString());

    final targetMonth = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            void submit() {
              final month = int.tryParse(monthController.text.trim());
              final year = int.tryParse(yearController.text.trim());

              if (month == null || month < 1 || month > 12) {
                setDialogState(() {
                  errorText = AppLocalizations.of(context).invalidMonth;
                });
                return;
              }

              if (year == null || year < 1) {
                setDialogState(() {
                  errorText = AppLocalizations.of(context).invalidYear;
                });
                return;
              }

                Navigator.of(dialogContext).pop(DateTime(year, month, 1));
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
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
                            Icons.calendar_month,
                            color: AppColors.accent(context),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).goToMonth,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: monthController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).rangeMonth,
                        hintText: '1 - 12',
                        filled: true,
                        fillColor: AppColors.chip(context),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.accent(context), width: 1.2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: yearController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                      ],
                      onSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).rangeYear,
                        hintText: AppLocalizations.of(context).yearHint,
                        filled: true,
                        fillColor: AppColors.chip(context),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.border(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.accent(context), width: 1.2),
                        ),
                      ),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        errorText!,
                        style: const TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                          ),
                          child: Text(
                            AppLocalizations.of(context).cancel,
                            style: TextStyle(color: AppColors.muted(context)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent(context),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context).go,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    monthController.dispose();
    yearController.dispose();

    if (!mounted || targetMonth == null) return;

    setState(() {
      _currentMonth = targetMonth;
    });
  }

  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _dragHandled = false;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    if (_dragHandled || _dragStartX == null) return;
    final delta = details.globalPosition.dx - _dragStartX!;
    const threshold = 60; // simple swipe threshold
    if (delta.abs() > threshold) {
      if (delta > 0) {
        _prevMonth();
      } else {
        _nextMonth();
      }
      _dragHandled = true; // avoid multiple triggers in one swipe
    }
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _dragStartX = null;
    _dragHandled = false;
  }

  Widget _buildDayContent(List<String> names) {
    if (names.isEmpty) return const SizedBox.shrink();

    if (_showChips) {
      // Show abbreviated chips
      const maxVisible = 4;
      final visible = names.take(maxVisible).toList();
      final overflow = names.length - visible.length;

      Color colorFor(String day) {
        final stored = widget.dayColors[day];
        if (stored != null) return Color(stored);
        final palette = Colors.primaries;
        final base = palette[day.hashCode.abs() % palette.length];
        return base.shade400;
      }

      String shortLabel(String n) {
        if (n.trim().isEmpty) return n;
        final parts = n.split(RegExp(r"\s+"));
        if (parts.length > 1) {
          final ac = parts.map((p) => p.isEmpty ? '' : p[0]).join();
          return ac.substring(0, ac.length.clamp(0, 3));
        }
        return n.length <= 3 ? n : n.substring(0, 3);
      }

      final List<Widget> chips = visible
          .map((n) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorFor(n),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  shortLabel(n),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ))
          .toList();

      if (overflow > 0) {
        chips.add(Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.border(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('+$overflow',
              style: TextStyle(
                color: AppColors.muted(context),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              )),
        ));
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: chips
              .map((chip) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: chip,
                  ))
              .toList(),
        ),
      );
    } else {
      // Show count badge
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.accent(context),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '${names.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
  }

  void _showFullList(BuildContext context, DateTime date, List<String> names) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final dateLabel = MaterialLocalizations.of(context).formatFullDate(date);
        bool tookCreatine = widget.isCreatineTaken(date);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.calendar_today, color: AppColors.accent(context), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).workoutsLabel,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                dateLabel,
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
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(AppLocalizations.of(context).creatineTaken),
                      subtitle: Text(AppLocalizations.of(context).showRedDot),
                      activeThumbColor: AppColors.accent(context),
                      value: tookCreatine,
                      onChanged: (v) async {
                        setSheetState(() => tookCreatine = v);
                        await widget.onToggleCreatine(date, v);
                        if (mounted) setState(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    if (names.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          AppLocalizations.of(context).noWorkoutsMarked,
                          style: TextStyle(
                            color: AppColors.muted(context),
                            fontSize: 13,
                          ),
                        ),
                      )
                    else
                      ...names
                          .map((n) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.card(context),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x0A000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: (widget.dayColors[n] != null)
                                          ? Color(widget.dayColors[n]!)
                                          : _fallbackColor(n),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.fitness_center, color: Colors.white, size: 20),
                                  ),
                                  title: Text(
                                    n,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ))
                          ,
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _fallbackColor(String day) {
    final palette = Colors.primaries;
    final base = palette[day.hashCode.abs() % palette.length];
    return base.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday; // 1..7
    final leadingEmpty = (firstWeekday + 6) % 7; // Start bei Montag
    final days = _daysInMonth(_currentMonth);
    final cells = leadingEmpty + days;
    final rows = (cells / 7).ceil();

    final localizations = MaterialLocalizations.of(context);
    final titleLabel = localizations.formatMonthYear(_currentMonth);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _handleHorizontalDragStart,
          onHorizontalDragUpdate: _handleHorizontalDragUpdate,
          onHorizontalDragEnd: _handleHorizontalDragEnd,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Modern header
                  Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      // Back button
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.card(context),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 10,
                                offset: Offset(0, 3),
                              )
                            ],
                          ),
                          child: Icon(Icons.arrow_back, color: AppColors.inkSoft(context)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: _jumpToMonthYear,
                              borderRadius: BorderRadius.circular(8),
                              child: Text(
                                titleLabel,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(context).swipeHint,
                              style: TextStyle(
                                color: AppColors.muted(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // View toggle
                      _ToggleButton(
                        icon: _showChips ? Icons.grid_view : Icons.filter_list,
                        onTap: () => setState(() => _showChips = !_showChips),
                      ),
                      const SizedBox(width: 8),
                      // Prev / Next
                      _MonthIconButton(icon: Icons.chevron_left, onTap: _prevMonth),
                      const SizedBox(width: 8),
                      _MonthIconButton(icon: Icons.chevron_right, onTap: _nextMonth, isPrimary: true),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (int d = 1; d <= 7; d++)
                      _Dow(localizedWeekdayShort(
                          d, Localizations.localeOf(context).toString())),
                  ],
                ),
                const Divider(height: 0),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 0.9, // kompakter
                    ),
                    itemCount: rows * 7,
                    itemBuilder: (_, idx) {
                      if (idx < leadingEmpty || idx >= leadingEmpty + days) {
                        return const SizedBox.shrink();
                      }
                      final dayNum = idx - leadingEmpty + 1;
                      final date =
                      DateTime(_currentMonth.year, _currentMonth.month, dayNum);
                      final key = _dateKey(date);
                      final names = widget.calendarByDate[key]?.toList() ?? const <String>[];
                      final isToday = _dateKey(date) == DayCycle.todayKey();
                      final tookCreatine = widget.isCreatineTaken(date);

                      return GestureDetector(
                        onTap: () => _showFullList(context, date, names),
                        onLongPress: () => _showFullList(context, date, names),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.card(context),
                                borderRadius: BorderRadius.circular(12),
                                border: isToday
                                    ? Border.all(color: AppColors.accent(context), width: 1.5)
                                    : Border.all(color: AppColors.border(context)),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0F000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('$dayNum',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          )),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (names.isNotEmpty)
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomLeft,
                                        child: _buildDayContent(names),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (tookCreatine)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.accent(context),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x33000000),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _Dow extends StatelessWidget {
  final String label;
  const _Dow(this.label);
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
            child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.muted(context),
          ),
        )),
      ),
    );
  }
}

class _MonthIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  const _MonthIconButton({required this.icon, required this.onTap, this.isPrimary = false});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.accent(context) : AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Icon(icon, color: isPrimary ? Colors.white : AppColors.inkSoft(context)),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ToggleButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: Icon(icon, color: AppColors.inkSoft(context), size: 20),
      ),
    );
  }
}