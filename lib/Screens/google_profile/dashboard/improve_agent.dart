// "Improve with AI" top card (website dashboard/ImproveAgent.jsx): the
// GrowthOS score now → after the selected fixes (as the fix list counts it),
// and the AI helper switch (on = ask first: every change waits for the
// vendor's Apply). Turning it off asks first.
// API: agent / setAgent — { on, configured, level, posts_per_week, review_replies, google_ready }.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'fixes_section.dart';
import 'improve_utils.dart';

/// "a, b and c".
String _joinWords(List<String> parts) {
  final list = parts.where((p) => p.isNotEmpty).toList();
  if (list.length > 1) {
    return '${list.sublist(0, list.length - 1).join(', ')} and ${list.last}';
  }
  return list.join();
}

/// The score now → after the selected fixes.
class _ImproveScore extends StatelessWidget {
  final GpFixReport? report;
  const _ImproveScore({required this.report});

  @override
  Widget build(BuildContext context) {
    const label = Text('GrowthOS score', style: GpText.label);
    final r = report;
    if (r == null || r.status == 'loading') {
      return const GpStack(gap: 6, children: [
        label,
        GpLoadingLine('Loading…'),
      ]);
    }
    final plan = r.plan;
    final audit =
        (plan != null && plan['available'] == true && plan['audit'] is Map)
            ? mapOf(plan['audit'])
            : null;
    if (audit == null) {
      return const GpStack(gap: 6, children: [
        label,
        Text('Not available yet', style: GpText.muted),
      ]);
    }
    final score = numOf(audit['score'])?.toInt() ?? 0;
    final max = numOf(audit['max_score'])?.toInt() ?? 100;
    final reported = r.after ?? score;
    final after = reported > score ? reported : score;
    final gain = after - score;
    return GpStack(gap: 6, children: [
      label,
      Semantics(
        label: gain > 0
            ? '$score now, $after after the selected fixes, out of $max'
            : '$score out of $max',
        excludeSemantics: true,
        child: Text.rich(TextSpan(children: [
          TextSpan(
              text: '$score',
              style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          if (gain > 0) ...[
            const TextSpan(
                text: ' → ',
                style: TextStyle(fontSize: 22, color: AppColors.textSecondary)),
            TextSpan(
                text: '$after',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentPink)),
          ],
          TextSpan(text: ' / $max', style: GpText.muted),
        ])),
      ),
      gain > 0
          ? GpChip('+$gain with the selected fixes', color: AppColors.accentPink)
          : const Text('No fixes selected right now.', style: GpText.note),
      const Text('Our own check, not an official Google score.',
          style: GpText.note),
    ]);
  }
}

class ImproveAgent extends StatefulWidget {
  final ImproveLoader agent;
  final GpFixReport? report;
  final VoidCallback onChanged;

  const ImproveAgent(
      {super.key,
      required this.agent,
      required this.report,
      required this.onChanged});

  @override
  State<ImproveAgent> createState() => _ImproveAgentState();
}

class _ImproveAgentState extends State<ImproveAgent> {
  bool _busy = false;
  Object? _error;
  bool _confirming = false;
  String _message = '';

  Map<String, dynamic>? get _data =>
      widget.agent.data is Map ? mapOf(widget.agent.data) : null;
  bool get _on => _data?['on'] == true;

  Future<void> _change(bool next) async {
    setState(() {
      _busy = true;
      _error = null;
      _message = '';
    });
    try {
      final answer = await GoogleProfileApi.instance.setAgent(next);
      if (!mounted) return;
      final before = _data;
      widget.agent.setData(
          (_) => answer ?? <String, dynamic>{...?before, 'on': next});
      setState(() {
        _confirming = false;
        _message = next
            ? 'The AI helper is on. It asks before every change.'
            : 'The AI helper is off.';
      });
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onSwitch() {
    if (_busy) return;
    if (_on) {
      setState(() => _confirming = true);
    } else {
      _change(true);
    }
  }

  Widget _helper() {
    final agent = widget.agent;
    if (agent.isLoading) {
      return const GpLoadingLine('Loading the AI helper…');
    }
    if (agent.isError) {
      return ImproveLoadFailed(
        error: agent.error,
        fallback: "We couldn't load the AI helper. Please try again.",
        onRetry: () => agent.reload(),
      );
    }
    final data = _data;
    final on = _on;
    final ppw = numOf(data?['posts_per_week'])?.toInt();
    final posts = (ppw != null && ppw > 0) ? ppw : null;
    final desc = on
        ? 'It ${_joinWords([
            'prepares changes for your Google profile',
            data?['review_replies'] == true ? 'drafts replies to 4–5★ reviews' : '',
            posts != null
                ? 'writes $posts Google ${posts == 1 ? 'post' : 'posts'} a week'
                : '',
          ])}. Nothing goes to Google until you press Apply.'
        : 'When it is on, it prepares changes for your Google profile. Nothing goes to Google until you press Apply.';
    return GpStack(gap: 10, children: [
      Semantics(
        toggled: on,
        label: 'AI helper',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: (_busy || _confirming) ? null : _onSwitch,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              const Text('AI helper', style: GpText.label),
              const SizedBox(width: 10),
              Switch(
                value: on,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.success,
                onChanged: (_busy || _confirming) ? null : (_) => _onSwitch(),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(on ? 'On — asks before every change' : 'Off',
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: on ? AppColors.success : AppColors.textSecondary)),
              ),
              if (_busy)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
          ),
        ),
      ),
      Text(desc, style: GpText.note),
      if (on && data != null && data['google_ready'] == false)
        const Text('It starts once your Google profile is connected and verified.',
            style: GpText.note),
      if (_confirming)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningTint,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: GpStack(gap: 10, children: [
            const Text('Turn off the AI helper?', style: GpText.h3),
            const Text(
                'It stops preparing fixes for your Google profile and drafting review replies. Nothing already on Google changes, and you can still make every change yourself.',
                style: GpText.lead),
            ImproveErrorNote(_error),
            GpButtons(children: [
              GpButton(
                  label: 'Turn off',
                  small: true,
                  busy: _busy,
                  onPressed: () => _change(false)),
              GpButton.ghost(
                label: 'Cancel',
                small: true,
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _confirming = false;
                          _error = null;
                        }),
              ),
            ]),
          ]),
        ),
      if (!_confirming) ImproveError(_error),
      if (_message.isNotEmpty) GpCallout(tone: GpTone.ok, text: _message),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return GpCard(
      tint: true,
      child: GpStack(gap: 14, children: [
        _ImproveScore(report: widget.report),
        const Divider(height: 1, color: AppColors.divider),
        _helper(),
      ]),
    );
  }
}
