// "Improve with AI" tab (website dashboard/ImproveTab.jsx): the AI assistant
// chat, the score, the AI helper switch and the ordered next steps (use my
// storefront, keywords, services, photos, AI fixes, things only the vendor can
// do). Each step is done / to do; the first one not done says "Start here"
// and starts open. On the website the chat is the main column; here a card at
// the top opens it full screen. A change applied in the chat reloads the fixes
// and the score; "Open fixes" in the chat opens the AI fixes step.
// API: agent / storefront / keywords / services / facts (+ the calls inside
// each step and the AI fixes).
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'assistant_chat.dart';
import 'fixes_section.dart';
import 'improve_agent.dart';
import 'improve_keywords.dart';
import 'improve_needs.dart';
import 'improve_photos.dart';
import 'improve_services.dart';
import 'improve_storefront.dart';
import 'improve_utils.dart';

const List<String> _stepIds = [
  'storefront',
  'keywords',
  'services',
  'photos',
  'fixes',
  'needs',
];

/// Done when the AI helper's check found the logo, the cover and photos in place.
bool _photosDoneByPlan(Map<String, dynamic>? plan) {
  if (plan == null || plan['available'] != true) return false;
  final rows = listOf(plan['checklist']);
  bool has(String step) => rows.any((r) => mapOf(r)['step'] == step);
  final needs = checklistKeys(plan, 'need');
  return has('logo') &&
      has('cover') &&
      !needs.any((k) => k == 'logo' || k == 'cover' || k == 'library_photos') &&
      !listOf(plan['needs_you']).any((n) => mapOf(n)['key'] == 'photos');
}

class GpImproveTab extends StatefulWidget {
  final Map<String, dynamic> view;
  final void Function(String tabId) onOpenTab;
  final VoidCallback onChanged;

  const GpImproveTab(
      {super.key,
      required this.view,
      required this.onOpenTab,
      required this.onChanged});

  @override
  State<GpImproveTab> createState() => _GpImproveTabState();
}

class _GpImproveTabState extends State<GpImproveTab> {
  final GoogleProfileApi _api = GoogleProfileApi.instance;
  late final ImproveLoader _agent = ImproveLoader(_api.agent);
  late final ImproveLoader _storefront = ImproveLoader(_api.storefront);
  late final ImproveLoader _keywords = ImproveLoader(_api.keywords);
  late final ImproveLoader _services = ImproveLoader(_api.services);

  /// What GrowthOS already has (read on load), replaced by the answer once the vendor presses the button.
  late final ImproveLoader _savedFacts = ImproveLoader(_api.facts);
  Map<String, dynamic>? _usedFacts;

  bool _photosSent = false;
  GpFixReport? _report;
  int _fixesRefresh = 0;
  final Map<String, bool> _opened = {};
  final Map<String, GlobalKey> _stepKeys = {
    for (final id in _stepIds) id: GlobalKey(),
  };

  List<ImproveLoader> get _loaders =>
      [_agent, _storefront, _keywords, _services, _savedFacts];

  @override
  void initState() {
    super.initState();
    for (final l in _loaders) {
      l.onError = _onLoadError;
      l.reload();
      l.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    for (final l in _loaders) {
      l.removeListener(_rebuild);
      l.dispose();
    }
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onLoadError(Object e) {
    if (mounted) gpHandleLocked(context, e);
  }

  void _onReport(GpFixReport next) {
    if (mounted) setState(() => _report = next);
  }

  /// The score and fixes are read again quietly (what is on screen stays until the new answer comes).
  void _reloadFixes() => setState(() => _fixesRefresh += 1);

  void _changed() {
    if (!mounted) return;
    _reloadFixes();
    widget.onChanged();
  }

  Future<void> _refreshAll() async {
    _reloadFixes();
    await Future.wait(_loaders.map((l) => l.reload(quiet: true)));
  }

  Map<String, dynamic>? get _facts {
    if (_usedFacts != null) return _usedFacts;
    return _savedFacts.isReady && _savedFacts.data is Map
        ? mapOf(_savedFacts.data)
        : null;
  }

  void _openStep(String id) {
    setState(() => _opened[id] = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _stepKeys[id]?.currentContext;
      if (ctx == null || !ctx.mounted) return;
      final reduce = MediaQuery.maybeOf(ctx)?.disableAnimations ?? false;
      Scrollable.ensureVisible(ctx,
          duration: reduce ? Duration.zero : const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    });
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GpAssistantChatScreen(
          onOpenTab: widget.onOpenTab,
          onOpenFixes: () => _openStep('fixes'),
          onChanged: _changed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    final plan = report?.status == 'ready' ? report!.plan : null;
    final planKnown = report?.status == 'ready' || report?.status == 'error';
    final available = plan?['available'] == true;
    final level = numOf(plan?['level'])?.toInt() ?? 0;
    final openFixes = available
        ? listOf(plan!['fixes']).where(improveIsOpenFix).toList()
        : const <dynamic>[];
    final activeCount = _keywords.isReady
        ? activeKeywords(improveListOf(_keywords.data)).length
        : 0;
    final serviceCount =
        _services.isReady ? improveListOf(_services.data).length : 0;
    final facts = _facts;
    final hasDescription = str(facts?['description']).isNotEmpty;
    final checklist = listOf(plan?['checklist']);

    final states = <String, String>{
      'storefront': hasDescription
          ? 'done'
          : _storefront.isLoading
              ? 'unknown'
              : 'todo',
      'keywords': _keywords.isLoading
          ? 'unknown'
          : activeCount >= keywordsNeeded
              ? 'done'
              : 'todo',
      'services': _services.isLoading
          ? 'unknown'
          : serviceCount > 0
              ? 'done'
              : 'todo',
      'photos': _photosSent || _photosDoneByPlan(plan)
          ? 'done'
          : planKnown
              ? 'todo'
              : 'unknown',
      'fixes': !planKnown
          ? 'unknown'
          : (available &&
                  level >= 2 &&
                  openFixes.isEmpty &&
                  plan!['checked_at'] != null &&
                  plan['rechecking'] != true)
              ? 'done'
              : 'todo',
      'needs': !planKnown
          ? 'unknown'
          : (available &&
                  checklist.isNotEmpty &&
                  vendorNeeds(plan).needs.isEmpty)
              ? 'done'
              : 'todo',
    };

    // The first step not done ("Start here"); unknown while an earlier step is
    // still loading, null when all are done.
    String? current;
    var currentKnown = true;
    for (final id in _stepIds) {
      if (states[id] == 'unknown') {
        currentKnown = false;
        break;
      }
      if (states[id] == 'todo') {
        current = id;
        break;
      }
    }

    // As on the website (2026-10-27): every step starts closed; "Start here"
    // marks the first one still to do.
    bool isOpen(String id) => _opened[id] ?? false;
    void toggle(String id) => setState(() => _opened[id] = !isOpen(id));

    final agentOff =
        _agent.isReady && _agent.data is Map && mapOf(_agent.data)['on'] != true;

    Widget step(String id, int number, String title, String summary, Widget body) {
      return ImproveStep(
        key: _stepKeys[id],
        number: number,
        total: _stepIds.length,
        title: title,
        state: states[id]!,
        current: currentKnown && current == id,
        open: isOpen(id),
        onToggle: () => toggle(id),
        summary: summary,
        child: body,
      );
    }

    final keywordSummary = _keywords.isReady
        ? activeCount >= keywordsNeeded
            ? '$activeCount keywords — enough.'
            : '$activeCount of $keywordsNeeded keywords.'
        : '';
    final serviceSummary = _services.isReady
        ? serviceCount > 0
            ? '$serviceCount ${serviceCount == 1 ? 'service' : 'services'} saved.'
            : 'No services yet.'
        : '';
    final fixSummary = !available
        ? ''
        : openFixes.isNotEmpty
            ? '${openFixes.length} ${openFixes.length == 1 ? 'fix waits' : 'fixes wait'} for your Apply.'
            : 'No fixes waiting.';
    final needCount = available ? vendorNeeds(plan).needs.length : 0;
    final needSummary = available && checklist.isNotEmpty
        ? (needCount > 0 ? '$needCount to do.' : 'Nothing needs you.')
        : '';

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _ChatCard(onOpen: _openChat),
          ImproveAgent(agent: _agent, report: report, onChanged: _changed),
          if (agentOff)
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: GpCallout(
                  tone: GpTone.warn,
                  text: 'Turn on the AI helper so it can prepare fixes.'),
            ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10, top: 4),
            child: Row(children: [
              const Expanded(child: Text('Next steps', style: GpText.h3)),
              if (currentKnown && current == null)
                const GpChip('All steps done', tone: GpTone.ok),
            ]),
          ),
          step(
            'storefront',
            1,
            'Use my storefront',
            hasDescription
                ? 'GrowthOS has your description.'
                : 'Copy your About us text and FAQs to GrowthOS.',
            ImproveStorefront(
              storefront: _storefront,
              facts: facts,
              onUsed: (answer) => setState(() => _usedFacts = answer),
            ),
          ),
          step('keywords', 2, 'Keywords', keywordSummary,
              ImproveKeywords(keywords: _keywords)),
          step('services', 3, 'Services', serviceSummary,
              ImproveServices(services: _services)),
          step(
            'photos',
            4,
            'Photos',
            _photosSent
                ? 'Photos sent to Google.'
                : 'Pick your cover photo, logo and photos from your storefront, or upload them.',
            ImprovePhotos(
              storefront: _storefront,
              onSent: () => setState(() => _photosSent = true),
            ),
          ),
          step(
            'fixes',
            5,
            'AI fixes ready',
            fixSummary,
            GpFixesSection(
              refresh: _fixesRefresh,
              onReport: _onReport,
              onOpenTab: widget.onOpenTab,
            ),
          ),
          step(
            'needs',
            6,
            'Only you can do this',
            needSummary,
            ImproveNeedsList(
              report: report,
              onOpenTab: widget.onOpenTab,
              onOpenStep: _openStep,
              onRetry: _reloadFixes,
            ),
          ),
        ]),
      ),
    );
  }
}

/// The card that opens the AI assistant chat (the website's main column).
class _ChatCard extends StatelessWidget {
  final VoidCallback onOpen;
  const _ChatCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: AppColors.headerGradient,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Ask the AI assistant',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ]),
        const SizedBox(height: 10),
        Text(
          'Tell it what to change on your Google profile in your own words — your hours, description, photos or a new post. It prepares the change and nothing goes to Google until you press Apply.',
          style: TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.92)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Open the AI assistant',
                style: TextStyle(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }
}
