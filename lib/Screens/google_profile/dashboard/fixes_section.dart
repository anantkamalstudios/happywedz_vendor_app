// The AI fixes inside "Improve with AI" (website dashboard/FixesTab.jsx, the
// `embedded` mode the Improve tab uses): GrowthOS's fix plan for the Google
// profile, each open fix with what it changes (now → new), Apply or Dismiss
// each (or Apply selected), and Check again (runs in the background; the plan
// is read again every few seconds until its checked_at changes).
// [onReport] tells the Improve tab the plan and the score after the selected
// fixes (the score and "Only you can do this" are shown there).
// API: fixes / prepareFixes / approveFix / rejectFix.
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'improve_utils.dart';

/// What the fix list tells the Improve tab: status loading | ready | error,
/// the plan, and the score after the selected fixes.
class GpFixReport {
  final String status;
  final Map<String, dynamic>? plan;
  final int? after;
  const GpFixReport(this.status, this.plan, this.after);
}

/// What the given fixes add: the points of the failed checks they fix, each counted once (GrowthOS gainOf).
int fixGainOf(Map<String, dynamic> plan, List<dynamic> fixes) {
  final checks = <String>{};
  for (final f in fixes) {
    for (final c in listOf(mapOf(f)['checks'])) {
      checks.add(str(c));
    }
  }
  final points = mapOf(plan['check_points']);
  var sum = 0;
  for (final c in checks) {
    sum += numOf(points[c])?.toInt() ?? 0;
  }
  return sum;
}

const Map<String, String> _fieldNames = {
  'description': 'description',
  'hours': 'opening hours',
  'services': 'services',
  'attributes': 'attributes',
  'categories': 'other categories',
  'special_hours': 'holiday hours',
  'website': 'website',
};

/// What a fix does, in words.
String fixText(Map<String, dynamic> f) {
  switch (f['action']) {
    case 'update_google_profile':
      final name = _fieldNames[str(f['field'])];
      return name != null ? 'Update your $name on Google' : 'Update your Google profile';
    case 'add_google_photo':
      return f['kind'] == 'logo'
          ? 'Add your logo to Google'
          : f['kind'] == 'cover'
              ? 'Add your cover photo to Google'
              : 'Add a photo to Google';
    case 'add_google_keyword':
      return 'Track the keyword “${str(f['keyword'])}”';
    case 'publish_google_post':
      return 'Publish a Google post: ${str(mapOf(f['post'])['topic'])}';
    default:
      return 'Improve your Google profile';
  }
}

const Duration _pollEvery = Duration(seconds: 3);
const int _pollTries = 60;

class GpFixesSection extends StatefulWidget {
  /// Going up (something changed elsewhere, e.g. in the AI chat): read the plan again quietly.
  final int refresh;
  final ValueChanged<GpFixReport> onReport;
  final void Function(String tabId) onOpenTab;

  const GpFixesSection(
      {super.key,
      required this.refresh,
      required this.onReport,
      required this.onOpenTab});

  @override
  State<GpFixesSection> createState() => _GpFixesSectionState();
}

class _GpFixesSectionState extends State<GpFixesSection> {
  String _status = 'loading';
  Map<String, dynamic>? _plan;
  Object? _error;

  /// null = every open fix.
  List<String>? _selected;

  /// The fix being applied or dismissed ({id, kind}), or id "all".
  String? _busyId;
  String? _busyKind;
  Object? _actionError;
  String _done = '';

  /// While Check again runs: the checked_at before it (wrapped, as it may be null).
  _Waiting? _waiting;
  bool _prepareBusy = false;
  Object? _prepareError;
  int _tries = 0;
  Timer? _timer;
  bool _showDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant GpFixesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refresh != oldWidget.refresh && widget.refresh > 0) {
      _load(quiet: true);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    // (Already "loading" on the first read: nothing to show or report yet.)
    if (!quiet && _status != 'loading') {
      setState(() {
        _status = 'loading';
        _error = null;
      });
      _report();
    }
    try {
      final plan = await GoogleProfileApi.instance.fixes();
      if (!mounted) return;
      setState(() {
        _status = 'ready';
        _plan = plan is Map ? Map<String, dynamic>.from(plan) : null;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        if (!(quiet && _status == 'ready')) {
          _status = 'error';
          _error = e;
        }
      });
    }
    _afterLoad();
  }

  Object? get _checkedAt => _plan?['checked_at'];

  List<dynamic> get _open =>
      listOf(_plan?['fixes']).where(improveIsOpenFix).toList();

  List<String> get _chosen =>
      _selected ?? _open.map((f) => str(mapOf(f)['action_id'])).toList();

  List<dynamic> get _picked {
    final chosen = _chosen;
    return _open.where((f) => chosen.contains(str(mapOf(f)['action_id']))).toList();
  }

  /// After every read: finish a running check, keep polling, and report.
  void _afterLoad() {
    if (!mounted) return;
    final finished = _waiting != null && _checkedAt != _waiting!.checked;
    if (finished) {
      setState(() {
        _waiting = null;
        _selected = null;
        _done = 'The check is finished. The plan below is up to date.';
      });
    }
    _schedulePoll();
    _report();
  }

  bool get _polling =>
      _status == 'ready' &&
      (_waiting != null || _plan?['rechecking'] == true) &&
      _tries < _pollTries;

  void _schedulePoll() {
    _timer?.cancel();
    _timer = null;
    if (!_polling) return;
    _timer = Timer(_pollEvery, () {
      if (!mounted) return;
      _tries += 1;
      _load(quiet: true);
    });
  }

  void _report() {
    final p = _plan;
    if (_status != 'ready' || p == null || p['available'] != true) {
      widget.onReport(GpFixReport(_status, p, null));
      return;
    }
    final audit = p['audit'] is Map ? mapOf(p['audit']) : null;
    final max = numOf(audit?['max_score'])?.toInt() ?? 100;
    final score = numOf(audit?['score'])?.toInt();
    widget.onReport(GpFixReport('ready', p,
        score == null ? null : _min(max, score + fixGainOf(p, _picked))));
  }

  int _min(int a, int b) => a < b ? a : b;

  void _setSelected(List<String>? next) {
    setState(() => _selected = next);
    _report();
  }

  Future<void> _checkAgain() async {
    setState(() {
      _prepareBusy = true;
      _prepareError = null;
      _done = '';
    });
    try {
      await GoogleProfileApi.instance.prepareFixes();
      if (!mounted) return;
      _tries = 0;
      setState(() => _waiting = _Waiting(_checkedAt));
      _schedulePoll();
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() => _prepareError = e);
    } finally {
      if (mounted) setState(() => _prepareBusy = false);
    }
  }

  Future<void> _runOne(Map<String, dynamic> fix, String kind) async {
    final id = str(fix['action_id']);
    setState(() {
      _busyId = id;
      _busyKind = kind;
      _actionError = null;
      _done = '';
    });
    try {
      if (kind == 'apply') {
        final result = await GoogleProfileApi.instance.approveFix(id);
        if (!mounted) return;
        final r = mapOf(result);
        if (r['status'] == 'failed') {
          final text = str(r['result']);
          setState(() => _actionError = ImproveLocalError(
              text.isNotEmpty ? text : '“${fixText(fix)}” could not be done.'));
        } else {
          setState(() => _done =
              'Sent to Google: ${fixText(fix)}. Google checks it before showing it.');
        }
      } else {
        await GoogleProfileApi.instance.rejectFix(id);
        if (!mounted) return;
        setState(() => _done = 'Dismissed: ${fixText(fix)}.');
      }
      setState(() => _selected = _selected?.where((x) => x != id).toList());
      await _load(quiet: true);
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() => _actionError = e);
    } finally {
      if (mounted) {
        setState(() {
          _busyId = null;
          _busyKind = null;
        });
      }
    }
  }

  Future<void> _applySelected() async {
    final picked = _picked.map(mapOf).toList();
    setState(() {
      _busyId = 'all';
      _busyKind = null;
      _actionError = null;
      _done = '';
    });
    var sent = 0;
    final failed = <String>[];
    for (final fix in picked) {
      try {
        final result =
            await GoogleProfileApi.instance.approveFix(str(fix['action_id']));
        final r = mapOf(result);
        if (r['status'] == 'failed') {
          final text = str(r['result']);
          failed.add('${fixText(fix)}${text.isNotEmpty ? ': $text' : ''}');
        } else {
          sent += 1;
        }
      } catch (e) {
        if (!mounted) return;
        if (gpHandleLocked(context, e)) return;
        failed.add('${fixText(fix)}: ${gpErrorMessage(e)}');
      }
    }
    if (!mounted) return;
    setState(() {
      if (sent > 0) {
        _done =
            '$sent ${sent == 1 ? 'fix' : 'fixes'} sent to Google. Google checks each change before showing it.';
      }
      if (failed.isNotEmpty) {
        _actionError =
            ImproveLocalError('${failed.length} could not be done.', failed);
      }
      _selected = null;
    });
    await _load(quiet: true);
    if (mounted) setState(() => _busyId = null);
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  Widget _header() {
    final plan = _plan;
    final when = plan?['checked_at'] != null
        ? 'Last checked ${formatWhen(plan!['checked_at'])}.'
        : plan?['prepared_at'] != null
            ? 'Prepared ${formatWhen(plan!['prepared_at'])}.'
            : 'Not checked yet.';
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Text(when, style: GpText.note)),
      const SizedBox(width: 8),
      GpButton.ghost(
        label: _waiting != null ? 'Checking…' : 'Check again',
        icon: Icons.refresh,
        small: true,
        busy: _prepareBusy || _waiting != null,
        onPressed: _busyId != null ? null : _checkAgain,
      ),
    ]);
  }

  Widget _statusLines() {
    return GpStack(gap: 8, children: [
      if (_waiting != null || _plan?['rechecking'] == true)
        GpCallout(
          tone: GpTone.warn,
          text: _tries >= _pollTries
              ? 'The check is taking longer than usual. Come back in a few minutes.'
              : 'Checking your Google profile and preparing fixes. This takes up to a minute; you can stay or come back.',
        ),
      if (_done.isNotEmpty) GpCallout(tone: GpTone.ok, text: _done),
    ]);
  }

  Widget _lockNote() {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
      Padding(
        padding: EdgeInsets.only(top: 1),
        child: Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
      ),
      SizedBox(width: 6),
      Expanded(
        child: Text(
            'AI never changes your name, address, main category or phone. Google checks every change before showing it.',
            style: GpText.note),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'loading') {
      return const GpLoadingLine('Loading your fix plan…');
    }
    if (_status == 'error') {
      return ImproveLoadFailed(
        error: _error,
        fallback: "We couldn't load this. Please try again.",
        onRetry: () => _load(),
      );
    }
    final plan = _plan;
    if (plan == null || plan['available'] != true) {
      return GpStack(children: [
        _header(),
        _statusLines(),
        ImproveErrorNote(_prepareError),
        GpCallout(
          tone: GpTone.warn,
          text: googleBlockText[str(plan?['reason'])] ??
              'The fix plan works once your Google profile is verified and connected. Please try again later.',
        ),
        GpButtons(children: [
          GpButton.ghost(
              label: 'Try again', icon: Icons.refresh, onPressed: () => _load()),
        ]),
      ]);
    }

    final fixes = listOf(plan['fixes']);
    final open = _open;
    final chosen = _chosen;
    final picked = _picked;
    final doneToday = fixes.where((f) {
      final s = mapOf(f)['status'];
      return s == 'executed' || s == 'failed';
    }).toList();
    final working = _busyId != null;
    final level = numOf(plan['level'])?.toInt() ?? 0;

    Widget emptyState() {
      if (level < 2) {
        return const ImproveEmptyBox(
          icon: Icons.build_outlined,
          title: 'The AI helper is off',
          text: 'Turn on the AI helper so it can prepare fixes.',
        );
      }
      if (plan['checked_at'] == null ||
          plan['rechecking'] == true ||
          _waiting != null) {
        return const ImproveEmptyBox(
          icon: Icons.build_outlined,
          title: 'The AI helper is checking your profile…',
          text: 'Fixes it prepares show up here, and each one waits for your Apply.',
        );
      }
      return const ImproveEmptyBox(
        icon: Icons.check,
        title: 'No fixes waiting',
        text:
            'Everything the AI can fix is done or waiting for its next daily check.',
      );
    }

    return GpStack(children: [
      _header(),
      _statusLines(),
      ImproveErrorNote(_prepareError),
      Row(children: [
        const Expanded(
            child: Text('AI can do these for you now', style: GpText.label)),
        if (open.length > 1)
          GpButton.ghost(
            label: chosen.length == open.length ? 'Clear all' : 'Select all',
            small: true,
            onPressed: working
                ? null
                : () => _setSelected(chosen.length == open.length
                    ? <String>[]
                    : open.map((f) => str(mapOf(f)['action_id'])).toList()),
          ),
      ]),
      ImproveErrorNote(_actionError),
      if (open.isEmpty)
        emptyState()
      else
        GpStack(children: [
          for (final raw in open)
            _FixItem(
              fix: mapOf(raw),
              plan: plan,
              checked: chosen.contains(str(mapOf(raw)['action_id'])),
              onCheck: (on) {
                final id = str(mapOf(raw)['action_id']);
                _setSelected(on
                    ? [...chosen, id]
                    : chosen.where((x) => x != id).toList());
              },
              busy: _busyId == str(mapOf(raw)['action_id']) ? _busyKind : null,
              disabled: working,
              onApply: () => _runOne(mapOf(raw), 'apply'),
              onDismiss: () => _runOne(mapOf(raw), 'dismiss'),
            ),
        ]),
      if (open.isNotEmpty)
        GpButton(
          label: _busyId == 'all'
              ? 'Sending to Google…'
              : picked.isEmpty
                  ? 'Select at least one fix'
                  : 'Apply ${picked.length} selected ${picked.length == 1 ? 'fix' : 'fixes'}',
          icon: Icons.check,
          busy: _busyId == 'all',
          expand: true,
          onPressed: (working || picked.isEmpty) ? null : _applySelected,
        ),
      if (doneToday.isNotEmpty)
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            initiallyExpanded: _showDone,
            onExpansionChanged: (v) => _showDone = v,
            title: Text('Done in the last 24 hours (${doneToday.length})',
                style: GpText.label),
            children: [
              for (final raw in doneToday)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Builder(builder: (_) {
                    final f = mapOf(raw);
                    final failed = f['status'] == 'failed';
                    final result = str(f['result']);
                    return Text(
                      '${failed ? 'Not done: ' : 'Done: '}${result.isNotEmpty ? result : fixText(f)}',
                      style: TextStyle(
                          fontSize: 13,
                          color: failed ? AppColors.error : AppColors.textPrimary),
                    );
                  }),
                ),
            ],
          ),
        ),
      _lockNote(),
    ]);
  }
}

class _Waiting {
  final Object? checked;
  const _Waiting(this.checked);
}

/// One open fix: what it changes, its points, Apply / Dismiss.
class _FixItem extends StatelessWidget {
  final Map<String, dynamic> fix;
  final Map<String, dynamic> plan;
  final bool checked;
  final ValueChanged<bool> onCheck;
  final String? busy;
  final bool disabled;
  final VoidCallback onApply;
  final VoidCallback onDismiss;

  const _FixItem({
    required this.fix,
    required this.plan,
    required this.checked,
    required this.onCheck,
    required this.busy,
    required this.disabled,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final points = fixGainOf(plan, [fix]);
    final post = fix['post'] is Map ? mapOf(fix['post']) : null;
    final imageUrl = str(fix['image_url']);
    final value = str(fix['value']);
    final current = str(fix['current']);
    final reason = str(fix['reason']);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: checked ? AppColors.primaryTint : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: checked ? AppColors.primarySurface : AppColors.border),
      ),
      child: GpStack(gap: 10, children: [
        GpCheck(
          value: checked,
          onChanged: disabled ? null : onCheck,
          label: GpStack(gap: 6, children: [
            Text(fixText(fix),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            Wrap(spacing: 6, runSpacing: 6, children: [
              points > 0
                  ? GpChip('+$points points', color: AppColors.accentPink)
                  : const GpChip('Not in the score',
                      color: AppColors.textSecondary),
              if (fix['status'] == 'escalated')
                const GpChip('Low confidence: check it', tone: GpTone.warn),
            ]),
          ]),
        ),
        if (imageUrl.isNotEmpty)
          Semantics(
            label: 'The photo that will be added',
            image: true,
            child: GpImage(
                url: imageUrl,
                height: 160,
                width: double.infinity,
                borderRadius: BorderRadius.circular(10)),
          ),
        if (post != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: GpStack(gap: 6, children: [
              Text(str(post['topic']),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (str(post['text']).isNotEmpty)
                Text(str(post['text']), style: GpText.lead),
              if (str(post['button']).isNotEmpty)
                Text('Button: ${str(post['button'])}', style: GpText.note),
            ]),
          ),
        if (value.isNotEmpty)
          GpStack(gap: 8, children: [
            _compare('On Google now', current.isEmpty ? null : current, false),
            _compare('New version', value, true),
          ]),
        if (reason.isNotEmpty) Text(reason, style: GpText.note),
        GpButtons(children: [
          GpButton(
            label: 'Apply',
            icon: Icons.check,
            small: true,
            busy: busy == 'apply',
            onPressed: disabled ? null : onApply,
          ),
          GpButton.ghost(
            label: 'Dismiss',
            icon: Icons.close,
            small: true,
            busy: busy == 'dismiss',
            onPressed: disabled ? null : onDismiss,
          ),
        ]),
      ]),
    );
  }

  Widget _compare(String title, String? text, bool isNew) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isNew ? AppColors.successTint : AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: GpStack(gap: 4, children: [
        Text(title, style: GpText.note),
        text == null
            ? const Text('Not set', style: GpText.muted)
            : Text(text, style: GpText.lead),
      ]),
    );
  }
}
