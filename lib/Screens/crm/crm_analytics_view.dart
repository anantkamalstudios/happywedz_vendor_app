import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import 'crm_widgets.dart';

/// CRM → Analytics, as on the web (`ja`): period pills or custom dates, the
/// four KPIs compared with the period before, the stage funnel, why work is
/// lost, the team table and which sources actually book.
class CrmAnalyticsView extends StatefulWidget {
  const CrmAnalyticsView({super.key});

  @override
  State<CrmAnalyticsView> createState() => _CrmAnalyticsViewState();
}

class _CrmAnalyticsViewState extends State<CrmAnalyticsView> {
  static final _ymd = DateFormat('yyyy-MM-dd');
  static const _funnelColors = {
    'lead': AppColors.info,
    'quoted': Color(0xFF6D28D9),
    'booked': AppColors.success,
    'completed': AppColors.textSecondary,
  };

  String _preset = 'year';
  late String _from;
  late String _to;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _applyPreset('year', load: false);
    _load();
  }

  /// This month / last 3 months / this financial year (from 1 April).
  void _applyPreset(String id, {bool load = true}) {
    final now = DateTime.now();
    final to = _ymd.format(now);
    final from = switch (id) {
      'month' => _ymd.format(DateTime(now.year, now.month, 1)),
      'quarter' => _ymd.format(DateTime(now.year, now.month - 3, now.day)),
      _ => '${now.month >= 4 ? now.year : now.year - 1}-04-01',
    };
    setState(() {
      _preset = id;
      _from = from;
      _to = to;
    });
    if (load) _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await CrmApi().analytics(_from, _to);
      if (mounted) setState(() => _data = res);
    } on CrmException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not work out your numbers.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _pct(dynamic v) => v == null ? '—' : '$v%';

  /// "3 more than the period before" / "Same as the period before".
  Widget _delta(
    num? value,
    num? before, {
    String kind = 'count',
    bool goodWhenLower = false,
  }) {
    if (value == null || before == null) return const SizedBox();
    final diff = ((value - before) * 10).round() / 10;
    if (diff == 0) {
      return const Text(
        'Same as the period before',
        style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
      );
    }
    final good = goodWhenLower ? diff < 0 : diff > 0;
    final abs = diff.abs();
    final amount = kind == 'money'
        ? CrmFormat.rupees(abs)
        : kind == 'percent'
        ? '${abs % 1 == 0 ? abs.toInt() : abs} points'
        : '${abs % 1 == 0 ? abs.toInt() : abs}';
    final color = good ? AppColors.success : AppColors.warning;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          diff > 0 ? Icons.trending_up : Icons.trending_down,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            '$amount ${diff > 0 ? 'more' : 'less'} than the period before',
            style: TextStyle(fontSize: 11, color: color),
          ),
        ),
      ],
    );
  }

  num? _v(Map k, String key, [String field = 'value']) =>
      (k[key] as Map?)?[field] as num?;

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: crmCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in const [
                    ('month', 'This month'),
                    ('quarter', 'Last 3 months'),
                    ('year', 'This financial year'),
                  ])
                    ChoiceChip(
                      label: Text(p.$2),
                      selected: _preset == p.$1,
                      onSelected: (_) => _applyPreset(p.$1),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CrmDateInput(
                      value: _from,
                      clearable: false,
                      lastDate: CrmFormat.parseDate(_to),
                      onChanged: (v) {
                        setState(() {
                          _preset = 'custom';
                          _from = v;
                        });
                        _load();
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('to'),
                  ),
                  Expanded(
                    child: CrmDateInput(
                      value: _to,
                      clearable: false,
                      firstDate: CrmFormat.parseDate(_from),
                      onChanged: (v) {
                        setState(() {
                          _preset = 'custom';
                          _to = v;
                        });
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loading && d == null)
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Center(
            child: Column(
              children: [
                Text(_error!),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          )
        else if (d != null) ...[
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          ..._content(d),
        ],
      ],
    );
  }

  List<Widget> _content(Map<String, dynamic> d) {
    final k = (d['kpis'] as Map?) ?? const {};
    final leads = (_v(k, 'leads') ?? 0).toInt();
    final booked = (_v(k, 'booked') ?? 0).toInt();
    final days = _v(k, 'daysToBook');
    final daysBefore = _v(k, 'daysToBook', 'before');
    final funnel = List.from(d['funnel'] ?? const []);
    final reasons = List.from(d['lostReasons'] ?? const []);
    final sources = List.from(d['sources'] ?? const []);
    final team = d['hasTeam'] == true
        ? List.from(d['team'] ?? const [])
        : const [];
    final range = (d['range'] as Map?) ?? const {};
    final funnelMax = math.max(
      1,
      funnel.fold<int>(
        0,
        (m, f) => math.max(m, ((f['count'] as num?) ?? 0).toInt()),
      ),
    );
    final reasonMax = math.max(
      1,
      reasons.fold<int>(
        0,
        (m, r) => math.max(m, ((r['count'] as num?) ?? 0).toInt()),
      ),
    );

    Widget kpi(String label, String value, Widget note, {Color? color}) =>
        Container(
          padding: const EdgeInsets.all(12),
          decoration: crmCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              note,
            ],
          ),
        );

    Widget pair(Widget a, Widget b) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: a),
            const SizedBox(width: 10),
            Expanded(child: b),
          ],
        ),
      ),
    );

    Widget bar(double fraction, Color color) => ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fraction.clamp(0, 1),
        minHeight: 8,
        backgroundColor: AppColors.inputFill,
        color: color,
      ),
    );

    Widget card(
      String title,
      String sub,
      List<Widget> children, {
      int? count,
    }) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (count != null && count > 0)
                Text(
                  '$count',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );

    Widget rateTable(List rows, String firstHeader) {
      TextStyle head = const TextStyle(
        fontSize: 11,
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      );
      return Column(
        children: [
          Row(
            children: [
              Expanded(flex: 3, child: Text(firstHeader, style: head)),
              Expanded(
                flex: 2,
                child: Text('Clients', textAlign: TextAlign.right, style: head),
              ),
              Expanded(
                flex: 2,
                child: Text('Booked', textAlign: TextAlign.right, style: head),
              ),
              Expanded(
                flex: 2,
                child: Text('Rate', textAlign: TextAlign.right, style: head),
              ),
              Expanded(
                flex: 3,
                child: Text('Value', textAlign: TextAlign.right, style: head),
              ),
            ],
          ),
          const Divider(),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${r['name'] ?? r['label']}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${r['leads'] ?? 0}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${r['booked'] ?? 0}',
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _pct(r['rate']),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: ((r['rate'] as num?) ?? -1) >= 40
                            ? AppColors.success
                            : r['rate'] == 0
                            ? AppColors.warning
                            : null,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      ((r['valuePaise'] as num?) ?? 0) > 0
                          ? CrmFormat.rupees(r['valuePaise'])
                          : '—',
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }

    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          '${CrmFormat.date(range['from'])} – ${CrmFormat.date(range['to'])}',
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ),
      if (d['thin'] == true)
        CrmNotice(
          'Only $leads client${leads == 1 ? '' : 's'} came in during this period, so the '
          'percentages below move a lot with each one. Pick a longer period to see a truer picture.',
          warn: false,
        ),
      pair(
        kpi(
          'New clients',
          '$leads',
          _delta(_v(k, 'leads'), _v(k, 'leads', 'before')),
        ),
        kpi(
          'Turned into bookings',
          _pct(_v(k, 'conversion')),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$booked of $leads',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              _delta(
                _v(k, 'conversion'),
                _v(k, 'conversion', 'before'),
                kind: 'percent',
              ),
            ],
          ),
          color: AppColors.primary,
        ),
      ),
      pair(
        kpi(
          'Days from enquiry to booking',
          days == null ? '—' : (days == 0 ? 'Same day' : '$days'),
          days == null
              ? const Text(
                  'No bookings closed in this period',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                )
              : daysBefore == null
              ? Text(
                  'Across $booked booking${booked == 1 ? '' : 's'} closed in this period',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                )
              : _delta(days, daysBefore, goodWhenLower: true),
        ),
        kpi(
          'Booked value',
          CrmFormat.rupees(_v(k, 'bookedValuePaise')),
          Text(
            '${booked > 1 ? '${CrmFormat.rupees(_v(k, 'averageBookingPaise'))} on average · ' : ''}'
            '${CrmFormat.rupees(_v(k, 'collectedPaise'))} collected in this period',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          color: AppColors.success,
        ),
      ),
      card(
        leads == 1
            ? 'Where this client got to'
            : 'Where these $leads clients got to',
        'Every client who came in between ${CrmFormat.date(range['from'])} and '
        '${CrmFormat.date(range['to'])}, and the furthest stage they reached.',
        leads == 0
            ? [
                const Text(
                  'No clients came in during this period',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const Text(
                  'Try a longer period, or add the enquiries you are working on.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ]
            : [
                for (final f in funnel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              '${f['label']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${f['count']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (f['rateFromPrevious'] != null)
                              Text(
                                '· ${_pct(f['rateFromPrevious'])} of the step before',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        bar(
                          ((f['count'] as num?) ?? 0) / funnelMax,
                          _funnelColors[f['id']] ?? AppColors.textSecondary,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (((f['lostBefore'] as num?) ?? 0) > 0)
                              Text(
                                '${f['lostBefore']} lost',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.error,
                                ),
                              ),
                            if (((f['stillOpen'] as num?) ?? 0) > 0)
                              Text(
                                '${f['stillOpen']} still going',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            Text(
                              CrmFormat.rupees(f['valuePaise']),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
      ),
      card(
        'Why work is lost',
        'From the reason picked when a client is moved to Lost or Cancelled.',
        count: ((d['lostCount'] as num?) ?? 0).toInt(),
        reasons.isEmpty
            ? [
                const Text(
                  'Nothing lost in this period',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ]
            : [
                for (final r in reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text('${r['label']}')),
                            Text(
                              '${r['count']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        bar(
                          ((r['count'] as num?) ?? 0) / reasonMax,
                          AppColors.error,
                        ),
                        Text(
                          CrmFormat.rupees(r['valuePaise']),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                CrmNotice(
                  '${CrmFormat.rupees(d['lostValuePaise'])} of work went elsewhere in this period.',
                  warn: false,
                ),
              ],
      ),
      if (team.isNotEmpty)
        card(
          'How the team is doing',
          'The clients each person was carrying, for the clients who came in during this period.',
          [rateTable(team, 'Member')],
        ),
      card(
        'Which sources actually book',
        'The lead source on each client, for the clients who came in during this period.',
        sources.isEmpty
            ? [
                const Text(
                  'Nothing to compare yet',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ]
            : [rateTable(sources, 'Source')],
      ),
    ];
  }
}
