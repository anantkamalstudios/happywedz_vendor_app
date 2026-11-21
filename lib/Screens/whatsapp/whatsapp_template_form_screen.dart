import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/common_app_bar.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';

/// Two forms over a template:
///
/// * a new one, submitted for Meta's approval (`POST /whatsapp/templates`);
///   submitting is all we can do — Meta approves in its own time, and the
///   template list reports the outcome;
/// * the wording of an existing one (`PUT /whatsapp/templates/wording`),
///   copied across from Wapzio so its preview and value count work.
///
/// Pops with the server's message (or '' ) when saved.
class WhatsAppTemplateFormScreen extends ConsumerStatefulWidget {
  final Map? template;

  const WhatsAppTemplateFormScreen({super.key}) : template = null;

  const WhatsAppTemplateFormScreen.wording({
    super.key,
    required Map this.template,
  });

  bool get isWording => template != null;

  @override
  ConsumerState<WhatsAppTemplateFormScreen> createState() =>
      _WhatsAppTemplateFormScreenState();
}

/// A button a template may carry. Meta allows at most three.
class _TemplateButton {
  String type = 'QUICK_REPLY';
  final text = TextEditingController();
  final value = TextEditingController();

  void dispose() {
    text.dispose();
    value.dispose();
  }
}

class _WhatsAppTemplateFormScreenState
    extends ConsumerState<WhatsAppTemplateFormScreen> {
  final _api = CrmApi();
  late final _name = TextEditingController(
    text: '${widget.template?['name'] ?? ''}',
  );
  late final _header = TextEditingController(
    text: '${widget.template?['header'] ?? ''}',
  );
  late final _body = TextEditingController(
    text: '${widget.template?['body'] ?? ''}',
  );
  late final _footer = TextEditingController(
    text: '${widget.template?['footer'] ?? ''}',
  );
  String _category = 'UTILITY';
  String _language = 'en';
  final List<_TemplateButton> _buttons = [];
  final _sample = WaTemplateDraft();
  bool _saving = false;
  String _error = '';

  /// Meta's three categories, in the words a vendor would use.
  static const _categories = {
    'UTILITY': 'Utility — about a booking, payment or document',
    'MARKETING': 'Marketing — offers and announcements',
    'AUTHENTICATION': 'Authentication — one-time codes',
  };

  static const _languages = {
    'en': 'English',
    'hi': 'Hindi',
    'mr': 'Marathi',
    'gu': 'Gujarati',
    'ta': 'Tamil',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ml': 'Malayalam',
    'bn': 'Bengali',
    'pa': 'Punjabi',
  };

  static const _buttonTypes = {
    'QUICK_REPLY': 'Quick reply',
    'URL': 'Open a link',
    'PHONE_NUMBER': 'Call a number',
  };

  @override
  void initState() {
    super.initState();
    _body.addListener(() => setState(() {}));
    _header.addListener(() => setState(() {}));
    _footer.addListener(() => setState(() {}));
    _sample.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _header.dispose();
    _body.dispose();
    _footer.dispose();
    _sample.dispose();
    for (final b in _buttons) {
      b.dispose();
    }
    super.dispose();
  }

  /// {{1}} {{2}} … in the order they must appear.
  int get _slotCount {
    final found = RegExp(
      r'\{\{\s*(\d+)\s*\}\}',
    ).allMatches(_body.text).map((m) => int.parse(m.group(1)!)).toList();
    return found.isEmpty ? 0 : found.reduce((a, b) => a > b ? a : b);
  }

  String? get _problem {
    if (!widget.isWording) {
      final name = _name.text.trim();
      if (name.isEmpty) return 'Give the template a name';
      if (!RegExp(r'^[a-z0-9_]+$').hasMatch(name)) {
        return 'Use only lowercase letters, numbers and _ in the name';
      }
    }
    final body = _body.text.trim();
    if (body.isEmpty) return 'Write the message';
    final numbers = RegExp(
      r'\{\{\s*(\d+)\s*\}\}',
    ).allMatches(body).map((m) => int.parse(m.group(1)!)).toSet();
    for (var i = 1; i <= _slotCount; i++) {
      if (!numbers.contains(i)) {
        return 'Number the values in order: {{$i}} is missing';
      }
    }
    for (final b in _buttons) {
      if (b.text.text.trim().isEmpty) return 'Every button needs its words';
      if (b.type != 'QUICK_REPLY' && b.value.text.trim().isEmpty) {
        return b.type == 'URL'
            ? 'A link button needs its address'
            : 'A call button needs its number';
      }
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _problem;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = '';
    });
    try {
      final Map<String, dynamic> res;
      if (widget.isWording) {
        res = await _api.saveWhatsappTemplateWording({
          'name': widget.template!['name'],
          'language': widget.template!['language'],
          'body': _body.text.trim(),
          'header': _header.text.trim().isEmpty ? null : _header.text.trim(),
          'footer': _footer.text.trim().isEmpty ? null : _footer.text.trim(),
        });
      } else {
        res = await _api.createWhatsappTemplate({
          'name': _name.text.trim(),
          'category': _category,
          'language': _language,
          'header': _header.text.trim().isEmpty ? null : _header.text.trim(),
          'body': _body.text.trim(),
          'footer': _footer.text.trim().isEmpty ? null : _footer.text.trim(),
          'variableCount': _slotCount,
          if (_slotCount > 0) 'examples': _sample.values,
          'buttons': [
            for (final b in _buttons)
              {
                'type': b.type,
                'text': b.text.text.trim(),
                if (b.type == 'URL') 'url': b.value.text.trim(),
                if (b.type == 'PHONE_NUMBER')
                  'phoneNumber': b.value.text.trim(),
              },
          ],
        });
      }
      if (!mounted) return;
      Navigator.pop(
        context,
        '${res['message'] ?? (widget.isWording ? 'Wording saved.' : 'Submitted to Meta for approval.')}',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        widget.isWording
            ? 'Could not save the wording.'
            : 'Could not submit this template.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = {
      'header': _header.text,
      'body': _body.text,
      'footer': _footer.text,
    };
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: widget.isWording ? 'Template wording' : 'New template',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    widget.isWording
                        ? 'Copy the wording of ${widget.template!['name']} from Wapzio so its '
                              'preview works and we know how many values it takes. This does not '
                              'change the template itself — what Meta approved is what is sent.'
                        : 'Submitted to Meta for approval. It can be sent once it shows as '
                              'approved on the Templates tab, which can take from minutes to a day.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  if (_error.isNotEmpty) WaErrorBox(_error),
                  if (!widget.isWording) ...[
                    CrmField(
                      label: 'Name',
                      hint:
                          'Lowercase letters, numbers and _ only, e.g. booking_confirmed.',
                      child: TextField(
                        controller: _name,
                        autocorrect: false,
                        onChanged: (v) {
                          final clean = v.toLowerCase().replaceAll(' ', '_');
                          if (clean != v) {
                            _name.value = TextEditingValue(
                              text: clean,
                              selection: TextSelection.collapsed(
                                offset: clean.length,
                              ),
                            );
                          }
                          setState(() {});
                        },
                        decoration: crmInputDecoration(
                          hint: 'booking_confirmed',
                        ),
                      ),
                    ),
                    CrmField(
                      label: 'Category',
                      child: CrmDropdown(
                        value: _category,
                        options: _categories,
                        onChanged: (v) => setState(() => _category = v),
                      ),
                    ),
                    CrmField(
                      label: 'Language',
                      child: CrmDropdown(
                        value: _language,
                        options: _languages,
                        onChanged: (v) => setState(() => _language = v),
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '${widget.template!['name']} · ${waLanguageName(widget.template!['language'])}',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  CrmField(
                    label: 'Header (optional)',
                    child: CrmTextInput(controller: _header, maxLength: 60),
                  ),
                  CrmField(
                    label: 'Message',
                    hint:
                        'Write {{1}}, {{2}} … where a value goes, e.g. "Hi {{1}}, your booking '
                        'for {{2}} is confirmed."',
                    child: CrmTextInput(
                      controller: _body,
                      lines: 4,
                      maxLength: 1024,
                    ),
                  ),
                  CrmField(
                    label: 'Footer (optional)',
                    child: CrmTextInput(controller: _footer, maxLength: 60),
                  ),
                  if (!widget.isWording) ...[
                    if (_slotCount > 0) ...[
                      Text('Example values', style: AppTextStyles.label),
                      const WaHint(
                        'Meta asks for an example of each value when it reviews the template.',
                      ),
                      for (var n = 1; n <= _slotCount; n++)
                        CrmField(
                          label: '{{$n}}',
                          child: CrmTextInput(
                            controller: _sample.controller(n),
                          ),
                        ),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: Text('Buttons', style: AppTextStyles.label),
                        ),
                        TextButton.icon(
                          onPressed: _buttons.length >= 3
                              ? null
                              : () => setState(
                                  () => _buttons.add(_TemplateButton()),
                                ),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add button'),
                        ),
                      ],
                    ),
                    const WaHint(
                      'Up to three. A quotation with "Confirm" and "Call us" on it is worth more '
                      'than one with a link to tap.',
                    ),
                    for (final b in _buttons) _buttonEditor(b),
                  ],
                  const SizedBox(height: 8),
                  Text('Preview', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  WaTemplateBubble(
                    template: _body.text.trim().isEmpty ? null : preview,
                    values: _sample.values,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: CrmFormButtons(
                primaryLabel: widget.isWording
                    ? 'Save wording'
                    : 'Submit for approval',
                onPrimary: _save,
                busy: _saving,
                busyLabel: widget.isWording ? 'Saving…' : 'Submitting…',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buttonEditor(_TemplateButton b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: crmCardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CrmDropdown(
                  value: b.type,
                  options: _buttonTypes,
                  onChanged: (v) => setState(() => b.type = v),
                ),
              ),
              IconButton(
                tooltip: 'Remove button',
                icon: const Icon(Icons.close, color: AppColors.error),
                onPressed: () => setState(() {
                  _buttons.remove(b);
                  b.dispose();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CrmTextInput(controller: b.text, hint: 'Button words', maxLength: 25),
          if (b.type != 'QUICK_REPLY') ...[
            const SizedBox(height: 8),
            CrmTextInput(
              controller: b.value,
              hint: b.type == 'URL' ? 'https://…' : '+91 98xxxxxxxx',
              keyboard: b.type == 'URL'
                  ? TextInputType.url
                  : TextInputType.phone,
            ),
          ],
        ],
      ),
    );
  }
}
