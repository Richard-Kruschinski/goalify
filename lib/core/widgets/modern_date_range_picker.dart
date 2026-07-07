import 'package:flutter/material.dart';

class ModernDateRangePicker extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;

  const ModernDateRangePicker({super.key, 
    this.initialStart,
    this.initialEnd,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<ModernDateRangePicker> createState() => _ModernDateRangePickerState();
}

class _ModernDateRangePickerState extends State<ModernDateRangePicker> {
  late DateTime _currentMonth;
  late DateTime? _selectedStart;
  late DateTime? _selectedEnd;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedStart = widget.initialStart;
    _selectedEnd = widget.initialEnd;
    _currentMonth = _selectedStart ?? DateTime.now();
    _pageController = PageController(
      initialPage: _monthDifference(widget.firstDate, _currentMonth),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _monthDifference(DateTime d1, DateTime d2) {
    return (d2.year - d1.year) * 12 + (d2.month - d1.month);
  }

  DateTime _getMonthFromIndex(int index) {
    return DateTime(
      widget.firstDate.year + (widget.firstDate.month + index - 1) ~/ 12,
      ((widget.firstDate.month + index - 1) % 12) + 1,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isInRange(DateTime date) {
    if (_selectedStart == null || _selectedEnd == null) return false;
    final start = _selectedStart!;
    final end = _selectedEnd!;
    return date.isAfter(start) && date.isBefore(end.add(Duration(days: 1)));
  }

  bool _isStartDate(DateTime date) {
    return _selectedStart != null && _isSameDay(date, _selectedStart!);
  }

  bool _isEndDate(DateTime date) {
    return _selectedEnd != null && _isSameDay(date, _selectedEnd!);
  }

  Future<void> _jumpToMonthYear() async {
    final monthController = TextEditingController(text: _currentMonth.month.toString());
    final yearController = TextEditingController(text: _currentMonth.year.toString());

    final minMonth = DateTime(widget.firstDate.year, widget.firstDate.month, 1);
    final maxMonth = DateTime(widget.lastDate.year, widget.lastDate.month, 1);

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
                  errorText = 'Month must be between 1 and 12';
                });
                return;
              }

              if (year == null || year < 1) {
                setDialogState(() {
                  errorText = 'Year must be greater than 0';
                });
                return;
              }

              final candidate = DateTime(year, month, 1);
              if (candidate.isBefore(minMonth) || candidate.isAfter(maxMonth)) {
                setDialogState(() {
                  errorText =
                      'Allowed range: ${_monthYearFormat(minMonth)} - ${_monthYearFormat(maxMonth)}';
                });
                return;
              }

              Navigator.of(dialogContext).pop(candidate);
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                              color: const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Color(0xFFE53935),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Go to month',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1D1F),
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
                        decoration: InputDecoration(
                          labelText: 'Month',
                          hintText: '1 - 12',
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE53935), width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: yearController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Year',
                          hintText: 'e.g. 2026',
                          filled: true,
                          fillColor: const Color(0xFFF7F8FA),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE6E8EC)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE53935), width: 1.2),
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
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF6F7789)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE53935),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Go',
                              style: TextStyle(fontWeight: FontWeight.w700),
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

    final pageIndex = _monthDifference(widget.firstDate, targetMonth);
    final maxPageIndex = _monthDifference(widget.firstDate, widget.lastDate);
    if (pageIndex < 0 || pageIndex > maxPageIndex) return;

    if (_pageController.hasClients) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }

    setState(() {
      _currentMonth = targetMonth;
    });
  }

  @override
  Widget build(BuildContext context) {
    final maxMonths = _monthDifference(widget.firstDate, widget.lastDate) + 1;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: const Color(0xFFF5F7FA),
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title and range display
          Padding(
            padding: EdgeInsets.all(isLandscape ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Datumsbereich wählen',
                  style: TextStyle(
                    fontSize: isLandscape ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: isLandscape ? 12 : 16),
                // Start and End date display
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Anfangsdatum',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedStart != null
                                  ? _formatDate(_selectedStart!)
                                  : 'Wählen...',
                              style: TextStyle(
                                fontSize: isLandscape ? 12 : 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedStart != null
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isLandscape ? 8 : 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enddatum',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedEnd != null ? _formatDate(_selectedEnd!) : 'Wählen...',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _selectedEnd != null
                                    ? const Color(0xFF111827)
                                    : const Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calendar
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentMonth = _getMonthFromIndex(index);
                });
              },
              itemCount: maxMonths,
              itemBuilder: (context, index) {
                final month = _getMonthFromIndex(index);
                return _buildCalendarMonth(month);
              },
            ),
          ),

          // Navigation and buttons
          Padding(
            padding: EdgeInsets.all(isLandscape ? 16 : 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: _jumpToMonthYear,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Text(
                          _monthYearFormat(_currentMonth),
                          style: TextStyle(
                            fontSize: isLandscape ? 12 : 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.chevron_left),
                          iconSize: isLandscape ? 18 : 20,
                          color: const Color(0xFF6B7280),
                        ),
                        IconButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.chevron_right),
                          iconSize: isLandscape ? 18 : 20,
                          color: const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isLandscape ? 12 : 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Abbrechen',
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: isLandscape ? 12 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE53935),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isLandscape ? 16 : 24,
                          vertical: isLandscape ? 8 : 12,
                        ),
                      ),
                      onPressed: _selectedStart != null && _selectedEnd != null
                          ? () {
                              Navigator.pop(
                                context,
                                DateTimeRange(start: _selectedStart!, end: _selectedEnd!),
                              );
                            }
                          : null,
                      child: Text(
                        'Anwenden',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: isLandscape ? 12 : 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarMonth(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    const weekDays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(
        maxHeight: isLandscape ? 300 : double.infinity,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Day headers
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: weekDays
                  .map((day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Calendar grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isLandscape ? 1.1 : 1.2,
              mainAxisSpacing: isLandscape ? 2 : 4,
              crossAxisSpacing: isLandscape ? 2 : 4,
              children: [
                // Empty cells for days before month starts
                ...List.generate(
                  firstWeekday - 1,
                  (_) => const SizedBox(),
                ),
                // Days of month
                ...List.generate(
                  daysInMonth,
                  (index) {
                  final date = DateTime(month.year, month.month, index + 1);
                  final isStart = _isStartDate(date);
                  final isEnd = _isEndDate(date);
                  final inRange = _isInRange(date);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedStart == null) {
                          _selectedStart = date;
                        } else if (_selectedEnd == null) {
                          if (date.isBefore(_selectedStart!)) {
                            _selectedEnd = _selectedStart;
                            _selectedStart = date;
                          } else {
                            _selectedEnd = date;
                          }
                        } else {
                          _selectedStart = date;
                          _selectedEnd = null;
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isStart || isEnd
                            ? const Color(0xFFE53935)
                            : inRange
                                ? const Color(0xFFFFEBEE)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: isLandscape ? 12 : 13,
                          fontWeight: isStart || isEnd ? FontWeight.w700 : FontWeight.w500,
                          color: isStart || isEnd
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  );
                },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _monthYearFormat(DateTime date) {
    const months = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${months[date.month]} ${date.year}';
  }
}

