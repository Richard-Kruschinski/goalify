import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../../core/utils/local_storage.dart';

enum Range { day, week, year }
enum DisplayMode { points, ratio }

class ActivityPoint {
  final DateTime t;
  final int value;
  ActivityPoint(this.t, this.value);
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with WidgetsBindingObserver {
  static const _kHistoryKey = 'progress_history_v1';
  static const _kDailyTasksKey = 'daily_tasks_v1';
  static const _kRangeKey = 'progress_range_v1';
  static const _kRatioHistoryKey = 'progress_ratio_history_v1';
  static const _kDisplayModeKey = 'progress_display_mode_v1';

  Range range = Range.week;                 // wird beim Laden aus Prefs überschrieben
  DisplayMode _mode = DisplayMode.ratio;    // Punkte- vs Verhältnis-Kurve
  Map<DateTime, int> _history = {};         // Mitternacht -> Punkte
  Map<DateTime, int> _ratioHistory = {};    // Mitternacht -> Verhältnis in %

  late ZoomPanBehavior _zoom;
  late TrackballBehavior _trackball;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _zoom = ZoomPanBehavior(enablePinching: true, enablePanning: true, zoomMode: ZoomMode.x);
    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipAlignment: ChartAlignment.near,
      tooltipSettings: const InteractiveTooltip(format: 'point.x : point.y'),
    );

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
    }
  }

  DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _loadAll() async {
    // Range aus Prefs (persistente Auswahl)
    final savedRange = await LocalStorage.loadJson(_kRangeKey, fallback: 'week');
    switch (savedRange) {
      case 'day':
        range = Range.day;
        break;
      case 'year':
        range = Range.year;
        break;
      default:
        range = Range.week;
    }
    // Modus aus Prefs
    final savedMode = await LocalStorage.loadJson(_kDisplayModeKey, fallback: 'ratio');
    switch (savedMode) {
      case 'points':
        _mode = DisplayMode.points;
        break;
      default:
        _mode = DisplayMode.ratio;
    }
    await _loadHistory();
    await _loadRatioHistory();
    if (mounted) setState(() {});
  }

  Future<void> _saveRange() async {
    await LocalStorage.saveJson(_kRangeKey, range.name); // "day" | "week" | "year"
  }
  Future<void> _saveMode() async {
    await LocalStorage.saveJson(_kDisplayModeKey, _mode.name); // "points" | "ratio"
  }

  Future<void> _loadHistory() async {
    final raw = await LocalStorage.loadJson(_kHistoryKey, fallback: {});
    final map = <DateTime, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String) {
          // Schlüssel ist yyyy-MM-dd
          final parts = k.split('-');
          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              map[DateTime(y, m, d)] = (v as num).toInt();
            }
          }
        }
      });
    }

    // Fallback für HEUTE: falls noch kein Eintrag, aus Daily-Tasks summieren
    // *** NUR Tasks zählen, die keep == true UND done == true sind. ***
    final today = _midnight(DateTime.now());
    if (!map.containsKey(today)) {
      final tasksRaw = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
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
    final raw = await LocalStorage.loadJson(_kRatioHistoryKey, fallback: {});
    final map = <DateTime, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        if (k is String) {
          final parts = k.split('-');
          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              map[DateTime(y, m, d)] = (v as num).toInt();
            }
          }
        }
      });
    }

    // Heutiges Verhältnis (nur keep-Tasks): donePts / totalPts in Prozent
    final today = _midnight(DateTime.now());
    final tasksRaw = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
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
    await LocalStorage.saveJson(
      _kRatioHistoryKey,
      // Speichern als yyyy-MM-dd -> Prozent
      {
        for (final entry in map.entries)
          "${entry.key.year.toString().padLeft(4, '0')}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}": entry.value,
      },
    );

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
    final now = DateTime.now();
    final today = _midnight(now);

    switch (range) {
      case Range.day:
      // Tagesansicht: ein Wert für heute – als flache 24h-Linie darstellen,
      // KPIs werden separat korrekt berechnet.
        final value = _history[today] ?? 0;
        final start = DateTime(now.year, now.month, now.day, 0);
        return List.generate(24, (h) => ActivityPoint(start.add(Duration(hours: h)), value));

      case Range.week:
        final start = today.subtract(const Duration(days: 6));
        return _sequence(start, today);

      case Range.year:
        final start = today.subtract(const Duration(days: 364));
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
    final now = DateTime.now();
    final today = _midnight(now);

    switch (range) {
      case Range.day:
        final value = _ratioHistory[today] ?? 0;
        final start = DateTime(now.year, now.month, now.day, 0);
        return List.generate(24, (h) => ActivityPoint(start.add(Duration(hours: h)), value));
      case Range.week:
        final start = today.subtract(const Duration(days: 6));
        return _ratioSequence(start, today);
      case Range.year:
        final start = today.subtract(const Duration(days: 364));
        return _ratioSequence(start, today);
    }
  }

  String _rangeLabel(Range r) => r == Range.day ? 'Day' : r == Range.week ? 'Week' : 'Year';

  /// KPIs korrekt berechnen (bei Range.day NICHT 24x zählen)
  int _sumForRange(List<ActivityPoint> data) {
    if (range == Range.day) {
      // Tageswert = heutiger Tagespunkt
      final today = _midnight(DateTime.now());
      return _history[today] ?? 0;
    }
    return data.fold<int>(0, (s, p) => s + p.value);
  }

  String _avgLabel(List<ActivityPoint> data) {
    if (data.isEmpty) return '-';
    if (range == Range.day) {
      final v = _sumForRange(data);
      return v.toStringAsFixed(0);
    }
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
    if (range == Range.day) {
      return _currentRatioLabel();
    }
    final avg = data.fold<int>(0, (s, p) => s + p.value) / data.length;
    return '${avg.toStringAsFixed(1)}%';
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
      await LocalStorage.saveJson(_kHistoryKey, <String, dynamic>{});
      await LocalStorage.saveJson(_kRatioHistoryKey, <String, dynamic>{});
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
                          child: SfCartesianChart(
                            zoomPanBehavior: _zoom,
                            trackballBehavior: _trackball,
                            primaryXAxis: DateTimeAxis(
                              intervalType: range == Range.year
                                  ? DateTimeIntervalType.months
                                  : range == Range.week
                                  ? DateTimeIntervalType.days
                                  : DateTimeIntervalType.hours,
                              majorGridLines: const MajorGridLines(width: 0),
                            ),
                            primaryYAxis: NumericAxis(
                              title: AxisTitle(text: _mode == DisplayMode.ratio ? 'Ratio (%)' : 'Points'),
                              majorGridLines: const MajorGridLines(width: 0.5),
                            ),
                            legend: const Legend(isVisible: false),
                            series: <CartesianSeries<ActivityPoint, DateTime>>[
                              SplineSeries<ActivityPoint, DateTime>(
                                dataSource: data,
                                xValueMapper: (p, _) => p.t,
                                yValueMapper: (p, _) => p.value,
                                name: _mode == DisplayMode.ratio ? 'Ratio' : 'Points',
                                color: const Color(0xFFE53935),
                                width: 3,
                                markerSettings: const MarkerSettings(
                                  isVisible: true,
                                  height: 8,
                                  width: 8,
                                  color: Color(0xFFE53935),
                                  borderColor: Colors.white,
                                  borderWidth: 2,
                                ),
                              ),
                            ],
                          ),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
              label: 'Day',
              icon: Icons.today,
              isSelected: range == Range.day,
              onTap: () async {
                setState(() => range = Range.day);
                await _saveRange();
              },
            ),
          ),
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
