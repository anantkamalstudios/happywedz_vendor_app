import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/plan_feature_guard.dart';
import 'crm_widgets.dart';

/// CRM → Record payment, as on the web: amount (with the balance before and
/// after), date, method, reference, optional invoice, advance flag and note.
/// Pops with the server's message on success.
class CrmPaymentFormScreen extends ConsumerStatefulWidget {
  final Map client;
  final Map money;

  /// Invoices that are not cancelled.
  final List invoices;
  final dynamic defaultInvoiceId;

  const CrmPaymentFormScreen({
    super.key,
    required this.client,
    required this.money,
    required this.invoices,
    this.defaultInvoiceId,
  });

  @override
  ConsumerState<CrmPaymentFormScreen> createState() =>
      _CrmPaymentFormScreenState();
}

class _CrmPaymentFormScreenState extends ConsumerState<CrmPaymentFormScreen> {
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _note = TextEditingController();
  String _paidOn = CrmFormat.today();
  String _method = 'upi';
  String _invoiceId = '';
  bool _isAdvance = false;
  bool _saving = false;
  String? _error;

  int get _balance => ((widget.money['balancePaise'] as num?) ?? 0).toInt();

  @override
  void initState() {
    super.initState();
    final received = ((widget.money['receivedPaise'] as num?) ?? 0).toInt();
    final def = widget.defaultInvoiceId;
    if (def != null) {
      _invoiceId = '$def';
      final inv = widget.invoices
          .where((i) => '${i['id']}' == '$def')
          .firstOrNull;
      if (inv != null) {
        final due =
            ((inv['totalPaise'] as num?) ?? 0) -
            ((inv['paidPaise'] as num?) ?? 0);
        _amount.text = CrmFormat.paiseToInput(due < 0 ? 0 : due);
      }
    }
    // The first payment for a client is usually the booking advance.
    _isAdvance = received == 0 && def == null;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = CrmFormat.toPaise(_amount.text);
    if (amount == null || amount == 0) {
      return setState(() => _error = 'Enter the amount received.');
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final res = await CrmApi().createPayment(widget.client['id'], {
        'amountPaise': amount,
        'paidOn': _paidOn,
        'method': _method,
        'reference': _reference.text,
        'invoiceId': _invoiceId.isEmpty ? null : int.tryParse(_invoiceId),
        'isAdvance': _isAdvance,
        'note': _note.text,
      });
      if (mounted) {
        Navigator.pop(context, '${res['message'] ?? 'Payment recorded.'}');
      }
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
      if (mounted) setState(() => _error = 'Could not record the payment.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entered = CrmFormat.toPaise(_amount.text) ?? 0;
    final after = _balance - entered;
    final finalPaise = ((widget.money['finalPaise'] as num?) ?? 0).toInt();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CommonAppBar(
        title: 'Record payment · ${widget.client['name'] ?? ''}',
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          CrmField(
            label: 'Amount received *',
            hint: finalPaise > 0
                ? '${_balance > 0 ? 'Balance now ${CrmFormat.rupees(_balance)}' : 'Nothing pending'}'
                      '${entered > 0 ? ' → ${after >= 0 ? CrmFormat.rupees(after) : '${CrmFormat.rupees(-after)} extra'} after this' : ''}'
                : null,
            child: CrmTextInput.rupees(
              controller: _amount,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
          ),
          CrmField(
            label: 'Date received',
            child: CrmDateInput(
              value: _paidOn,
              clearable: false,
              lastDate: DateTime.now(),
              onChanged: (d) => setState(() => _paidOn = d),
            ),
          ),
          CrmField(
            label: 'Method',
            child: CrmDropdown(
              value: _method,
              options: CrmOptions.paymentMethods,
              onChanged: (v) => setState(() => _method = v),
            ),
          ),
          CrmField(
            label: 'Reference',
            child: CrmTextInput(
              controller: _reference,
              hint: 'UTR, cheque no…',
              maxLength: 80,
            ),
          ),
          if (widget.invoices.isNotEmpty)
            CrmField(
              label: 'Against invoice',
              child: CrmDropdown(
                value: _invoiceId,
                options: {
                  '': 'Not linked to an invoice',
                  for (final i in widget.invoices)
                    '${i['id']}':
                        '${i['number']} · ${CrmFormat.rupees(i['totalPaise'])}'
                        '${((i['paidPaise'] as num?) ?? 0) > 0 ? ' (received ${CrmFormat.rupees(i['paidPaise'])})' : ''}',
                },
                onChanged: (v) => setState(() => _invoiceId = v),
              ),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _isAdvance,
            onChanged: (v) => setState(() => _isAdvance = v ?? false),
            title: const Text(
              'This is an advance (booking amount)',
              style: TextStyle(fontSize: 14),
            ),
          ),
          CrmField(
            label: 'Note',
            child: CrmTextInput(
              controller: _note,
              hint: 'Printed on the receipt',
              maxLength: 1000,
            ),
          ),
          if (_error != null) CrmNotice(_error!),
          const SizedBox(height: 4),
          CrmFormButtons(
            primaryLabel: 'Save payment',
            onPrimary: _save,
            busy: _saving,
          ),
        ],
      ),
    );
  }
}
