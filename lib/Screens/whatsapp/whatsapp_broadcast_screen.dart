import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/common_app_bar.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';

/// A new broadcast.
///
/// Two things this screen is honest about. Values are set once for the whole
/// campaign, so a template with a name in it would greet everybody by the
/// same name — except `{name}`, which the server fills per client. And a
/// broadcast cannot be recalled, so the number of people it will reach is on
/// the button, not reported after.
///
/// Pops with the server's message once the campaign has started.
class WhatsAppBroadcastScreen extends ConsumerStatefulWidget {
  /// Approved templates (every language).
  final List<Map> templates;

  const WhatsAppBroadcastScreen({super.key, required this.templates});

  @override
  ConsumerState<WhatsAppBroadcastScreen> createState() =>
      _WhatsAppBroadcastScreenState();
}

class _WhatsAppBroadcastScreenState
    extends ConsumerState<WhatsAppBroadcastScreen> {
  final _api = CrmApi();
  final _name = TextEditingController();
  final _draft = WaTemplateDraft();
  String _audienceId = 'all';
  Map? _audience;
  bool _counting = true;
  DateTime? _scheduledAt;
  bool _sending = false;
  String _error = '';

  /// Bumped on every recount so an older answer cannot overwrite a newer one.
  int _countSeq = 0;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() => _error = ''));
    _draft.addListener(() => setState(() => _error = ''));
    _count();
  }

  @override
  void dispose() {
    _name.dispose();
    _draft.dispose();
    super.dispose();
  }

  /// Recount every time the group changes, so the number on the button is
  /// always the number that will actually be messaged.
  Future<void> _count() async {
    final seq = ++_countSeq;
    setState(() => _counting = true);
    try {
      final r = await _api.whatsappAudience(_audienceId);
      if (!mounted || seq != _countSeq) return;
      setState(() => _audience = r);
    } catch (_) {
      if (!mounted || seq != _countSeq) return;
      setState(() => _audience = null);
    } finally {
      if (mounted && seq == _countSeq) setState(() => _counting = false);
    }
  }

  List<Map> get _unique => waUniqueByName(widget.templates);

  Map? get _chosen => widget.templates
      .where((t) => t['name'] == _draft.name)
      .cast<Map?>()
      .firstWhere((_) => true, orElse: () => null);

  int get _reach => ((_audience?['reachable'] as num?) ?? 0).toInt();

  String get _problem {
    if (_name.text.trim().isEmpty) return 'Give this campaign a name';
    if (_draft.name.isEmpty) return 'Choose a template';
    if (_reach == 0) {
      return ((_audience?['total'] as num?) ?? 0) > 0
          ? 'Nobody here has a number WhatsApp can reach'
          : 'Nobody in this group yet';
    }
    final max = (_audience?['max'] as num?)?.toInt();
    if (max != null && max > 0 && _reach > max) {
      return 'Too many at once — $max is the limit';
    }
    final at = _scheduledAt;
    // Matches the server's rule, so the refusal arrives while the vendor is
    // still looking at the field.
    if (at != null &&
        at.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
      return 'Pick a time at least a minute from now';
    }
    final needed = waVariableCount(_chosen);
    final values = _draft.values;
    for (var n = 1; n <= needed; n++) {
      if ((values['$n'] ?? '').trim().isEmpty) return 'Fill in {{$n}}';
    }
    return '';
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(hours: 1));
    final day = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      );
      _error = '';
    });
  }

  Future<void> _send() async {
    final problem = _problem;
    if (problem.isNotEmpty) {
      setState(() => _error = problem);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      final result = await _api.startWhatsappCampaign({
        'name': _name.text.trim(),
        'templateName': _draft.name,
        'audience': _audienceId,
        // UTC ISO carries the timezone; a local wall-clock time would not.
        'scheduledAt': _scheduledAt?.toUtc().toIso8601String(),
        'variables': _draft.values,
      });
      if (!mounted) return;
      Navigator.pop(
        context,
        '${result['message'] ?? 'Your broadcast has started.'}',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not start this campaign.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chosen = _chosen;
    final languages = _draft.name.isEmpty
        ? <String>[]
        : widget.templates
              .where((t) => t['name'] == _draft.name)
              .map((t) => '${t['language'] ?? ''}')
              .where((l) => l.isNotEmpty)
              .toSet()
              .toList();
    final a = _audience;
    final options = <String, String>{
      for (final o in List.from(a?['options'] ?? const []).whereType<Map>())
        '${o['id']}': '${o['label']}',
    };
    if (!options.containsKey(_audienceId)) {
      options[_audienceId] = _audienceId == 'all' ? 'All clients' : _audienceId;
    }
    final total = ((a?['total'] as num?) ?? 0).toInt();
    final unreachable = List.from(a?['unreachable'] ?? const []);
    final optedOut = List.from(a?['optedOut'] ?? const []);
    final problem = _problem;

    String audienceHint;
    if (_counting && a == null) {
      audienceHint = 'Counting…';
    } else if (a == null) {
      audienceHint = 'Could not count this group.';
    } else if (total == 0) {
      audienceHint = 'Nobody in this group yet';
    } else {
      audienceHint =
          '$_reach of $total in this group will be messaged'
          '${unreachable.isNotEmpty ? ' · ${unreachable.length} have no usable number' : ''}'
          // Left out on purpose, and said so: a smaller number than expected
          // should come with its reason.
          '${optedOut.isNotEmpty ? ' · ${optedOut.length} asked not to be messaged' : ''}';
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'New broadcast'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Goes to many clients at once and cannot be recalled. Only approved '
                    'templates can be used.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  if (_error.isNotEmpty) WaErrorBox(_error),
                  CrmField(
                    label: 'Campaign name',
                    hint: 'Only you see this.',
                    child: CrmTextInput(
                      controller: _name,
                      hint: 'Diwali offer',
                      maxLength: 120,
                    ),
                  ),
                  CrmField(
                    label: 'Template',
                    hint: languages.length > 1
                        ? 'This one is approved in ${languages.map(waLanguageName).join(' and ')}. '
                              'A broadcast is sent by name only, so Wapzio picks which goes out.'
                        : _unique.isNotEmpty
                        ? 'Only approved templates are listed.'
                        : 'You have no approved templates yet.',
                    child: CrmDropdown(
                      value: _draft.name,
                      options: {
                        '': 'Choose a template',
                        for (final t in _unique) '${t['name']}': '${t['name']}',
                      },
                      onChanged: _draft.choose,
                    ),
                  ),
                  CrmField(
                    label: 'Send to',
                    hint: audienceHint,
                    child: CrmDropdown(
                      value: _audienceId,
                      options: options,
                      onChanged: (v) {
                        setState(() {
                          _audienceId = v;
                          _error = '';
                        });
                        _count();
                      },
                    ),
                  ),
                  CrmField(
                    label: 'Send later (optional)',
                    hint: 'Leave empty to send now.',
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: crmInputDecoration(
                          suffix: _scheduledAt == null
                              ? const Icon(Icons.schedule, size: 18)
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () =>
                                      setState(() => _scheduledAt = null),
                                ),
                        ),
                        child: Text(
                          _scheduledAt == null
                              ? 'Now'
                              : DateFormat(
                                  'd MMM yyyy, h:mm a',
                                ).format(_scheduledAt!),
                          style: TextStyle(
                            color: _scheduledAt == null
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (chosen != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: crmCardDecoration(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Values for this campaign',
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(height: 4),
                          const WaHint(
                            'Write {name} and each client sees their own name. Anything else is '
                            'the same for everyone, so keep other personal details out of a '
                            'broadcast.',
                          ),
                          ..._valueFields(chosen),
                        ],
                      ),
                    ),
                  ],
                  if (unreachable.isNotEmpty)
                    CrmNotice(
                      '${unreachable.length} will be skipped for want of a usable number: '
                      '${unreachable.take(5).map((c) => c is Map ? '${c['name']}' : '$c').join(', ')}'
                      '${unreachable.length > 5 ? ' and others' : ''}.',
                    ),
                  Text('Preview', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  ListenableBuilder(
                    listenable: _draft,
                    builder: (_, _) => WaTemplateBubble(
                      template: chosen,
                      values: _draft.values,
                      name: a?['sample'] == null ? null : '${a!['sample']}',
                    ),
                  ),
                  if ('${chosen?['body'] ?? ''}'.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: WaHint(
                        '${a?['sample'] ?? 'Each client'} sees their own name wherever you write {name}.',
                      ),
                    ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (problem.isNotEmpty && _name.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(problem, style: AppTextStyles.caption),
                    ),
                  CrmFormButtons(
                    primaryLabel: _scheduledAt != null
                        ? 'Schedule for $_reach'
                        : 'Send to $_reach now',
                    onPrimary: problem.isNotEmpty ? null : _send,
                    busy: _sending,
                    busyLabel: 'Starting…',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One box per value the template takes; three where the count is unknown.
  List<Widget> _valueFields(Map chosen) {
    final count = waVariableCount(chosen);
    final slots = count > 0
        ? List.generate(count, (i) => i + 1)
        : const [1, 2, 3];
    return [
      if ('${chosen['body'] ?? ''}'.isEmpty)
        const WaHint(
          "Wapzio did not return this template's wording, so we cannot show how many "
          'values it takes. Fill in the ones it uses and leave the rest blank.',
        ),
      for (final n in slots)
        CrmField(
          label: '{{$n}}',
          child: CrmTextInput(controller: _draft.controller(n)),
        ),
    ];
  }
}
