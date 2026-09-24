import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/plan_feature_guard.dart';

/// CRM → Add / Edit client. Same fields, validation and payload as the web's
/// client form (CrmPage.jsx): details, lead source/status, events with prices,
/// follow-up, description, and the optional notes / payment-due section.
/// Pops with the saved client map on success.
class CrmClientFormScreen extends ConsumerStatefulWidget {
  /// Editing this client (null = adding a new one).
  final Map? client;

  /// The client's current events, when editing.
  final List events;

  const CrmClientFormScreen({super.key, this.client, this.events = const []});

  @override
  ConsumerState<CrmClientFormScreen> createState() =>
      _CrmClientFormScreenState();
}

class _EventRow {
  /// Server id of an existing event (kept on edit so it is updated, not re-created).
  final dynamic id;
  final TextEditingController name;
  final TextEditingController venue;
  final TextEditingController price;
  String eventDate;

  _EventRow([String initialName = ''])
    : id = null,
      name = TextEditingController(text: initialName),
      venue = TextEditingController(),
      price = TextEditingController(),
      eventDate = '';

  _EventRow.from(Map e)
    : id = e['id'],
      name = TextEditingController(text: '${e['name'] ?? ''}'),
      venue = TextEditingController(text: '${e['venue'] ?? ''}'),
      price = TextEditingController(
        text: CrmFormat.paiseToInput(e['pricePaise']),
      ),
      eventDate = '${e['eventDate'] ?? ''}';

  bool get isBlank =>
      name.text.trim().isEmpty &&
      eventDate.isEmpty &&
      price.text.trim().isEmpty;

  bool get hasContent =>
      name.text.trim().isNotEmpty ||
      eventDate.isNotEmpty ||
      venue.text.trim().isNotEmpty ||
      price.text.trim().isNotEmpty;

  void dispose() {
    name.dispose();
    venue.dispose();
    price.dispose();
  }
}

class _CrmClientFormScreenState extends ConsumerState<CrmClientFormScreen> {
  final _api = CrmApi();

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _location = TextEditingController();
  final _followUpNote = TextEditingController();
  final _description = TextEditingController();
  final _additionalNote = TextEditingController();
  final _additionalInfo = TextEditingController();
  final _pendingNote = TextEditingController();

  String _state = '';
  String _leadSource = 'other';
  String _status = 'lead';
  String _lostReason = '';
  String _followUpDate = '';
  String _paymentDueDate = '';
  bool _remindersEnabled = true;
  bool _showMore = false;

  late final List<_EventRow> _events = widget.events.isNotEmpty
      ? widget.events.map((e) => _EventRow.from(e as Map)).toList()
      : [_EventRow('Wedding')];

  bool get _isEdit => widget.client != null;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    if (c == null) return;
    String str(String k) => c[k] == null ? '' : '${c[k]}';
    _name.text = str('name');
    _phone.text = str('phone');
    _email.text = str('email');
    _location.text = str('location');
    _state = str('state');
    _leadSource = str('leadSource').isEmpty ? 'other' : str('leadSource');
    _status = str('status').isEmpty ? 'lead' : str('status');
    _description.text = str('description');
    _additionalNote.text = str('additionalNote');
    _additionalInfo.text = str('additionalInfo');
    _paymentDueDate = str('paymentDueDate');
    _pendingNote.text = str('pendingNote');
    _followUpDate = str('followUpDate');
    _followUpNote.text = str('followUpNote');
    _remindersEnabled = c['remindersEnabled'] != false;
    _lostReason = str('lostReason');
    // Open the extra section when it already holds something, as on the web.
    _showMore =
        _additionalNote.text.isNotEmpty ||
        _additionalInfo.text.isNotEmpty ||
        _paymentDueDate.isNotEmpty ||
        _pendingNote.text.isNotEmpty ||
        !_remindersEnabled;
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _phone,
      _email,
      _location,
      _followUpNote,
      _description,
      _additionalNote,
      _additionalInfo,
      _pendingNote,
    ]) {
      c.dispose();
    }
    for (final e in _events) {
      e.dispose();
    }
    super.dispose();
  }

  bool get _isLostOrCancelled => _status == 'lost' || _status == 'cancelled';

  int get _totalPaise =>
      _events.fold(0, (sum, e) => sum + (CrmFormat.toPaise(e.price.text) ?? 0));

  List<String> get _suggestions => CrmOptions.eventSuggestions
      .where(
        (s) => !_events.any(
          (e) => e.name.text.trim().toLowerCase() == s.toLowerCase(),
        ),
      )
      .toList();

  /// Same as the web: a suggestion fills the first empty row, else adds one.
  void _addEvent([String name = '']) {
    setState(() {
      final blank = _events.where((e) => e.isBlank).firstOrNull;
      if (blank != null && name.isNotEmpty) {
        blank.name.text = name;
      } else {
        _events.add(_EventRow(name));
      }
    });
  }

  Future<String?> _pickDate(String current) async {
    final initial = CrmFormat.parseDate(current) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    return picked == null ? null : DateFormat('yyyy-MM-dd').format(picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);

    if (_name.text.trim().isEmpty) {
      return setState(() => _error = "Enter the client's name.");
    }
    final events = _events.where((e) => e.hasContent).toList();
    if (events.any((e) => e.name.text.trim().isEmpty)) {
      return setState(
        () => _error = 'Give every event a name, or remove the empty row.',
      );
    }
    if (events.any((e) => CrmFormat.toPaise(e.price.text) == null)) {
      return setState(() => _error = 'Check the event prices.');
    }

    String? orNull(String v) => v.trim().isEmpty ? null : v.trim();

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'email': _email.text.trim(),
      'location': _location.text.trim(),
      'state': _state,
      'leadSource': _leadSource,
      'status': _status,
      'description': _description.text,
      'additionalNote': _additionalNote.text,
      'additionalInfo': _additionalInfo.text,
      'paymentDueDate': _paymentDueDate,
      'pendingNote': _pendingNote.text,
      'followUpDate': orNull(_followUpDate),
      'followUpNote': orNull(_followUpNote.text),
      'remindersEnabled': _remindersEnabled,
      'lostReason': _isLostOrCancelled ? orNull(_lostReason) : null,
      'events': events
          .map(
            (e) => {
              'id': e.id,
              'name': e.name.text.trim(),
              'eventDate': orNull(e.eventDate),
              'venue': e.venue.text,
              'pricePaise': CrmFormat.toPaise(e.price.text),
            },
          )
          .toList(),
    };

    setState(() => _saving = true);
    try {
      final res = _isEdit
          ? await _api.updateClient(widget.client!['id'], body)
          : await _api.createClient(body);
      if (!mounted) return;
      Navigator.pop(context, res['client'] ?? <String, dynamic>{});
    } on PlanModuleLockedException catch (e) {
      if (mounted) {
        showPlanModuleLocked(
          context,
          ref,
          module: e.module.isEmpty ? 'crm' : e.module,
          message: e.message,
        );
      }
    } on CrmException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save the client.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: _isEdit ? 'Edit client' : 'Add client'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _field(
            'Client name *',
            _text(_name, hint: 'e.g. Riya & Arjun', maxLength: 150),
          ),
          _field(
            'Phone',
            _text(_phone, keyboard: TextInputType.phone, maxLength: 20),
          ),
          _field(
            'Email',
            _text(_email, keyboard: TextInputType.emailAddress, maxLength: 150),
            hint: 'Needed to email quotations and invoices.',
          ),
          _field(
            'Location',
            _text(_location, hint: 'City or address', maxLength: 200),
          ),
          _field(
            'State',
            _dropdown(_state, {
              '': 'Not set',
              for (final s in CrmOptions.states) s: s,
            }, (v) => setState(() => _state = v)),
            hint:
                'Used for GST: same state as you → CGST + SGST, other state → IGST.',
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  'Lead source',
                  _dropdown(
                    _leadSource,
                    CrmOptions.leadSources,
                    (v) => setState(() => _leadSource = v),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  'Status',
                  _dropdown(
                    _status,
                    CrmOptions.statuses,
                    (v) => setState(() => _status = v),
                  ),
                ),
              ),
            ],
          ),
          if (_isLostOrCancelled)
            _field(
              'Why?',
              _dropdown(_lostReason, {
                '': 'Not sure',
                ...CrmOptions.lostReasons,
              }, (v) => setState(() => _lostReason = v)),
            ),
          const SizedBox(height: 6),
          _eventsSection(),
          const SizedBox(height: 12),
          _field(
            'Next follow-up',
            _dateButton(
              _followUpDate,
              (d) => setState(() => _followUpDate = d),
              onClear: () => setState(() => _followUpDate = ''),
            ),
          ),
          _field(
            'Follow-up about',
            _text(
              _followUpNote,
              hint: 'e.g. Send the album options',
              maxLength: 300,
            ),
          ),
          _field(
            'Description',
            _text(
              _description,
              hint: 'What the client wants',
              maxLength: 4000,
              lines: 3,
            ),
          ),
          if (_showMore) ...[
            _field(
              'Additional note',
              _text(_additionalNote, maxLength: 4000, lines: 3),
            ),
            _field(
              'Additional information',
              _text(_additionalInfo, maxLength: 4000, lines: 3),
            ),
            _field(
              'Balance due by',
              _dateButton(
                _paymentDueDate,
                (d) => setState(() => _paymentDueDate = d),
                onClear: () => setState(() => _paymentDueDate = ''),
              ),
            ),
            _field(
              'Pending payment note',
              _text(
                _pendingNote,
                hint: 'e.g. Rest after the reception',
                maxLength: 2000,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _remindersEnabled,
              onChanged: (v) => setState(() => _remindersEnabled = v ?? true),
              title: const Text(
                'Send this client automatic payment reminders by email',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ] else
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _showMore = true),
                child: const Text('+ Notes, payment due date and more'),
              ),
            ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    _saving
                        ? 'Saving…'
                        : _isEdit
                        ? 'Save changes'
                        : 'Add client',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _eventsSection() {
    final suggestions = _suggestions;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Events',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'Total ${CrmFormat.rupees(_totalPaise)}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestions
                  .map(
                    (s) => ActionChip(
                      label: Text('+ $s', style: const TextStyle(fontSize: 12)),
                      onPressed: () => _addEvent(s),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          for (final e in _events) _eventCard(e),
          TextButton.icon(
            onPressed: () => _addEvent(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add event'),
          ),
        ],
      ),
    );
  }

  Widget _eventCard(_EventRow e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _text(
                  e.name,
                  hint: 'Event name',
                  maxLength: 100,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                tooltip: 'Remove event',
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () => setState(() {
                  _events.remove(e);
                  e.dispose();
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dateButton(
                  e.eventDate,
                  (d) => setState(() => e.eventDate = d),
                  onClear: () => setState(() => e.eventDate = ''),
                  placeholder: 'Event date',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _text(
                  e.price,
                  hint: 'Price',
                  prefix: '₹ ',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _text(e.venue, hint: 'Venue', maxLength: 200),
        ],
      ),
    );
  }

  // ---------- small form helpers ----------

  Widget _field(String label, Widget input, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          input,
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration({String? hint, String? prefix}) =>
      InputDecoration(
        hintText: hint,
        prefixText: prefix,
        isDense: true,
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );

  Widget _text(
    TextEditingController c, {
    String? hint,
    int? maxLength,
    int lines = 1,
    String? prefix,
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: c,
      maxLength: maxLength,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
      onChanged: onChanged,
      decoration: _decoration(hint: hint, prefix: prefix),
    );
  }

  Widget _dropdown(
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: options.containsKey(value) ? value : options.keys.first,
      isExpanded: true,
      decoration: _decoration(),
      items: options.entries
          .map(
            (e) => DropdownMenuItem(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  Widget _dateButton(
    String value,
    ValueChanged<String> onPicked, {
    required VoidCallback onClear,
    String placeholder = 'Select date',
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () async {
        final d = await _pickDate(value);
        if (d != null) onPicked(d);
      },
      child: InputDecorator(
        decoration: _decoration().copyWith(
          suffixIcon: value.isEmpty
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                ),
        ),
        child: Text(
          value.isEmpty ? placeholder : CrmFormat.date(value),
          style: TextStyle(
            color: value.isEmpty
                ? AppColors.textTertiary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
