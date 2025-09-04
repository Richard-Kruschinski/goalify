import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../storage/local_storage.dart';

enum Range { day, week, year }

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

  Range range = Range.week;                 // wird beim Laden aus Prefs überschrieben
  Map<DateTime, int> _history = {};         // Mitternacht -> Punkte

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
    await _loadHistory();
    if (mounted) setState(() {});
  }

  Future<void> _saveRange() async {
    await LocalStorage.saveJson(_kRangeKey, range.name); // "day" | "week" | "year"
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

    // Fallback für HEUTE: falls noch kein Eintrag, aus Daily-Tasks summieren (nur Anzeige, kein Persist)
    final today = _midnight(DateTime.now());
    if (!map.containsKey(today)) {
      final tasksRaw = await LocalStorage.loadJson(_kDailyTasksKey, fallback: []);
      if (tasksRaw is List) {
        int todayPts = 0;
        for (final e in tasksRaw) {
          final m = Map<String, dynamic>.from(e as Map);
          final done = (m['done'] ?? false) as bool;
          final pts = (m['points'] ?? 1) as int;
          if (done) todayPts += pts;
        }
        map[today] = todayPts; // nur für Anzeige
      }
    }

    _history = map;
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
      // aber KPIs berechnen wir separat korrekt (ohne *24).
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

  String _rangeLabel(Range r) => r == Range.day ? 'Tag' : r == Range.week ? 'Woche' : 'Jahr';

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

  Future<void> _confirmClearHistory() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Progress zurücksetzen?'),
        content: const Text('Alle gespeicherten Tagespunkte werden gelöscht. Dies kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (ok == true) {
      await LocalStorage.saveJson(_kHistoryKey, <String, dynamic>{});
      _history.clear();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _dataForRange();
    final sum = _sumForRange(data);
    final avg = _avgLabel(data);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        actions: [
          IconButton(
            tooltip: 'Neu laden',
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'clear') _confirmClearHistory();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'clear', child: Text('Clear history')),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<Range>(
              segments: const [
                ButtonSegment(value: Range.day, label: Text('Tag')),
                ButtonSegment(value: Range.week, label: Text('Woche')),
                ButtonSegment(value: Range.year, label: Text('Jahr')),
              ],
              selected: {range},
              onSelectionChanged: (s) async {
                setState(() => range = s.first);
                await _saveRange();
              },
            ),
            const SizedBox(height: 12),

            Expanded(
              child: Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
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
                    primaryYAxis: const NumericAxis(
                      title: AxisTitle(text: 'Punkte'),
                      majorGridLines: MajorGridLines(width: 0.5),
                    ),
                    legend: const Legend(isVisible: false),
                    series: <CartesianSeries<ActivityPoint, DateTime>>[
                      SplineSeries<ActivityPoint, DateTime>(
                        dataSource: data,
                        xValueMapper: (p, _) => p.t,
                        yValueMapper: (p, _) => p.value,
                        name: 'Punkte',
                        width: 2,
                        markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _metricCard('Aktuelle ${_rangeLabel(range)}', '$sum Pkt')),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('Ø pro Tag', avg)),
              ],
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
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
