// AI assistant chat — the message box (website
// dashboard/AssistantComposer.jsx): text, one photo attached (uploaded as soon
// as it is picked; PNG / JPEG / WebP up to 5 MB), Send, and the starter
// commands while the chat is empty (a chip fills the box).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'assistant_utils.dart';

/// The photo picked for the next message.
class _Attachment {
  final int token;
  final String status; // uploading | ready | error
  final String name;
  final String? preview; // local path
  final Map<String, dynamic>? data;
  final String? error;
  const _Attachment({
    required this.token,
    required this.status,
    required this.name,
    this.preview,
    this.data,
    this.error,
  });
}

class AssistantComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool busy;
  final List<String> suggestions;

  /// The text and the uploaded photo ({ id, name, url, preview }) or null.
  final void Function(String text, Map<String, dynamic>? attachment) onSend;

  const AssistantComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.busy,
    required this.onSend,
    this.suggestions = const [],
  });

  @override
  State<AssistantComposer> createState() => _AssistantComposerState();
}

class _AssistantComposerState extends State<AssistantComposer> {
  _Attachment? _attachment;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant AssistantComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _remove() {
    setState(() => _attachment = null);
    widget.focusNode.requestFocus();
  }

  Future<void> _pick() async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      picked = null;
    }
    if (picked == null || !mounted) return;
    final file = picked;
    final name = assistantFileName(file);
    final token = ++_token;
    final problem = await assistantPhotoProblem(file);
    if (!mounted || token != _token) return;
    if (problem.isNotEmpty) {
      setState(
        () => _attachment = _Attachment(
          token: token,
          status: 'error',
          name: name,
          error: problem,
        ),
      );
      return;
    }
    setState(
      () => _attachment = _Attachment(
        token: token,
        status: 'uploading',
        name: name,
        preview: file.path,
      ),
    );
    try {
      final data = await GoogleProfileApi.instance.assistantAttach(
        File(file.path),
      );
      if (data is! Map || str(data['id']).isEmpty) {
        throw assistantMessageError('no id');
      }
      if (!mounted || _attachment?.token != token) return;
      setState(
        () => _attachment = _Attachment(
          token: token,
          status: 'ready',
          name: name,
          preview: file.path,
          data: Map<String, dynamic>.from(data),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      if (_attachment?.token != token) return;
      final text = gpErrorCode(e) == 'client'
          ? 'The photo did not upload. Please try again.'
          : assistantErrorText(
              e,
              'The photo did not upload. Please try again.',
            );
      setState(
        () => _attachment = _Attachment(
          token: token,
          status: 'error',
          name: name,
          preview: file.path,
          error: text,
        ),
      );
    }
  }

  bool get _uploading => _attachment?.status == 'uploading';

  String get _text => widget.controller.text.trim();

  bool get _canSend =>
      !widget.busy &&
      !_uploading &&
      _text.isNotEmpty &&
      _text.length <= assistantPromptMax;

  void _send() {
    if (!_canSend) return;
    final a = _attachment;
    final ready = a != null && a.status == 'ready' ? a : null;
    widget.onSend(
      _text,
      ready == null
          ? null
          : {
              'id': ready.data!['id'],
              'name': ready.name,
              'url': ready.data!['url'],
              'preview': ready.preview,
            },
    );
    setState(() => _attachment = null);
  }

  @override
  Widget build(BuildContext context) {
    final a = _attachment;
    final length = widget.controller.text.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: GpStack(
        gap: 8,
        cross: CrossAxisAlignment.stretch,
        children: [
          if (widget.suggestions.isNotEmpty)
            GpStack(
              gap: 6,
              children: [
                const Text('Try one of these:', style: GpText.note),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (_, i) {
                      final s = widget.suggestions[i];
                      return ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12.5)),
                        backgroundColor: AppColors.primaryTint,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        onPressed: () {
                          widget.controller.value = TextEditingValue(
                            text: s,
                            selection: TextSelection.collapsed(
                              offset: s.length,
                            ),
                          );
                          widget.focusNode.requestFocus();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          if (a != null)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: a.status == 'error'
                    ? AppColors.errorTint
                    : AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: a.status == 'error'
                      ? AppColors.error.withValues(alpha: 0.3)
                      : AppColors.border,
                ),
              ),
              child: Row(
                children: [
                  if (a.preview != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(
                        File(a.preview!),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.attach_file, size: 18),
                      ),
                    )
                  else
                    const Icon(Icons.attach_file, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GpStack(
                      gap: 2,
                      children: [
                        Text(
                          a.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GpText.label,
                        ),
                        if (a.status == 'uploading')
                          const GpLoadingLine('Uploading…')
                        else if (a.status == 'ready')
                          const Text(
                            'Photo ready. It goes with your next message.',
                            style: GpText.note,
                          )
                        else
                          Text(a.error ?? '', style: GpText.error),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Remove ${a.name}',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _remove,
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Attach a photo',
                icon: const Icon(Icons.attach_file),
                color: AppColors.textSecondary,
                onPressed: _uploading ? null : _pick,
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(assistantPromptMax),
                  ],
                  style: const TextStyle(fontSize: 14),
                  decoration: gpInputDecoration(
                    hint: 'Ask anything, or tell the AI what to change',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: 'Send',
                child: SizedBox(
                  width: 46,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _canSend ? _send : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: widget.busy ? 0.75 : 0.4,
                      ),
                      disabledForegroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, size: 20),
                  ),
                ),
              ),
            ],
          ),
          if (length >= assistantPromptMax - 100)
            Text(
              '$length / $assistantPromptMax',
              textAlign: TextAlign.right,
              style: GpText.note,
            ),
        ],
      ),
    );
  }
}
