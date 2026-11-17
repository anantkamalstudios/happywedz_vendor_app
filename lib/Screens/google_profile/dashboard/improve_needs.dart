// "Improve with AI" step 6 (website dashboard/ImproveNeeds.jsx): what only the
// vendor can do, from the AI helper's last check (the fix plan's checklist
// "need:" rows, low-rated reviews, review replies waiting, photos), each with
// one button that opens the right tab (Profile, Reviews) or a step above.
import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'fixes_section.dart';
import 'improve_utils.dart';

class ImproveNeedsList extends StatelessWidget {
  final GpFixReport? report;
  final void Function(String tabId) onOpenTab;
  final void Function(String stepId) onOpenStep;
  final VoidCallback onRetry;

  const ImproveNeedsList({
    super.key,
    required this.report,
    required this.onOpenTab,
    required this.onOpenStep,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final r = report;
    if (r == null || r.status == 'loading') {
      return const GpLoadingLine("Loading the AI helper's check…");
    }
    if (r.status == 'error') {
      return GpStack(gap: 10, children: [
        const GpCallout(
            tone: GpTone.bad,
            text: "We couldn't load the AI helper's check. Please try again."),
        GpButton.ghost(label: 'Try again', icon: Icons.refresh, onPressed: onRetry),
      ]);
    }
    final plan = r.plan;
    if (plan == null || plan['available'] != true) {
      return GpCallout(
        tone: GpTone.warn,
        text: googleBlockText[str(plan?['reason'])] ??
            'This list works once your Google profile is verified and connected.',
      );
    }

    final result = vendorNeeds(plan);
    final checked = listOf(plan['checklist']).isNotEmpty;

    return GpStack(gap: 12, children: [
      if (result.needs.isEmpty)
        GpCallout(
          tone: checked ? GpTone.ok : GpTone.warn,
          text: checked
              ? 'Nothing needs you right now.'
              : 'After its first check, the AI helper lists here what only you can do.',
        )
      else
        GpStack(gap: 10, children: [
          for (final n in result.needs)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: GpStack(gap: 6, children: [
                Text(n.title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text(n.body, style: GpText.note),
                const SizedBox(height: 2),
                GpButton.ghost(
                  label: n.action,
                  icon: Icons.arrow_forward,
                  small: true,
                  onPressed: () =>
                      n.tab != null ? onOpenTab(n.tab!) : onOpenStep(n.step!),
                ),
              ]),
            ),
        ]),
      if (result.fixed.isNotEmpty)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check, size: 14, color: AppColors.success),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                'You fixed: ${result.fixed.join(', ')}. The AI helper checks again and uses it.',
                style: GpText.note),
          ),
        ]),
    ]);
  }
}
