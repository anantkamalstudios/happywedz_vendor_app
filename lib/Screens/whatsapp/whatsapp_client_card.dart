import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/whatsapp_icon.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';

/// "Message on WhatsApp" on a client's page — the website's `WhatsAppReply`
/// (ClientExtras.jsx): a free-text message, an approved template, or a photo
/// or file, plus clearing a client's opt-out.
///
/// A plain message only reaches a client who wrote in the last 24 hours, and
/// nothing here knows whether they did, so the send is attempted and the
/// refusal explained. Shown only when WhatsApp is connected.
class WhatsAppClientCard extends ConsumerStatefulWidget {
  final Map client;

  /// The client's stored files, so a file picked from the phone can be found
  /// again after it is uploaded.
  final List files;

  /// The client changed (opt-out cleared, a file uploaded): reload the page.
  final Future<void> Function() onClientChanged;

  const WhatsAppClientCard({
    super.key,
    required this.client,
    required this.files,
    required this.onClientChanged,
  });

  @override
  ConsumerState<WhatsAppClientCard> createState() => _WhatsAppClientCardState();
}

class _WhatsAppClientCardState extends ConsumerState<WhatsAppClientCard> {
  final _api = CrmApi();
  final _text = TextEditingController();
  final _mediaUrl = TextEditingController();
  late final _draft = WaTemplateDraft(
    firstValue: '${widget.client['name'] ?? ''}',
  );

  // Templates, fetched only when the vendor asks for one: a client's page
  // should not call the provider on every open for a list most visits never
  // need.
  bool _templating = false;
  List<Map>? _templates;
  bool _attaching = false;
  bool _uploading = false;
  bool _sending = false;
  String _error = '';
  String _sent = '';

  String get _name => '${widget.client['name'] ?? ''}'.isEmpty
      ? 'this client'
      : '${widget.client['name']}';

  @override
  void initState() {
    super.initState();
    void clearError() {
      // A failure left on screen while the vendor retypes reads as though the
      // new attempt failed too.
      if (_error.isNotEmpty) _error = '';
      setState(() {});
    }

    _text.addListener(clearError);
    _mediaUrl.addListener(clearError);
    _draft.addListener(clearError);
  }

  @override
  void dispose() {
    _text.dispose();
    _mediaUrl.dispose();
    _draft.dispose();
    super.dispose();
  }

  String? _handle(Object e, String fallback) =>
      waHandleError(context, ref, e, fallback);

  Future<void> _openTemplates() async {
    setState(() {
      _templating = true;
      _error = '';
    });
    if (_templates != null) return;
    try {
      final data = await _api.whatsappTemplates();
      if (!mounted) return;
      setState(
        () => _templates = waUniqueByName(
          waApproved(List.from(data['templates'] ?? const [])),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = _handle(e, 'Could not read your templates.');
      setState(() {
        _templates = const [];
        if (msg != null) _error = msg;
      });
    }
  }

  Future<void> _sendTemplate() async {
    if (_draft.name.isEmpty) return;
    setState(() {
      _sending = true;
      _error = '';
      _sent = '';
    });
    try {
      final data = await _api.whatsappSendTemplate(widget.client['id'], {
        'templateName': _draft.name,
        'variables': _draft.values,
      });
      if (!mounted) return;
      setState(() {
        _sent = '${data['message'] ?? 'Sent to $_name.'}';
        _templating = false;
      });
      _draft.reset();
    } catch (e) {
      if (!mounted) return;
      final msg = _handle(e, 'Could not send this template.');
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// The type WhatsApp needs, from the address: a PDF is a document, a JPEG
  /// a photo, and they are not interchangeable.
  static String _typeOf(String url) {
    final lower = url.toLowerCase();
    if (RegExp(r'\.(jpe?g|png|webp|gif)(\?|$)').hasMatch(lower)) return 'image';
    if (RegExp(r'\.(mp4|mov|3gp)(\?|$)').hasMatch(lower)) return 'video';
    if (RegExp(r'\.(mp3|ogg|m4a|aac)(\?|$)').hasMatch(lower)) return 'audio';
    final mime = lookupMimeType(lower.split('?').first) ?? '';
    if (mime.startsWith('image/')) return 'image';
    if (mime.startsWith('video/')) return 'video';
    if (mime.startsWith('audio/')) return 'audio';
    return 'document';
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    final media = _mediaUrl.text.trim();
    if (_attaching ? media.isEmpty : text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = '';
      _sent = '';
    });
    try {
      if (_attaching) {
        await _api.whatsappFile(widget.client['id'], {
          'type': _typeOf(media),
          'mediaUrl': media,
          'caption': text,
        });
        if (!mounted) return;
        _mediaUrl.clear();
      } else {
        await _api.whatsappReply(widget.client['id'], {'text': text});
        if (!mounted) return;
      }
      setState(() => _sent = 'Sent to $_name.');
      _text.clear();
    } catch (e) {
      if (!mounted) return;
      final msg = _handle(e, 'Could not send this message.');
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// WhatsApp fetches a file from a public link, so a file on the phone is
  /// first stored with the client (Photos & documents) and its link used.
  Future<void> _pickFromPhone() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
    );
    final file = picked?.files.single;
    if (!mounted || file?.path == null) return;
    if (file!.size > 10 * 1024 * 1024) {
      setState(() => _error = '${file.name} is larger than 10 MB.');
      return;
    }
    final before = {
      for (final f in widget.files)
        if (f is Map) '${f['id']}',
    };
    setState(() {
      _uploading = true;
      _error = '';
    });
    try {
      final res = await _api.uploadFiles(widget.client['id'], [
        File(file.path!),
      ]);
      String? url;
      final returned = res['files'] ?? res['file'];
      final list = returned is List
          ? returned
          : (returned is Map ? [returned] : const []);
      for (final f in list) {
        if (f is Map && f['url'] != null) url = '${f['url']}';
      }
      if (url == null) {
        // Not in the answer: read the client back and take the new file.
        final fresh = await _api.client(widget.client['id']);
        for (final f in List.from(fresh['files'] ?? const [])) {
          if (f is Map && !before.contains('${f['id']}') && f['url'] != null) {
            url = '${f['url']}';
          }
        }
      }
      if (!mounted) return;
      final full = CrmApi.imageUrl(url);
      if (full == null) {
        setState(
          () => _error =
              'Uploaded, but its link did not come back. Try a web address instead.',
        );
      } else {
        _mediaUrl.text = full;
      }
      widget.onClientChanged();
    } catch (e) {
      if (!mounted) return;
      final msg = _handle(e, 'Upload failed.');
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _allowAgain() {
    showCrmConfirm(
      context,
      title: 'Message $_name again?',
      text:
          '$_name asked you to stop messaging them. Only do this if they have asked to '
          'hear from you again.',
      confirmLabel: 'They asked to hear from me',
      onConfirm: (_) async {
        setState(() {
          _sending = true;
          _error = '';
        });
        try {
          final data = await _api.clearWhatsappOptOut(widget.client['id']);
          if (!mounted) return false;
          setState(
            () => _sent = '${data['message'] ?? 'They can be messaged again.'}',
          );
          // The flag lives on the client, so the page has to say so.
          await widget.onClientChanged();
          return true;
        } catch (e) {
          if (!mounted) return false;
          final msg = _handle(e, 'Could not change that.');
          if (msg != null) setState(() => _error = msg);
          return false;
        } finally {
          if (mounted) setState(() => _sending = false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.client;
    final optedOut = c['whatsappOptedOutAt'] != null;
    final canSend = _attaching
        ? _mediaUrl.text.trim().isNotEmpty
        : _text.text.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              WhatsAppIcon(size: 18),
              SizedBox(width: 8),
              Text(
                'Message on WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (optedOut)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: '$_name asked you to stop messaging them',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              '${'${c['whatsappOptOutText'] ?? ''}'.isNotEmpty ? ' — they wrote "${c['whatsappOptOutText']}".' : '.'}'
                              ' They are left out of every broadcast, and messages here will be '
                              'refused.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton(
                    onPressed: _sending ? null : _allowAgain,
                    child: const Text('They asked to hear from me again'),
                  ),
                ],
              ),
            ),
          if (_error.isNotEmpty) WaErrorBox(_error),
          if (_sent.isNotEmpty) CrmNotice(_sent, warn: false),
          if (_templating) ..._templateSection() else ..._messageSection(),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: _sending
                    ? null
                    : () => _templating
                          ? setState(() => _templating = false)
                          : _openTemplates(),
                child: Text(
                  _templating ? 'Back to a message' : 'Send a template',
                ),
              ),
              if (!_templating)
                OutlinedButton(
                  onPressed: _sending
                      ? null
                      : () => setState(() => _attaching = !_attaching),
                  child: Text(
                    _attaching ? 'Just a message' : 'Attach a photo or file',
                  ),
                ),
              ElevatedButton.icon(
                onPressed: _sending
                    ? null
                    : _templating
                    ? (_draft.name.isEmpty ? null : _sendTemplate)
                    : (canSend && !_uploading ? _send : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const WhatsAppIcon(size: 15, color: Colors.white),
                label: Text(
                  _sending
                      ? 'Sending…'
                      : _templating
                      ? (_draft.name.isEmpty
                            ? 'Choose a template'
                            : 'Send template')
                      : 'Send',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _messageSection() => [
    TextField(
      controller: _text,
      minLines: 2,
      maxLines: 6,
      textCapitalization: TextCapitalization.sentences,
      decoration: crmInputDecoration(
        hint: _attaching ? 'Caption (optional)' : 'Write to $_name…',
      ),
    ),
    const SizedBox(height: 6),
    const WaHint(
      'A plain message only reaches a client who has written to you in the last 24 hours. '
      'Outside that, WhatsApp allows approved templates only — send one below, and once '
      'they reply you can write freely again.',
    ),
    if (_attaching) ...[
      CrmField(
        label: 'Web address of the file',
        hint:
            'WhatsApp fetches the file itself, so it has to be a link anyone can open. A file '
            "from your phone is saved to this client's Photos & documents first, and its link "
            'used.',
        child: TextField(
          controller: _mediaUrl,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: crmInputDecoration(hint: 'https://…/venue-photos.pdf'),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: _uploading || _sending ? null : _pickFromPhone,
          icon: _uploading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file, size: 18),
          label: Text(
            _uploading ? 'Uploading…' : 'Choose from phone (photo or PDF)',
          ),
        ),
      ),
    ],
  ];

  List<Widget> _templateSection() => [
    Text('Approved template', style: AppTextStyles.label),
    const SizedBox(height: 6),
    if (_templates == null)
      const WaHint('Reading your templates…')
    else
      WaTemplateFields(
        templates: _templates!,
        draft: _draft,
        emptyText:
            'You have no approved templates yet. Create one on the WhatsApp screen; Meta has '
            'to approve it before it can be sent.',
        unknownHint:
            'This template was made outside HappyWedz, so we cannot show its wording or how '
            'many values it takes. Fill in the ones it uses and leave the rest blank.',
      ),
  ];
}
