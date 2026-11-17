// "Improve with AI" step 2 (website dashboard/ImproveKeywords.jsx): the
// keywords GrowthOS tracks for the Google profile. The AI suggests some (the
// top 5 new ones are ticked), the vendor adds the ticked ones, and can remove
// or track again a saved one. Done at 5 active keywords.
// API: keywords / suggestKeywords / addKeyword / setKeywordStatus / deleteKeyword.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'improve_utils.dart';

class ImproveKeywords extends StatefulWidget {
  final ImproveLoader keywords;
  const ImproveKeywords({super.key, required this.keywords});

  @override
  State<ImproveKeywords> createState() => _ImproveKeywordsState();
}

class _KeywordIdeas {
  final String? area;
  final List<Map<String, dynamic>> list;
  const _KeywordIdeas(this.area, this.list);
}

class _ImproveKeywordsState extends State<ImproveKeywords> {
  _KeywordIdeas? _ideas;
  List<String> _ticked = [];

  // "suggest" | "add" | "own" | "remove:ID" | "resume:ID"
  String? _busy;
  Object? _error;
  ImproveMessage? _message;
  final TextEditingController _own = TextEditingController();

  @override
  void initState() {
    super.initState();
    _own.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  ImproveLoader get _kw => widget.keywords;
  List<Map<String, dynamic>> get _saved =>
      improveListOf(_kw.data).map(mapOf).toList();

  /// The page with [update] applied to its list (keeps a { data, meta } shape).
  dynamic _withList(dynamic page, List<dynamic> Function(List<dynamic>) update) {
    final list = update(improveListOf(page).toList());
    if (page is GpPage) return GpPage(list, page.meta);
    if (page is Map) return {...page, 'data': list};
    return GpPage(list, null);
  }

  bool _locked(Object e) => gpHandleLocked(context, e);

  Future<void> _suggest() async {
    setState(() {
      _busy = 'suggest';
      _error = null;
      _message = null;
    });
    try {
      final answer = mapOf(await GoogleProfileApi.instance.suggestKeywords());
      if (!mounted) return;
      final saved = _saved;
      final list = listOf(answer['suggestions'])
          .map(mapOf)
          .where((s) =>
              str(s['keyword']).isNotEmpty &&
              s['already_added'] != true &&
              !saved.any((k) => improveSame(k['keyword'], s['keyword'])))
          .toList();
      final area = answer['area'] is String && str(answer['area']).isNotEmpty
          ? str(answer['area'])
          : null;
      setState(() {
        _ideas = _KeywordIdeas(area, list);
        _ticked = list.take(keywordsNeeded).map((s) => str(s['keyword'])).toList();
        _message = ImproveMessage(
          list.isNotEmpty ? GpTone.ok : GpTone.warn,
          list.isNotEmpty
              ? '${list.length} keyword ${list.length == 1 ? 'idea is' : 'ideas are'} ready below.'
              : 'No new keyword ideas right now.',
        );
      });
    } catch (e) {
      if (!mounted || _locked(e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _addTicked() async {
    final ideas = _ideas;
    final chosen =
        (ideas?.list ?? []).where((s) => _ticked.contains(str(s['keyword']))).toList();
    if (chosen.isEmpty) return;
    setState(() {
      _busy = 'add';
      _error = null;
      _message = null;
    });
    final added = <String>[];
    final failed = <String>[];
    for (final s in chosen) {
      final keyword = str(s['keyword']);
      try {
        final service = mapOf(s['service']);
        await GoogleProfileApi.instance.addKeyword({
          'keyword': keyword,
          if (str(s['intent']).isNotEmpty) 'intent': s['intent'],
          if (service['id'] != null && str(service['id']).isNotEmpty)
            'service_id': service['id'],
          if (ideas?.area != null) 'area': ideas!.area,
          'source': 'ai',
        });
        added.add(keyword);
      } catch (e) {
        if (!mounted || _locked(e)) return;
        failed.add('“$keyword” (${gpErrorMessage(e)})');
      }
    }
    if (!mounted) return;
    setState(() {
      final cur = _ideas;
      if (cur != null) {
        _ideas = _KeywordIdeas(cur.area,
            cur.list.where((s) => !added.contains(str(s['keyword']))).toList());
      }
      _ticked = _ticked.where((k) => !added.contains(k)).toList();
    });
    await _kw.reload(quiet: true);
    if (!mounted) return;
    setState(() {
      _message = ImproveMessage(
        failed.isNotEmpty ? GpTone.bad : GpTone.ok,
        [
          if (added.isNotEmpty)
            'Added ${added.length} ${added.length == 1 ? 'keyword' : 'keywords'}.',
          if (failed.isNotEmpty) 'Not added: ${failed.join('; ')}.',
        ].join(' '),
      );
      _busy = null;
    });
  }

  Future<void> _addOwn() async {
    final keyword = _own.text.trim();
    if (keyword.isEmpty) return;
    if (_saved.any((k) => improveSame(k['keyword'], keyword))) {
      setState(() {
        _error = null;
        _message =
            ImproveMessage(GpTone.warn, '“$keyword” is already in your keywords.');
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = 'own';
      _error = null;
      _message = null;
    });
    try {
      await GoogleProfileApi.instance
          .addKeyword({'keyword': keyword, 'source': 'manual'});
      if (!mounted) return;
      _own.clear();
      await _kw.reload(quiet: true);
      if (!mounted) return;
      setState(() => _message = ImproveMessage(GpTone.ok, 'Added “$keyword”.'));
    } catch (e) {
      if (!mounted || _locked(e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _remove(Map<String, dynamic> k) async {
    final id = str(k['id']);
    setState(() {
      _busy = 'remove:$id';
      _error = null;
      _message = null;
    });
    try {
      await GoogleProfileApi.instance.deleteKeyword(id);
      if (!mounted) return;
      _kw.setData((page) => _withList(
          page, (list) => list.where((x) => str(mapOf(x)['id']) != id).toList()));
      setState(() =>
          _message = ImproveMessage(GpTone.ok, 'Removed “${str(k['keyword'])}”.'));
    } catch (e) {
      if (!mounted || _locked(e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _resume(Map<String, dynamic> k) async {
    final id = str(k['id']);
    setState(() {
      _busy = 'resume:$id';
      _error = null;
      _message = null;
    });
    try {
      final answer = await GoogleProfileApi.instance.setKeywordStatus(id, 'active');
      if (!mounted) return;
      _kw.setData((page) => _withList(
          page,
          (list) => list.map((x) {
                final m = mapOf(x);
                if (str(m['id']) != id) return x;
                return {
                  ...m,
                  if (answer is Map) ...mapOf(answer),
                  'status': 'active',
                };
              }).toList()));
      setState(() => _message =
          ImproveMessage(GpTone.ok, 'Tracking “${str(k['keyword'])}” again.'));
    } catch (e) {
      if (!mounted || _locked(e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _tag(Map<String, dynamic> k, bool working) {
    final id = str(k['id']);
    final active = k['status'] == 'active';
    Widget iconButton(String busyKey, IconData icon, String tip, VoidCallback onTap) {
      return SizedBox(
        width: 30,
        height: 30,
        child: _busy == busyKey
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(strokeWidth: 2))
            : IconButton(
                padding: EdgeInsets.zero,
                iconSize: 16,
                tooltip: tip,
                onPressed: working ? null : onTap,
                icon: Icon(icon, color: AppColors.textSecondary),
              ),
      );
    }

    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: active ? AppColors.primaryTint : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: active ? AppColors.primarySurface : AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(
          child: Text(str(k['keyword']),
              style: TextStyle(
                  fontSize: 13,
                  color: active ? AppColors.textPrimary : AppColors.textSecondary)),
        ),
        if (!active) ...[
          const SizedBox(width: 4),
          const Text('(paused)', style: GpText.note),
          iconButton('resume:$id', Icons.refresh,
              'Track “${str(k['keyword'])}” again', () => _resume(k)),
        ],
        iconButton('remove:$id', Icons.close, 'Remove “${str(k['keyword'])}”',
            () => _remove(k)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_kw.isLoading) return const GpLoadingLine('Loading your keywords…');
    if (_kw.isError) {
      return ImproveLoadFailed(
        error: _kw.error,
        fallback: "We couldn't load your keywords. Please try again.",
        onRetry: () => _kw.reload(),
      );
    }
    final saved = _saved;
    final active = activeKeywords(saved);
    final working = _busy != null;
    final toTick = _ideas?.list ?? const <Map<String, dynamic>>[];
    final showIdeas = _ideas != null && toTick.isNotEmpty;

    return GpStack(gap: 14, children: [
      Text(
        'Keywords are the words couples type into Google to find a vendor like you. The AI uses them in your description and posts. ${active.length >= keywordsNeeded ? 'You have ${active.length} active keywords.' : 'Add at least $keywordsNeeded; you have ${active.length}.'}',
        style: GpText.note,
      ),
      if (saved.isNotEmpty)
        GpStack(gap: 8, children: [
          const Text('Your keywords', style: GpText.label),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in saved) _tag(k, working),
          ]),
        ])
      else
        const Text('No keywords yet.', style: GpText.muted),
      if (showIdeas)
        ImproveAiBox(
          label:
              'AI keyword ideas${_ideas!.area != null ? ' for ${_ideas!.area}' : ''}',
          children: [
            for (final s in toTick)
              GpCheck(
                value: _ticked.contains(str(s['keyword'])),
                onChanged: working
                    ? null
                    : (on) => setState(() {
                          final kw = str(s['keyword']);
                          _ticked = on
                              ? [..._ticked, kw]
                              : _ticked.where((k) => k != kw).toList();
                        }),
                label: GpStack(gap: 2, children: [
                  Text(str(s['keyword']),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (str(s['priority_rationale']).isNotEmpty)
                    Text(str(s['priority_rationale']), style: GpText.note),
                ]),
              ),
            GpButton(
              label: _busy == 'add'
                  ? 'Adding…'
                  : _ticked.isNotEmpty
                      ? 'Add ${_ticked.length} selected'
                      : 'Tick at least one',
              icon: Icons.add,
              busy: _busy == 'add',
              onPressed: (working || _ticked.isEmpty) ? null : _addTicked,
            ),
          ],
        ),
      ImproveError(_error),
      if (_message != null) GpCallout(tone: _message!.tone, text: _message!.text),
      if (!showIdeas)
        GpButton(
          label: _busy == 'suggest' ? 'Finding keywords…' : 'Suggest keywords',
          icon: Icons.auto_awesome,
          busy: _busy == 'suggest',
          onPressed: working ? null : _suggest,
        ),
      GpStack(gap: 6, children: [
        const Text('Or add your own keyword', style: GpText.label),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: TextField(
              controller: _own,
              enabled: !working,
              maxLength: 80,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addOwn(),
              style: const TextStyle(fontSize: 14),
              decoration: gpInputDecoration(
                  hint: 'e.g. banquet hall in Nashik', counter: ''),
            ),
          ),
          const SizedBox(width: 8),
          GpButton.ghost(
            label: 'Add',
            icon: Icons.add,
            busy: _busy == 'own',
            onPressed: (working || _own.text.trim().isEmpty) ? null : _addOwn,
          ),
        ]),
      ]),
    ]);
  }
}
