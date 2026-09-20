import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/i18n/task_labels.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/day_cycle.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/gym_models.dart';
import '../../../../core/widgets/modern_date_range_picker.dart';

/// ===============================================================
/// Vollbild-Seite für die Chart
/// ===============================================================
class FullScreenChartPage extends StatefulWidget {
  final String title;
  final List<WorkoutLog> logs;
  final bool isDurationBased;

  const FullScreenChartPage({
    super.key,
    required this.title,
    required this.logs,
    this.isDurationBased = false,
  });

  @override
  State<FullScreenChartPage> createState() => _FullScreenChartPageState();
}

class _FullScreenChartPageState extends State<FullScreenChartPage> {
  // Filter options
  String _filterBy = 'Standard'; // Standard (max weight), Gewicht, Datum, Set 1, Set 2, Set 3, etc.
  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;
  double? _filterWeight;
  List<WorkoutLog> _lastFilteredLogs = const [];
  bool _showAllSets = true;

  bool get _durationBased => widget.isDurationBased;
  WorkoutUnits get _units => workoutUnitsOf(AppLocalizations.of(context));
  String get _unitLabel => _durationBased ? _units.secShort : _units.kg;

  double _yValueForLog(WorkoutLog log) =>
      _durationBased ? log.longestDurationSeconds.toDouble() : log.maxWeightKg;

  WorkoutLog? _logForSpotX(List<WorkoutLog> source, double x) {
    final target = x.round();
    for (final log in source) {
      if (log.dateTime.millisecondsSinceEpoch == target) {
        return log;
      }
    }
    return null;
  }

  int _repsForFilter(WorkoutLog log) {
    if (!_filterBy.startsWith('Set ')) {
      return log.heaviestSetReps;
    }

    if (_filterBy.contains('•')) {
      final parts = _filterBy.split('•');
      final setNum = int.tryParse(parts[0].trim().split(' ')[1]) ?? 1;
      final dropsetNum = int.tryParse(parts[1].trim().split(' ')[1]) ?? 1;
      if (setNum <= 0 || setNum > log.sets.length) return 0;
      final set = log.sets[setNum - 1];
      if (dropsetNum <= 0 || dropsetNum > set.dropsets.length) return 0;
      return set.dropsets[dropsetNum - 1].reps;
    }

    final setNum = int.tryParse(_filterBy.split(' ')[1]) ?? 1;
    if (setNum <= 0 || setNum > log.sets.length) return 0;
    return log.sets[setNum - 1].reps;
  }

  String _tooltipValue(double yValue, WorkoutLog log) {
    final u = _units;
    if (_durationBased) return formatDurationShort(log.longestDurationSeconds, u);
    return '${yValue.toStringAsFixed(1)} ${u.kg} x ${_repsForFilter(log)}';
  }

  Color _seriesColor(int index) {
    final palette = Colors.primaries;
    return palette[index % palette.length].shade400;
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    super.dispose();
  }

  void _showFilterMenu() {
    if (_durationBased && _filterBy == 'Gewicht') {
      setState(() {
        _filterBy = 'Standard';
        _filterWeight = null;
      });
    }
    showDialog<void>(
      context: context,
      builder: (_) => _FilterDialogModern(
        filterBy: _filterBy,
        dateRangeStart: _dateRangeStart,
        dateRangeEnd: _dateRangeEnd,
        filterWeight: _filterWeight,
        logs: widget.logs,
        isDurationBased: _durationBased,
        showAllSets: _showAllSets,
        onFilterChanged: (filterBy, {dateStart, dateEnd, weight}) {
          setState(() {
            _filterBy = filterBy;
            _dateRangeStart = dateStart;
            _dateRangeEnd = dateEnd;
            _filterWeight = weight;
          });
          Navigator.pop(context);
        },
        onToggleShowAllSets: (value) {
          setState(() => _showAllSets = value);
        },
      ),
    );
  }

  List<FlSpot> _getFilteredSpots(List<WorkoutLog> logs) {
    List<WorkoutLog> filteredLogs = logs;

    // Apply date range filter if "Datum" is selected
    if (_filterBy == 'Datum' && _dateRangeStart != null && _dateRangeEnd != null) {
      filteredLogs = logs.where((log) {
        final logDate = log.dateTime;
        return logDate.isAfter(_dateRangeStart!) &&
            logDate.isBefore(_dateRangeEnd!.add(const Duration(days: 1)));
      }).toList();
    }

    double yForLog(WorkoutLog log) => _yValueForLog(log);

    // Apply weight/duration filter if selected AND value is set
    if (_filterBy == 'Gewicht' && _filterWeight != null) {
      filteredLogs = filteredLogs.where((log) => yForLog(log) >= _filterWeight!).toList();
      _lastFilteredLogs = filteredLogs;
      return List<FlSpot>.generate(
        filteredLogs.length,
        (i) => FlSpot(
          filteredLogs[i].dateTime.millisecondsSinceEpoch.toDouble(),
          yForLog(filteredLogs[i]),
        ),
      );
    }

    // Handle Set N oder Set N • Dropset M filter
    if (_filterBy.startsWith('Set ')) {
      _lastFilteredLogs = filteredLogs;
      return List<FlSpot>.generate(
        filteredLogs.length,
        (i) {
          final log = filteredLogs[i];
          
          // Parse filter: "Set 1", "Set 1 • Dropset 1", etc.
          double value = 0;
          
          if (_filterBy.contains('•')) {
            // Dropset filter: "Set 1 • Dropset 1"
            final parts = _filterBy.split('•');
            final setNum = int.tryParse(parts[0].trim().split(' ')[1]) ?? 1;
            final dropsetNum = int.tryParse(parts[1].trim().split(' ')[1]) ?? 1;
            
            if (setNum <= log.sets.length) {
              final set = log.sets[setNum - 1];
              if (dropsetNum <= set.dropsets.length) {
                final dropset = set.dropsets[dropsetNum - 1];
                value = _durationBased
                    ? (dropset.durationSeconds ?? 0).toDouble()
                    : dropset.totalWeightKg;
              }
            }
          } else {
            // Regular set filter: "Set 1"
            final setIndex = int.tryParse(_filterBy.split(' ')[1]) ?? 1;
            if (setIndex <= log.sets.length) {
              final set = log.sets[setIndex - 1];
              value = _durationBased
                  ? (set.durationSeconds ?? 0).toDouble()
                  : set.totalWeightKg;
            }
          }
          
          return FlSpot(
            log.dateTime.millisecondsSinceEpoch.toDouble(),
            value,
          );
        },
      );
    }

    // Default: show heaviest weight or longest duration per day
    _lastFilteredLogs = filteredLogs;
    return List<FlSpot>.generate(
      filteredLogs.length,
      (i) => FlSpot(
        filteredLogs[i].dateTime.millisecondsSinceEpoch.toDouble(),
        yForLog(filteredLogs[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = List<WorkoutLog>.from(widget.logs)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final bool useMulti = _showAllSets &&
        (_filterBy == 'Standard' || _filterBy == 'Datum');

    final List<WorkoutLog> dateFilteredLogs = (_filterBy == 'Datum' &&
            _dateRangeStart != null &&
            _dateRangeEnd != null)
        ? logs.where((log) {
            final logDate = log.dateTime;
            return logDate.isAfter(_dateRangeStart!) &&
                logDate.isBefore(_dateRangeEnd!.add(const Duration(days: 1)));
          }).toList()
        : logs;

    final List<int> seriesSetIndices = <int>[];
    final List<List<FlSpot>> multiSeriesSpots = <List<FlSpot>>[];

    if (useMulti) {
      final int maxSets = dateFilteredLogs.fold<int>(
        0,
        (m, l) => math.max(m, l.sets.length),
      );

      for (int setIndex = 0; setIndex < maxSets; setIndex++) {
        final series = <FlSpot>[];
        for (final log in dateFilteredLogs) {
          if (log.sets.length <= setIndex) continue;
          final set = log.sets[setIndex];
          final value = _durationBased
              ? (set.durationSeconds ?? 0).toDouble()
              : set.totalWeightKg;
          if (value <= 0) continue;
          series.add(FlSpot(
            log.dateTime.millisecondsSinceEpoch.toDouble(),
            value,
          ));
        }
        if (series.isNotEmpty) {
          seriesSetIndices.add(setIndex);
          multiSeriesSpots.add(series);
        }
      }
    }

    final spots = useMulti
        ? <FlSpot>[]
        : _getFilteredSpots(logs);

    final allSpots = useMulti
        ? multiSeriesSpots.expand((s) => s).toList()
        : spots;

    if (allSpots.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.bg(context),
        appBar: AppBar(
          backgroundColor: AppColors.card(context),
          foregroundColor: AppColors.ink(context),
          elevation: 0.5,
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              tooltip: AppLocalizations.of(context).filter,
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterMenu,
            ),
            IconButton(
              tooltip: AppLocalizations.of(context).exitFullScreen,
              icon: const Icon(Icons.fullscreen_exit),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: Center(child: Text(AppLocalizations.of(context).noDataForFilter)),
      );
    }

    final double minX = allSpots.map((s) => s.x).reduce(math.min);
    final double maxX = allSpots.map((s) => s.x).reduce(math.max);

    double niceNum(double range, {required bool round}) {
      if (range <= 0) return 1;
      final double exp =
      math.pow(10, (math.log(range) / math.ln10).floor()).toDouble();
      final double f = range / exp;
      double nf;
      if (round) {
        if (f < 1.5) {
          nf = 1;
        } else if (f < 3) {
          nf = 2;
        } else if (f < 7) {
          nf = 5;
        } else {
          nf = 10;
        }
      } else {
        if (f <= 1) {
          nf = 1;
        } else if (f <= 2) {
          nf = 2;
        } else if (f <= 5) {
          nf = 5;
        } else {
          nf = 10;
        }
      }
      return nf * exp;
    }

    // Calculate Y-range based on filter
    double rawMinY;
    double rawMaxY;
    
    if (allSpots.isEmpty) {
      rawMinY = 0;
      rawMaxY = 10;
    } else {
      rawMinY = (allSpots.map((s) => s.y).reduce(math.min) as num).toDouble();
      rawMaxY = (allSpots.map((s) => s.y).reduce(math.max) as num).toDouble();
    }
    
    if (rawMinY == rawMaxY) {
      rawMinY -= 1;
      rawMaxY += 1;
    }
    if (_durationBased && rawMinY < 0) rawMinY = 0;

    const targetLines = 5;
    final niceRange = niceNum(rawMaxY - rawMinY, round: false);
    final yInterval = niceNum(niceRange / (targetLines - 1), round: true);
    final minY = (rawMinY / yInterval).floor() * yInterval;
    final maxY = (rawMaxY / yInterval).ceil() * yInterval;

    String fmtDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    String fmtTooltip(DateTime d) => fmtDate(d);

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      appBar: AppBar(
        backgroundColor: AppColors.card(context),
        foregroundColor: AppColors.ink(context),
        elevation: 0.5,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).filter,
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).exitFullScreen,
            icon: const Icon(Icons.fullscreen_exit),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 12, 18, 12),
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(_unitLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                axisNameSize: 26,
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 42,
                  interval: yInterval,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    space: 6,
                    child: Text(value.toStringAsFixed(0)),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  interval: (maxX - minX) == 0 ? 1 : (maxX - minX),
                  getTitlesWidget: (value, meta) {
                    const eps = 0.5;
                    final bool isFirst = (value - minX).abs() < eps;
                    final bool isLast = (value - maxX).abs() < eps;

                    if ((maxX - minX).abs() < eps) {
                      final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return SideTitleWidget(
                        meta: meta,
                        space: 6,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(fmtDate(dt), style: const TextStyle(fontSize: 12)),
                        ),
                      );
                    }
                    if (!isFirst && !isLast) return const SizedBox.shrink();

                    final dt = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                    return SideTitleWidget(
                      meta: meta,
                      space: 6,
                      child: Padding(
                        padding: EdgeInsets.only(left: isFirst ? 8 : 0, right: isLast ? 24 : 0),
                        child: Text(
                          fmtDate(dt),
                          style: const TextStyle(fontSize: 12),
                          textAlign: isFirst ? TextAlign.left : TextAlign.right,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) => AppColors.card(context),
                tooltipPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                getTooltipItems: (touchedSpots) => touchedSpots.map((t) {
                  final dt = DateTime.fromMillisecondsSinceEpoch(t.x.round());

                  final dateStr = fmtTooltip(dt);
                  if (useMulti) {
                    final setIndex = seriesSetIndices[t.barIndex];
                    final log = _logForSpotX(dateFilteredLogs, t.x);
                    final reps = (log != null && setIndex >= 0 && setIndex < log.sets.length)
                        ? log.sets[setIndex].reps
                        : 0;
                    final valueStr = _durationBased
                        ? formatDurationShort(t.y.round(), _units)
                        : '${t.y.toStringAsFixed(1)} ${_units.kg} x $reps';
                    return LineTooltipItem(
                      '$dateStr\n',
                      TextStyle(color: AppColors.ink(context), fontWeight: FontWeight.w700),
                      children: [
                        TextSpan(
                          text: AppLocalizations.of(context).setLabel(setIndex + 1, valueStr),
                          style: TextStyle(
                            color: AppColors.ink(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  }

                  final activeLogs = _lastFilteredLogs.isNotEmpty ? _lastFilteredLogs : logs;
                  final idx = t.spotIndex.clamp(0, activeLogs.length - 1);
                  final log = activeLogs[idx];
                  final valueStr = _tooltipValue(t.y, log);

                  return LineTooltipItem(
                    '$dateStr\n',
                    TextStyle(color: AppColors.ink(context), fontWeight: FontWeight.w700),
                    children: [
                      TextSpan(
                        text: valueStr,
                        style: TextStyle(
                          color: AppColors.ink(context),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
            minX: minX,
            maxX: maxX,
            minY: minY.toDouble(),
            maxY: maxY.toDouble(),
            lineBarsData: useMulti
                ? List<LineChartBarData>.generate(
                    multiSeriesSpots.length,
                    (i) {
                      final color = _seriesColor(i);
                      return LineChartBarData(
                        spots: multiSeriesSpots[i],
                        isCurved: false,
                        barWidth: 2.6,
                        color: color,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) {
                            return FlDotCirclePainter(
                              radius: 3.0,
                              color: color,
                              strokeWidth: 1.4,
                              strokeColor: color.withValues(alpha: 0.5),
                            );
                          },
                        ),
                      );
                    },
                  )
                : [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      barWidth: 3,
                      color: AppColors.accent(context),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          return FlDotCirclePainter(
                            radius: 3.2,
                            color: AppColors.accent(context),
                            strokeWidth: 1.5,
                            strokeColor: const Color(0x66E53935),
                          );
                        },
                      ),
                    ),
                  ],
          ),
        ),
      ),
    );
  }
}

class _FilterDialogModern extends StatefulWidget {
  final String filterBy;
  final DateTime? dateRangeStart;
  final DateTime? dateRangeEnd;
  final double? filterWeight;
  final List<WorkoutLog> logs;
  final bool isDurationBased;
  final bool showAllSets;
  final Function(String, {DateTime? dateStart, DateTime? dateEnd, double? weight}) onFilterChanged;
  final ValueChanged<bool> onToggleShowAllSets;

  const _FilterDialogModern({
    required this.filterBy,
    this.dateRangeStart,
    this.dateRangeEnd,
    this.filterWeight,
    required this.logs,
    this.isDurationBased = false,
    required this.showAllSets,
    required this.onFilterChanged,
    required this.onToggleShowAllSets,
  });

  @override
  State<_FilterDialogModern> createState() => _FilterDialogModernState();
}

class _FilterDialogModernState extends State<_FilterDialogModern> {
  late String _selectedFilter;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late TextEditingController _weightController;
  late bool _showAllSetsLocal;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.filterBy;
    _startDate = widget.dateRangeStart;
    _endDate = widget.dateRangeEnd;
    _weightController = TextEditingController(
      text: widget.filterWeight?.toStringAsFixed(1) ?? '',
    );
    _showAllSetsLocal = widget.showAllSets;

    if (widget.isDurationBased && _selectedFilter == 'Gewicht') {
      _selectedFilter = 'Standard';
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.bg(context),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                AppLocalizations.of(context).filterBy,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),

              // Filter options - Standard (no filter)
              _buildFilterOption(
                'Standard',
                AppLocalizations.of(context).showStrongestSet,
                _selectedFilter == 'Standard',
                () => setState(() => _selectedFilter = 'Standard'),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.card(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border(context)),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    AppLocalizations.of(context).multipleGraphs,
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    AppLocalizations.of(context).multipleGraphsSubtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: _showAllSetsLocal,
                  onChanged: (v) => setState(() => _showAllSetsLocal = v),
                  activeColor: AppColors.accent(context),
                ),
              ),
              const SizedBox(height: 16),

              // Filter options - Gewicht
              _buildFilterOption(
                'Gewicht',
                AppLocalizations.of(context).minWeightEnter,
                _selectedFilter == 'Gewicht',
                () => setState(() => _selectedFilter = 'Gewicht'),
              ),
              if (_selectedFilter == 'Gewicht') ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).weightHintKg,
                        hintStyle: TextStyle(color: AppColors.faint(context)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        suffixText: AppLocalizations.of(context).unitKg,
                        suffixStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Filter options - Datum
              _buildFilterOption(
                'Datum',
                _startDate != null && _endDate != null
                    ? '${_fmtDate(_startDate!)} - ${_fmtDate(_endDate!)}'
                    : AppLocalizations.of(context).chooseDateRange,
                _selectedFilter == 'Datum',
                () async {
                  final range = await showDialog<DateTimeRange>(
                    context: context,
                    builder: (context) => ModernDateRangePicker(
                      initialStart: _startDate,
                      initialEnd: _endDate,
                      firstDate: DateTime(2020),
                      lastDate: DayCycle.today(),
                    ),
                  );
                  if (range != null) {
                    setState(() {
                      _selectedFilter = 'Datum';
                      _startDate = range.start;
                      _endDate = range.end;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Filter options - Sets
              ..._buildSetFilterOptions(),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Abbrechen',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    onPressed: () {
                      widget.onToggleShowAllSets(_showAllSetsLocal);
                      double? weight;
                      if (_selectedFilter == 'Gewicht' && _weightController.text.isNotEmpty) {
                        weight = double.tryParse(
                          _weightController.text.replaceAll(',', '.'),
                        );
                      }

                      if (_selectedFilter == 'Datum') {
                        widget.onFilterChanged(
                          _selectedFilter,
                          dateStart: _startDate,
                          dateEnd: _endDate,
                        );
                      } else if (_selectedFilter == 'Gewicht') {
                        widget.onFilterChanged(
                          _selectedFilter,
                          weight: weight,
                        );
                      } else {
                        widget.onFilterChanged(_selectedFilter);
                      }
                    },
                    child: Text(
                      AppLocalizations.of(context).apply,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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

  Widget _buildFilterOption(
    String title,
    String subtitle,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentSoft(context) : AppColors.card(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent(context) : AppColors.border(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: title,
              groupValue: _selectedFilter,
              onChanged: (_) => onTap(),
              activeColor: AppColors.accent(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSetFilterOptions() {
    final options = <Map<String, String>>[];
    int setIndex = 1;

    for (final log in widget.logs) {
      for (int i = 0; i < log.sets.length; i++) {
        final set = log.sets[i];
        final setLabel = 'Set $setIndex';
        
        // Füge das Haupt-Set hinzu
        options.add({
          'label': setLabel,
          'subtitle': AppLocalizations.of(context).weightOfSet(setIndex),
        });

        // Füge Dropsets hinzu, falls vorhanden
        for (int d = 0; d < set.dropsets.length; d++) {
          options.add({
            'label': '$setLabel • Dropset ${d + 1}',
            'subtitle': AppLocalizations.of(context).dropsetOfSet(d + 1, setIndex),
          });
        }
        
        setIndex++;
      }
    }

    // Deduplizieren - nur einzigartige Set-Labels behalten
    final seen = <String>{};
    final uniqueOptions = <Map<String, String>>[];
    
    for (final option in options) {
      final label = option['label']!;
      if (!seen.contains(label)) {
        seen.add(label);
        uniqueOptions.add(option);
      }
    }

    return List.generate(
      uniqueOptions.length,
      (index) => Padding(
        padding: EdgeInsets.only(bottom: index < uniqueOptions.length - 1 ? 16 : 0),
        child: _buildFilterOption(
          uniqueOptions[index]['label']!,
          uniqueOptions[index]['subtitle']!,
          _selectedFilter == uniqueOptions[index]['label']!,
          () => setState(() => _selectedFilter = uniqueOptions[index]['label']!),
        ),
      ),
    );
  }
}