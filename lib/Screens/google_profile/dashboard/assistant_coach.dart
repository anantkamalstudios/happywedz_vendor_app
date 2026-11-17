// AI assistant chat — today's message (website dashboard/AssistantCoach.jsx):
// the coach items (built by GrowthOS from the score, the fixes and what only
// the vendor can do; no AI credit) in one assistant bubble, each with its one
// action: upload a photo, send a command, open the AI fixes, share the review
// link (copy / WhatsApp), type an answer, or open a dashboard tab.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'assistant_message.dart';
import 'assistant_utils.dart';

/// The review link: copy it, or share it on WhatsApp.
class _ReviewLinkActions extends StatefulWidget {
  final String url;
  const _ReviewLinkActions({required this.url});

  @override
  State<_ReviewLinkActions> createState() => _ReviewLinkActionsState();
}

class _ReviewLinkActionsState extends State<_ReviewLinkActions> {
  String _copied = '';

  Future<void> _copy() async {
    var ok = true;
    try {
      await Clipboard.setData(ClipboardData(text: widget.url));
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(
      () => _copied = ok
          ? 'Link copied.'
          : "Couldn't copy. Select the link and copy it.",
    );
  }

  @override
  Widget build(BuildContext context) {
    return GpStack(
      gap: 6,
      children: [
        GpButtons(
          children: [
            GpButton.ghost(
              label: 'Copy link',
              icon: Icons.copy,
              small: true,
              onPressed: _copy,
            ),
            GpButton.ghost(
              label: 'Share on WhatsApp',
              icon: Icons.share_outlined,
              small: true,
              onPressed: () =>
                  gpOpenUrl(context, assistantWhatsappShareUrl(widget.url)),
            ),
          ],
        ),
        if (_copied.isNotEmpty) Text(_copied, style: GpText.note),
      ],
    );
  }
}

class AssistantCoach extends StatelessWidget {
  final GpLoad<dynamic> coach;
  final bool busy;
  final ValueChanged<String> onSend;
  final void Function(String command, String purpose) onUploadFor;
  final VoidCallback onOpenFixes;
  final ValueChanged<String> onOpenTab;
  final ValueChanged<String> onTypeAnswer;
  final VoidCallback onReload;

  const AssistantCoach({
    super.key,
    required this.coach,
    required this.busy,
    required this.onSend,
    required this.onUploadFor,
    required this.onOpenFixes,
    required this.onOpenTab,
    required this.onTypeAnswer,
    required this.onReload,
  });

  Widget? _action(Map<String, dynamic> action) {
    final type = str(action['type']);
    switch (type) {
      case 'upload_photo':
        final purpose = str(action['purpose']);
        return GpButton(
          label: purpose == 'photo'
              ? 'Upload photos'
              : (assistantPurposeLabels[purpose] ?? 'Upload a photo'),
          icon: Icons.upload_outlined,
          small: true,
          onPressed: busy
              ? null
              : () => onUploadFor(str(action['command']), purpose),
        );
      case 'command':
        return GpButton(
          label: 'Ask the AI to do it',
          small: true,
          onPressed: busy ? null : () => onSend(str(action['command'])),
        );
      case 'open_fixes':
        final count = numOf(action['count']);
        return GpButton(
          label: action['count'] is num && count! > 0
              ? 'Open fixes (${count.toInt()})'
              : 'Open fixes',
          small: true,
          onPressed: onOpenFixes,
        );
      case 'review_link':
        final url = str(action['url']);
        return url.isEmpty ? null : _ReviewLinkActions(url: url);
      case 'type_answer':
        final question = str(action['question']);
        return GpStack(
          gap: 6,
          children: [
            if (question.isNotEmpty)
              Text(
                question,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                ),
              ),
            GpButton.ghost(
              label: 'Type answer',
              small: true,
              onPressed: () => onTypeAnswer(str(action['command_prefix'])),
            ),
          ],
        );
      case 'open_tab':
        final tab = str(action['tab']);
        final label = assistantTabLabels[tab];
        return label == null
            ? null
            : GpButton.ghost(
                label: label,
                small: true,
                onPressed: () => onOpenTab(tab),
              );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (coach.isLoading) {
      return const AssistantBubble(
        child: GpLoadingLine("Loading today's tips…"),
      );
    }
    if (coach.isError) {
      return AssistantBubble(
        child: GpStack(
          gap: 10,
          children: [
            AssistantErrorText(
              assistantErrorText(coach.error, "We couldn't load today's tips."),
            ),
            GpButton.ghost(
              label: 'Try again',
              icon: Icons.refresh,
              small: true,
              onPressed: onReload,
            ),
          ],
        ),
      );
    }

    final data = coach.data is Map ? coach.data as Map : const {};
    final items = assistantListOf(
      data['items'],
    ).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    if (items.isEmpty) {
      return const AssistantBubble(
        child: AssistantText(
          'Your profile looks complete today. Ask me anything about it.',
        ),
      );
    }

    return AssistantBubble(
      wide: true,
      child: GpStack(
        gap: 12,
        children: [
          const AssistantText(
            "Here's what will help your Google profile today:",
          ),
          for (var i = 0; i < items.length; i++)
            _tip(items[i], i, items.length),
        ],
      ),
    );
  }

  Widget _tip(Map<String, dynamic> item, int index, int total) {
    final points = item['points'];
    final action = item['action'] is Map
        ? _action(Map<String, dynamic>.from(item['action'] as Map))
        : null;
    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: const BoxDecoration(
              color: AppColors.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Tip ${index + 1} of $total',
              child: GpStack(
                gap: 8,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        str(item['title']),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (points is num && points > 0)
                        GpChip(
                          '+${points.toInt()} points',
                          color: AppColors.accentPink,
                        ),
                    ],
                  ),
                  if (str(item['message']).isNotEmpty)
                    AssistantText(str(item['message'])),
                  action,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
