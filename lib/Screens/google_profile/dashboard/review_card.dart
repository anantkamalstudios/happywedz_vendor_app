// One Google review on the Reviews tab (website dashboard/ReviewCard.jsx):
// stars, name, date, text and the reply. Write with AI (draft), edit, Save,
// Publish to Google (the vendor's Publish is the approval, after a small
// confirm), and for a reply on Google: Edit and Delete reply (with a confirm).
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'review_format.dart';

class _Sentiment {
  final String label;
  final GpTone? tone;
  final Color? color;
  const _Sentiment(this.label, {this.tone, this.color});
}

const Map<String, _Sentiment> _sentimentChip = {
  'positive': _Sentiment('Positive', tone: GpTone.ok),
  'neutral': _Sentiment('Neutral', color: AppColors.textSecondary),
  'negative': _Sentiment('Negative', tone: GpTone.bad),
};

/// `publishAvailable` comes from the reviews status (a verified profile).
/// `onChange(next, before)` gets the review as the server returned it after
/// each change.
class GpReviewCard extends StatefulWidget {
  final Map<String, dynamic> review;
  final bool publishAvailable;
  final void Function(Map<String, dynamic>? next, Map<String, dynamic> before)
      onChange;

  const GpReviewCard({
    super.key,
    required this.review,
    required this.publishAvailable,
    required this.onChange,
  });

  @override
  State<GpReviewCard> createState() => _GpReviewCardState();
}

class _GpReviewCardState extends State<GpReviewCard> {
  final _api = GoogleProfileApi.instance;
  final _focus = FocusNode();
  late final TextEditingController _text;

  String _mode = 'view'; // view | edit (reply not on Google) | editPublished
  String? _busy;
  String? _confirm; // publish | delete
  RvErrorInfo? _error;
  String _notice = '';

  Map<String, dynamic> get _review => widget.review;
  String get _id => str(_review['id']);
  String get _reply => str(_review['reply']);

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: _reply);
    _text.addListener(_onText);
  }

  @override
  void dispose() {
    _text.removeListener(_onText);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onText() {
    if (mounted) setState(() {});
  }

  void _setText(String value) {
    _text.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _focusEditor() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _mode != 'view') _focus.requestFocus();
    });
  }

  void _openEditor(String nextMode) {
    setState(() {
      _setText(_reply);
      _error = null;
      _notice = '';
      _confirm = null;
      _mode = nextMode;
    });
    _focusEditor();
  }

  void _closeEditor() {
    _focus.unfocus();
    setState(() {
      _mode = 'view';
      _confirm = null;
      _error = null;
      _setText(_reply);
    });
  }

  void _askConfirm(String kind) {
    _focus.unfocus();
    setState(() {
      _error = null;
      _notice = '';
      _confirm = kind;
    });
  }

  void _cancelConfirm() => setState(() => _confirm = null);

  /// Runs one call; on success hands the review to the parent and says [done].
  Future<void> _run(
    String key,
    Future<dynamic> Function() call,
    Map<String, dynamic>? fallbackReview,
    String done, [
    void Function(Map<String, dynamic>? next)? after,
  ]) async {
    final before = _review;
    setState(() {
      _busy = key;
      _error = null;
      _notice = '';
    });
    try {
      final answer = await call();
      if (!mounted) return;
      final next =
          rvIsReview(answer) ? Map<String, dynamic>.from(answer) : fallbackReview;
      widget.onChange(next, before);
      setState(() {
        _notice = done;
        _busy = null;
      });
      after?.call(next);
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _busy = null;
        _error = rvErrorInfo(e);
        if (key == 'publish' || key == 'delete') _confirm = null;
      });
    }
  }

  String get _trimmed => _text.text.trim();

  void _draft() {
    final wasEditing = _mode == 'edit';
    _run(
      'draft',
      () => _api.draftReply(_id),
      null,
      'AI draft ready. Read it and change anything you like before you publish.',
      (next) {
        setState(() {
          final r = str(next?['reply']);
          if (r.isNotEmpty) _setText(r);
          if (!wasEditing) _mode = 'edit';
        });
        _focusEditor();
      },
    );
  }

  void _save() {
    final t = _trimmed;
    _run(
      'save',
      () => _api.saveReply(_id, t),
      {..._review, 'reply': t, 'reply_status': 'draft'},
      "Draft saved. It isn't on Google yet.",
    );
  }

  void _publish() {
    final t = _trimmed;
    _run(
      'publish',
      () => _api.publishReply(_id, t),
      {
        ..._review,
        'reply': t,
        'reply_status': 'published',
        'published_at': DateTime.now().toUtc().toIso8601String(),
      },
      'Reply published on Google.',
      (_) => setState(() {
        _confirm = null;
        _mode = 'view';
      }),
    );
  }

  void _savePublished() {
    final t = _trimmed;
    _run(
      'editPublished',
      () => _api.editPublishedReply(_id, t),
      {..._review, 'reply': t},
      'Reply updated on Google.',
      (_) {
        _focus.unfocus();
        setState(() => _mode = 'view');
      },
    );
  }

  void _remove() {
    _run(
      'delete',
      () => _api.deleteReply(_id),
      {..._review, 'reply': null, 'reply_status': 'none', 'published_at': null},
      'Reply deleted from Google. The review needs a reply again.',
      (next) => setState(() {
        _confirm = null;
        _setText(str(next?['reply']));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final published = _review['reply_status'] == 'published';
    final trimmed = _trimmed;
    final tooLong = trimmed.length > rvMaxReplyLength;
    final editing = _mode != 'view';
    final working = _busy != null;
    final aiGenerated = _review['ai_generated'] == true;
    // A draft from the AI (or a saved draft) whose text the vendor has not changed.
    final unchangedDraft = trimmed == _reply.trim();
    final sentiment = _sentimentChip[str(_review['sentiment'])];
    final status = rvReplyStatusWords[str(_review['reply_status'])] ??
        rvReplyStatusWords['none']!;
    final flags = listOf(_review['policy_flags'])
        .map((f) => '$f')
        .where(rvPolicyWords.containsKey)
        .toList();
    final date = rvFormatDate(_review['review_date']);
    final name = str(_review['reviewer_name']);
    final reviewText = str(_review['review_text']);
    final publishAvailable = widget.publishAvailable;

    return GpCard(
      margin: EdgeInsets.zero,
      child: GpStack(gap: 12, children: [
        // Header
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primaryTint,
            child: Text(initials(_review['reviewer_name']),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GpStack(gap: 4, children: [
              Text(name.isNotEmpty ? name : 'A Google user',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ReviewStars(rating: _review['rating']),
                  if (date.isNotEmpty) Text(date, style: GpText.muted),
                ],
              ),
            ]),
          ),
        ]),
        Wrap(spacing: 6, runSpacing: 6, children: [
          if (sentiment != null)
            GpChip(sentiment.label,
                tone: sentiment.tone, color: sentiment.color),
          status.tone == 'pink'
              ? GpChip(status.label, color: AppColors.accentPink)
              : GpChip(status.label,
                  tone: status.tone == 'ok' ? GpTone.ok : GpTone.warn),
        ]),

        reviewText.isNotEmpty
            ? Text(reviewText, style: GpText.lead)
            : const Text('No written review, only a star rating.',
                style: GpText.muted),

        if (_reply.isNotEmpty && !editing)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: published ? AppColors.successTint : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border(
                left: BorderSide(
                    color: published ? AppColors.success : AppColors.borderStrong,
                    width: 3),
              ),
            ),
            child: GpStack(gap: 6, children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                      published
                          ? 'Your reply on Google'
                          : 'Your draft reply (not on Google yet)',
                      style: GpText.label),
                  if (aiGenerated && !published)
                    const GpChip('Written by AI', icon: Icons.auto_awesome),
                ],
              ),
              Text(_reply, style: GpText.lead),
            ]),
          ),

        if (editing)
          GpStack(gap: 6, children: [
            Text(
                _mode == 'editPublished'
                    ? 'Change your reply on Google'
                    : 'Your reply',
                style: GpText.label),
            TextField(
              controller: _text,
              focusNode: _focus,
              readOnly: working,
              minLines: 5,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14),
              decoration: gpInputDecoration(),
            ),
            Text(
              tooLong
                  ? 'Too long: ${trimmed.length} of $rvMaxReplyLength characters. Please shorten it.'
                  : 'Public on Google. ${trimmed.length} of $rvMaxReplyLength characters.',
              style: tooLong ? GpText.error : GpText.note,
            ),
            if (_mode == 'edit' &&
                aiGenerated &&
                unchangedDraft &&
                trimmed.isNotEmpty)
              const Text('Written by AI. Read it before you publish.',
                  style: GpText.note),
          ]),

        if (flags.isNotEmpty && !published && (_reply.isNotEmpty || editing))
          GpCallout(
            tone: GpTone.alert,
            title: 'Check before you publish',
            child: _Bullets(flags.map((f) => rvPolicyWords[f]!).toList()),
          ),

        if (!publishAvailable && !published && editing)
          const Text(
              'Replies can go on Google once Google verifies your profile. You can save a draft now.',
              style: GpText.note),

        if (_confirm == null)
          _buttons(
            published: published,
            working: working,
            trimmed: trimmed,
            tooLong: tooLong,
            unchangedDraft: unchangedDraft,
            publishAvailable: publishAvailable,
          ),

        if (_confirm == 'publish')
          GpConfirmBox(
            text:
                'Publish this reply on Google? Everyone who sees your profile can read it.',
            confirmLabel: 'Yes, publish',
            cancelLabel: 'Not now',
            busy: _busy == 'publish',
            onConfirm: _publish,
            onCancel: _cancelConfirm,
          ),

        if (_confirm == 'delete')
          GpConfirmBox(
            text:
                'Delete your reply from Google? The review will show as not answered.',
            confirmLabel: 'Yes, delete reply',
            cancelLabel: 'Keep it',
            danger: true,
            busy: _busy == 'delete',
            onConfirm: _remove,
            onCancel: _cancelConfirm,
          ),

        if (_error != null)
          GpCallout(
            tone: GpTone.bad,
            text: _error!.message,
            child: (_error!.flags.isEmpty && _error!.hint.isEmpty)
                ? null
                : GpStack(gap: 6, children: [
                    if (_error!.flags.isNotEmpty)
                      _Bullets(
                          _error!.flags.map((f) => rvPolicyWords[f]!).toList()),
                    if (_error!.hint.isNotEmpty)
                      Text(_error!.hint, style: GpText.note),
                  ]),
          ),

        if (_notice.isNotEmpty)
          Semantics(
            liveRegion: true,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.check_circle_outline,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_notice,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.success, height: 1.35)),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _buttons({
    required bool published,
    required bool working,
    required String trimmed,
    required bool tooLong,
    required bool unchangedDraft,
    required bool publishAvailable,
  }) {
    VoidCallback? when(bool ok, VoidCallback fn) => ok ? fn : null;
    final hasReply = _reply.isNotEmpty;

    if (_mode == 'view' && !published) {
      return GpButtons(children: [
        GpButton(
          label: hasReply ? 'Write again with AI' : 'Write with AI',
          icon: Icons.auto_awesome_outlined,
          small: true,
          busy: _busy == 'draft',
          onPressed: when(!working, _draft),
        ),
        GpButton.ghost(
          label: hasReply ? 'Edit draft' : 'Write a reply',
          icon: Icons.edit_outlined,
          small: true,
          onPressed: when(!working, () => _openEditor('edit')),
        ),
      ]);
    }

    if (_mode == 'edit') {
      return GpButtons(children: [
        GpButton(
          label: 'Publish to Google',
          icon: Icons.send_outlined,
          small: true,
          onPressed: when(
              !working && trimmed.isNotEmpty && !tooLong && publishAvailable,
              () => _askConfirm('publish')),
        ),
        GpButton.ghost(
          label: 'Save',
          icon: Icons.edit_outlined,
          small: true,
          busy: _busy == 'save',
          onPressed: when(
              !working &&
                  trimmed.isNotEmpty &&
                  !tooLong &&
                  !(str(_review['reply_status']) != 'none' && unchangedDraft),
              _save),
        ),
        GpButton.ghost(
          label: trimmed.isNotEmpty ? 'Write again with AI' : 'Write with AI',
          icon: Icons.auto_awesome_outlined,
          small: true,
          busy: _busy == 'draft',
          onPressed: when(!working, _draft),
        ),
        GpButton.ghost(
          label: 'Cancel',
          small: true,
          onPressed: when(!working, _closeEditor),
        ),
      ]);
    }

    if (_mode == 'view' && published) {
      return GpButtons(children: [
        GpButton.ghost(
          label: 'Edit',
          icon: Icons.edit_outlined,
          small: true,
          onPressed: when(!working, () => _openEditor('editPublished')),
        ),
        GpButton.ghost(
          label: 'Delete reply',
          icon: Icons.delete_outline,
          small: true,
          danger: true,
          onPressed: when(!working, () => _askConfirm('delete')),
        ),
      ]);
    }

    if (_mode == 'editPublished') {
      return GpButtons(children: [
        GpButton(
          label: 'Save on Google',
          icon: Icons.send_outlined,
          small: true,
          busy: _busy == 'editPublished',
          onPressed: when(
              !working && trimmed.isNotEmpty && !tooLong && !unchangedDraft,
              _savePublished),
        ),
        GpButton.ghost(
          label: 'Cancel',
          small: true,
          onPressed: when(!working, _closeEditor),
        ),
      ]);
    }
    return const SizedBox.shrink();
  }
}

class _Bullets extends StatelessWidget {
  final List<String> items;
  const _Bullets(this.items);

  @override
  Widget build(BuildContext context) {
    return GpStack(gap: 4, children: [
      for (final item in items)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('•  ', style: GpText.lead),
          Expanded(child: Text(item, style: GpText.lead)),
        ]),
    ]);
  }
}
