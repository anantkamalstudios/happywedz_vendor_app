// AI assistant chat (website dashboard/AssistantChat.jsx) — GrowthOS's Command
// Center for the Google profile, inside "Improve with AI": today's message
// (coach items with their action buttons), the chat of the last 30 days
// (questions with their answers, command cards), and the message box with one
// photo. A message is read as a question (the answer text) or a command (a
// card that changes nothing until the vendor presses Apply / Publish to
// Google). "Clear chat" asks first.
// API: assistantCoach / History / Suggestions / Send / Attach / Clear (+ the card's calls).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/common_app_bar.dart';
import '../../../widgets/app_shimmer.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'assistant_coach.dart';
import 'assistant_command_card.dart';
import 'assistant_composer.dart';
import 'assistant_message.dart';
import 'assistant_utils.dart';

/// "Add more photos" in today's tips: at most this many photos in one go.
const int _photosAtOnce = 10;

class GpAssistantChatScreen extends StatefulWidget {
  const GpAssistantChatScreen({
    super.key,
    required this.onOpenTab,
    required this.onOpenFixes,
    required this.onChanged,
  });

  final void Function(String tabId) onOpenTab;
  final VoidCallback onOpenFixes;
  final VoidCallback onChanged;

  @override
  State<GpAssistantChatScreen> createState() => _GpAssistantChatScreenState();
}

class _GpAssistantChatScreenState extends State<GpAssistantChatScreen> {
  final _api = GoogleProfileApi.instance;
  final _prompt = TextEditingController();
  final _inputFocus = FocusNode();
  final _scroll = ScrollController();

  GpLoad<dynamic> _coach = const GpLoad.loading();
  GpLoad<dynamic> _history = const GpLoad.loading();
  GpLoad<dynamic> _suggestions = const GpLoad.loading();

  List<AssistantTurn> _fresh = []; // this visit's turns
  bool _busy = false;
  String _photoNote = '';
  bool _confirming = false;
  bool _clearing = false;
  Object? _clearError;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _loadCoach();
    _loadHistory();
    _loadSuggestions();
  }

  @override
  void dispose() {
    _prompt.dispose();
    _inputFocus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Loading (website useLoad) ─────────────────────────────────────────────

  Future<void> _loadCoach() async {
    setState(() => _coach = const GpLoad.loading());
    try {
      final data = await _api.assistantCoach();
      if (!mounted) return;
      setState(() => _coach = GpLoad.ready(data));
    } catch (e) {
      if (!mounted || gpHandleLocked(context, e)) return;
      setState(() => _coach = GpLoad.failed(e));
    }
    _scrollOnOpen();
  }

  Future<void> _loadHistory() async {
    setState(() => _history = const GpLoad.loading());
    try {
      final data = await _api.assistantHistory();
      if (!mounted) return;
      setState(() => _history = GpLoad.ready(data));
    } catch (e) {
      if (!mounted || gpHandleLocked(context, e)) return;
      setState(() => _history = GpLoad.failed(e));
    }
    _scrollOnOpen();
  }

  Future<void> _loadSuggestions() async {
    try {
      final data = await _api.assistantSuggestions();
      if (!mounted) return;
      setState(() => _suggestions = GpLoad.ready(data));
    } catch (e) {
      if (!mounted || gpHandleLocked(context, e)) return;
      setState(() => _suggestions = GpLoad.failed(e));
    }
  }

  // ── Scrolling ─────────────────────────────────────────────────────────────

  /// The chat opens at its newest message (today's AI message is the last one).
  void _scrollOnOpen() {
    if (_opened || _history.isLoading || _coach.isLoading) return;
    _opened = true;
    _scrollToEnd(animate: false);
  }

  void _scrollToEnd({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(
          end,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(end);
        // Photos and cards may still grow after the first frame.
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && _scroll.hasClients) {
            _scroll.jumpTo(_scroll.position.maxScrollExtent);
          }
        });
      }
    });
  }

  void _setFresh(List<AssistantTurn> list) {
    setState(() => _fresh = list);
    _scrollToEnd();
  }

  void _replaceTurn(String key, AssistantTurn turn) {
    _setFresh([for (final t in _fresh) t.key == key ? turn : t]);
  }

  // ── Sending ───────────────────────────────────────────────────────────────

  /// Sends one message (with a photo already uploaded, or a file to upload
  /// first) and shows the answer.
  Future<void> _submit({
    required String text,
    Map<String, dynamic>? attachment,
    File? file,
    String? preview,
  }) async {
    if (text.isEmpty) return;
    final key = assistantNewKey();
    AssistantTurn base(
      String type, {
      Map<String, dynamic>? sent,
      String? stage,
      String answer = '',
      Map<String, dynamic>? command,
      Object? error,
      bool keepFile = false,
    }) => AssistantTurn(
      key: key,
      type: type,
      text: text,
      preview: preview,
      attachments: sent == null ? const [] : [sent],
      stage: stage,
      answer: answer,
      command: command,
      error: error,
      attachment: keepFile ? sent : null,
      file: keepFile && sent == null ? file : null,
    );

    setState(() {
      _busy = true;
      _fresh = [
        ..._fresh,
        base(
          'pending',
          sent: attachment,
          stage: file != null && attachment == null ? 'upload' : 'ai',
        ),
      ];
    });
    _scrollToEnd();

    var sent = attachment;
    AssistantTurn turn;
    try {
      if (sent == null && file != null) {
        final data = await _api.assistantAttach(file);
        final id = data is Map ? str(data['id']) : '';
        if (id.isEmpty) {
          throw assistantMessageError(
            'The photo did not upload. Please try again.',
          );
        }
        final d = data as Map;
        sent = {
          'id': id,
          'name': str(d['name']).isNotEmpty
              ? str(d['name'])
              : file.path.split(Platform.pathSeparator).last,
          'url': d['url'],
        };
        if (!mounted) return;
        _replaceTurn(key, base('pending', sent: sent, stage: 'ai'));
      }
      final answer = await _api.assistantSend(text, str(sent?['id']));
      final a = answer is Map ? answer : const {};
      if (a['kind'] == 'command' && a['command'] is Map) {
        turn = base(
          'command',
          sent: sent,
          command: Map<String, dynamic>.from(a['command'] as Map),
        );
      } else if (a['kind'] == 'question') {
        turn = base('question', sent: sent, answer: str(a['answer']));
      } else {
        throw assistantMessageError(
          "We couldn't read the AI's answer. Please try again.",
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      turn = base('failed', sent: sent, error: e, keepFile: true);
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _replaceTurn(key, turn);
  }

  void _sendText(String text, Map<String, dynamic>? attachment) {
    if (_busy) return;
    _prompt.clear();
    setState(() => _photoNote = '');
    _submit(
      text: text,
      attachment: attachment == null
          ? null
          : {
              'id': attachment['id'],
              'name': attachment['name'],
              'url': attachment['url'],
            },
      preview: attachment?['preview'] as String?,
    );
  }

  void _retry(AssistantTurn turn) {
    if (_busy) return;
    setState(() => _fresh = _fresh.where((t) => t.key != turn.key).toList());
    _submit(
      text: turn.text,
      attachment: turn.attachment,
      file: turn.file,
      preview: turn.preview,
    );
  }

  // ── Coach actions ─────────────────────────────────────────────────────────

  /// Coach "Upload photo": pick a photo, then send the item's command with it.
  /// "Add more photos" (purpose photo) takes up to [_photosAtOnce] photos and
  /// sends them straight to Google as photos (category Other), one by one,
  /// without the AI.
  Future<void> _onUploadFor(String command, String purpose) async {
    if (_busy) return;
    final many = purpose == 'photo';
    setState(() => _photoNote = '');
    final picker = ImagePicker();
    List<XFile> picked;
    try {
      if (many) {
        picked = await picker.pickMultiImage();
      } else {
        final one = await picker.pickImage(source: ImageSource.gallery);
        picked = one == null ? [] : [one];
      }
    } catch (_) {
      picked = [];
    }
    if (!mounted || picked.isEmpty) return;

    if (many) {
      String bad = '';
      final good = <XFile>[];
      for (final f in picked) {
        final problem = await assistantPhotoProblem(f);
        if (problem.isEmpty) {
          good.add(f);
        } else if (bad.isEmpty) {
          bad = problem;
        }
      }
      if (!mounted) return;
      final extra = good.length > _photosAtOnce
          ? ' Only the first $_photosAtOnce are sent; add the rest after.'
          : '';
      setState(
        () => _photoNote = bad.isNotEmpty
            ? 'Some photos were left out: $bad$extra'
            : extra.trim(),
      );
      if (good.isNotEmpty) _sendPhotos(good.take(_photosAtOnce).toList());
      return;
    }

    final file = picked.first;
    if (command.isEmpty) return;
    final problem = await assistantPhotoProblem(file);
    if (!mounted) return;
    if (problem.isNotEmpty) {
      setState(() => _photoNote = problem);
      return;
    }
    setState(() => _photoNote = '');
    _submit(text: command, file: File(file.path), preview: file.path);
  }

  Future<void> _sendPhotos(List<XFile> files) async {
    final key = assistantNewKey();
    final shown = [
      for (var i = 0; i < files.length; i++)
        <String, dynamic>{
          'id': '$key-$i',
          'kind': 'image',
          'name': assistantFileName(files[i]),
          'local': files[i].path,
        },
    ];
    final text = files.length == 1
        ? 'Add this photo to my Google profile'
        : 'Add these ${files.length} photos to my Google profile';
    AssistantTurn pending(int done) => AssistantTurn(
      key: key,
      type: 'pending',
      text: text,
      attachments: shown,
      stage: 'upload',
      label: 'Sending photo ${done + 1} of ${files.length} to Google…',
    );
    setState(() {
      _busy = true;
      _fresh = [..._fresh, pending(0)];
    });
    _scrollToEnd();

    var sent = 0;
    final failed = <String>[];
    for (var i = 0; i < files.length; i++) {
      if (!mounted) return;
      _replaceTurn(key, pending(i));
      try {
        await _api.addPhoto(File(files[i].path), 'ADDITIONAL');
        sent += 1;
      } catch (e) {
        if (!mounted) return;
        if (gpHandleLocked(context, e)) return;
        final m = e is GpException ? e.serverMessage : null;
        failed.add(
          '${assistantFileName(files[i])}: ${(m == null || m.isEmpty) ? 'not sent' : m}',
        );
      }
    }
    if (!mounted) return;
    final answer = [
      sent > 0
          ? '$sent ${sent == 1 ? 'photo' : 'photos'} sent to Google as "Other". Google checks photos before showing them.'
          : 'No photo was sent.',
      if (failed.isNotEmpty) ...['Not sent:', ...failed],
    ].join('\n');
    setState(() => _busy = false);
    _replaceTurn(
      key,
      AssistantTurn(
        key: key,
        type: 'question',
        text: text,
        attachments: shown,
        answer: answer,
      ),
    );
    if (sent > 0) widget.onChanged();
  }

  /// Coach "Type answer": the box starts with the command, the vendor types the rest.
  void _onTypeAnswer(String prefix) {
    _prompt.value = TextEditingValue(
      text: prefix,
      selection: TextSelection.collapsed(offset: prefix.length),
    );
    _inputFocus.requestFocus();
  }

  // ── Leaving for a dashboard tab ───────────────────────────────────────────

  void _openTab(String tab) {
    Navigator.pop(context);
    widget.onOpenTab(tab);
  }

  void _openFixes() {
    Navigator.pop(context);
    widget.onOpenFixes();
  }

  // ── Cards ─────────────────────────────────────────────────────────────────

  /// A card that changed (Apply, Undo, Choose …): in this visit's turns, or in the loaded chat.
  void _replaceCommand(Map<String, dynamic> next) {
    final id = str(next['id']);
    if (_fresh.any((t) => t.type == 'command' && t.commandId == id)) {
      setState(
        () => _fresh = [
          for (final t in _fresh)
            t.type == 'command' && t.commandId == id
                ? t.copyWith(command: next)
                : t,
        ],
      );
    } else {
      final rows = assistantListOf(
        _history.data,
      ).map((r) => r is Map && str(r['id']) == id ? next : r).toList();
      setState(() => _history = GpLoad.ready(rows));
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<void> _clear() async {
    setState(() {
      _clearing = true;
      _clearError = null;
    });
    try {
      await _api.assistantClear();
      if (!mounted) return;
      setState(() {
        _history = const GpLoad.ready([]);
        _fresh = [];
        _confirming = false;
        _clearing = false;
      });
      gpToast(context, 'The chat is cleared.');
    } catch (e) {
      if (!mounted || gpHandleLocked(context, e)) return;
      setState(() {
        _clearError = e;
        _clearing = false;
      });
    }
  }

  // ── View ──────────────────────────────────────────────────────────────────

  Widget _renderTurn(AssistantTurn turn, {bool compact = false}) {
    Widget? reply;
    switch (turn.type) {
      case 'pending':
        reply = AssistantTyping(
          label:
              turn.label ??
              (turn.stage == 'upload'
                  ? 'Uploading your photo…'
                  : 'The AI is writing… This can take up to a minute.'),
        );
        break;
      case 'question':
        reply = AssistantBubble(
          child: AssistantText(
            turn.answer.isNotEmpty
                ? turn.answer
                : 'The AI had no answer this time. Please ask again.',
            selectable: true,
          ),
        );
        break;
      case 'command':
        reply = AssistantBubble(
          wide: true,
          child: AssistantCommandCard(
            key: ValueKey('cmd-${turn.commandId}'),
            command: turn.command!,
            onChange: _replaceCommand,
            onChanged: widget.onChanged,
            onOpenTab: _openTab,
            compact: compact,
          ),
        );
        break;
      case 'failed':
        reply = AssistantBubble(
          child: GpStack(
            gap: 10,
            children: [
              AssistantErrorText(assistantErrorText(turn.error)),
              GpButton.ghost(
                label: 'Try again',
                icon: Icons.refresh,
                small: true,
                onPressed: _busy ? null : () => _retry(turn),
              ),
            ],
          ),
        );
        break;
    }
    return Column(
      key: ValueKey(turn.key),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssistantUserBubble(
          text: turn.text,
          attachments: turn.attachments,
          localPreview: turn.preview,
        ),
        if (reply != null) reply,
      ],
    );
  }

  Widget _confirmBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: GpStack(
        gap: 10,
        children: [
          const Text('Clear the chat?', style: GpText.label),
          const Text(
            "This removes your messages and the AI's answers from this chat. Changes already made on Google stay.",
            style: GpText.note,
          ),
          if (_clearError != null)
            GpCallout(tone: GpTone.bad, text: gpErrorMessage(_clearError)),
          GpButtons(
            children: [
              GpButton(
                label: 'Clear chat',
                danger: true,
                small: true,
                busy: _clearing,
                onPressed: _clear,
              ),
              GpButton.ghost(
                label: 'Cancel',
                small: true,
                onPressed: _clearing
                    ? null
                    : () => setState(() {
                        _confirming = false;
                        _clearError = null;
                      }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final freshIds = _fresh
        .where((t) => t.type == 'command')
        .map((t) => t.commandId)
        .toSet();
    final past = _history.isReady
        ? assistantTurnsFromHistory(
            _history.data,
          ).where((t) => !freshIds.contains(t.commandId)).toList()
        : <AssistantTurn>[];
    final turns = [...past, ..._fresh];
    final empty = !_history.isLoading && turns.isEmpty;
    final starters = empty && _suggestions.isReady
        ? assistantSuggestionTexts(_suggestions.data).take(6).toList()
        : const <String>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: CommonAppBar(
        title: 'AI assistant',
        actions: [
          if (turns.isNotEmpty && !_confirming)
            IconButton(
              tooltip: 'Clear chat',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy
                  ? null
                  : () => setState(() => _confirming = true),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_confirming) _confirmBox(),
            Expanded(
              child: ListView(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Ask about your profile or tell the AI what to change. Nothing goes to Google until you tap.',
                      style: GpText.note,
                    ),
                  ),
                  if (_history.isLoading) const _ChatShimmer(),
                  if (_history.isError)
                    AssistantBubble(
                      child: GpStack(
                        gap: 10,
                        children: [
                          AssistantErrorText(
                            assistantErrorText(
                              _history.error,
                              "We couldn't load your earlier messages.",
                            ),
                          ),
                          GpButton.ghost(
                            label: 'Try again',
                            icon: Icons.refresh,
                            small: true,
                            onPressed: _loadHistory,
                          ),
                        ],
                      ),
                    ),
                  // Earlier visits' finished cards are short; today's AI message
                  // comes after them, then this visit's messages.
                  for (final turn in past) _renderTurn(turn, compact: true),
                  AssistantCoach(
                    coach: _coach,
                    busy: _busy,
                    onSend: (text) => _sendText(text, null),
                    onUploadFor: _onUploadFor,
                    onOpenFixes: _openFixes,
                    onOpenTab: _openTab,
                    onTypeAnswer: _onTypeAnswer,
                    onReload: _loadCoach,
                  ),
                  for (final turn in _fresh) _renderTurn(turn),
                ],
              ),
            ),
            if (_photoNote.isNotEmpty)
              Container(
                width: double.infinity,
                color: AppColors.errorTint,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: AssistantErrorText(_photoNote),
              ),
            AssistantComposer(
              controller: _prompt,
              focusNode: _inputFocus,
              busy: _busy,
              suggestions: starters,
              onSend: _sendText,
            ),
          ],
        ),
      ),
    );
  }
}

/// The chat while its earlier messages load.
class _ChatShimmer extends StatelessWidget {
  const _ChatShimmer();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppShimmer(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ShimmerBox(width: w * 0.55, height: 44, radius: 14),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: w * 0.7, height: 90, radius: 14),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ShimmerBox(width: w * 0.45, height: 44, radius: 14),
            ),
          ],
        ),
      ),
    );
  }
}
