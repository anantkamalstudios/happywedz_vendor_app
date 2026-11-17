// "Improve with AI" step 3 (website dashboard/ImproveServices.jsx): the
// vendor's services in GrowthOS. The AI suggests up to 10 from the storefront;
// the vendor ticks them, can change each name and description, and adds the
// ticked ones; saved ones can be removed. The Growth Agent then lists them on
// Google. API: services / suggestServices / addService / deleteService.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'improve_utils.dart';

// GrowthOS serviceSchema limits.
const int _nameMax = 150;
const int _categoryMax = 100;
const int _descriptionMax = 2000;

/// Why a service can't be added yet, per field (service_name, category, description).
Map<String, String> _problemsOf(String name, String category, String description) {
  final out = <String, String>{};
  final n = name.trim(), c = category.trim(), d = description.trim();
  if (n.isEmpty) {
    out['service_name'] = 'Enter a name.';
  } else if (n.length > _nameMax) {
    out['service_name'] = 'Use at most $_nameMax characters.';
  }
  if (c.isEmpty) {
    out['category'] = 'Enter a category.';
  } else if (c.length > _categoryMax) {
    out['category'] = 'Use at most $_categoryMax characters.';
  }
  if (d.isEmpty) {
    out['description'] = 'Enter a short description.';
  } else if (d.length > _descriptionMax) {
    out['description'] = 'Use at most $_descriptionMax characters.';
  }
  return out;
}

/// One AI idea, with its editable fields.
class _Idea {
  final String key;
  final TextEditingController name;
  final TextEditingController category;
  final TextEditingController description;
  final bool aiCategory;
  bool ticked = true;

  _Idea(this.key, String n, String c, String d, this.aiCategory)
      : name = TextEditingController(text: n),
        category = TextEditingController(text: c),
        description = TextEditingController(text: d);

  Map<String, String> get problems =>
      _problemsOf(name.text, category.text, description.text);

  void dispose() {
    name.dispose();
    category.dispose();
    description.dispose();
  }
}

class ImproveServices extends StatefulWidget {
  final ImproveLoader services;
  const ImproveServices({super.key, required this.services});

  @override
  State<ImproveServices> createState() => _ImproveServicesState();
}

class _ImproveServicesState extends State<ImproveServices> {
  List<_Idea>? _ideas;

  /// "suggest" | "add" | "own" | a service id
  String? _busy;
  Object? _error;
  ImproveMessage? _message;
  bool _showProblems = false;

  // A service the vendor types (works when the AI is down too).
  final TextEditingController _ownName = TextEditingController();
  final TextEditingController _ownCategory = TextEditingController();
  final TextEditingController _ownDescription = TextEditingController();
  bool _ownChecked = false;

  @override
  void dispose() {
    for (final i in _ideas ?? const <_Idea>[]) {
      i.dispose();
    }
    _ownName.dispose();
    _ownCategory.dispose();
    _ownDescription.dispose();
    super.dispose();
  }

  ImproveLoader get _sv => widget.services;
  List<Map<String, dynamic>> get _saved =>
      improveListOf(_sv.data).map(mapOf).toList();

  bool _locked(Object e) => gpHandleLocked(context, e);

  void _replaceIdeas(List<_Idea>? next) {
    final old = _ideas ?? const <_Idea>[];
    final keep = next ?? const <_Idea>[];
    for (final i in old) {
      if (!keep.contains(i)) i.dispose();
    }
    _ideas = next;
  }

  Future<void> _suggest() async {
    setState(() {
      _busy = 'suggest';
      _error = null;
      _message = null;
      _showProblems = false;
    });
    try {
      final answer = await GoogleProfileApi.instance.suggestServices();
      if (!mounted) return;
      final saved = _saved;
      final raw = improveSuggestionsOf(answer)
          .map(mapOf)
          .where((s) =>
              s['service_name'] is String && str(s['service_name']).trim().isNotEmpty)
          .where((s) =>
              !saved.any((x) => improveSame(x['service_name'], s['service_name'])))
          .toList();
      final list = <_Idea>[];
      for (var i = 0; i < raw.length; i++) {
        final s = raw[i];
        final cat = s['category'] is String ? str(s['category']).trim() : '';
        list.add(_Idea(
          '$i-${s['service_name']}',
          str(s['service_name']).trim(),
          cat,
          s['description'] is String ? str(s['description']).trim() : '',
          cat.isNotEmpty && cat.length <= _categoryMax,
        ));
      }
      setState(() {
        _replaceIdeas(list);
        _message = ImproveMessage(
          list.isNotEmpty ? GpTone.ok : GpTone.warn,
          list.isNotEmpty
              ? '${list.length} service ${list.length == 1 ? 'idea is' : 'ideas are'} ready below. Check each one.'
              : 'No new service ideas from your storefront.',
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
    final ticked = (_ideas ?? const <_Idea>[]).where((s) => s.ticked).toList();
    if (ticked.isEmpty) return;
    if (ticked.any((s) => s.problems.isNotEmpty)) {
      setState(() {
        _showProblems = true;
        _message = const ImproveMessage(GpTone.bad,
            'Some ticked services need a change first. See the notes in red.');
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = 'add';
      _error = null;
      _message = null;
    });
    final added = <_Idea>[];
    final failed = <String>[];
    for (final s in ticked) {
      try {
        await GoogleProfileApi.instance.addService({
          'service_name': s.name.text.trim(),
          'category': s.category.text.trim(),
          'description': s.description.text.trim(),
        });
        added.add(s);
      } catch (e) {
        if (!mounted || _locked(e)) return;
        failed.add('“${s.name.text}” (${gpErrorMessage(e)})');
      }
    }
    if (!mounted) return;
    setState(() => _replaceIdeas(
        _ideas?.where((s) => !added.contains(s)).toList()));
    await _sv.reload(quiet: true);
    if (!mounted) return;
    setState(() {
      _showProblems = false;
      _message = ImproveMessage(
        failed.isNotEmpty ? GpTone.bad : GpTone.ok,
        [
          if (added.isNotEmpty)
            'Added ${added.length} ${added.length == 1 ? 'service' : 'services'}. The AI then adds them to your Google profile.',
          if (failed.isNotEmpty) 'Not added: ${failed.join('; ')}.',
        ].join(' '),
      );
      _busy = null;
    });
  }

  Future<void> _remove(Map<String, dynamic> s) async {
    final id = str(s['id']);
    setState(() {
      _busy = id;
      _error = null;
      _message = null;
    });
    try {
      await GoogleProfileApi.instance.deleteService(id);
      if (!mounted) return;
      _sv.setData((page) {
        final list =
            improveListOf(page).where((x) => str(mapOf(x)['id']) != id).toList();
        if (page is GpPage) return GpPage(list, page.meta);
        if (page is Map) return {...page, 'data': list};
        return GpPage(list, null);
      });
      setState(() => _message =
          ImproveMessage(GpTone.ok, 'Removed “${str(s['service_name'])}”.'));
    } catch (e) {
      if (!mounted || _locked(e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _addOwn() async {
    setState(() => _ownChecked = true);
    if (_problemsOf(_ownName.text, _ownCategory.text, _ownDescription.text)
        .isNotEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    final name = _ownName.text.trim();
    setState(() {
      _busy = 'own';
      _error = null;
      _message = null;
    });
    try {
      await GoogleProfileApi.instance.addService({
        'service_name': name,
        'category': _ownCategory.text.trim(),
        'description': _ownDescription.text.trim(),
      });
      if (!mounted) return;
      _ownName.clear();
      _ownCategory.clear();
      _ownDescription.clear();
      setState(() => _ownChecked = false);
      await _sv.reload(quiet: true);
      if (!mounted) return;
      setState(() => _message = ImproveMessage(GpTone.ok, 'Added “$name”.'));
    } catch (e) {
      if (!mounted || _locked(e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _ideaTile(_Idea idea, bool working) {
    final problems = (_showProblems && idea.ticked) ? idea.problems : const {};
    final name = idea.name.text.trim();
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: idea.ticked ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: idea.ticked ? AppColors.primarySurface : AppColors.border),
      ),
      child: GpStack(gap: 10, children: [
        GpCheck(
          value: idea.ticked,
          onChanged:
              working ? null : (on) => setState(() => idea.ticked = on),
          label: Text('Add “${name.isNotEmpty ? name : 'this service'}”',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        if (idea.ticked) ...[
          GpTextField(
            label: 'Name',
            controller: idea.name,
            maxLength: _nameMax,
            enabled: !working,
            error: problems['service_name'],
            onChanged: (_) => setState(() {}),
          ),
          idea.aiCategory
              ? Text('Category: ${idea.category.text}', style: GpText.note)
              : GpTextField(
                  label: 'Category',
                  controller: idea.category,
                  maxLength: _categoryMax,
                  enabled: !working,
                  error: problems['category'],
                  onChanged: (_) => setState(() {}),
                ),
          GpTextField(
            label: 'Description',
            controller: idea.description,
            maxLength: _descriptionMax,
            minLines: 2,
            maxLines: 6,
            enabled: !working,
            error: problems['description'],
            onChanged: (_) => setState(() {}),
          ),
        ],
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sv.isLoading) return const GpLoadingLine('Loading your services…');
    if (_sv.isError) {
      return ImproveLoadFailed(
        error: _sv.error,
        fallback: "We couldn't load your services. Please try again.",
        onRetry: () => _sv.reload(),
      );
    }
    final saved = _saved;
    final working = _busy != null;
    final ideas = _ideas ?? const <_Idea>[];
    final ticked = ideas.where((s) => s.ticked).length;
    final showIdeas = ideas.isNotEmpty;
    final ownProblems = _ownChecked
        ? _problemsOf(_ownName.text, _ownCategory.text, _ownDescription.text)
        : const <String, String>{};

    return GpStack(gap: 14, children: [
      const Text(
          'Your services tell couples what you offer. The AI then adds them to your Google profile.',
          style: GpText.note),
      if (saved.isNotEmpty)
        GpStack(gap: 8, children: [
          const Text('Your services', style: GpText.label),
          for (final s in saved)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Expanded(
                  child: GpStack(gap: 2, children: [
                    Text(str(s['service_name']),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (str(s['category']).isNotEmpty)
                      Text(str(s['category']), style: GpText.note),
                  ]),
                ),
                _busy == str(s['id'])
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2)))
                    : IconButton(
                        tooltip: 'Remove “${str(s['service_name'])}”',
                        onPressed: working ? null : () => _remove(s),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error),
                      ),
              ]),
            ),
        ])
      else
        const Text('No services yet.', style: GpText.muted),
      if (showIdeas)
        ImproveAiBox(
          label: 'AI service ideas from your storefront',
          children: [
            for (final idea in ideas) _ideaTile(idea, working),
            GpButton(
              label: _busy == 'add'
                  ? 'Adding…'
                  : ticked > 0
                      ? 'Add $ticked selected'
                      : 'Tick at least one',
              icon: Icons.add,
              busy: _busy == 'add',
              onPressed: (working || ticked == 0) ? null : _addTicked,
            ),
          ],
        ),
      ImproveError(_error),
      if (_message != null) GpCallout(tone: _message!.tone, text: _message!.text),
      if (!showIdeas)
        GpButton(
          label: _busy == 'suggest'
              ? 'Reading your storefront…'
              : 'Suggest services from my storefront',
          icon: Icons.auto_awesome,
          busy: _busy == 'suggest',
          onPressed: working ? null : _suggest,
        ),
      GpStack(gap: 10, children: [
        const Text('Or add your own service', style: GpText.label),
        GpTextField(
          label: 'Service name',
          controller: _ownName,
          hint: 'e.g. Wedding reception hall',
          maxLength: _nameMax,
          enabled: !working,
          error: ownProblems['service_name'],
          onChanged: (_) => setState(() {}),
        ),
        GpTextField(
          label: 'Category',
          controller: _ownCategory,
          hint: 'e.g. Venue',
          maxLength: _categoryMax,
          enabled: !working,
          error: ownProblems['category'],
          onChanged: (_) => setState(() {}),
        ),
        GpTextField(
          label: 'Short description',
          controller: _ownDescription,
          maxLength: _descriptionMax,
          minLines: 2,
          maxLines: 5,
          enabled: !working,
          error: ownProblems['description'],
          onChanged: (_) => setState(() {}),
        ),
        GpButton.ghost(
          label: 'Add service',
          icon: Icons.add,
          busy: _busy == 'own',
          onPressed: working ? null : _addOwn,
        ),
      ]),
    ]);
  }
}
