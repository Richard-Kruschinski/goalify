import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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

class _ProgressScreenState extends State<ProgressScreen> {
  Range range = Range.week;
  late final List<ActivityPoint> all; // Rohdaten (z. B. erledigte Tasks je Stunde/Tag)

  late ZoomPanBehavior _zoom;
  late TrackballBehavior _trackball;

  @override
  void initState() {
    super.initState();
    // Demo-Daten erzeugen: letzte 365 Tage, zufällige "Produktivität"
    final now = DateTime.now();
    all = List.generate(365, (i) {
      final d = now.subtract(Duration(days: 364 - i));
      final v = 1 + (3 * (0.5 + 0.5 * ( // simple noise
          (d.millisecondsSinceEpoch % 97) / 97.0
      ))).round();
      return ActivityPoint(d, v);
    });

    _zoom = ZoomPanBehavior(
      enablePinching: true,
      enablePanning: true,
      zoomMode: ZoomMode.x,
    );

    _trackball = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipAlignment: ChartAlignment.near,
      tooltipSettings: const InteractiveTooltip(format: 'point.x : point.y'),
    );
  }

  List<ActivityPoint> _filtered() {
    final now = DateTime.now();
    switch (range) {
      case Range.day:
        final dayStart = DateTime(now.year, now.month, now.day);
        // stündliche Punkte für *heute* aus weekly data gemappt
        return List.generate(24, (h) {
          final ts = dayStart.add(Duration(hours: h));
          final base = all.last.value;
          final mod = ((h * 37) % 5); // kleine Variation
          return ActivityPoint(ts, base - 2 + mod);
        });
      case Range.week:
        final weekStart = now.subtract(Duration(days: 6));
        return all.where((p) => p.t.isAfter(weekStart)).toList();
      case Range.year:
        return all; // ganze Historie zeigen
    }
  }

  String _rangeLabel(Range r) =>
      r == Range.day ? 'Tag' : r == Range.week ? 'Woche' : 'Jahr';

  @override
  Widget build(BuildContext context) {
    final data = _filtered();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Segmented Filter
            SegmentedButton<Range>(
              segments: const [
                ButtonSegment(value: Range.day, label: Text('Tag')),
                ButtonSegment(value: Range.week, label: Text('Woche')),
                ButtonSegment(value: Range.year, label: Text('Jahr')),
              ],
              selected: {range},
              onSelectionChanged: (s) => setState(() => range = s.first),
            ),
            const SizedBox(height: 12),

            // Karte mit Chart
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
                    primaryYAxis: NumericAxis(
                      title: AxisTitle(text: 'Punkte'),
                      majorGridLines: const MajorGridLines(width: 0.5),
                    ),
                    legend: const Legend(isVisible: false),
                    series: <CartesianSeries<ActivityPoint, DateTime>>[
                      SplineSeries<ActivityPoint, DateTime>(
                        dataSource: data,
                        xValueMapper: (p, _) => p.t,
                        yValueMapper: (p, _) => p.value,
                        name: 'Produktivität',
                        width: 2,
                        markerSettings: const MarkerSettings(isVisible: true, height: 6, width: 6),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // kleine KPI-Boxen (optional)
            Row(
              children: [
                Expanded(child: _metricCard('Aktuelle ${_rangeLabel(range)}', '${data.fold<int>(0, (s, p) => s + p.value)} Pkt')),
                const SizedBox(width: 12),
                Expanded(child: _metricCard('Ø pro Tag', _avgLabel(data))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _avgLabel(List<ActivityPoint> data) {
    if (data.isEmpty) return '-';
    final avg = data.fold<int>(0, (s, p) => s + p.value) / data.length;
    return avg.toStringAsFixed(1);
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
