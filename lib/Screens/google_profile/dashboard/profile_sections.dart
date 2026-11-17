// The section forms of the Profile tab (website dashboard/ProfileSections.jsx).
// Each saves one section on Google with saveProfileSection(section, body), the
// body being exactly GrowthOS's section schema. Business name, categories,
// address and service area (and "permanently closed") need a ticked warning,
// sent as confirm_risk. On mobile each form is a full-screen page; it pops
// with `true` once Google saved the section.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/common_app_bar.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'profile_hours_editor.dart';
import 'profile_search.dart';
import 'profile_shared.dart';
import 'profile_utils.dart';

/// Sections where Google may review the change.
const List<String> profileRiskySections = [
  'name',
  'categories',
  'address',
  'service_area',
];

class _Risk {
  final String title;
  final String label;
  const _Risk(this.title, this.label);
}

const _Risk _defaultRisk = _Risk(
  'Google may review this change or ask you to verify your profile again.',
  'I understand. Save this change on Google.',
);

/// The full-screen form for [section] (one of the tab's section ids).
Widget profileSectionPage(
    String section, Map<String, dynamic> data, String title) {
  switch (section) {
    case 'name':
      return _NameForm(data: data, title: title);
    case 'categories':
      return _CategoriesForm(data: data, title: title);
    case 'description':
      return _DescriptionForm(data: data, title: title);
    case 'contact':
      return _ContactForm(data: data, title: title);
    case 'address':
      return _AddressForm(data: data, title: title);
    case 'service_area':
      return _ServiceAreaForm(data: data, title: title);
    case 'hours':
      return _HoursForm(data: data, title: title);
    case 'special_hours':
      return _SpecialHoursForm(data: data, title: title);
    case 'more_hours':
      return _MoreHoursForm(data: data, title: title);
    case 'open_status':
      return _OpenStatusForm(data: data, title: title);
    case 'services':
      return _ServicesForm(data: data, title: title);
    case 'attributes':
      return _AttributesForm(data: data, title: title);
  }
  return _NameForm(data: data, title: title);
}

Map<String, dynamic> _profileOf(Map<String, dynamic> data) =>
    mapOf(data['profile']);

// ── Saving and the frame ────────────────────────────────────────────────────

/// Saving one section: busy, the server's error, and save(body).
mixin _SectionSave<T extends StatefulWidget> on State<T> {
  bool busy = false;
  Object? saveError;
  String get section;

  Future<void> save(Map<String, dynamic> body) async {
    setState(() {
      busy = true;
      saveError = null;
    });
    try {
      await GoogleProfileApi.instance.saveProfileSection(section, body);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        saveError = e;
        busy = false;
      });
    }
  }
}

/// The frame of one section form: heading, the fields, the risk warning with
/// its tick box, the error, and Save on Google / Cancel.
class _SectionFrame extends StatefulWidget {
  final String section;
  final String title;
  final String? intro;

  /// When [customRisk] is false the warning follows [profileRiskySections].
  final bool customRisk;
  final _Risk? risk;
  final void Function(bool confirmed) onSubmit;
  final bool busy;
  final Object? error;
  final bool canSave;
  final String? problems;
  final List<Widget> children;

  const _SectionFrame({
    required this.section,
    required this.title,
    required this.onSubmit,
    required this.busy,
    required this.error,
    required this.children,
    this.intro,
    this.customRisk = false,
    this.risk,
    this.canSave = true,
    this.problems,
  });

  @override
  State<_SectionFrame> createState() => _SectionFrameState();
}

class _SectionFrameState extends State<_SectionFrame> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final warning = widget.customRisk
        ? widget.risk
        : (profileRiskySections.contains(widget.section) ? _defaultRisk : null);
    final busy = widget.busy;
    final problems = widget.problems ?? '';
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(title: 'Edit ${widget.title.toLowerCase()}'),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
            children: [
              GpCard(
                child: GpStack(gap: 16, children: [
                  Text(
                      widget.intro ??
                          'Saved on your Google profile when you press Save on Google.',
                      style: GpText.note),
                  ...widget.children,
                  if (problems.isNotEmpty) Text(problems, style: GpText.error),
                  if (warning != null)
                    GpStack(gap: 8, children: [
                      GpCallout(tone: GpTone.alert, title: warning.title),
                      GpCheck(
                        value: _confirmed,
                        onChanged: busy
                            ? null
                            : (v) => setState(() => _confirmed = v),
                        label: Text(warning.label, style: GpText.lead),
                      ),
                    ]),
                  if (widget.error != null)
                    ProfileErrorNote(error: widget.error),
                  GpButtons(children: [
                    GpButton(
                      label: busy ? 'Saving…' : 'Save on Google',
                      busy: busy,
                      onPressed: (!widget.canSave ||
                              (warning != null && !_confirmed))
                          ? null
                          : () {
                              FocusScope.of(context).unfocus();
                              if (!busy) widget.onSubmit(_confirmed);
                            },
                    ),
                    GpButton.ghost(
                      label: 'Cancel',
                      onPressed:
                          busy ? null : () => Navigator.of(context).pop(),
                    ),
                  ]),
                  if (warning != null && !_confirmed && !busy)
                    const Text('Tick the box above to save.',
                        style: GpText.note),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A label with "(required)" after it.
String _req(String label, bool required) =>
    required ? '$label (required)' : label;

// ── Description ─────────────────────────────────────────────────────────────

class _DescriptionForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _DescriptionForm({required this.data, required this.title});
  @override
  State<_DescriptionForm> createState() => _DescriptionFormState();
}

class _DescriptionFormState extends State<_DescriptionForm>
    with _SectionSave {
  @override
  String get section => 'description';

  late final TextEditingController _text = TextEditingController(
      text: str(_profileOf(widget.data)['description']));
  final TextEditingController _focus = TextEditingController();
  bool _aiBusy = false;
  Object? _aiError;
  String _aiNote = '';
  String _problem = '';

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _writeWithAi() async {
    setState(() {
      _aiBusy = true;
      _aiError = null;
      _aiNote = '';
    });
    try {
      final focus = _focus.text.trim();
      final result = mapOf(await GoogleProfileApi.instance
          .generateDescription({'focus': focus.isEmpty ? null : focus}));
      if (!mounted) return;
      final description = str(result['description']);
      final used = listOf(result['keywords_used']).map((e) => '$e').toList();
      setState(() {
        if (description.isNotEmpty) {
          _text.text = description.length > GpProfileLimits.description
              ? description.substring(0, GpProfileLimits.description)
              : description;
        }
        _aiBusy = false;
        _aiNote =
            'The AI wrote a new description below. Read it and change anything before you save.${used.isNotEmpty ? ' Keywords used: ${used.join(', ')}.' : ''}';
      });
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _aiBusy = false;
        _aiError = e;
      });
    }
  }

  void _submit(bool _) {
    if (_text.text.trim().length > GpProfileLimits.description) {
      setState(() => _problem =
          'Google allows up to ${GpProfileLimits.description} characters.');
      return;
    }
    setState(() => _problem = '');
    save({'description': _text.text.trim()});
  }

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: GpStack(gap: 10, children: [
            GpTextField(
              label: 'What to highlight (optional)',
              controller: _focus,
              maxLength: 300,
              hint: 'e.g. bridal makeup, open on Sundays',
              helper: 'Only things that are true for your business.',
            ),
            GpButton.ghost(
              label: _aiBusy
                  ? 'Writing…'
                  : (_text.text.trim().isNotEmpty
                      ? 'Write a new version with AI'
                      : 'Write with AI'),
              icon: Icons.auto_awesome_outlined,
              busy: _aiBusy,
              onPressed: (_aiBusy || busy) ? null : _writeWithAi,
            ),
            Text(
                "Written from your business details and services, within Google's ${GpProfileLimits.description} characters (no phone numbers, links or prices).",
                style: GpText.note),
            if (_aiNote.isNotEmpty) GpCallout(tone: GpTone.info, text: _aiNote),
            if (_aiError != null) ProfileErrorNote(error: _aiError),
          ]),
        ),
        GpStack(gap: 4, children: [
          GpTextField(
            label: 'Description',
            controller: _text,
            minLines: 6,
            maxLines: 12,
            maxLength: GpProfileLimits.description,
            error: _problem.isEmpty ? null : _problem,
            onChanged: (_) => setState(() {}),
          ),
          Text(
              '${_text.text.length} of ${GpProfileLimits.description} characters',
              style: GpText.note),
        ]),
      ],
    );
  }
}

// ── Hours ───────────────────────────────────────────────────────────────────

class _HoursForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _HoursForm({required this.data, required this.title});
  @override
  State<_HoursForm> createState() => _HoursFormState();
}

class _HoursFormState extends State<_HoursForm> with _SectionSave {
  @override
  String get section => 'hours';

  late ProfileWeek _week =
      profileToWeek(listOf(_profileOf(widget.data)['regular_hours']));
  Map<String, String> _errors = {};

  void _submit(bool _) {
    final found = profileWeekErrors(_week);
    setState(() => _errors = found);
    if (found.isNotEmpty) return;
    save({'periods': profileFromWeek(_week)});
  }

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      problems: _errors.isNotEmpty
          ? 'Some hours need fixing. See the days marked below.'
          : '',
      children: [
        ProfileHoursEditor(
          legend: 'Opening hours',
          value: _week,
          onChanged: (w) => setState(() => _week = w),
          errors: _errors,
        ),
      ],
    );
  }
}

class _MoreHoursForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _MoreHoursForm({required this.data, required this.title});
  @override
  State<_MoreHoursForm> createState() => _MoreHoursFormState();
}

class _MoreHoursFormState extends State<_MoreHoursForm> with _SectionSave {
  @override
  String get section => 'more_hours';

  late final List<Map<String, dynamic>> _types = listOf(
          widget.data['more_hours_types'])
      .map(mapOf)
      .toList();
  late final Map<String, ProfileWeek> _weeks = {
    for (final t in _types)
      str(t['id']): profileToWeek(listOf(listOf(
              _profileOf(widget.data)['more_hours'])
          .map(mapOf)
          .firstWhere((h) => str(h['type_id']) == str(t['id']),
              orElse: () => const <String, dynamic>{})['periods'])),
  };
  Map<String, String> _errors = {};

  ProfileWeek _weekOf(String id) => _weeks[id] ?? profileToWeek();

  void _submit(bool _) {
    final found = <String, String>{};
    for (final t in _types) {
      found.addAll(profileWeekErrors(_weekOf(str(t['id'])), '${t['id']}.'));
    }
    setState(() => _errors = found);
    if (found.isNotEmpty) return;
    save({
      'types': _types
          .map((t) => {
                'type_id': t['id'],
                'periods': profileFromWeek(_weekOf(str(t['id']))),
              })
          .where((t) => (t['periods'] as List).isNotEmpty)
          .toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      intro:
          'Extra hours Google shows for your category. Leave a type closed every day to not show it.',
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      problems: _errors.isNotEmpty
          ? 'Some hours need fixing. See the days marked below.'
          : '',
      children: [
        for (final t in _types)
          ProfileHoursEditor(
            key: ValueKey('more-${t['id']}'),
            legend: str(t['name']).isEmpty ? str(t['id']) : str(t['name']),
            value: _weekOf(str(t['id'])),
            onChanged: (w) => setState(() => _weeks[str(t['id'])] = w),
            errors: _errors,
            prefix: '${t['id']}.',
          ),
      ],
    );
  }
}

class _SpecialDay {
  String date;
  bool closed;
  String open;
  String close;
  _SpecialDay(
      {this.date = '', this.closed = true, this.open = '', this.close = ''});
}

class _SpecialHoursForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _SpecialHoursForm({required this.data, required this.title});
  @override
  State<_SpecialHoursForm> createState() => _SpecialHoursFormState();
}

class _SpecialHoursFormState extends State<_SpecialHoursForm>
    with _SectionSave {
  @override
  String get section => 'special_hours';

  late final List<_SpecialDay> _days =
      listOf(_profileOf(widget.data)['special_hours']).map((raw) {
    final d = mapOf(raw);
    return _SpecialDay(
      date: str(d['date']),
      closed: d['closed'] == true,
      open: str(d['open']),
      close: str(d['close']),
    );
  }).toList();
  Map<int, String> _errors = {};

  void _submit(bool _) {
    final found = <int, String>{};
    for (var i = 0; i < _days.length; i++) {
      final d = _days[i];
      if (d.date.isEmpty) {
        found[i] = 'Choose a date.';
      } else if (!d.closed &&
          (!profileIsTime(d.open) || !profileIsTime(d.close))) {
        found[i] =
            'Set an opening and a closing time, or tick Closed all day.';
      } else if (!d.closed && d.close.compareTo(d.open) <= 0) {
        found[i] = 'The closing time must be after the opening time.';
      }
    }
    setState(() => _errors = found);
    if (found.isNotEmpty) return;
    save({
      'days': _days
          .map((d) => d.closed
              ? {'date': d.date, 'closed': true, 'open': null, 'close': null}
              : {
                  'date': d.date,
                  'closed': false,
                  'open': d.open,
                  'close': d.close
                })
          .toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      intro: 'Dates when your hours differ from the usual, like holidays.',
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      problems:
          _errors.isNotEmpty ? 'Some dates need fixing. See below.' : '',
      children: [
        if (_days.isEmpty)
          const Text('No special hours yet.', style: GpText.note),
        for (var i = 0; i < _days.length; i++) _day(i),
        if (_days.length < GpProfileLimits.specialDays)
          Align(
            alignment: Alignment.centerLeft,
            child: GpButton.ghost(
              label: 'Add a date',
              icon: Icons.add,
              small: true,
              onPressed: () => setState(() => _days.add(_SpecialDay())),
            ),
          ),
      ],
    );
  }

  Widget _day(int i) {
    final d = _days[i];
    return Container(
      key: ObjectKey(d),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: _errors[i] != null ? AppColors.error : AppColors.border),
      ),
      child: GpStack(gap: 10, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: ProfileDateField(
              label: 'Date',
              value: d.date,
              onChanged: (v) => setState(() => d.date = v),
            ),
          ),
          IconButton(
            tooltip: 'Remove special date ${i + 1}',
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () => setState(() {
              _days.removeAt(i);
              _errors = {};
            }),
          ),
        ]),
        GpCheck(
          value: d.closed,
          onChanged: (v) => setState(() => d.closed = v),
          label: const Text('Closed all day', style: GpText.lead),
        ),
        if (!d.closed)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(children: [
              Expanded(
                child: GpTimeField(
                  label: 'Opens',
                  value: d.open,
                  onChanged: (v) => setState(() => d.open = v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GpTimeField(
                  label: 'Closes',
                  value: d.close,
                  onChanged: (v) => setState(() => d.close = v),
                ),
              ),
            ]),
          ),
        if (_errors[i] != null) Text(_errors[i]!, style: GpText.error),
      ]),
    );
  }
}

// ── Contact, name, address ──────────────────────────────────────────────────

class _ContactForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _ContactForm({required this.data, required this.title});
  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> with _SectionSave {
  @override
  String get section => 'contact';

  late final Map<String, dynamic> _p = _profileOf(widget.data);
  late final TextEditingController _primary =
      TextEditingController(text: str(_p['primary_phone']));
  late final List<TextEditingController> _more = listOf(
          _p['additional_phones'])
      .map((e) => TextEditingController(text: str(e)))
      .toList();
  late final TextEditingController _website =
      TextEditingController(text: str(_p['website']));
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _primary.dispose();
    for (final c in _more) {
      c.dispose();
    }
    _website.dispose();
    super.dispose();
  }

  void _submit(bool _) {
    final found = <String, String>{};
    if (_primary.text.trim().length > 30) found['primary'] = 'Too long.';
    for (var i = 0; i < _more.length; i++) {
      final p = _more[i].text.trim();
      if (p.isEmpty) {
        found['more$i'] = 'Enter the number, or remove this box.';
      } else if (p.length > 30) {
        found['more$i'] = 'Too long.';
      }
    }
    final website = _website.text.trim();
    if (website.isNotEmpty && !profileIsHttpUrl(website)) {
      found['website'] = 'Enter a web address starting with https://';
    }
    setState(() => _errors = found);
    if (found.isNotEmpty) return;
    save({
      'primary_phone': _primary.text.trim(),
      'additional_phones': _more.map((c) => c.text.trim()).toList(),
      'website': website,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      children: [
        GpTextField(
          label: 'Main phone',
          controller: _primary,
          keyboardType: TextInputType.phone,
          error: _errors['primary'],
        ),
        for (var i = 0; i < _more.length; i++)
          Row(
            key: ObjectKey(_more[i]),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GpTextField(
                  label: 'Other phone ${i + 1}',
                  controller: _more[i],
                  keyboardType: TextInputType.phone,
                  error: _errors['more$i'],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: IconButton(
                  tooltip: 'Remove other phone ${i + 1}',
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => setState(() {
                    _more.removeAt(i).dispose();
                    _errors = {};
                  }),
                ),
              ),
            ],
          ),
        if (_more.length < GpProfileLimits.additionalPhones)
          Align(
            alignment: Alignment.centerLeft,
            child: GpButton.ghost(
              label: 'Add a phone number',
              icon: Icons.add,
              small: true,
              onPressed: () =>
                  setState(() => _more.add(TextEditingController())),
            ),
          ),
        GpTextField(
          label: 'Website',
          controller: _website,
          hint: 'https://',
          keyboardType: TextInputType.url,
          error: _errors['website'],
        ),
      ],
    );
  }
}

class _NameForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _NameForm({required this.data, required this.title});
  @override
  State<_NameForm> createState() => _NameFormState();
}

class _NameFormState extends State<_NameForm> with _SectionSave {
  @override
  String get section => 'name';

  late final TextEditingController _name =
      TextEditingController(text: str(_profileOf(widget.data)['title']));
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit(bool confirmed) {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Enter the business name.');
      return;
    }
    setState(() => _error = '');
    save({'title': _name.text.trim(), 'confirm_risk': confirmed});
  }

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      children: [
        GpTextField(
          label: _req('Business name', true),
          controller: _name,
          maxLength: 100,
          error: _error.isEmpty ? null : _error,
          helper: 'Use your real business name, as customers know it.',
        ),
      ],
    );
  }
}

const List<(String, String, bool)> _addressFields = [
  ('line1', 'Street address', true),
  ('line2', 'Area or landmark', false),
  ('line3', 'Address line 3', false),
  ('locality', 'City', true),
  ('administrative_area', 'State', true),
  ('postal_code', 'PIN code', true),
];

class _AddressForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _AddressForm({required this.data, required this.title});
  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> with _SectionSave {
  @override
  String get section => 'address';

  late final Map<String, dynamic> _a =
      mapOf(_profileOf(widget.data)['address']);
  late final Map<String, TextEditingController> _v = () {
    final lines = listOf(_a['address_lines']).map((e) => str(e)).toList();
    String line(int i) => i < lines.length ? lines[i] : '';
    return {
      'line1': TextEditingController(text: line(0)),
      'line2': TextEditingController(text: line(1)),
      'line3': TextEditingController(text: line(2)),
      'locality': TextEditingController(text: str(_a['locality'])),
      'administrative_area':
          TextEditingController(text: str(_a['administrative_area'])),
      'postal_code': TextEditingController(text: str(_a['postal_code'])),
    };
  }();
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in _v.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _t(String key) => _v[key]!.text.trim();

  void _submit(bool confirmed) {
    final found = <String, String>{};
    for (final (key, _, required) in _addressFields) {
      if (required && _t(key).isEmpty) found[key] = 'This is needed.';
    }
    if (_t('postal_code').length > 12) found['postal_code'] = 'Too long.';
    setState(() => _errors = found);
    if (found.isNotEmpty) return;
    final region = str(_a['region_code']);
    save({
      'region_code': RegExp(r'^[A-Z]{2}$').hasMatch(region) ? region : 'IN',
      'address_lines':
          [_t('line1'), _t('line2'), _t('line3')].where((x) => x.isNotEmpty).toList(),
      'locality': _t('locality'),
      'administrative_area': _t('administrative_area'),
      'postal_code': _t('postal_code'),
      'confirm_risk': confirmed,
    });
  }

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      children: [
        for (final (key, label, required) in _addressFields)
          GpTextField(
            label: _req(label, required),
            controller: _v[key]!,
            maxLength: key == 'postal_code' ? 12 : 80,
            keyboardType: key == 'postal_code'
                ? TextInputType.number
                : TextInputType.streetAddress,
            error: _errors[key],
          ),
      ],
    );
  }
}

// ── Open status ─────────────────────────────────────────────────────────────

const List<(String, String)> _openStatuses = [
  ('OPEN', 'Open'),
  ('CLOSED_TEMPORARILY', 'Temporarily closed'),
  ('CLOSED_PERMANENTLY', 'Permanently closed'),
];

class _OpenStatusForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _OpenStatusForm({required this.data, required this.title});
  @override
  State<_OpenStatusForm> createState() => _OpenStatusFormState();
}

class _OpenStatusFormState extends State<_OpenStatusForm> with _SectionSave {
  @override
  String get section => 'open_status';

  late final Map<String, dynamic> _os =
      mapOf(_profileOf(widget.data)['open_status']);
  late String _status = _openStatuses.any((s) => s.$1 == str(_os['status']))
      ? str(_os['status'])
      : 'OPEN';
  late String _date = str(_os['opening_date']);

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      customRisk: true,
      risk: _status == 'CLOSED_PERMANENTLY'
          ? const _Risk(
              'A permanently closed business is hidden from most Google searches.',
              'I understand. Mark the business as permanently closed on Google.')
          : null,
      onSubmit: (confirmed) => save({
        'status': _status,
        'opening_date': _date.isEmpty ? null : _date,
        'confirm_risk': confirmed,
      }),
      busy: busy,
      error: saveError,
      children: [
        GpStack(gap: 6, children: [
          const Text('Is the business open?', style: GpText.label),
          for (final (value, label) in _openStatuses)
            GpChoice(
              selected: _status == value,
              title: label,
              onTap: busy ? null : () => setState(() => _status = value),
            ),
        ]),
        ProfileDateField(
          label: 'Opening date (optional)',
          value: _date,
          clearable: true,
          helper: 'When the business opened or will open.',
          onChanged: (v) => setState(() => _date = v),
        ),
      ],
    );
  }
}

// ── Services and attributes ─────────────────────────────────────────────────

class _ServicesForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _ServicesForm({required this.data, required this.title});
  @override
  State<_ServicesForm> createState() => _ServicesFormState();
}

class _ServicesFormState extends State<_ServicesForm> with _SectionSave {
  @override
  String get section => 'services';

  late final List<Map<String, dynamic>> _services =
      listOf(widget.data['growthos_services']).map(mapOf).toList();
  late final Set<Object?> _chosen = _services
      .where((x) => x['on_google'] == true)
      .map((x) => x['id'])
      .toSet();

  @override
  Widget build(BuildContext context) {
    final currency = str(widget.data['currency']);
    final onGoogle =
        listOf(_profileOf(widget.data)['services_on_google']).map(mapOf);
    return _SectionFrame(
      section: section,
      title: widget.title,
      intro:
          'Choose the services to show on Google. Services added on Google with other names are kept.',
      onSubmit: (_) => save({
        'service_ids': _services
            .where((x) => _chosen.contains(x['id']))
            .map((x) => x['id'])
            .toList(),
      }),
      busy: busy,
      error: saveError,
      canSave: _services.isNotEmpty,
      children: [
        GpStack(gap: 6, children: [
          const Text('Your services', style: GpText.label),
          if (_services.isEmpty)
            const Text('No services to choose from yet.', style: GpText.note)
          else
            for (final x in _services)
              GpChoice(
                checkbox: true,
                selected: _chosen.contains(x['id']),
                title: str(x['name']),
                subtitle: x['price'] is num
                    ? profileMoney(x['price'], currency)
                    : 'No fixed price',
                onTap: busy
                    ? null
                    : () => setState(() {
                          if (!_chosen.remove(x['id'])) _chosen.add(x['id']);
                        }),
              ),
        ]),
        GpStack(gap: 6, children: [
          const Text('On Google now', style: GpText.label),
          if (onGoogle.isEmpty)
            const Text('No services on Google yet.', style: GpText.note)
          else
            for (final x in onGoogle)
              Text(
                  '• ${str(x['label'])}${x['price'] is num ? ' · ${profileMoney(x['price'], str(x['currency']).isEmpty ? currency : str(x['currency']))}' : ''}',
                  style: GpText.lead),
        ]),
      ],
    );
  }
}

bool _sameValues(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

class _AttributesForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _AttributesForm({required this.data, required this.title});
  @override
  State<_AttributesForm> createState() => _AttributesFormState();
}

class _AttributesFormState extends State<_AttributesForm> with _SectionSave {
  @override
  String get section => 'attributes';

  late final List<Map<String, dynamic>> _meta =
      listOf(mapOf(widget.data['attributes'])['meta']).map(mapOf).toList();
  late final Map<String, List<dynamic>> _initial = () {
    final values =
        listOf(mapOf(widget.data['attributes'])['values']).map(mapOf).toList();
    return {
      for (final m in _meta)
        str(m['name']): List<dynamic>.from(listOf(values.firstWhere(
            (v) => str(v['name']) == str(m['name']),
            orElse: () => const <String, dynamic>{})['values'])),
    };
  }();
  late final Map<String, List<dynamic>> _values = {
    for (final e in _initial.entries) e.key: List<dynamic>.from(e.value),
  };
  late final Map<String, TextEditingController> _urls = {
    for (final m in _meta)
      if (str(m['value_type']) == 'URL')
        str(m['name']): TextEditingController(
            text: (_initial[str(m['name'])] ?? const []).isNotEmpty &&
                    _initial[str(m['name'])]!.first is String
                ? _initial[str(m['name'])]!.first as String
                : ''),
  };
  Map<String, String> _urlErrors = {};

  @override
  void dispose() {
    for (final c in _urls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<dynamic> _v(String name) => _values[name] ?? const [];

  /// Only what was changed or set (Google can't clear a yes / no or single
  /// choice, so those stay as they are).
  List<Map<String, dynamic>> get _changed => _meta.where((m) {
        final name = str(m['name']);
        final v = _v(name);
        if (_sameValues(v, _initial[name] ?? const [])) return false;
        final type = str(m['value_type']);
        return type == 'REPEATED_ENUM' || type == 'URL' || v.isNotEmpty;
      }).toList();

  void _submit(bool _) {
    final changed = _changed;
    final bad = <String, String>{};
    for (final m in changed) {
      final name = str(m['name']);
      if (str(m['value_type']) == 'URL' &&
          !_v(name).every((u) => u is String && profileIsHttpUrl(u))) {
        bad[name] = 'Enter a web address starting with https://';
      }
    }
    setState(() => _urlErrors = bad);
    if (bad.isNotEmpty) return;
    save({
      'values': changed
          .map((m) => {
                'name': m['name'],
                'values': _v(str(m['name']))
                    .map((x) => x is String ? x.trim() : x)
                    .toList(),
              })
          .toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final groups = _meta.map((m) => str(m['group'])).toSet().toList()
      ..sort((a, b) =>
          a.isEmpty ? 1 : (b.isEmpty ? -1 : a.compareTo(b)));
    final changed = _changed;
    return _SectionFrame(
      section: section,
      title: widget.title,
      intro:
          'Google offers these for your category. Only what you change is saved.',
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      canSave: changed.isNotEmpty,
      children: [
        for (final group in groups)
          GpStack(gap: 12, children: [
            Text((group.isEmpty ? 'Other' : group).toUpperCase(),
                style: const TextStyle(
                    fontSize: 11.5,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            for (final m in _meta.where((m) => str(m['group']) == group))
              _input(m),
          ]),
        if (changed.isEmpty)
          const Text('Change an answer to save.', style: GpText.note),
      ],
    );
  }

  Widget _input(Map<String, dynamic> meta) {
    final name = str(meta['name']);
    final type = str(meta['value_type']);
    final label = str(meta['display_name']).isEmpty
        ? name
        : str(meta['display_name']);
    final value = _v(name);
    final error = _urlErrors[name];
    final choices = listOf(meta['choices']).map(mapOf).toList();
    void set(List<dynamic> v) => setState(() => _values[name] = v);

    if (type == 'BOOL' || type == 'ENUM') {
      final first = value.isNotEmpty ? value.first : null;
      final current = type == 'BOOL'
          ? (first == true ? 'yes' : (first == false ? 'no' : ''))
          : (first is String ? first : '');
      final options = type == 'BOOL'
          ? const [('yes', 'Yes'), ('no', 'No')]
          : [
              for (final c in choices)
                (str(c['value']), str(c['display_name'])),
            ];
      return GpDropdown<String>(
        key: ValueKey('attr-$name'),
        label: label,
        value: options.any((o) => o.$1 == current) ? current : '',
        error: error,
        items: [
          const DropdownMenuItem(value: '', child: Text('Not set')),
          for (final (v, l) in options)
            DropdownMenuItem(value: v, child: Text(l)),
        ],
        onChanged: busy
            ? null
            : (v) {
                if (type == 'BOOL') {
                  set(v == 'yes' ? [true] : (v == 'no' ? [false] : []));
                } else {
                  set((v ?? '').isNotEmpty ? [v] : []);
                }
              },
      );
    }
    if (type == 'URL') {
      return GpTextField(
        label: label,
        controller: _urls[name]!,
        hint: 'https://',
        keyboardType: TextInputType.url,
        error: error,
        onChanged: (v) => set(v.isNotEmpty ? [v] : []),
      );
    }
    return GpStack(gap: 4, children: [
      Text(label, style: GpText.label),
      for (final c in choices)
        GpCheck(
          value: value.contains(c['value']),
          onChanged: busy
              ? null
              : (on) => set(on
                  ? [...value, c['value']]
                  : value.where((x) => x != c['value']).toList()),
          label: Text(str(c['display_name']), style: GpText.lead),
        ),
      if (error != null) Text(error, style: GpText.error),
    ]);
  }
}

// ── Categories and service area (searched on Google) ────────────────────────

class _CategoriesForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _CategoriesForm({required this.data, required this.title});
  @override
  State<_CategoriesForm> createState() => _CategoriesFormState();
}

class _CategoriesFormState extends State<_CategoriesForm> with _SectionSave {
  @override
  String get section => 'categories';

  late final Map<String, dynamic> _p = _profileOf(widget.data);
  late Map<String, dynamic>? _primary =
      _p['primary_category'] is Map ? mapOf(_p['primary_category']) : null;
  late List<Map<String, dynamic>> _additional =
      listOf(_p['additional_categories']).map(mapOf).toList();
  String _problem = '';

  bool get _full =>
      _additional.length >= GpProfileLimits.additionalCategories;
  bool _chosen(String name) =>
      str(_primary?['name']) == name ||
      _additional.any((c) => str(c['name']) == name);

  void _submit(bool confirmed) {
    if (_primary == null) {
      setState(() => _problem =
          'Choose a main category: search below and press Make main.');
      return;
    }
    setState(() => _problem = '');
    final main = str(_primary!['name']);
    save({
      'primary': _primary!['name'],
      'additional': _additional
          .map((c) => c['name'])
          .where((n) => str(n) != main)
          .toList(),
      'confirm_risk': confirmed,
    });
  }

  @override
  Widget build(BuildContext context) {
    final region = profileRegion(_p);
    return _SectionFrame(
      section: section,
      title: widget.title,
      onSubmit: _submit,
      busy: busy,
      error: saveError,
      problems: _problem,
      children: [
        GpStack(gap: 6, children: [
          const Text('Main category', style: GpText.label),
          _primary != null
              ? ProfileTag(str(_primary!['display_name']), main: true)
              : const Text('No main category yet. Search and choose one.',
                  style: GpText.muted),
        ]),
        GpStack(gap: 6, children: [
          const Text('Other categories', style: GpText.label),
          if (_additional.isEmpty)
            const Text('No other categories.', style: GpText.note)
          else
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final c in _additional)
                ProfileTag(
                  str(c['display_name']),
                  removeTooltip: 'Remove ${str(c['display_name'])}',
                  onRemove: busy
                      ? null
                      : () => setState(() => _additional = _additional
                          .where((x) => str(x['name']) != str(c['name']))
                          .toList()),
                ),
            ]),
          Text(
              'Up to ${GpProfileLimits.additionalCategories} other categories.',
              style: GpText.note),
        ]),
        ProfileSearch(
          label: "Search Google's categories",
          search: (q) => GoogleProfileApi.instance.categories(q, region),
          itemTitle: (c) => str(c['display_name']),
          emptyText: 'No matching categories.',
          buildActions: (c) => _chosen(str(c['name']))
              ? const GpChip('Chosen', tone: GpTone.ok)
              : Wrap(spacing: 6, runSpacing: 6, children: [
                  GpButton.ghost(
                    label: 'Make main',
                    small: true,
                    onPressed: () => setState(() {
                      _primary = c;
                      _additional = _additional
                          .where((x) => str(x['name']) != str(c['name']))
                          .toList();
                    }),
                  ),
                  GpButton.ghost(
                    label: 'Add',
                    small: true,
                    onPressed: _full
                        ? null
                        : () => setState(() => _additional = [..._additional, c]),
                  ),
                ]),
        ),
      ],
    );
  }
}

const List<(String, String)> _businessTypes = [
  ('CUSTOMER_AND_BUSINESS_LOCATION', "At your business and at customers' places"),
  ('CUSTOMER_LOCATION_ONLY',
      "Only at customers' places (your address is hidden)"),
];

class _ServiceAreaForm extends StatefulWidget {
  final Map<String, dynamic> data;
  final String title;
  const _ServiceAreaForm({required this.data, required this.title});
  @override
  State<_ServiceAreaForm> createState() => _ServiceAreaFormState();
}

class _ServiceAreaFormState extends State<_ServiceAreaForm>
    with _SectionSave {
  @override
  String get section => 'service_area';

  late final Map<String, dynamic> _area =
      mapOf(_profileOf(widget.data)['service_area']);
  late String _type =
      _businessTypes.any((t) => t.$1 == str(_area['business_type']))
          ? str(_area['business_type'])
          : 'CUSTOMER_AND_BUSINESS_LOCATION';
  late List<Map<String, dynamic>> _places =
      listOf(_area['places']).map(mapOf).toList();

  bool get _full => _places.length >= GpProfileLimits.places;

  @override
  Widget build(BuildContext context) {
    return _SectionFrame(
      section: section,
      title: widget.title,
      onSubmit: (confirmed) => save({
        'business_type': _type,
        'places': _places
            .map((p) => {'place_id': p['place_id'], 'name': p['name']})
            .toList(),
        'confirm_risk': confirmed,
      }),
      busy: busy,
      error: saveError,
      children: [
        GpStack(gap: 6, children: [
          const Text('Where you serve customers', style: GpText.label),
          for (final (value, label) in _businessTypes)
            GpChoice(
              selected: _type == value,
              title: label,
              onTap: busy ? null : () => setState(() => _type = value),
            ),
        ]),
        GpStack(gap: 6, children: [
          const Text('Service areas', style: GpText.label),
          if (_places.isEmpty)
            const Text('No service areas yet.', style: GpText.note)
          else
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final p in _places)
                ProfileTag(
                  str(p['name']),
                  removeTooltip: 'Remove ${str(p['name'])}',
                  onRemove: busy
                      ? null
                      : () => setState(() => _places = _places
                          .where((x) =>
                              str(x['place_id']) != str(p['place_id']))
                          .toList()),
                ),
            ]),
          Text('Up to ${GpProfileLimits.places} areas.', style: GpText.note),
        ]),
        ProfileSearch(
          label: 'Search for a city or area',
          search: (q) => GoogleProfileApi.instance.places(q),
          disabled: _full,
          itemTitle: (p) => str(p['name']),
          itemSub: (p) => str(p['address']),
          emptyText: 'No matching places.',
          buildActions: (p) => _places
                  .any((x) => str(x['place_id']) == str(p['place_id']))
              ? const GpChip('Added', tone: GpTone.ok)
              : GpButton.ghost(
                  label: 'Add',
                  small: true,
                  onPressed: () => setState(() => _places = [
                        ..._places,
                        {'place_id': p['place_id'], 'name': p['name']},
                      ]),
                ),
        ),
      ],
    );
  }
}
