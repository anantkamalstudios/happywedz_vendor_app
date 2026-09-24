import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import 'crm_widgets.dart';

/// CRM → Calendar, as on the web (`ca`): a Monday-first month grid with a dot
/// per event / follow-up / payment due, and the month's (or a tapped day's)
/// items listed underneath. Tapping an item opens its client.
class CrmCalendarView extends StatefulWidget {
  final void Function(dynamic clientId) onOpenClient;

  const CrmCalendarView({super.key, required this.onOpenClient});

  @override
  State<CrmCalendarView> createState() => _CrmCalendarViewState();
}

class _CrmCalendarViewState extends State<CrmCalendarView> {
  static final _ymd = DateFormat('yyyy-MM-dd');
  static const _typeLabels = {
    'event': 'Event',
    'follow_up': 'Follow-up',
    'payment_due': 'Payment due',
  };
  static const _typeColors = {
    'event': AppColors.primary,
    'follow_up': AppColors.info,
    'payment_due': AppColors.warning,
  };

  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List _items = [];
  bool _loading = true;
  String? _error;
  String? _selected;

  /// Monday before the 1st → Sunday after the last day, like the web grid.
  List<DateTime> get _days {
    final first = _month;
    final start = first.subtract(Duration(days: (first.weekday + 6) % 7));
    final last = DateTime(_month.year, _month.month + 1, 0);
    final end = last.add(Duration(days: 6 - (last.weekday + 6) % 7));
    return [
      for (
        var d = start;
        !d.isAfter(end);
        d = DateTime(d.year, d.month, d.day + 1)
      )
        d,
    ];
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final days = _days;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await CrmApi().calendar(
        _ymd.format(days.first),
        _ymd.format(days.last),
      );
      if (mounted) setState(() => _items = List.from(res['items'] ?? const []));
    } on CrmException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load the calendar.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _shift(int months) {
    setState(() {
      _selected = null;
      _month = DateTime(_month.year, _month.month + months);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final byDate = <String, List<Map>>{};
    for (final i in _items) {
      byDate.putIfAbsent('${i['date']}', () => []).add(i as Map);
    }
    final today = CrmFormat.today();
    final monthKey = DateFormat('yyyy-MM').format(_month);
    final monthName = DateFormat('MMMM yyyy').format(_month);
    final listed = _items
        .where(
          (i) => _selected != null
              ? i['date'] == _selected
              : '${i['date']}'.startsWith(monthKey),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: () => _shift(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monthName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: () => _shift(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final t in _typeLabels.entries) ...[
                CircleAvatar(radius: 4, backgroundColor: _typeColors[t.key]),
                const SizedBox(width: 4),
                Text(t.value, style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 10),
              ],
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selected = null;
                    _month = DateTime(
                      DateTime.now().year,
                      DateTime.now().month,
                    );
                  });
                  _load();
                },
                child: const Text('Today'),
              ),
            ],
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Text(_error!),
                    TextButton(
                      onPressed: _load,
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 6),
            Row(
              children: [
                for (final d in const [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ])
                  Expanded(
                    child: Center(
                      child: Text(
                        d,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 0.9,
              children: [for (final d in _days) _dayCell(d, byDate, today)],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selected != null
                        ? CrmFormat.date(_selected)
                        : 'All of $monthName',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_selected != null)
                  TextButton(
                    onPressed: () => setState(() => _selected = null),
                    child: const Text('Show whole month'),
                  ),
              ],
            ),
            if (listed.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Nothing scheduled.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            for (final i in listed) _row(i as Map),
          ],
        ],
      ),
    );
  }

  Widget _dayCell(DateTime d, Map<String, List<Map>> byDate, String today) {
    final key = _ymd.format(d);
    final items = byDate[key] ?? const [];
    final outside = d.month != _month.month;
    final isToday = key == today;
    final selected = key == _selected;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _selected = selected ? null : key),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTint : null,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: AppColors.primary) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${d.day}',
              style: TextStyle(
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: outside ? AppColors.textTertiary : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final i in items.take(4))
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: CircleAvatar(
                      radius: 2.5,
                      backgroundColor:
                          _typeColors[i['type']] ?? AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Map i) {
    final type = '${i['type']}';
    final extra = [
      if (type == 'event' && '${i['venue'] ?? ''}'.isNotEmpty) '${i['venue']}',
      if (type == 'payment_due') CrmFormat.rupees(i['amountPaise']),
      if (type == 'follow_up' && '${i['note'] ?? ''}'.isNotEmpty)
        '${i['note']}',
    ];
    return InkWell(
      onTap: () => widget.onOpenClient(i['clientId']),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: _typeColors[type],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: Text(
                CrmFormat.date(i['date']),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: type == 'event'
                          ? '${i['title']}'
                          : _typeLabels[type] ?? type,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: ' · ${i['clientName']}'),
                    for (final e in extra) TextSpan(text: ' · $e'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
