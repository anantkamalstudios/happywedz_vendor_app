// Reviews tab (website dashboard/ReviewsTab.jsx): Google reviews with stars
// and filters, unanswered first; AI draft, edit, publish (the vendor's Publish
// is the approval), edit or delete a published reply; Sync now. Shapes:
// GrowthOS ReviewsStatus, Review and the review list with
// meta { page, page_size, total, counts }. Never sample reviews.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'review_card.dart';
import 'review_format.dart';

/// What the tab shows (GrowthOS reviewsView): the list, or why there are no reviews.
String _viewOf(Map<String, dynamic>? status) {
  if (status == null) return 'loading';
  if ((numOf(status['total_reviews']) ?? 0) > 0) return 'list';
  if (status['google_connected'] != true) return 'disconnected';
  if (status['sync_available'] != true) return 'waiting';
  return 'empty';
}

class _Words {
  final String title;
  final String body;
  final IconData icon;
  const _Words(this.title, this.body, this.icon);
}

const Map<String, _Words> _emptyWords = {
  'disconnected': _Words(
    "Google isn't connected",
    'Reviews come from your Google Business Profile. They appear here once your profile is connected.',
    Icons.link_off,
  ),
  'waiting': _Words(
    'Waiting for Google to verify your profile',
    'Google reviews can be read once your profile is verified. They appear here after that.',
    Icons.hourglass_empty,
  ),
  'empty': _Words(
    'No reviews yet',
    'When people review you on Google, their reviews appear here, and you can answer them.',
    Icons.rate_review_outlined,
  ),
};

/// The automatic check on opening runs when the last sync is older than this
/// (GrowthOS allows one every 5 minutes).
const Duration _autoSyncAfter = Duration(minutes: 5);

String _numberSafe(Object? n) =>
    (n is num && n.isFinite) ? rvNumber(n) : '';

class GpReviewsTab extends StatefulWidget {
  final Map<String, dynamic> view;
  final void Function(String tabId) onOpenTab;
  final VoidCallback onChanged;

  const GpReviewsTab({
    super.key,
    required this.view,
    required this.onOpenTab,
    required this.onChanged,
  });

  @override
  State<GpReviewsTab> createState() => _GpReviewsTabState();
}

class _GpReviewsTabState extends State<GpReviewsTab> {
  final _api = GoogleProfileApi.instance;
  bool _started = false;

  // Reviews status (website useOverviewLoad: keeps its data while reloading).
  String _stStatus = 'loading';
  Map<String, dynamic>? _info;
  Object? _stError;
  int _stRequest = 0;

  // The list.
  String _filter = 'all';
  int _reload = 0;
  String? _listKey;
  String _listStatus = 'idle'; // idle | loading | ready | error
  String? _listFilter;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _meta;
  Object? _listError;
  int _request = 0;

  // Load more.
  bool _moreBusy = false;
  RvErrorInfo? _moreError;

  // Sync now.
  bool _syncBusy = false;
  bool _syncQuiet = false;
  RvErrorInfo? _syncError;
  String _syncNotice = '';
  bool _autoSynced = false;

  String get _view => _stStatus == 'error' ? 'error' : _viewOf(_info);

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _started = true;
  }

  // ── Loading ─────────────────────────────────────────────────────────────

  Future<void> _loadStatus() async {
    final id = ++_stRequest;
    _stStatus = 'loading';
    _stError = null;
    if (_started) setState(() {});
    try {
      final data = await _api.reviewsStatus();
      if (!mounted || id != _stRequest) return;
      setState(() {
        _stStatus = 'ready';
        _info = data is Map ? Map<String, dynamic>.from(data) : null;
      });
    } catch (e) {
      if (!mounted || id != _stRequest) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _stStatus = 'error';
        _info = null;
        _stError = e;
      });
    }
    _afterChange();
  }

  /// The website's effects: page 1 of the chosen filter whenever the view,
  /// the filter or the reload count changes; and the one automatic sync.
  void _afterChange() {
    if (!mounted) return;
    final view = _view;
    final key = '$view|$_filter|$_reload';
    if (key != _listKey) {
      _listKey = key;
      if (view == 'list') _loadList();
    }

    final info = _info;
    if (!_autoSynced &&
        _stStatus == 'ready' &&
        info != null &&
        info['sync_available'] == true) {
      _autoSynced = true;
      final last = gpDate(info['last_synced_at']);
      if (last == null || DateTime.now().difference(last) > _autoSyncAfter) {
        _syncNow(quiet: true);
      }
    }
  }

  Future<void> _loadList() async {
    final id = ++_request;
    final filter = _filter;
    setState(() {
      _listStatus = 'loading';
      _listError = null;
      _moreBusy = false;
      _moreError = null;
    });
    try {
      final page =
          await _api.reviews(filter: filter, page: 1, pageSize: rvPageSize);
      if (!mounted || _request != id) return;
      setState(() {
        _listStatus = 'ready';
        _listFilter = filter;
        _items = page.list.map(mapOf).toList();
        _meta = page.meta;
        _listError = null;
      });
    } catch (e) {
      if (!mounted || _request != id) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _listStatus = 'error';
        _listFilter = filter;
        _items = [];
        _meta = null;
        _listError = e;
      });
    }
  }

  Future<void> _loadMore() async {
    final id = _request;
    final nextPage = ((numOf(_meta?['page']) ?? 1).toInt()) + 1;
    setState(() {
      _moreBusy = true;
      _moreError = null;
    });
    try {
      final page = await _api.reviews(
          filter: _filter, page: nextPage, pageSize: rvPageSize);
      if (!mounted || _request != id) return;
      final fresh = page.list.map(mapOf).toList();
      setState(() {
        final known = _items.map((r) => str(r['id'])).toSet();
        final added = fresh.where((r) => !known.contains(str(r['id'])));
        _items = [..._items, ...added];
        _meta = page.meta ?? _meta;
        _moreBusy = false;
      });
    } catch (e) {
      if (!mounted || _request != id) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _moreBusy = false;
        _moreError = rvErrorInfo(e);
      });
    }
  }

  /// [quiet]: the automatic check when the tab opens — it only speaks up when
  /// new reviews came in, and a refusal (e.g. the 5-minute limit) is not
  /// shown; the list already on screen stays.
  Future<void> _syncNow({bool quiet = false}) async {
    setState(() {
      _syncBusy = true;
      _syncQuiet = quiet;
      _syncError = null;
      _syncNotice = '';
    });
    try {
      final result = await _api.syncReviews();
      if (!mounted) return;
      final r = mapOf(result);
      final found = r['new_reviews'] is num ? r['new_reviews'] as num : null;
      final drafted = r['drafted'] is num ? r['drafted'] as num : 0;
      var notice = found == null
          ? 'Synced with Google.'
          : found == 0
              ? 'Synced. No new reviews.'
              : 'Synced. ${rvPlural(found, 'new review', 'new reviews')}.';
      if (drafted > 0) {
        notice +=
            ' AI wrote ${rvPlural(drafted, 'draft reply', 'draft replies')} for you to check.';
      }
      if (quiet && !(found != null && found > 0) && drafted == 0) notice = '';
      setState(() {
        _syncBusy = false;
        _syncQuiet = false;
        _syncError = null;
        _syncNotice = notice;
        _reload++;
      });
      _loadStatus();
      _afterChange();
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _syncBusy = false;
        _syncQuiet = false;
        _syncError = quiet ? null : rvErrorInfo(e);
        _syncNotice = '';
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _reload++);
    await _loadStatus();
  }

  void _retryList() {
    setState(() => _reload++);
    _afterChange();
  }

  void _chooseFilter(String id) {
    if (id == _filter) return;
    setState(() => _filter = id);
    _afterChange();
  }

  /// A review changed on its card: keep it in the list and keep the
  /// "need a reply" count right.
  void _onReviewChange(Map<String, dynamic>? next, Map<String, dynamic> before) {
    if (next == null || !mounted) return;
    setState(() {
      final id = str(next['id']);
      _items = _items.map((r) => str(r['id']) == id ? next : r).toList();
      final was = before['reply_status'] == 'published';
      final now = next['reply_status'] == 'published';
      final counts = _meta?['counts'];
      if (counts is Map && was != now) {
        final step = now ? 1 : -1;
        final answered = (numOf(counts['answered']) ?? 0) + step;
        final unanswered = (numOf(counts['unanswered']) ?? 0) - step;
        _meta = {
          ..._meta!,
          'counts': {
            ...Map<String, dynamic>.from(counts),
            'answered': answered < 0 ? 0 : answered,
            'unanswered': unanswered < 0 ? 0 : unanswered,
          },
        };
      }
    });
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final info = _info;
    final view = _view;
    final counts = _meta?['counts'] is Map ? _meta!['counts'] as Map : null;

    // Status line: "128 reviews · 5 need a reply · Last synced 21 Oct, 14:05".
    final line = <String>[];
    if (info != null) {
      line.add(rvPlural(numOf(info['total_reviews']) ?? 0, 'review', 'reviews'));
      final un = counts?['unanswered'];
      if (un is num) {
        line.add(un == 0
            ? 'all replied'
            : '${_numberSafe(un)} ${un == 1 ? 'needs' : 'need'} a reply');
      }
      final synced = str(info['last_synced_at']);
      line.add(synced.isNotEmpty
          ? 'Last synced ${formatWhen(synced)}'
          : 'Not synced yet');
    }
    final withheld = numOf(info?['withheld_reviews']) ?? 0;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: GpStack(gap: 4, children: [
                const Text('Google reviews', style: GpText.h3),
                if (info != null) Text(line.join(' · '), style: GpText.note),
              ]),
            ),
            if (info?['sync_available'] == true) ...[
              const SizedBox(width: 10),
              GpButton.ghost(
                label: _syncBusy && _syncQuiet ? 'Checking Google…' : 'Sync now',
                icon: Icons.refresh,
                small: true,
                busy: _syncBusy,
                onPressed: _syncBusy ? null : () => _syncNow(),
              ),
            ],
          ]),
          const SizedBox(height: 14),
          if (_syncNotice.isNotEmpty) ...[
            GpCallout(tone: GpTone.ok, text: _syncNotice),
            const SizedBox(height: 12),
          ],
          if (_syncError != null) ...[
            GpCallout(
              tone: GpTone.bad,
              text: _syncError!.message,
              child: _syncError!.hint.isEmpty
                  ? null
                  : Text(_syncError!.hint, style: GpText.note),
            ),
            const SizedBox(height: 12),
          ],
          if (withheld > 0) ...[
            GpCallout(
              tone: GpTone.warn,
              text:
                  "Google shows ${rvPlural(withheld, 'review', 'reviews')} on your profile that it hasn't released yet. Google checks new reviews first, usually for a day or two. They appear here after that.",
            ),
            const SizedBox(height: 12),
          ],
          if (view == 'list' && info?['publish_available'] == false) ...[
            const GpCallout(
              tone: GpTone.warn,
              text:
                  "Replies can't go on Google until Google verifies your profile. You can write and save replies now.",
            ),
            const SizedBox(height: 12),
          ],
          _body(view, counts),
        ],
      ),
    );
  }

  Widget _body(String view, Map? counts) {
    if (view == 'error') {
      return GpLoadError(
        message: rvErrorInfo(
                _stError, "We couldn't load your reviews. Please try again.")
            .message,
        onRetry: _loadStatus,
      );
    }
    if (view == 'loading') {
      return Semantics(
          label: 'Loading your reviews…',
          child: const GpCardsShimmer(count: 3, height: 170));
    }
    if (view != 'list') {
      final words = _emptyWords[view]!;
      return GpCard(
        child: GpEmpty(icon: words.icon, title: words.title, message: words.body),
      );
    }

    final filters = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final f in rvFilters)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _FilterPill(
              label: f.label,
              count: counts != null && counts[f.id] is num
                  ? _numberSafe(counts[f.id])
                  : null,
              on: f.id == _filter,
              onTap: () => _chooseFilter(f.id),
            ),
          ),
      ]),
    );

    return GpStack(gap: 14, children: [filters, _listBody()]);
  }

  Widget _listBody() {
    final sameFilter = _listFilter == _filter;
    if ((_listStatus == 'loading' || _listStatus == 'idle') &&
        (!sameFilter || _items.isEmpty)) {
      return Semantics(
          label: 'Loading reviews…',
          child: const GpCardsShimmer(count: 3, height: 170));
    }
    if (_listStatus == 'error') {
      return GpLoadError(
        message: rvErrorInfo(
                _listError, "We couldn't load your reviews. Please try again.")
            .message,
        onRetry: _retryList,
      );
    }
    if (_items.isEmpty) {
      return GpCard(
        child: GpEmpty(
          icon: Icons.filter_alt_off_outlined,
          title: 'No reviews here',
          message: 'No reviews match this filter.',
          action: _filter != 'all'
              ? GpButton.ghost(
                  label: 'Show all reviews',
                  onPressed: () => _chooseFilter('all'))
              : null,
        ),
      );
    }

    final busy = _listStatus == 'loading';
    final total = _meta?['total'];
    final hasMore = total is num && _items.length < total;
    final publishAvailable = _info?['publish_available'] != false;
    return GpStack(gap: 12, children: [
      if (busy) const LinearProgressIndicator(minHeight: 2),
      AnimatedOpacity(
        opacity: busy ? 0.55 : 1,
        duration: const Duration(milliseconds: 150),
        child: IgnorePointer(
          ignoring: busy,
          child: GpStack(gap: 12, children: [
            for (final review in _items)
              GpReviewCard(
                key: ValueKey('review-${str(review['id'])}'),
                review: review,
                publishAvailable: publishAvailable,
                onChange: _onReviewChange,
              ),
          ]),
        ),
      ),
      if (_moreError != null)
        GpCallout(tone: GpTone.bad, text: _moreError!.message),
      if (hasMore)
        Row(children: [
          GpButton.ghost(
            label: 'Load more reviews',
            small: true,
            busy: _moreBusy,
            onPressed: (_moreBusy || busy) ? null : _loadMore,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing ${_numberSafe(_items.length)} of ${_numberSafe(total)}',
              style: GpText.note,
            ),
          ),
        ]),
    ]);
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final String? count;
  final bool on;
  final VoidCallback onTap;
  const _FilterPill(
      {required this.label,
      required this.count,
      required this.on,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = on ? Colors.white : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: on,
      child: Material(
        color: on ? AppColors.primary : Colors.white,
        shape: StadiumBorder(
            side: BorderSide(
                color: on ? AppColors.primary : AppColors.borderStrong)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text.rich(TextSpan(
              text: label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              children: [
                if (count != null && count!.isNotEmpty)
                  TextSpan(
                      text: ' ($count)',
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: on
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppColors.textSecondary)),
              ],
            )),
          ),
        ),
      ),
    );
  }
}
