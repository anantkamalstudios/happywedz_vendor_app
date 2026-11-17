// Overview tab (website dashboard/OverviewTab.jsx): views, calls, website
// clicks and direction requests (performance) with the period before, a daily
// chart, and the profile's rating and review count (overview). A figure
// Google did not give shows "Not available yet", never 0.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/app_shimmer.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'overview_chart.dart';
import 'review_format.dart';

const List<int> _periods = [7, 30, 90];

class _Figure {
  final String key;
  final String label;
  final String hint;
  final IconData icon;
  const _Figure(this.key, this.label, this.hint, this.icon);
}

const List<_Figure> _figures = [
  _Figure('views', 'Views', 'Times your profile was shown on Google Search and Maps',
      Icons.visibility_outlined),
  _Figure('calls', 'Calls', 'Calls from your profile', Icons.phone_outlined),
  _Figure('website_actions', 'Website clicks', 'Clicks to your website',
      Icons.ads_click_outlined),
  _Figure('direction_requests', 'Direction requests', 'Requests for directions',
      Icons.place_outlined),
];

/// Why Google's numbers are not available (GrowthOS GOOGLE_BLOCKS).
const Map<String, String> _blockWords = {
  'google_not_connected':
      "Google isn't connected, so there are no numbers to show yet.",
  'google_no_location':
      'No Google profile is linked yet, so there are no numbers to show.',
  'google_not_configured':
      'Google numbers are switched off right now. Please try again later.',
  'google_unverified': 'Google shows numbers once your profile is verified.',
};

class _Trend {
  final String dir; // up | down | flat
  final String text;
  const _Trend(this.dir, this.text);
}

/// "+12% vs previous 30 days", in words, with a direction for the arrow.
_Trend? _comparison(Map<String, dynamic>? metric, int days) {
  final span = 'previous $days days';
  if (metric == null || !rvIsNumber(metric['value'])) return null;
  final value = metric['value'] as num;
  final previous = metric['previous'];
  if (!rvIsNumber(previous)) {
    return _Trend('flat', 'No numbers for the $span to compare');
  }
  final prev = previous as num;
  if (value == prev) return _Trend('flat', 'Same as the $span');
  if (prev == 0) return _Trend('up', 'Up from 0 in the $span');
  // Math.round rounds halves up (towards +∞).
  final pct = (((value - prev) / prev) * 100 + 0.5).floor();
  if (pct == 0) {
    return _Trend(value > prev ? 'up' : 'down', 'About the same as the $span');
  }
  return _Trend(pct > 0 ? 'up' : 'down',
      '${pct > 0 ? '+' : '−'}${pct.abs()}% vs $span');
}

/// A small loader (website OverviewLoad): keeps the last data while a newer
/// request runs, and ignores answers that arrive after a newer request.
class _Loader {
  String status = 'loading'; // loading | ready | error
  Map<String, dynamic>? data;
  Object? error;
  int request = 0;
}

class GpOverviewTab extends StatefulWidget {
  final Map<String, dynamic> view;
  final void Function(String tabId) onOpenTab;
  final VoidCallback onChanged;

  const GpOverviewTab({
    super.key,
    required this.view,
    required this.onOpenTab,
    required this.onChanged,
  });

  @override
  State<GpOverviewTab> createState() => _GpOverviewTabState();
}

class _GpOverviewTabState extends State<GpOverviewTab> {
  final _api = GoogleProfileApi.instance;
  int _days = 30;
  final _perf = _Loader();
  final _overview = _Loader();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _loadPerformance();
    _loadOverview();
    _started = true;
  }

  Future<void> _run(_Loader l, Future<dynamic> Function() call) async {
    final id = ++l.request;
    l.status = 'loading';
    l.error = null;
    if (_started) setState(() {});
    try {
      final data = await call();
      if (!mounted || l.request != id) return;
      setState(() {
        l.status = 'ready';
        l.data = data is Map ? Map<String, dynamic>.from(data) : null;
      });
    } catch (e) {
      if (!mounted || l.request != id) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        l.status = 'error';
        l.data = null;
        l.error = e;
      });
    }
  }

  Future<void> _loadPerformance() => _run(_perf, () => _api.performance(_days));
  Future<void> _loadOverview() => _run(_overview, () => _api.overview());

  void _chooseDays(int d) {
    if (d == _days) return;
    setState(() => _days = d);
    _loadPerformance();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => Future.wait([_loadPerformance(), _loadOverview()]),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          const Text('How people found you on Google', style: GpText.h3),
          const SizedBox(height: 4),
          const Text('These numbers come from your Google Business Profile.',
              style: GpText.note),
          const SizedBox(height: 12),
          RvSegments(
            ids: _periods.map((d) => '$d').toList(),
            labels: _periods.map((d) => '$d days').toList(),
            selected: '$_days',
            onSelect: (id) => _chooseDays(int.parse(id)),
          ),
          const SizedBox(height: 14),
          _performance(),
          const SizedBox(height: 4),
          _ratingCard(),
        ],
      ),
    );
  }

  // ── Performance ─────────────────────────────────────────────────────────

  Widget _performance() {
    final data = _perf.data;
    if (_perf.status == 'loading' && data == null) {
      return Semantics(
        label: 'Loading your Google numbers…',
        child: AppShimmer(
          child: Column(children: [
            for (var i = 0; i < _figures.length; i++)
              ShimmerBox(
                  height: 104,
                  radius: 14,
                  margin: const EdgeInsets.only(bottom: 12)),
          ]),
        ),
      );
    }
    if (_perf.status == 'error') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GpLoadError(
          message: gpErrorMessage(_perf.error,
              "We couldn't load your Google numbers. Please try again."),
          onRetry: _loadPerformance,
        ),
      );
    }
    final google = data?['google'];
    if (google is Map && google['available'] == false) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GpCallout(
          tone: GpTone.warn,
          text: _blockWords[str(google['reason'])] ??
              "Google's numbers aren't available yet.",
        ),
      );
    }
    final period = data?['period'];
    final metrics = data?['metrics'];
    if (period is! Map || metrics is! Map) {
      return const GpCard(
        child: GpEmpty(
          icon: Icons.insights_outlined,
          title: 'No numbers yet',
          message:
              'Google sends its numbers once a day, and they are a few days behind. Check back tomorrow.',
        ),
      );
    }

    final shownDays =
        rvIsNumber(period['days']) ? (period['days'] as num).toInt() : _days;
    final busy = _perf.status == 'loading';
    final synced = str(data?['synced_at']);
    return AnimatedOpacity(
      opacity: busy ? 0.55 : 1,
      duration: const Duration(milliseconds: 150),
      child: IgnorePointer(
        ignoring: busy,
        child: GpStack(gap: 12, children: [
          if (busy) const LinearProgressIndicator(minHeight: 2),
          Text(
            '${rvFormatDay(period['from'], true)} – ${rvFormatDay(period['to'], true)} '
            "(Google's newest day), compared with the $shownDays days before."
            '${synced.isNotEmpty ? ' Updated ${formatWhen(synced)}.' : ''}',
            style: GpText.note,
          ),
          for (final f in _figures)
            _FigureCard(
                figure: f,
                metric: metrics[f.key] is Map
                    ? Map<String, dynamic>.from(metrics[f.key])
                    : null,
                days: shownDays),
          OverviewChart(
            key: ValueKey('${period['from']}:${period['to']}'),
            daily: listOf(data?['daily']),
          ),
        ]),
      ),
    );
  }

  // ── Rating ──────────────────────────────────────────────────────────────

  Widget _ratingCard() {
    final profile = mapOf(_overview.data?['profile']);
    final rating =
        rvIsNumber(profile['rating']) ? (profile['rating'] as num) : null;
    final reviews =
        rvIsNumber(profile['reviews']) ? (profile['reviews'] as num) : null;

    Widget body;
    if (_overview.status == 'loading') {
      body = const GpLoadingLine('Loading your rating…');
    } else if (_overview.status == 'error') {
      body = GpLoadError(
        message: gpErrorMessage(
            _overview.error, "We couldn't load your rating. Please try again."),
        onRetry: _loadOverview,
      );
    } else if (rating != null) {
      body = Row(children: [
        Text(rating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(width: 12),
        Expanded(
          child: GpStack(gap: 4, children: [
            ReviewStars(rating: rating, size: 18),
            Text(
              'out of 5 · ${reviews != null ? rvPlural(reviews, 'review', 'reviews') : 'review count not available yet'}',
              style: GpText.muted,
            ),
          ]),
        ),
      ]);
    } else {
      body = GpStack(gap: 4, children: [
        const Text('Not available yet',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textTertiary)),
        Text(
          reviews != null
              ? rvPlural(reviews, 'review', 'reviews')
              : "Google hasn't shared your rating yet.",
          style: GpText.muted,
        ),
      ]);
    }

    return GpCard(
      child: GpStack(gap: 12, children: [
        const Text('Your rating on Google', style: GpText.h3),
        body,
        GpButton(
          label: 'See and answer reviews',
          onPressed: () => widget.onOpenTab('reviews'),
        ),
      ]),
    );
  }
}

class _FigureCard extends StatelessWidget {
  final _Figure figure;
  final Map<String, dynamic>? metric;
  final int days;
  const _FigureCard(
      {required this.figure, required this.metric, required this.days});

  @override
  Widget build(BuildContext context) {
    final known = metric != null && rvIsNumber(metric!['value']);
    final trend = known ? _comparison(metric, days) : null;
    final trendColor = trend == null
        ? AppColors.textSecondary
        : trend.dir == 'up'
            ? AppColors.success
            : trend.dir == 'down'
                ? AppColors.error
                : AppColors.textSecondary;
    final trendIcon = trend == null
        ? null
        : trend.dir == 'up'
            ? Icons.north_east
            : trend.dir == 'down'
                ? Icons.south_east
                : Icons.remove;
    return GpCard(
      margin: EdgeInsets.zero,
      child: GpStack(gap: 6, children: [
        Row(children: [
          Icon(figure.icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(figure.label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
        ]),
        known
            ? Text(rvNumber(metric!['value'] as num),
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary))
            : const Text('Not available yet',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary)),
        if (trend != null)
          Row(children: [
            Icon(trendIcon, size: 14, color: trendColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(trend.text,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: trendColor)),
            ),
          ]),
        Text(figure.hint, style: GpText.note),
      ]),
    );
  }
}
