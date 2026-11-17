// AI assistant chat — one command's card (website
// dashboard/AssistantCommandCard.jsx): what will change (before → after),
// items, notes, the text the vendor may edit, the parts of a goal with tick
// boxes, the photo of a post, Google's questions; several matches → choose
// one; a missing photo → upload it; refused / not allowed / unsupported /
// failed → why. Nothing changes until Apply ("Publish to Google" when it
// changes Google). After Apply: the result, and Undo when it can be taken back.
// API: assistantApply / Choose / Cancel / Undo / Attach + Upload.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'assistant_message.dart';
import 'assistant_utils.dart';

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(Object? v) => listOf(
  v,
).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();

class AssistantCommandCard extends StatefulWidget {
  final Map<String, dynamic> command;
  final ValueChanged<Map<String, dynamic>> onChange;
  final VoidCallback onChanged;
  final ValueChanged<String>? onOpenTab;
  final bool compact;

  const AssistantCommandCard({
    super.key,
    required this.command,
    required this.onChange,
    required this.onChanged,
    this.onOpenTab,
    this.compact = false,
  });

  @override
  State<AssistantCommandCard> createState() => _AssistantCommandCardState();
}

class _AssistantCommandCardState extends State<AssistantCommandCard> {
  final TextEditingController _text = TextEditingController();
  final Map<String, TextEditingController> _partText = {};
  bool _editing = false;
  List<String> _ticked = [];
  Object? _photo;
  Map<String, Object?> _answers = {};
  int _gen = 0;

  String _busy = ''; // apply | cancel | undo | upload | choose:<id>
  bool _detailsOpen = false;
  Object? _error;

  Map<String, dynamic> get _c => widget.command;
  Map<String, dynamic> get _p => _map(_c['preview']);
  List<Map<String, dynamic>> get _parts => _maps(_p['parts']);
  Map<String, dynamic>? get _choice {
    final own = _p['photo_choice'];
    if (own is Map) return Map<String, dynamic>.from(own);
    for (final x in _parts) {
      if (str(x['id']) == 'post' && x['photo_choice'] is Map) {
        return Map<String, dynamic>.from(x['photo_choice'] as Map);
      }
    }
    return null;
  }

  String get _status => str(_c['status']);
  bool get _ready => _status == 'ready';
  bool get _applied => _status == 'applied';
  bool get _blocked => assistantBlocked.contains(_status);

  @override
  void initState() {
    super.initState();
    _reset();
    _text.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// A new preview (after Choose or an upload): start again from what the AI prepared.
  void _reset() {
    final p = _p;
    final editable = _map(p['editable']);
    _text.text = str(editable['value']);
    _editing = false;
    final parts = _parts;
    _ticked = parts.map((x) => str(x['id'])).toList();
    for (final c in _partText.values) {
      c.dispose();
    }
    _partText.clear();
    for (final x in parts) {
      if (x['editable'] is Map) {
        _partText[str(x['id'])] = TextEditingController(
          text: str(_map(x['editable'])['value']),
        );
      }
    }
    _photo = _choice?['selected'];
    _answers = {
      for (final q in _maps(p['attribute_form'])) str(q['name']): q['value'],
    };
    _gen += 1;
  }

  @override
  void didUpdateWidget(covariant AssistantCommandCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.command['preview'], widget.command['preview'])) {
      _reset();
    }
  }

  @override
  void dispose() {
    _text.dispose();
    for (final c in _partText.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>?> _run(
    String key,
    Future<dynamic> Function() call,
  ) async {
    setState(() {
      _busy = key;
      _error = null;
    });
    try {
      final next = await call();
      if (!mounted) return null;
      setState(() => _busy = '');
      if (next is Map) {
        final m = Map<String, dynamic>.from(next);
        widget.onChange(m);
        return m;
      }
      return null;
    } catch (e) {
      if (!mounted) return null;
      if (gpHandleLocked(context, e)) return null;
      setState(() {
        _busy = '';
        _error = e;
      });
      return null;
    }
  }

  String get _id => str(_c['id']);

  /// Shown photo: while choosing, the one chosen; otherwise the prepared one.
  String? _imageOf(Object? choice, Object? prepared) {
    if (_ready && choice is Map) {
      for (final o in _maps(choice['options'])) {
        if (o['id'] == _photo) {
          final u = str(o['url']);
          return u.isEmpty ? null : u;
        }
      }
      return null;
    }
    final u = str(prepared);
    return u.isEmpty ? null : u;
  }

  bool get _photoChanged {
    final c = _choice;
    return c != null && _photo != c['selected'];
  }

  void _apply() {
    final p = _p;
    final parts = _parts;
    final Map<String, dynamic> body;
    if (parts.isNotEmpty) {
      final edits = <String, String>{};
      for (final k in const ['description', 'post']) {
        Map<String, dynamic>? part;
        for (final x in parts) {
          if (str(x['id']) == k) part = x;
        }
        final original = part == null ? null : _map(part['editable'])['value'];
        final edited = _partText[k]?.text.trim();
        if (edited != null && edited.isNotEmpty && edited != original) {
          edits[k] = edited;
        }
      }
      body = {
        'parts': _ticked,
        'edits': edits,
        if (_photoChanged) 'photo_id': _photo ?? 'none',
      };
    } else {
      final editable = p['editable'];
      body = {
        if (editable is Map && _text.text != editable['value'])
          'text': _text.text,
        if (_photoChanged) 'photo_id': _photo ?? 'none',
        if (p['attribute_form'] != null)
          'attributes': _answers.entries
              .map((e) => {'name': e.key, 'value': e.value})
              .toList(),
      };
    }
    _run('apply', () async {
      final next = await GoogleProfileApi.instance.assistantApply(_id, body);
      widget.onChanged();
      return next;
    });
  }

  void _undo() {
    _run('undo', () async {
      final next = await GoogleProfileApi.instance.assistantUndo(_id);
      widget.onChanged();
      return next;
    });
  }

  Future<void> _upload() async {
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      picked = null;
    }
    if (picked == null || !mounted) return;
    final file = picked;
    final problem = await assistantPhotoProblem(file);
    if (!mounted) return;
    if (problem.isNotEmpty) {
      setState(() => _error = assistantMessageError(problem));
      return;
    }
    await _run('upload', () async {
      final attachment = await GoogleProfileApi.instance.assistantAttach(
        File(file.path),
      );
      final aid = attachment is Map ? str(attachment['id']) : '';
      if (aid.isEmpty) {
        throw assistantMessageError(
          'The photo did not upload. Please try again.',
        );
      }
      return GoogleProfileApi.instance.assistantUpload(_id, aid);
    });
  }

  void _openTab(String tab) => widget.onOpenTab?.call(tab);

  // ── Pieces ──────────────────────────────────────────────────────────────

  Widget _changes(List<Map<String, dynamic>> changes) {
    if (changes.isEmpty) return const SizedBox.shrink();
    return GpStack(
      gap: 8,
      children: [
        for (final c in changes)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: GpStack(
              gap: 4,
              children: [
                Text(str(c['label']), style: GpText.note),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (c['before'] != null) ...[
                      Text(
                        str(c['before']).isEmpty ? 'Not set' : str(c['before']),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ],
                    Text(
                      c['after'] == null ? 'Not set' : str(c['after']),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _items(List<Map<String, dynamic>> items, {bool small = false}) {
    if (items.isEmpty) return const SizedBox.shrink();
    return GpStack(
      gap: 8,
      children: [
        for (final item in items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (str(item['image_url']).isNotEmpty) ...[
                GpImage(
                  url: str(item['image_url']),
                  width: small ? 44 : 56,
                  height: small ? 44 : 56,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GpStack(
                  gap: 2,
                  children: [
                    Text(
                      str(item['title']),
                      style: TextStyle(
                        fontSize: small ? 13 : 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (str(item['body']).isNotEmpty)
                      Text(
                        str(item['body']),
                        style: TextStyle(
                          fontSize: small ? 12.5 : 13.5,
                          height: 1.4,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (str(item['meta']).isNotEmpty)
                      Text(str(item['meta']), style: GpText.note),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  /// The post's photo: one of the library photos, or none.
  Widget _photoPicker(Map<String, dynamic> choice) {
    final options = [
      ..._maps(choice['options']),
      <String, dynamic>{'id': null, 'url': null, 'label': 'No photo'},
    ];
    return GpStack(
      gap: 8,
      children: [
        const Text('Photo for the post', style: GpText.label),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in options)
              Semantics(
                button: true,
                selected: _photo == o['id'],
                label: str(o['label']).isNotEmpty
                    ? str(o['label'])
                    : (str(o['url']).isNotEmpty ? 'Library photo' : 'No photo'),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => setState(() => _photo = o['id']),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: _photo == o['id'] ? 2.5 : 1,
                        color: _photo == o['id']
                            ? AppColors.primary
                            : AppColors.borderStrong,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        str(o['url']).isNotEmpty
                            ? GpImage(
                                url: str(o['url']),
                                borderRadius: BorderRadius.circular(8),
                              )
                            : const Center(
                                child: Text(
                                  'No photo',
                                  textAlign: TextAlign.center,
                                  style: GpText.note,
                                ),
                              ),
                        if (_photo == o['id'])
                          Positioned(
                            right: 3,
                            top: 3,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Google's questions about the business (attributes).
  Widget _attributeForm(List<Map<String, dynamic>> questions) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final q in questions) {
      final g = str(q['group']).isEmpty ? 'Other' : str(q['group']);
      groups.putIfAbsent(g, () => []).add(q);
    }
    return GpStack(
      gap: 14,
      children: [
        for (final entry in groups.entries)
          GpStack(
            gap: 10,
            children: [
              Text(entry.key, style: GpText.label),
              for (final q in entry.value) _attribute(q),
            ],
          ),
      ],
    );
  }

  Widget _attribute(Map<String, dynamic> q) {
    final name = str(q['name']);
    final v = _answers[name];
    if (str(q['type']) == 'bool') {
      const options = [('Yes', true), ('No', false), ('Not sure', null)];
      return GpStack(
        gap: 6,
        children: [
          Text(str(q['label']), style: const TextStyle(fontSize: 13.5)),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, value) in options)
                ChoiceChip(
                  label: Text(label),
                  selected: v == value,
                  showCheckmark: false,
                  selectedColor: AppColors.primaryTint,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: v == value
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                  side: BorderSide(
                    color: v == value
                        ? AppColors.primary
                        : AppColors.borderStrong,
                  ),
                  onSelected: (_) => setState(() => _answers[name] = value),
                ),
            ],
          ),
        ],
      );
    }
    final choices = _maps(q['choices']);
    final current = v is String && choices.any((c) => str(c['value']) == v)
        ? v
        : 'unsure';
    return GpStack(
      gap: 6,
      children: [
        Text(str(q['label']), style: const TextStyle(fontSize: 13.5)),
        DropdownButtonFormField<String>(
          key: ValueKey('attr-$_gen-$name'),
          initialValue: current,
          isExpanded: true,
          decoration: gpInputDecoration(),
          items: [
            const DropdownMenuItem(value: 'unsure', child: Text('Not sure')),
            for (final c in choices)
              DropdownMenuItem(
                value: str(c['value']),
                child: Text(str(c['label'])),
              ),
          ],
          onChanged: (value) => setState(
            () => _answers[name] = (value == null || value == 'unsure')
                ? null
                : value,
          ),
        ),
      ],
    );
  }

  Widget? _statusChip() {
    if (_applied) {
      return _c['undone_at'] != null
          ? const GpChip('Undone', color: AppColors.textSecondary)
          : const GpChip('Done', tone: GpTone.ok);
    }
    if (_status == 'cancelled') {
      return const GpChip('Cancelled', color: AppColors.textSecondary);
    }
    if (_ready) {
      return const GpChip('Waiting for you', color: AppColors.accentPink);
    }
    if (_status == 'needs_choice' || _status == 'needs_info') {
      return const GpChip('Needs you', tone: GpTone.warn);
    }
    return null;
  }

  Widget _part(Map<String, dynamic> part) {
    final pid = str(part['id']);
    final on = _ticked.contains(pid);
    final partImage = _imageOf(part['photo_choice'], part['image_url']);
    final partChanges = _maps(part['changes']);
    final editable = part['editable'] is Map ? _map(part['editable']) : null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: on && _ready ? AppColors.primaryTint : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: on && _ready ? AppColors.primary : AppColors.border,
        ),
      ),
      child: GpStack(
        gap: 8,
        children: [
          _ready
              ? GpCheck(
                  value: on,
                  onChanged: _busy.isNotEmpty
                      ? null
                      : (checked) => setState(() {
                          if (checked) {
                            if (!_ticked.contains(pid)) {
                              _ticked = [..._ticked, pid];
                            }
                          } else {
                            _ticked = _ticked.where((x) => x != pid).toList();
                          }
                        }),
                  label: Text(str(part['title']), style: GpText.label),
                )
              : Text(str(part['title']), style: GpText.label),
          if (partImage != null)
            GpImage(
              url: partImage,
              width: double.infinity,
              height: 160,
              borderRadius: BorderRadius.circular(8),
            ),
          if (_ready && on && part['photo_choice'] is Map)
            _photoPicker(_map(part['photo_choice'])),
          if (partChanges.isNotEmpty &&
              !(editable != null && _ready && _editing))
            GpStack(
              gap: 4,
              children: [
                for (final c in partChanges)
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(
                          text: str(c['label']),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        if (str(c['after']).isNotEmpty &&
                            str(c['after']) != str(c['label']))
                          TextSpan(text: ' — ${str(c['after'])}'),
                      ],
                    ),
                  ),
              ],
            ),
          _items(_maps(part['items']), small: true),
          if (editable != null &&
              _ready &&
              on &&
              _editing &&
              _partText[pid] != null)
            TextField(
              controller: _partText[pid],
              minLines: 3,
              maxLines: 8,
              maxLength: numOf(editable['max'])?.toInt(),
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 14),
              decoration: gpInputDecoration(hint: str(editable['label'])),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    final p = _p;
    final parts = _parts;
    final changes = _maps(p['changes']);
    final items = _maps(p['items']);
    final notes = listOf(p['notes']).map(str).toList();
    final status = _status;
    final ready = _ready;
    final applied = _applied;
    final blocked = _blocked;
    final message = str(c['message']);
    final editable = p['editable'] is Map ? _map(p['editable']) : null;
    final photoChoice = p['photo_choice'] is Map
        ? _map(p['photo_choice'])
        : null;
    final attributeForm = _maps(p['attribute_form']);

    final short =
        widget.compact && (applied || status == 'cancelled') && !_detailsOpen;
    final google = assistantChangesGoogle(c['kind']);
    final hasEditable =
        editable != null || parts.any((x) => x['editable'] is Map);
    final applyLabel = parts.isNotEmpty
        ? 'Apply ${_ticked.length} ${_ticked.length == 1 ? 'step' : 'steps'}'
        : google
        ? 'Publish to Google'
        : 'Apply';
    final applyDisabled =
        (editable != null && _text.text.trim().isEmpty) ||
        (parts.isNotEmpty && _ticked.isEmpty);
    final link = p['link'] is Map ? _map(p['link']) : null;
    final linkTab = link == null ? null : assistantTabOfLink(link['href']);
    final shown = _imageOf(p['photo_choice'], p['image_url']);
    final chip = _statusChip();
    final busy = _busy.isNotEmpty;
    final options = _maps(c['options']);
    final editMax = numOf(editable?['max'])?.toInt();
    final buttons = <Widget>[
      if (ready) ...[
        GpButton(
          label: applyLabel,
          icon: Icons.check,
          small: true,
          busy: _busy == 'apply',
          onPressed: applyDisabled || busy ? null : _apply,
        ),
        if (hasEditable && !_editing)
          GpButton.ghost(
            label: 'Edit',
            icon: Icons.edit_outlined,
            small: true,
            onPressed: busy ? null : () => setState(() => _editing = true),
          ),
        GpButton.ghost(
          label: 'Cancel',
          small: true,
          busy: _busy == 'cancel',
          onPressed: busy
              ? null
              : () => _run(
                  'cancel',
                  () => GoogleProfileApi.instance.assistantCancel(_id),
                ),
        ),
      ],
      if (c['can_undo'] == true)
        GpButton.ghost(
          label: 'Undo',
          icon: Icons.undo,
          small: true,
          busy: _busy == 'undo',
          onPressed: busy ? null : _undo,
        ),
      if (linkTab != null && (applied || blocked) && widget.onOpenTab != null)
        GpButton.ghost(
          label: 'Open ${assistantTabNames[linkTab] ?? linkTab}',
          small: true,
          onPressed: () => _openTab(linkTab),
        ),
    ];

    return GpStack(
      gap: 12,
      children: [
        if (chip != null) chip,

        if (message.isNotEmpty && !ready && !applied)
          blocked
              ? GpCallout(
                  tone: status == 'failed' ? GpTone.bad : GpTone.warn,
                  title: assistantBlockedTitle(status, message),
                  text: message,
                )
              : AssistantText(message),

        if (status == 'needs_info' && str(p['upload']).isNotEmpty)
          GpButtons(
            children: [
              GpButton(
                label: _busy == 'upload'
                    ? 'Uploading…'
                    : (assistantUploadLabels[str(p['upload'])] ??
                          'Upload a photo'),
                icon: Icons.upload_outlined,
                busy: _busy == 'upload',
                small: true,
                onPressed: _upload,
              ),
              const Text('PNG, JPEG or WebP, up to 5 MB.', style: GpText.note),
            ],
          ),

        if (status == 'needs_choice' && options.isNotEmpty)
          GpStack(
            gap: 8,
            children: [
              for (final o in options)
                GpButton.ghost(
                  label: str(o['label']),
                  expand: true,
                  busy: _busy == 'choose:${str(o['id'])}',
                  onPressed: busy
                      ? null
                      : () => _run(
                          'choose:${str(o['id'])}',
                          () => GoogleProfileApi.instance.assistantChoose(
                            _id,
                            o['id'],
                          ),
                        ),
                ),
            ],
          ),

        if (str(p['title']).isNotEmpty &&
            (ready || applied || status == 'cancelled'))
          GpStack(
            gap: 12,
            children: [
              Text(
                str(p['title']),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.compact && (applied || status == 'cancelled'))
                GpLink(
                  _detailsOpen ? 'Hide details' : 'Show details',
                  onTap: () => setState(() => _detailsOpen = !_detailsOpen),
                ),
              if (!short && shown != null)
                GpImage(
                  url: shown,
                  width: double.infinity,
                  height: 180,
                  borderRadius: BorderRadius.circular(10),
                ),
              if (ready && photoChoice != null) _photoPicker(photoChoice),
              if (ready && attributeForm.isNotEmpty)
                _attributeForm(attributeForm),
              if (!short && changes.isNotEmpty) _changes(changes),
              if (!short && items.isNotEmpty) _items(items),
              if (editable != null && ready)
                _editing
                    ? GpStack(
                        gap: 6,
                        children: [
                          Text(str(editable['label']), style: GpText.label),
                          TextField(
                            controller: _text,
                            autofocus: true,
                            minLines: 5,
                            maxLines: 10,
                            maxLength: editMax,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(fontSize: 14),
                            decoration: gpInputDecoration(
                              counter:
                                  '${_text.text.length} / ${editMax ?? ''}',
                            ),
                          ),
                        ],
                      )
                    // The text is shown once: here, unless the changes above already show it.
                    : (!changes.any((ch) => ch['after'] == _text.text)
                          ? GpStack(
                              gap: 4,
                              children: [
                                Text(
                                  str(editable['label']),
                                  style: GpText.label,
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: AssistantText(
                                    _text.text,
                                    selectable: true,
                                  ),
                                ),
                              ],
                            )
                          : null),
              if (parts.isNotEmpty && !short)
                GpStack(
                  gap: 8,
                  children: [for (final part in parts) _part(part)],
                ),
              if (notes.isNotEmpty && !short)
                GpStack(
                  gap: 4,
                  children: [
                    for (final n in notes) Text(n, style: GpText.note),
                  ],
                ),
            ],
          ),

        if (applied && str(c['result']).isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check, size: 16, color: AppColors.success),
              const SizedBox(width: 6),
              Expanded(child: AssistantText(str(c['result']))),
            ],
          ),

        if (_error != null)
          GpCallout(tone: GpTone.bad, text: assistantErrorText(_error)),

        if (buttons.isNotEmpty) GpButtons(children: buttons),

        if (ready)
          Text(
            google || parts.isNotEmpty
                ? 'Nothing has changed yet. Check it, then press the button to send it to Google.'
                : 'Nothing has changed yet. Check it, then press Apply.',
            style: GpText.note,
          ),
      ],
    );
  }
}
