import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/activity_point.dart';
import '../../data/models/weekly_review_data.dart';
import '../../data/repositories/progress_repository_impl.dart';
import '../../data/repositories/weekly_review_repository_impl.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/weekly_review_repository.dart';

enum Range { week, month, year }
enum DisplayMode { points, ratio }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with WidgetsBindingObserver {
  // All persistence goes through the repository abstraction so the storage
  // backend (local today, database/server later) can be swapped without
  // touching this screen.
  final ProgressRepository _repo = ProgressRepositoryImpl();
  final WeeklyReviewRepository _weeklyRepo = WeeklyReviewRepositoryImpl();

  Range range = Range.week;                 // wird beim Laden aus Prefs überschrieben
  DisplayMode _mode = DisplayMode.ratio;    // Punkte- vs Verhältnis-Kurve
  Map<DateTime, int> _history = {};         // Mitternacht -> Punkte
  Map<DateTime, int> _ratioHistory = {};    // Mitternacht -> Verhältnis in %
  WeeklyReviewData _weeklyReview = const WeeklyReviewData();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadHistory(); // neu einlesen, falls der Tag gewechselt hat
      _loadRatioHistory();
      _loadWeeklyReview();
    }
  }

  DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime _startOfMonth(DateTime d) => DateTime(d.year, d.month, 1);
  DateTime _startOfYear(DateTime d) => DateTime(d.year, 1, 1);

  Future<void> _loadAll() async {
    // Range aus Prefs (persistente Auswahl)
    final savedRange = await _repo.loadRange();
    switch (savedRange) {
      case 'month':
        range = Range.month;
        break;
      case 'year':
        range = Range.year;
        break;
      default:
        range = Range.week;
    }
    // Modus aus Prefs
    final savedMode = await _repo.loadDisplayMode();
    switch (savedMode) {
      case 'points':
        _mode = DisplayMode.points;
        break;
      default:
        _mode = DisplayMode.ratio;
    }
    await _loadHistory();
    await _loadRatioHistory();
    await _loadWeeklyReview();
    if (mounted) setState(() {});
  }

  Future<void> _loadWeeklyReview() async {
    final review = await _weeklyRepo.loadWeeklyReview();
    _weeklyReview = review;
    if (mounted) setState(() {});
  }

  Future<void> _saveRange() async {
    await _repo.saveRange(range.name); // "week" | "month" | "year"
  }
  Future<void> _saveMode() async {
    await _repo.saveDisplayMode(_mode.name); // "points" | "ratio"
  }

  Future<void> _loadHistory() async {
    final map = await _repo.loadHistory();

    // Fallback für HEUTE: falls noch kein Eintrag, aus Daily-Tasks summieren
    // *** NUR Tasks zählen, die keep == true UND done == true sind. ***
    final today = _midnight(DateTime.now());
    if (!map.containsKey(today)) {
      final tasksRaw = await _repo.loadDailyTasksRaw();
      if (tasksRaw is List) {
        int todayPts = 0;
        for (final e in tasksRaw) {
          final m = Map<String, dynamic>.from(e as Map);
          final done = (m['done'] ?? false) as bool;
          final keep = (m['keep'] ?? false) as bool;
          final pts = (m['points'] ?? 1) as int;
          if (keep && done) todayPts += pts;
        }
        map[today] = todayPts; // nur für Anzeige (Persist kommt aus Daily-Screen)
      }
    }

    _history = map;
    if (mounted) setState(() {});
  }

  Future<void> _loadRatioHistory() async {
    final map = await _repo.loadRatioHistory();

    // Heutiges Verhältnis (nur keep-Tasks): donePts / totalPts in Prozent
    final today = _midnight(DateTime.now());
    final tasksRaw = await _repo.loadDailyTasksRaw();
    int donePts = 0;
    int totalPts = 0;
    if (tasksRaw is List) {
      for (final e in tasksRaw) {
        final m = Map<String, dynamic>.from(e as Map);
        final done = (m['done'] ?? false) as bool;
        final keep = (m['keep'] ?? false) as bool;
        final pts = (m['points'] ?? 1) as int;
        if (keep) {
          totalPts += pts;
          if (done) donePts += pts;
        }
      }
    }
    final ratioPct = totalPts > 0 ? ((donePts * 100.0) / totalPts).round() : 0;
    map[today] = ratioPct;
    await _repo.saveRatioHistory(map);

    _ratioHistory = map;
    if (mounted) setState(() {});
  }

  /// Lückenlose Tagespunkte zwischen [start]..[end] (inkl.)
  List<ActivityPoint> _sequence(DateTime start, DateTime end) {
    final res = <ActivityPoint>[];
    DateTime d = _midnight(start);
    final last = _midnight(end);
    while (!d.isAfter(last)) {
      res.add(ActivityPoint(d, _history[d] ?? 0));
      d = d.add(const Duration(days: 1));
    }
    return res;
  }

  List<ActivityPoint> _dataForRange() {
    final today = _midnight(DateTime.now());

    switch (range) {
      case Range.week:
        final start = today.subtract(const Duration(days: 6));
        return _sequence(start, today);

      case Range.month:
        final start = _startOfMonth(today);
        return _sequence(start, today);

      case Range.year:
        final start = _startOfYear(today);
        return _sequence(start, today);
    }
  }

  List<ActivityPoint> _ratioSequence(DateTime start, DateTime end) {
    final res = <ActivityPoint>[];
    DateTime d = _midnight(start);
    final last = _midnight(end);
    while (!d.isAfter(last)) {
      res.add(ActivityPoint(d, _ratioHistory[d] ?? 0));
      d = d.add(const Duration(days: 1));
    }
    return res;
  }

  List<ActivityPoint> _ratioDataForRange() {
    final today = _midnight(DateTime.now());

    switch (range) {
      case Range.week:
        final start = today.subtract(const Duration(days: 6));
        return _ratioSequence(start, today);
      case Range.month:
        final start = _startOfMonth(today);
        return _ratioSequence(start, today);
      case Range.year:
        final start = _startOfYear(today);
        return _ratioSequence(start, today);
    }
  }

  String _rangeLabel(Range r) => r == Range.week ? 'Week' : r == Range.month ? 'Month' : 'Year';

  int _sumForRange(List<ActivityPoint> data) {
    return data.fold<int>(0, (s, p) => s + p.value);
  }

  String _avgLabel(List<ActivityPoint> data) {
    if (data.isEmpty) return '-';
    final avg = _sumForRange(data) / data.length;
    return avg.toStringAsFixed(1);
  }

  int _todayRatio() {
    final today = _midnight(DateTime.now());
    return _ratioHistory[today] ?? 0;
  }

  String _currentRatioLabel() {
    final v = _todayRatio();
    return '$v%';
  }

  String _avgRatioLabel(List<ActivityPoint> data) {
    if (data.isEmpty) return '-';
    final avg = data.fold<int>(0, (s, p) => s + p.value) / data.length;
    return '${avg.toStringAsFixed(1)}%';
  }

  List<FlSpot> _spotsFromData(List<ActivityPoint> data) {
    return List<FlSpot>.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i].value.toDouble()),
    );
  }

  double _maxYForData(List<ActivityPoint> data) {
    if (_mode == DisplayMode.ratio) {
      return 100;
    }
    if (data.isEmpty) {
      return 5;
    }
    final maxValue = data
        .map((point) => point.value)
        .fold<int>(0, (a, b) => a > b ? a : b);
    return (maxValue + 2).toDouble().clamp(5, 9999);
  }

  String _dateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    if (range == Range.year) {
      return '$month.${date.year.toString().substring(2)}';
    }
    return '$day.$month';
  }

  Widget _buildProgressChart(List<ActivityPoint> data) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data yet',
          style: TextStyle(color: Color(0xFF6F7789), fontWeight: FontWeight.w500),
        ),
      );
    }

    final spots = _spotsFromData(data);
    final maxX = (data.length - 1).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: _maxYForData(data),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _mode == DisplayMode.ratio ? 20 : null,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: Color(0x14000000),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => const Color(0xFF1A1D1F),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                final point = data[index];
                return LineTooltipItem(
                  '${_dateLabel(point.t)}\n${point.value}${_mode == DisplayMode.ratio ? '%' : ' pts'}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList();
            },
          ),
          getTouchedSpotIndicator: (barData, spotIndexes) {
            return spotIndexes
                .map(
                  (_) => TouchedSpotIndicatorData(
                    const FlLine(color: Color(0x55E53935), strokeWidth: 1),
                    FlDotData(
                      getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                        radius: 5,
                        color: const Color(0xFFE53935),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                )
                .toList();
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: _mode == DisplayMode.ratio ? 20 : null,
              getTitlesWidget: (value, meta) {
                if (value < 0) {
                  return const SizedBox.shrink();
                }
                if (_mode == DisplayMode.ratio && value % 20 != 0) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _mode == DisplayMode.ratio ? '${value.toInt()}%' : value.toInt().toString(),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6F7789)),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                if (data.isEmpty) {
                  return const SizedBox.shrink();
                }
                final index = value.round();
                final mid = (data.length - 1) ~/ 2;
                if (index != 0 && index != mid && index != data.length - 1) {
                  return const SizedBox.shrink();
                }
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  _dateLabel(data[index].t),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6F7789)),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFE53935),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3.5,
                color: const Color(0xFFE53935),
                strokeWidth: 1.8,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935)),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Reset progress?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'All stored daily points will be removed. This cannot be undone.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
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
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.saveHistory(<DateTime, int>{});
      await _repo.saveRatioHistory(<DateTime, int>{});
      _history.clear();
      _ratioHistory.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _mode == DisplayMode.ratio ? _ratioDataForRange() : _dataForRange();
    final currentRatio = _currentRatioLabel();
    final avgRatio = _avgRatioLabel(_ratioDataForRange());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Mode toggle buttons
                    _buildModeToggle(),
                    const SizedBox(height: 12),
                    // Range toggle buttons
                    _buildRangeToggle(),
                    const SizedBox(height: 16),

                    // Chart card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                        child: SizedBox(
                          height: 300,
                          child: _buildProgressChart(data),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        if (_mode == DisplayMode.ratio) ...[
                          Expanded(child: _metricCard('Current ratio', currentRatio)),
                        ] else ...[
                          Expanded(child: _metricCard('Current ${_rangeLabel(range)}', '${_sumForRange(_dataForRange())} pts')),
                        ],
                        const SizedBox(width: 12),
                        if (_mode == DisplayMode.ratio) ...[
                          Expanded(child: _metricCard('Avg ratio', avgRatio)),
                        ] else ...[
                          Expanded(child: _metricCard('Avg per day', _avgLabel(_dataForRange()))),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    _buildWeeklyReviewCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFocusMinutes(int minutes) {
    if (minutes < 60) return '$minutes min.';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h $m min.';
  }

  Widget _buildWeeklyReviewCard() {
    final r = _weeklyReview;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights,
                  color: Color(0xFFE53935),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Weekly Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1F),
                ),
              ),
              const Spacer(),
              Text(
                'vs. last week',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _weeklyReviewRow(
            icon: Icons.timer_outlined,
            label: 'Focus time',
            value: _formatFocusMinutes(r.focusMinutes),
            delta: r.focusMinutes - r.prevFocusMinutes,
            deltaLabel: _formatFocusMinutes(
              (r.focusMinutes - r.prevFocusMinutes).abs(),
            ),
          ),
          const SizedBox(height: 12),
          _weeklyReviewRow(
            icon: Icons.app_blocking_outlined,
            label: 'Blocker time',
            value: _formatFocusMinutes(r.blockerMinutes),
            delta: r.blockerMinutes - r.prevBlockerMinutes,
            deltaLabel: _formatFocusMinutes(
              (r.blockerMinutes - r.prevBlockerMinutes).abs(),
            ),
          ),
          const SizedBox(height: 12),
          _weeklyReviewRow(
            icon: Icons.check_circle_outline,
            label: 'Tasks done',
            value: '${r.tasksDone}',
            delta: r.tasksDone - r.prevTasksDone,
            deltaLabel: '${(r.tasksDone - r.prevTasksDone).abs()}',
          ),
          const SizedBox(height: 12),
          _weeklyReviewRow(
            icon: Icons.fitness_center,
            label: 'Workouts',
            value: '${r.workouts}',
            delta: r.workouts - r.prevWorkouts,
            deltaLabel: '${(r.workouts - r.prevWorkouts).abs()}',
          ),
        ],
      ),
    );
  }

  Widget _weeklyReviewRow({
    required IconData icon,
    required String label,
    required String value,
    required int delta,
    required String deltaLabel,
  }) {
    final Color deltaColor;
    final Color deltaBg;
    final IconData deltaIcon;
    if (delta > 0) {
      deltaColor = const Color(0xFF2E7D32);
      deltaBg = const Color(0xFFE8F5E9);
      deltaIcon = Icons.arrow_upward;
    } else if (delta < 0) {
      deltaColor = const Color(0xFFE53935);
      deltaBg = const Color(0xFFFFEBEE);
      deltaIcon = Icons.arrow_downward;
    } else {
      deltaColor = const Color(0xFF6F7789);
      deltaBg = const Color(0xFFEFF1F5);
      deltaIcon = Icons.remove;
    }

    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF6F7789)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1D1F),
            ),
          ),
        ),
        // Fixed-width columns so values and delta chips line up across rows.
        SizedBox(
          width: 80,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1D1F),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: deltaBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(deltaIcon, size: 12, color: deltaColor),
                  const SizedBox(width: 3),
                  Text(
                    deltaLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: deltaColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Icons.show_chart,
                  color: Color(0xFFE53935),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1D1F),
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                tooltip: 'Reload',
                onPressed: () async {
                  await _loadHistory();
                  await _loadRatioHistory();
                  await _loadWeeklyReview();
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF6F7789)),
              ),
              IconButton(
                tooltip: 'More options',
                onPressed: _showActionsSheet,
                icon: const Icon(Icons.more_vert, color: Color(0xFF6F7789)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showActionsSheet() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E4EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Color(0xFFE53935)),
                  title: const Text('Clear history', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Remove all stored progress data'),
                  onTap: () => Navigator.pop(context, 'clear'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.close, color: Color(0xFF6F7789)),
                  title: const Text('Close'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (action == 'clear') {
      await _confirmClearHistory();
    }
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              label: 'Points',
              icon: Icons.star_outline,
              isSelected: _mode == DisplayMode.points,
              onTap: () async {
                setState(() => _mode = DisplayMode.points);
                await _saveMode();
              },
            ),
          ),
          Expanded(
            child: _toggleButton(
              label: 'Ratio',
              icon: Icons.percent,
              isSelected: _mode == DisplayMode.ratio,
              onTap: () async {
                setState(() => _mode = DisplayMode.ratio);
                await _saveMode();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleButton(
              label: 'Week',
              icon: Icons.view_week,
              isSelected: range == Range.week,
              onTap: () async {
                setState(() => range = Range.week);
                await _saveRange();
              },
            ),
          ),
          Expanded(
            child: _toggleButton(
              label: 'Month',
              icon: Icons.calendar_view_month,
              isSelected: range == Range.month,
              onTap: () async {
                setState(() => range = Range.month);
                await _saveRange();
              },
            ),
          ),
          Expanded(
            child: _toggleButton(
              label: 'Year',
              icon: Icons.calendar_month,
              isSelected: range == Range.year,
              onTap: () async {
                setState(() => range = Range.year);
                await _saveRange();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF6F7789),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isSelected ? Colors.white : const Color(0xFF6F7789),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
