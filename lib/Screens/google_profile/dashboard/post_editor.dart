// The "Write a post" editor of the Posts tab (website dashboard/PostEditor.jsx),
// as a full-screen page. Post fields: type, topic, text, button and link,
// dates, offer and coupon, image, schedule. Save draft keeps it in GrowthOS;
// Publish now and Schedule save it first, then put it on Google (now, or at
// the schedule time). A post already on Google is saved there directly
// ("Save on Google").
// API: createPost / updatePost / generatePost / uploadImage / publishPost / schedulePost.
// The page pops with the kind of save (draft | published | scheduled | updated),
// or null when cancelled.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/common_app_bar.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'posts_utils.dart';

/// Opens the editor for [post] (null = a new one). Resolves to the kind of
/// save, or null when the vendor cancelled.
Future<String?> openPostEditor(BuildContext context,
    {Map<String, dynamic>? post}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => GpPostEditorScreen(post: post)),
  );
}

// Server field paths that have a box here (the rest are shown in the error box).
const List<String> _fieldPaths = [
  'post_type',
  'topic',
  'description',
  'cta',
  'cta_url',
  'start_date',
  'end_date',
  'offer',
  'coupon',
  'image_upload_id',
  'schedule_at',
];

class GpPostEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? post;
  const GpPostEditorScreen({super.key, this.post});

  @override
  State<GpPostEditorScreen> createState() => _GpPostEditorScreenState();
}

class _GpPostEditorScreenState extends State<GpPostEditorScreen> {
  // The form (website formOf).
  String _postType = 'update';
  final _topic = TextEditingController();
  final _description = TextEditingController();
  String _cta = '';
  final _ctaUrl = TextEditingController();
  String _startDate = '';
  String _endDate = '';
  final _offer = TextEditingController();
  final _coupon = TextEditingController();
  String? _imageUploadId;
  String? _imageUrl;
  String _scheduleDate = '';
  String _scheduleTime = '';
  bool _aiGenerated = false;

  String? _savedId;
  Map<String, String> _errors = {};
  String? _busy; // save | publish | schedule | ai | upload
  Object? _error;
  String _aiNote = '';
  String? _imageProblem;
  bool _confirmPublish = false;

  final Map<String, GlobalKey> _keys = {
    for (final k in [
      'post_type',
      'topic',
      'description',
      'cta',
      'cta_url',
      'start_date',
      'end_date',
      'offer',
      'coupon',
      'image_upload_id',
      'schedule_date',
      'schedule_time',
    ])
      k: GlobalKey(),
  };

  Map<String, dynamic>? get _post => widget.post;
  bool get _live => str(_post?['status']) == 'published';
  bool get _working => _busy != null;

  @override
  void initState() {
    super.initState();
    final p = _post;
    if (p != null) {
      final when = postsLocalParts(p['schedule_at']);
      _postType = str(p['post_type']).isEmpty ? 'update' : str(p['post_type']);
      _topic.text = str(p['topic']);
      _description.text = str(p['description']);
      _cta = str(p['cta']);
      _ctaUrl.text = str(p['cta_url']);
      _startDate = str(p['start_date']);
      _endDate = str(p['end_date']);
      _offer.text = str(p['offer']);
      _coupon.text = str(p['coupon']);
      _imageUploadId = str(p['image_upload_id']).isEmpty ? null : str(p['image_upload_id']);
      _imageUrl = str(p['image_url']).isEmpty ? null : str(p['image_url']);
      _scheduleDate = when.date;
      _scheduleTime = when.time;
      _aiGenerated = p['ai_generated'] == true;
      _savedId = str(p['id']).isEmpty ? null : str(p['id']);
    }
    if (!postsTypeLabels.containsKey(_postType)) _postType = 'update';
    if (_cta.isNotEmpty && !postsCtaLabels.containsKey(_cta)) _cta = '';
  }

  @override
  void dispose() {
    _topic.dispose();
    _description.dispose();
    _ctaUrl.dispose();
    _offer.dispose();
    _coupon.dispose();
    super.dispose();
  }

  /// The request body GrowthOS's postInputSchema expects (blanks → null; fields the type does not use → null).
  Map<String, dynamic> _body() {
    final dated = _postType != 'update';
    final offer = _postType == 'offer';
    String? orNull(String v) => v.trim().isEmpty ? null : v.trim();
    return {
      'post_type': _postType,
      'topic': _topic.text.trim(),
      'description': orNull(_description.text),
      'cta': _cta.isEmpty ? null : _cta,
      'cta_url': _cta.isNotEmpty && _cta != 'call' ? orNull(_ctaUrl.text) : null,
      'start_date': dated && _startDate.isNotEmpty ? _startDate : null,
      'end_date': dated && _endDate.isNotEmpty ? _endDate : null,
      'offer': offer ? orNull(_offer.text) : null,
      'coupon': offer ? orNull(_coupon.text) : null,
      'image_upload_id': _imageUploadId,
      'location_id': null,
      'schedule_at': postsToIsoTime(_scheduleDate, _scheduleTime),
      'ai_generated': _aiGenerated,
    };
  }

  /// The same checks as GrowthOS's postInputSchema, in plain words. [forSchedule] also needs a future time.
  Map<String, String> _problems(bool forSchedule) {
    final out = <String, String>{};
    final topic = _topic.text.trim();
    if (_postType.isEmpty) out['post_type'] = 'Choose a post type.';
    if (topic.isEmpty) {
      out['topic'] = 'Write what the post is about.';
    } else if (topic.length > PostsLimits.topic) {
      out['topic'] = 'Keep it to ${PostsLimits.topic} characters.';
    }
    if (_description.text.length > PostsLimits.description) {
      out['description'] = 'Keep it to ${PostsLimits.description} characters.';
    }
    if (_cta.isNotEmpty && _cta != 'call') {
      if (_ctaUrl.text.trim().isEmpty) {
        out['cta_url'] = 'Add the web address the button opens.';
      } else if (!postsIsHttpUrl(_ctaUrl.text)) {
        out['cta_url'] = 'Enter a web address starting with https://';
      }
    }
    if (_postType != 'update' &&
        _startDate.isNotEmpty &&
        _endDate.isNotEmpty &&
        _endDate.compareTo(_startDate) < 0) {
      out['end_date'] = 'The end date must be on or after the start date.';
    }
    if (_postType == 'offer') {
      if (_offer.text.length > PostsLimits.offer) {
        out['offer'] = 'Keep it to ${PostsLimits.offer} characters.';
      }
      if (_coupon.text.length > PostsLimits.coupon) {
        out['coupon'] = 'Keep it to ${PostsLimits.coupon} characters.';
      }
    }
    if (_scheduleDate.isNotEmpty && _scheduleTime.isEmpty) {
      out['schedule_time'] = 'Add a time, or clear the date.';
    }
    if (_scheduleTime.isNotEmpty && _scheduleDate.isEmpty) {
      out['schedule_date'] = 'Add a date, or clear the time.';
    }
    if (forSchedule) {
      final at = postsToIsoTime(_scheduleDate, _scheduleTime);
      if (_scheduleDate.isEmpty && _scheduleTime.isEmpty) {
        out['schedule_date'] = 'Choose when the post should go live.';
      } else if (at != null &&
          DateTime.parse(at)
              .isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
        out['schedule_time'] = 'Choose a time at least 5 minutes from now.';
      }
    }
    return out;
  }

  void _showFirst(Map<String, String> found) {
    if (found.isEmpty) return;
    final ctx = _keys[found.keys.first]?.currentContext;
    if (ctx == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 250), alignment: 0.1);
    });
  }

  void _fail(Object failure) {
    final fields = postsFieldErrorsOf(failure);
    final mapped = <String, String>{
      for (final e in fields.entries)
        if (_fieldPaths.contains(e.key)) e.key: e.value,
    };
    if (mapped.containsKey('schedule_at')) {
      mapped['schedule_time'] = mapped.remove('schedule_at')!;
    }
    setState(() {
      _errors = mapped;
      _error = failure;
    });
  }

  /// Checks the form; true when it can be sent.
  bool _check([bool forSchedule = false]) {
    final found = _problems(forSchedule);
    setState(() {
      _errors = found;
      _error = null;
    });
    if (found.isNotEmpty) {
      _showFirst(found);
      return false;
    }
    return true;
  }

  /// Saves the post (new → create, else update) and returns it.
  Future<Map<String, dynamic>> _save() async {
    final body = _body();
    final saved = _savedId != null
        ? await GoogleProfileApi.instance.updatePost(_savedId!, body)
        : await GoogleProfileApi.instance.createPost(body);
    final m = mapOf(saved);
    if (str(m['id']).isNotEmpty) _savedId = str(m['id']);
    return m;
  }

  Future<void> _run(String kind, Future<String> Function() action) async {
    setState(() => _busy = kind);
    try {
      final done = await action();
      if (!mounted) return;
      Navigator.of(context).pop(done);
    } catch (failure) {
      if (!mounted) return;
      if (gpHandleLocked(context, failure)) return;
      _fail(failure);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _onSaveDraft() async {
    if (_working || !_check()) return;
    await _run('save', () async {
      await _save();
      return _live ? 'updated' : 'draft';
    });
  }

  Future<void> _onPublish() async {
    setState(() => _confirmPublish = false);
    if (_working || !_check()) return;
    await _run('publish', () async {
      final saved = await _save();
      final id = str(saved['id']).isNotEmpty ? str(saved['id']) : _savedId!;
      await GoogleProfileApi.instance.publishPost(id);
      return 'published';
    });
  }

  Future<void> _onSchedule() async {
    if (_working || !_check(true)) return;
    await _run('schedule', () async {
      final saved = await _save();
      final id = str(saved['id']).isNotEmpty ? str(saved['id']) : _savedId!;
      await GoogleProfileApi.instance.schedulePost(id);
      return 'scheduled';
    });
  }

  Future<void> _onWriteWithAi() async {
    if (_working) return;
    final found = <String, String>{};
    if (_postType.isEmpty) found['post_type'] = 'Choose a post type.';
    if (_topic.text.trim().isEmpty) {
      found['topic'] = 'Write what the post is about first. The AI writes from it.';
    }
    setState(() {
      _errors = found;
      _error = null;
      _aiNote = '';
    });
    if (found.isNotEmpty) {
      _showFirst(found);
      return;
    }
    final b = _body();
    setState(() => _busy = 'ai');
    try {
      final result = mapOf(await GoogleProfileApi.instance.generatePost({
        'post_type': b['post_type'],
        'topic': b['topic'],
        'location_id': null,
        'offer': b['offer'],
        'coupon': b['coupon'],
        'start_date': b['start_date'],
        'end_date': b['end_date'],
      }));
      if (!mounted) return;
      final text = str(result['description']);
      if (text.isNotEmpty) {
        final cta = str(result['cta']);
        setState(() {
          _description.text = text.length > PostsLimits.description
              ? text.substring(0, PostsLimits.description)
              : text;
          _aiGenerated = true;
          if (cta.isNotEmpty && postsCtaLabels.containsKey(cta)) _cta = cta;
          _aiNote =
              'The AI wrote the text below. Read it and change anything before you save.';
        });
        _showFirst({'description': ''});
      }
    } catch (failure) {
      if (!mounted) return;
      if (gpHandleLocked(context, failure)) return;
      _fail(failure);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _onPickImage() async {
    if (_working) return;
    XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (_) {
      if (mounted) gpToast(context, 'Could not open your photos.', error: true);
      return;
    }
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    final problem = await postsImageProblem(file);
    if (!mounted) return;
    setState(() => _imageProblem = problem);
    if (problem != null) return;
    setState(() {
      _busy = 'upload';
      _error = null;
    });
    try {
      final uploaded = mapOf(await GoogleProfileApi.instance.uploadImage(file));
      if (!mounted) return;
      if (str(uploaded['id']).isNotEmpty) {
        setState(() {
          _imageUploadId = str(uploaded['id']);
          _imageUrl = str(uploaded['url']).isEmpty ? null : str(uploaded['url']);
        });
      }
    } catch (failure) {
      if (!mounted) return;
      if (gpHandleLocked(context, failure)) return;
      setState(() {
        _imageProblem = null;
        _error = failure;
      });
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  Widget _field(String key, Widget child) =>
      KeyedSubtree(key: _keys[key], child: child);

  Widget _required(String label) => Text.rich(TextSpan(
        text: label,
        style: GpText.label,
        children: const [
          TextSpan(
              text: ' (required)',
              style: TextStyle(
                  fontWeight: FontWeight.w400, color: AppColors.textTertiary)),
        ],
      ));

  Widget _textBox({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helper,
    String? error,
    bool required = false,
    int? maxLength,
    int minLines = 1,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      required ? _required(label) : Text(label, style: GpText.label),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        enabled: !_working,
        maxLength: maxLength,
        minLines: minLines,
        maxLines: maxLines,
        keyboardType: keyboardType ??
            (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        onChanged: onChanged,
        style: const TextStyle(fontSize: 14),
        decoration: gpInputDecoration(
            hint: hint, helper: helper, error: error, counter: ''),
      ),
    ]);
  }

  Widget _section(String title, List<Widget> children) {
    return GpCard(
      child: GpStack(gap: 14, children: [
        Text(title, style: GpText.label),
        ...children,
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final dated = _postType != 'update';
    final isOffer = _postType == 'offer';
    final needsUrl = _cta.isNotEmpty && _cta != 'call';
    final blocked = gpErrorCode(_error) == 'google_unverified';
    final publishError = str(post?['publish_error']);
    final bottom = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: !_working,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: post != null ? 'Edit post' : 'Write a post'),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottom),
            children: [
              Text(
                _live
                    ? 'This post is on Google. Save on Google changes it there at once.'
                    : 'Save draft keeps it here. Publish now puts it on Google at once; Schedule puts it there at the time you choose.',
                style: GpText.note,
              ),
              const SizedBox(height: 12),
              if (publishError.isNotEmpty && _error == null) ...[
                GpCallout(
                  tone: GpTone.alert,
                  title: 'The last publish did not go through.',
                  text: publishError,
                ),
                const SizedBox(height: 12),
              ],

              // Type and topic.
              GpCard(
                child: GpStack(gap: 14, children: [
                  _field(
                    'post_type',
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _required('Post type'),
                      const SizedBox(height: 6),
                      GpDropdown<String>(
                        key: ValueKey('type-$_postType'),
                        label: '',
                        value: _postType,
                        error: _errors['post_type'],
                        helper: _live ? 'A post on Google keeps its type.' : null,
                        items: [
                          for (final e in postsTypeLabels.entries)
                            DropdownMenuItem(value: e.key, child: Text(e.value)),
                        ],
                        onChanged: _live || _working
                            ? null
                            : (v) => setState(() => _postType = v ?? 'update'),
                      ),
                    ]),
                  ),
                  _field(
                    'topic',
                    _textBox(
                      label: 'Topic',
                      controller: _topic,
                      required: true,
                      maxLength: PostsLimits.topic,
                      helper: 'What the post is about, in a few words.',
                      error: _errors['topic'],
                    ),
                  ),
                ]),
              ),

              // AI.
              GpCard(
                tint: true,
                child: GpStack(gap: 8, children: [
                  GpButton.ghost(
                    label: _busy == 'ai' ? 'Writing…' : 'Write with AI',
                    icon: Icons.auto_awesome_outlined,
                    busy: _busy == 'ai',
                    onPressed: _working ? null : _onWriteWithAi,
                  ),
                  const Text(
                      'Uses the post type, topic and your confirmed business details. Check the text before you save.',
                      style: GpText.note),
                  if (_aiNote.isNotEmpty)
                    Text(_aiNote,
                        style: const TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600)),
                ]),
              ),

              // Text and button.
              GpCard(
                child: GpStack(gap: 14, children: [
                  _field(
                    'description',
                    _textBox(
                      label: 'Text',
                      controller: _description,
                      maxLength: PostsLimits.description,
                      minLines: 6,
                      maxLines: 12,
                      helper:
                          '${_description.text.length} of ${PostsLimits.description} characters. No phone numbers or email addresses; Google rejects them.',
                      error: _errors['description'],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  _field(
                    'cta',
                    GpDropdown<String>(
                      key: ValueKey('cta-$_cta'),
                      label: 'Button',
                      value: _cta,
                      error: _errors['cta'],
                      helper: _cta == 'call'
                          ? 'Call now uses your business phone number.'
                          : isOffer
                              ? "Google shows an offer's link instead of a button."
                              : null,
                      items: [
                        const DropdownMenuItem(value: '', child: Text('No button')),
                        for (final e in postsCtaLabels.entries)
                          DropdownMenuItem(value: e.key, child: Text(e.value)),
                      ],
                      onChanged:
                          _working ? null : (v) => setState(() => _cta = v ?? ''),
                    ),
                  ),
                  if (needsUrl)
                    _field(
                      'cta_url',
                      _textBox(
                        label: 'Button link',
                        controller: _ctaUrl,
                        required: true,
                        hint: 'https://',
                        keyboardType: TextInputType.url,
                        error: _errors['cta_url'],
                      ),
                    ),
                ]),
              ),

              // Dates and offer.
              if (dated)
                GpCard(
                  child: GpStack(gap: 14, children: [
                    _field(
                      'start_date',
                      PostsDateField(
                        label: 'Start date',
                        value: _startDate,
                        helper: 'An offer or event needs both dates on Google.',
                        error: _errors['start_date'],
                        onChanged: _working
                            ? null
                            : (v) => setState(() => _startDate = v),
                      ),
                    ),
                    _field(
                      'end_date',
                      PostsDateField(
                        label: 'End date',
                        value: _endDate,
                        min: _startDate,
                        error: _errors['end_date'],
                        onChanged:
                            _working ? null : (v) => setState(() => _endDate = v),
                      ),
                    ),
                    if (isOffer) ...[
                      _field(
                        'offer',
                        _textBox(
                          label: 'Offer terms',
                          controller: _offer,
                          maxLength: PostsLimits.offer,
                          minLines: 2,
                          maxLines: 4,
                          error: _errors['offer'],
                        ),
                      ),
                      _field(
                        'coupon',
                        _textBox(
                          label: 'Coupon code',
                          controller: _coupon,
                          maxLength: PostsLimits.coupon,
                          error: _errors['coupon'],
                        ),
                      ),
                    ],
                  ]),
                ),

              // Image.
              _field(
                'image_upload_id',
                _section('Image (optional)', [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _imageUrl != null
                        ? GpImage(
                            url: _imageUrl,
                            width: 96,
                            height: 96,
                            borderRadius: BorderRadius.circular(10))
                        : Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.textTertiary, size: 26),
                          ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GpStack(gap: 8, children: [
                        GpButton.ghost(
                          small: true,
                          icon: Icons.image_outlined,
                          busy: _busy == 'upload',
                          label: _busy == 'upload'
                              ? 'Uploading…'
                              : _imageUploadId != null
                                  ? 'Change image'
                                  : 'Add an image',
                          onPressed: _working ? null : _onPickImage,
                        ),
                        if (_imageUploadId != null)
                          GpButton.ghost(
                            small: true,
                            icon: Icons.delete_outline,
                            label: 'Remove image',
                            onPressed: _working
                                ? null
                                : () => setState(() {
                                      _imageUploadId = null;
                                      _imageUrl = null;
                                    }),
                          ),
                      ]),
                    ),
                  ]),
                  const Text('PNG, JPEG or WebP, up to 5 MB.', style: GpText.note),
                  if ((_imageProblem ?? _errors['image_upload_id']) != null)
                    Text(_imageProblem ?? _errors['image_upload_id']!,
                        style: GpText.error),
                ]),
              ),

              // Schedule.
              if (!_live)
                _section('Schedule (optional)', [
                  _field(
                    'schedule_date',
                    PostsDateField(
                      label: 'Date',
                      value: _scheduleDate,
                      min: postsDayString(DateTime.now()),
                      error: _errors['schedule_date'],
                      onChanged: _working
                          ? null
                          : (v) => setState(() => _scheduleDate = v),
                    ),
                  ),
                  _field(
                    'schedule_time',
                    GpTimeField(
                      label: 'Time',
                      value: _scheduleTime,
                      clearable: true,
                      error: _errors['schedule_time'],
                      onChanged: _working
                          ? null
                          : (v) => setState(() => _scheduleTime = v),
                    ),
                  ),
                  const Text(
                      'When the post should go live on Google, in your own time. Then press Schedule.',
                      style: GpText.note),
                ]),

              if (_error != null) ...[
                PostsErrorNote(error: _error),
                const SizedBox(height: 8),
              ],
              if (blocked) ...[
                const Text('You can still save it as a draft.', style: GpText.note),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 4),
              if (_confirmPublish)
                PostsConfirmBox(
                  title: 'Publish this post on Google now?',
                  message:
                      'It is saved first and then shown on your Google profile. Google may take a few minutes to show it.',
                  confirmLabel: 'Publish now',
                  onConfirm: _onPublish,
                  onCancel: () => setState(() => _confirmPublish = false),
                )
              else
                GpStack(gap: 10, children: [
                  if (_live)
                    GpButton(
                      label: 'Save on Google',
                      expand: true,
                      busy: _busy == 'save',
                      onPressed: _working ? null : _onSaveDraft,
                    )
                  else ...[
                    GpButton(
                      label: 'Save draft',
                      expand: true,
                      busy: _busy == 'save',
                      onPressed: _working ? null : _onSaveDraft,
                    ),
                    Row(children: [
                      Expanded(
                        child: GpButton.ghost(
                          label: 'Publish now',
                          icon: Icons.send_outlined,
                          expand: true,
                          busy: _busy == 'publish',
                          onPressed: _working
                              ? null
                              : () {
                                  if (_check()) {
                                    setState(() => _confirmPublish = true);
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GpButton.ghost(
                          label: 'Schedule',
                          icon: Icons.calendar_today_outlined,
                          expand: true,
                          busy: _busy == 'schedule',
                          onPressed: _working ? null : _onSchedule,
                        ),
                      ),
                    ]),
                  ],
                  GpButton.ghost(
                    label: 'Cancel',
                    expand: true,
                    onPressed: _working ? null : () => Navigator.of(context).pop(),
                  ),
                ]),
            ],
          ),
        ),
      ),
    );
  }
}
