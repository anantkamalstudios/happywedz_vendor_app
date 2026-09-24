import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/plan_feature_guard.dart';
import 'crm_business_details_screen.dart';
import 'crm_widgets.dart';

enum CrmDocKind { quotation, invoice }

/// CRM quotation (new / edit) and invoice (new) editor, as on the web: line
/// items that start from the client's events, discount, GST by tax mode,
/// dates, notes and terms. An invoice can instead be issued straight from an
/// accepted quotation. Pops with the server's message on success.
class CrmDocumentEditorScreen extends ConsumerStatefulWidget {
  final CrmDocKind kind;
  final Map client;
  final List events;
  final Map? profile;

  /// Editing this quotation (quotations only).
  final Map? quotation;

  /// All of the client's quotations (invoices only — accepted ones can be used).
  final List quotations;
  final dynamic defaultQuotationId;

  const CrmDocumentEditorScreen.quotation({
    super.key,
    required this.client,
    required this.events,
    required this.profile,
    this.quotation,
  }) : kind = CrmDocKind.quotation,
       quotations = const [],
       defaultQuotationId = null;

  const CrmDocumentEditorScreen.invoice({
    super.key,
    required this.client,
    required this.events,
    required this.profile,
    required this.quotations,
    this.defaultQuotationId,
  }) : kind = CrmDocKind.invoice,
       quotation = null;

  @override
  ConsumerState<CrmDocumentEditorScreen> createState() =>
      _CrmDocumentEditorScreenState();
}

class _CrmDocumentEditorScreenState
    extends ConsumerState<CrmDocumentEditorScreen> {
  late final int _defaultGst =
      (num.tryParse('${widget.profile?['defaultGstRate'] ?? 18}') ?? 18)
          .toInt();
  late final String _taxMode = CrmTax.mode(
    widget.profile,
    widget.client['state']?.toString(),
  );
  late final List _accepted = widget.quotations
      .where((q) => q['status'] == 'accepted')
      .toList();

  bool get _isQuotation => widget.kind == CrmDocKind.quotation;
  bool get _isEdit => widget.quotation != null;

  final List<CrmLine> _lines = [];
  final List<List<TextEditingController>> _lineCtrls = [];
  final _discount = TextEditingController();
  final _notes = TextEditingController();
  final _terms = TextEditingController();
  late String _date; // issue / invoice date
  late String _date2; // valid until / due date

  // Invoice only.
  late String _source = _accepted.isNotEmpty ? 'quotation' : 'items';
  late String _quotationId =
      '${widget.defaultQuotationId ?? (_accepted.isNotEmpty ? _accepted.first['id'] : '')}';

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final q = widget.quotation;
    final sac = '${widget.profile?['defaultSac'] ?? ''}';
    final start = q != null
        ? CrmLine.fromItems(List.from(q['items'] ?? const []))
        : CrmLine.fromEvents(widget.events, _defaultGst, sac);
    for (final l
        in start.isEmpty ? [CrmLine(gstRate: '$_defaultGst')] : start) {
      _addLine(l);
    }
    if (q != null && ((q['discountPaise'] as num?) ?? 0) > 0) {
      _discount.text = CrmFormat.paiseToInput(q['discountPaise']);
    }
    _notes.text = q?['notes']?.toString() ?? '';
    _terms.text = q != null
        ? '${q['terms'] ?? ''}'
        : '${widget.profile?['terms'] ?? ''}';

    if (_isQuotation) {
      _date = q?['issueDate']?.toString() ?? CrmFormat.today();
      _date2 = q != null ? '${q['validUntil'] ?? ''}' : CrmFormat.inDays(15);
    } else {
      _date = CrmFormat.today();
      final due = '${widget.client['paymentDueDate'] ?? ''}';
      _date2 = due.isNotEmpty && due.compareTo(CrmFormat.today()) >= 0
          ? due
          : CrmFormat.inDays(7);
    }
  }

  @override
  void dispose() {
    for (final c in _lineCtrls.expand((x) => x)) {
      c.dispose();
    }
    _discount.dispose();
    _notes.dispose();
    _terms.dispose();
    super.dispose();
  }

  void _addLine(CrmLine l) {
    _lines.add(l);
    _lineCtrls.add([
      TextEditingController(text: l.description),
      TextEditingController(text: l.quantity),
      TextEditingController(text: l.rate),
    ]);
  }

  void _removeLine(int i) {
    for (final c in _lineCtrls[i]) {
      c.dispose();
    }
    _lines.removeAt(i);
    _lineCtrls.removeAt(i);
  }

  Map? get _selectedQuotation =>
      _accepted.where((q) => '${q['id']}' == _quotationId).firstOrNull;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _error = null);
    final useQuotation = !_isQuotation && _source == 'quotation';

    final body = <String, dynamic>{'notes': _notes.text, 'terms': _terms.text};
    if (useQuotation) {
      if (_selectedQuotation == null) {
        return setState(() => _error = 'Choose a quotation.');
      }
      body['quotationId'] = _selectedQuotation!['id'];
    } else {
      final problem = CrmLine.validate(_lines);
      if (problem != null) return setState(() => _error = problem);
      final discount = CrmFormat.toPaise(_discount.text);
      if (discount == null) {
        return setState(() => _error = 'Enter a valid discount.');
      }
      body['items'] = _lines.map((l) => l.toJson()).toList();
      body['discountPaise'] = discount;
    }
    if (_isQuotation) {
      body['issueDate'] = _date;
      body['validUntil'] = _date2.isEmpty ? null : _date2;
    } else {
      body['invoiceDate'] = _date;
      body['dueDate'] = _date2.isEmpty ? null : _date2;
    }

    setState(() => _saving = true);
    try {
      final api = CrmApi();
      final res = _isQuotation
          ? (_isEdit
                ? await api.updateQuotation(widget.quotation!['id'], body)
                : await api.createQuotation(widget.client['id'], body))
          : await api.createInvoice(widget.client['id'], body);
      if (mounted) Navigator.pop(context, '${res['message'] ?? 'Saved.'}');
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
      if (mounted) {
        setState(
          () => _error = _isQuotation
              ? 'Could not save the quotation.'
              : 'Could not issue the invoice.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openBusiness() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const CrmBusinessDetailsScreen()),
  );

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    final title = _isQuotation
        ? (_isEdit
              ? 'Edit quotation ${widget.quotation!['number']}'
              : 'New quotation')
        : 'New invoice';
    final useQuotation = !_isQuotation && _source == 'quotation';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(title: title),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          Text(
            'For ${widget.client['name'] ?? ''}',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (_isEdit && widget.quotation!['status'] == 'sent')
            const CrmNotice(
              "Your client already has the link. They'll see these changes when they open it.",
              warn: false,
            ),
          if (!_isQuotation) _taxNotice(),
          if (!_isQuotation) _sourceChoice(),
          CrmField(
            label: _isQuotation ? 'Quotation date' : 'Invoice date',
            child: CrmDateInput(
              value: _date,
              clearable: false,
              onChanged: (d) => setState(() => _date = d),
            ),
          ),
          CrmField(
            label: _isQuotation ? 'Valid until' : 'Due date',
            child: CrmDateInput(
              value: _date2,
              firstDate: CrmFormat.parseDate(_date),
              onChanged: (d) => setState(() => _date2 = d),
            ),
          ),
          if (_isQuotation)
            CrmField(
              label: 'Tax',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      CrmOptions.taxModeHints[_taxMode] ?? '',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (_taxMode == 'none')
                    TextButton(
                      onPressed: _openBusiness,
                      child: const Text('Business details'),
                    ),
                ],
              ),
            ),
          if (useQuotation) _quotationSummary() else _itemsEditor(),
          const SizedBox(height: 8),
          CrmField(
            label: _isQuotation ? 'Notes for the client' : 'Notes',
            child: CrmTextInput(
              controller: _notes,
              lines: 3,
              maxLength: 4000,
              hint: _isQuotation
                  ? "What's included, deliverables, timelines…"
                  : null,
            ),
          ),
          CrmField(
            label: 'Terms & conditions',
            hint: _isQuotation && '${widget.profile?['terms'] ?? ''}'.isEmpty
                ? 'Save default terms in Business details to fill this in every time.'
                : null,
            child: CrmTextInput(
              controller: _terms,
              lines: 3,
              maxLength: 4000,
              hint: 'e.g. 50% advance to confirm the booking',
            ),
          ),
          if (!_isQuotation)
            const CrmNotice(
              "Check the details before issuing. An invoice can't be edited afterwards — only cancelled and issued again.",
            ),
          if (_error != null) CrmNotice(_error!),
          CrmFormButtons(
            primaryLabel: _isQuotation
                ? (_isEdit ? 'Save quotation' : 'Save as draft')
                : 'Issue invoice',
            busyLabel: _isQuotation ? 'Saving…' : 'Issuing…',
            onPrimary: _save,
            busy: _saving,
          ),
        ],
      ),
    );
  }

  Widget _taxNotice() {
    if (_taxMode == 'none') {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: AppColors.infoTint,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                "This invoice won't include GST because your GSTIN isn't saved.",
                style: TextStyle(fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _openBusiness,
              child: const Text('Add GSTIN'),
            ),
          ],
        ),
      );
    }
    return CrmNotice(
      'Tax invoice from GSTIN ${widget.profile?['gstin']} with '
      '${_taxMode == 'intra' ? 'CGST + SGST' : 'IGST (client in ${widget.client['state']})'}.',
      warn: false,
    );
  }

  Widget _sourceChoice() {
    Widget option(String id, String title, String sub, bool enabled) {
      final selected = _source == id;
      return Opacity(
        opacity: enabled ? 1 : 0.55,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: enabled ? () => setState(() => _source = id) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppColors.primary : AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        sub,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          option(
            'quotation',
            'From an accepted quotation',
            _accepted.isNotEmpty
                ? 'Same items and prices the client agreed to.'
                : 'No accepted quotation yet.',
            _accepted.isNotEmpty,
          ),
          option(
            'items',
            'Enter items',
            "Starts from the client's events and prices.",
            true,
          ),
          if (_source == 'quotation' && _accepted.length > 1)
            CrmField(
              label: 'Quotation',
              child: CrmDropdown(
                value: _quotationId,
                options: {
                  for (final q in _accepted)
                    '${q['id']}':
                        '${q['number']} · ${CrmFormat.rupees(q['totalPaise'])}',
                },
                onChanged: (v) => setState(() => _quotationId = v),
              ),
            ),
        ],
      ),
    );
  }

  /// Read-only view of the accepted quotation an invoice will copy.
  Widget _quotationSummary() {
    final q = _selectedQuotation;
    if (q == null) return const SizedBox();
    var lines = CrmLine.fromItems(List.from(q['items'] ?? const []));
    if (q['taxMode'] == 'none') {
      lines = lines.map((l) => l..gstRate = '$_defaultGst').toList();
    }
    final t = CrmTax.totals(
      lines,
      ((q['discountPaise'] as num?) ?? 0).toInt(),
      _taxMode,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quotation ${q['number']}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final item in List.from(q['items'] ?? const []))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${[item['eventName'], item['description']].where((x) => x != null && '$x'.isNotEmpty).join(' – ')}'
                      '${(num.tryParse('${item['quantity']}') ?? 1) != 1 ? ' × ${item['quantity']}' : ''}',
                    ),
                  ),
                  Text(
                    CrmFormat.rupees(item['amountPaise'], decimals: true),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const Divider(),
          if (t.discount > 0)
            _totalRow(
              'Discount',
              '− ${CrmFormat.rupees(t.discount, decimals: true)}',
            ),
          if (_taxMode == 'intra')
            _totalRow('CGST + SGST', CrmFormat.rupees(t.tax, decimals: true)),
          if (_taxMode == 'inter')
            _totalRow('IGST', CrmFormat.rupees(t.tax, decimals: true)),
          _totalRow(
            'Invoice total',
            CrmFormat.rupees(t.total, decimals: true),
            bold: true,
          ),
          if (q['taxMode'] == 'none' && _taxMode != 'none')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'The quotation had no GST; $_defaultGst% GST is added on the invoice.',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemsEditor() {
    final discount = CrmFormat.toPaise(_discount.text) ?? 0;
    final t = CrmTax.totals(_lines, discount, _taxMode);
    final withGst = _taxMode != 'none';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Items',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < _lines.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: crmCardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CrmTextInput(
                        controller: _lineCtrls[i][0],
                        hint: 'e.g. Haldi – candid photography',
                        maxLength: 300,
                        onChanged: (v) => _lines[i].description = v,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove item',
                      icon: const Icon(Icons.delete_outline),
                      color: AppColors.error,
                      onPressed: _lines.length == 1
                          ? null
                          : () => setState(() => _removeLine(i)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: CrmTextInput(
                        controller: _lineCtrls[i][1],
                        hint: 'Qty',
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (v) =>
                            setState(() => _lines[i].quantity = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CrmTextInput.rupees(
                        controller: _lineCtrls[i][2],
                        hint: 'Rate',
                        onChanged: (v) => setState(() => _lines[i].rate = v),
                      ),
                    ),
                    if (withGst) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 92,
                        child: CrmDropdown(
                          value: _lines[i].gstRate,
                          options: {
                            for (final r in CrmOptions.gstRates) '$r': '$r%',
                          },
                          onChanged: (v) =>
                              setState(() => _lines[i].gstRate = v),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    CrmFormat.rupees(
                      i < t.lineAmounts.length ? t.lineAmounts[i] : 0,
                      decimals: true,
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: () =>
              setState(() => _addLine(CrmLine(gstRate: '$_defaultGst'))),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add item'),
        ),
        CrmField(
          label: 'Discount',
          child: CrmTextInput.rupees(
            controller: _discount,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: crmCardDecoration(),
          child: Column(
            children: [
              _totalRow(
                'Subtotal',
                CrmFormat.rupees(t.subtotal, decimals: true),
              ),
              if (t.discount > 0)
                _totalRow(
                  'Discount',
                  '− ${CrmFormat.rupees(t.discount, decimals: true)}',
                ),
              if (_taxMode == 'intra') ...[
                _totalRow('CGST', CrmFormat.rupees(t.cgst, decimals: true)),
                _totalRow('SGST', CrmFormat.rupees(t.sgst, decimals: true)),
              ],
              if (_taxMode == 'inter')
                _totalRow('IGST', CrmFormat.rupees(t.igst, decimals: true)),
              const Divider(),
              _totalRow(
                'Total',
                CrmFormat.rupees(t.total, decimals: true),
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: bold
                  ? style
                  : style.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(value, style: style),
        ],
      ),
    );
  }
}
