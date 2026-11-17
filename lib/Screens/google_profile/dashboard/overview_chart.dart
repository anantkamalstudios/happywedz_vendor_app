// The daily chart on the Overview tab (website dashboard/OverviewChart.jsx):
// one figure at a time as bars, a readout for the touched day (or the total
// and the best day), and a table of every day. Data: performance.daily.
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'review_format.dart';

class _Series {
  final String key;
  final String label;
  final String one;
  final String many;
  const _Series(this.key, this.label, this.one, this.many);
}

const List<_Series> _series = [
  _Series('views', 'Views', 'view', 'views'),
  _Series('calls', 'Calls', 'call', 'calls'),
  _Series('website_actions', 'Website clicks', 'website click', 'website clicks'),
  _Series('direction_requests', 'Direction requests', 'direction request',
      'direction requests'),
];

String _amount(num n, _Series s) => '${rvNumber(n)} ${n == 1 ? s.one : s.many}';

num _valueOf(Object? day, String key) {
  final v = day is Map ? day[key] : null;
  return (v is num && v.isFinite) ? v : 0;
}

class OverviewChart extends StatefulWidget {
  final List<dynamic> daily;
  const OverviewChart({super.key, required this.daily});

  @override
  State<OverviewChart> createState() => _OverviewChartState();
}

class _OverviewChartState extends State<OverviewChart> {
  String _seriesKey = 'views';
  int? _active;
  bool _tableOpen = false;

  @override
  Widget build(BuildContext context) {
    final series =
        _series.firstWhere((s) => s.key == _seriesKey, orElse: () => _series.first);
    final days = widget.daily.map(mapOf).toList();

    if (days.isEmpty) {
      return GpCard(
        child: GpStack(gap: 8, children: const [
          Text('Day by day', style: GpText.h3),
          Text("Google hasn't sent daily numbers for this period yet.",
              style: GpText.note),
        ]),
      );
    }

    final values = days.map((d) => _valueOf(d, series.key)).toList();
    final total = values.fold<num>(0, (sum, v) => sum + v);
    final max = values.reduce(math.max);
    final peakIndex = values.indexOf(max);
    final first = rvFormatDay(days.first['date']);
    final last = rvFormatDay(days.last['date']);
    final summary = max == 0
        ? '${series.label} per day, $first to $last: none in this period.'
        : '${series.label} per day, $first to $last: ${_amount(total, series)} in total, most on ${rvFormatDay(days[peakIndex]['date'])} with ${rvNumber(max)}.';
    final shown = (_active != null && _active! < days.length) ? _active : null;
    final readout = shown != null
        ? '${rvFormatDay(days[shown]['date'], true)}: ${_amount(values[shown], series)}'
        : max == 0
            ? 'No ${series.many} in this period'
            : '${_amount(total, series)} in total · most on ${rvFormatDay(days[peakIndex]['date'])} (${rvNumber(max)})';

    return GpCard(
      child: GpStack(gap: 12, children: [
        Text('${series.label} per day', style: GpText.h3),
        RvSegments(
          ids: _series.map((s) => s.key).toList(),
          labels: _series.map((s) => s.label).toList(),
          selected: series.key,
          onSelect: (id) => setState(() {
            _seriesKey = id;
            _active = null;
          }),
        ),
        Text(readout,
            style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        Semantics(
          label: summary,
          child: ExcludeSemantics(
            child: _plot(values, max, shown, first, last),
          ),
        ),
        _table(days),
      ]),
    );
  }

  Widget _plot(List<num> values, num max, int? shown, String first, String last) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(rvNumber(max), style: GpText.note),
      const SizedBox(height: 4),
      SizedBox(
        height: 160,
        child: LayoutBuilder(builder: (context, box) {
          final slot = box.maxWidth / values.length;
          final barWidth = math.max(1.0, math.min(18.0, slot * 0.7));
          final top = max > 0 ? max.toDouble() : 1.0;
          return BarChart(
            BarChartData(
              minY: 0,
              maxY: top,
              alignment: BarChartAlignment.spaceAround,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                    bottom: BorderSide(color: AppColors.borderStrong)),
              ),
              titlesData: const FlTitlesData(show: false),
              barTouchData: BarTouchData(
                handleBuiltInTouches: false,
                touchExtraThreshold:
                    EdgeInsets.symmetric(horizontal: slot / 2, vertical: 200),
                // The touched day stays in the readout after the finger lifts.
                touchCallback: (event, response) {
                  final index = response?.spot?.touchedBarGroupIndex;
                  if (index != null && index != _active) {
                    setState(() => _active = index);
                  }
                },
              ),
              barGroups: [
                for (var i = 0; i < values.length; i++)
                  BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      // A day with any number shows at least a sliver.
                      toY: values[i] > 0
                          ? math.max(values[i].toDouble(), top * 0.02)
                          : 0,
                      width: barWidth,
                      color: shown == i ? AppColors.primaryDark : AppColors.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: shown == i,
                        toY: top,
                        color: AppColors.primaryTint,
                      ),
                    ),
                  ]),
              ],
            ),
            duration: Duration.zero,
          );
        }),
      ),
      const SizedBox(height: 6),
      Row(children: [
        Text(first, style: GpText.note),
        const Spacer(),
        Text(last, style: GpText.note),
      ]),
    ]);
  }

  Widget _table(List<Map<String, dynamic>> days) {
    const head = TextStyle(
        fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
    const cell = TextStyle(fontSize: 12.5, color: AppColors.textPrimary);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () => setState(() => _tableOpen = !_tableOpen),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_tableOpen ? Icons.expand_less : Icons.expand_more,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 4),
            const Text('See the numbers for each day',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ]),
        ),
      ),
      if (_tableOpen)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 36,
            dataRowMinHeight: 32,
            dataRowMaxHeight: 36,
            horizontalMargin: 8,
            columnSpacing: 18,
            columns: [
              const DataColumn(label: Text('Day', style: head)),
              for (final s in _series)
                DataColumn(numeric: true, label: Text(s.label, style: head)),
            ],
            rows: [
              for (final d in days)
                DataRow(cells: [
                  DataCell(Text(rvFormatDay(d['date'], true), style: head)),
                  for (final s in _series)
                    DataCell(Text(rvNumber(_valueOf(d, s.key)), style: cell)),
                ]),
            ],
          ),
        ),
    ]);
  }
}
