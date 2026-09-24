import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/plan_feature_guard.dart';

/// CRM → Business details: what is printed on quotations, invoices and
/// receipts. Same fields, validation and save as the web (CrmPage.jsx):
/// business, payment details, GST, reminders and document numbering.
class CrmBusinessDetailsScreen extends ConsumerStatefulWidget {
  const CrmBusinessDetailsScreen({super.key});

  @override
  ConsumerState<CrmBusinessDetailsScreen> createState() =>
      _CrmBusinessDetailsScreenState();
}

class _CrmBusinessDetailsScreenState
    extends ConsumerState<CrmBusinessDetailsScreen> {
  final _api = CrmApi();

  /// Text fields, keyed by the profile field the server uses.
  static const _textKeys = [
    'legalName',
    'gstin',
    'pan',
    'address',
    'city',
    'pincode',
    'phone',
    'email',
    'invoicePrefix',
    'quotationPrefix',
    'receiptPrefix',
    'defaultSac',
    'bankDetails',
    'upiId',
    'terms',
  ];

  final Map<String, TextEditingController> _c = {
    for (final k in _textKeys) k: TextEditingController(),
  };

  String _state = '';
  String _defaultGstRate = '18';
  String _reminderDaysBefore = '0';
  bool _autoReminders = true;
  bool _dailyDigest = true;
  String? _logoUrl;

  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await _api.profile();
      final p = (res['profile'] as Map?) ?? const {};
      String str(String k) => p[k] == null ? '' : '${p[k]}';
      for (final k in _textKeys) {
        _c[k]!.text = str(k);
      }
      final savedState = str('state').trim();
      _state = CrmOptions.states.firstWhere(
        (s) => s.toLowerCase() == savedState.toLowerCase(),
        orElse: () => savedState,
      );
      _defaultGstRate = '${num.tryParse(str('defaultGstRate'))?.toInt() ?? 18}';
      _reminderDaysBefore = str('reminderDaysBefore').isEmpty
          ? '0'
          : str('reminderDaysBefore');
      _autoReminders = p['autoReminders'] != false;
      _dailyDigest = p['dailyDigest'] != false;
      _logoUrl = p['logoUrl']?.toString();
    } on PlanModuleLockedException catch (e) {
      if (mounted) {
        showPlanModuleLocked(
          context,
          ref,
          module: e.module.isEmpty ? 'crm' : e.module,
          message: e.message,
        );
      }
      return;
    } on CrmException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load your business details.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final gstin = _c['gstin']!.text.trim().toUpperCase();
    final code = CrmOptions.gstStateCodes[_state];
    String? problem;
    if (gstin.isNotEmpty && !CrmOptions.gstinPattern.hasMatch(gstin)) {
      problem =
          "GSTIN doesn't look right. It has 15 characters, like 27ABCDE1234F1Z5.";
    } else if (gstin.isNotEmpty && _state.isEmpty) {
      problem =
          'Select your state. It decides whether invoices charge CGST + SGST or IGST.';
    } else if (gstin.isNotEmpty && code != null && !gstin.startsWith(code)) {
      problem =
          'A $_state GSTIN starts with $code. Check the GSTIN or the state.';
    }
    if (problem != null) return setState(() => _error = problem);

    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final res = await _api.saveProfile({
        for (final k in _textKeys) k: _c[k]!.text,
        'gstin': gstin,
        'state': _state,
        'defaultGstRate': num.parse(_defaultGstRate),
        'reminderDaysBefore': num.parse(_reminderDaysBefore),
        'autoReminders': _autoReminders,
        'dailyDigest': _dailyDigest,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${res['message'] ?? 'Business details saved.'}'),
        ),
      );
      Navigator.pop(context);
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
      if (mounted) setState(() => _error = 'Could not save.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickLogo() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final lower = picked.path.toLowerCase();
    if (!(lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg'))) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Use a PNG or JPG logo.')),
      );
      return;
    }
    final file = File(picked.path);
    if (await file.length() > 3 * 1024 * 1024) {
      messenger.showSnackBar(
        const SnackBar(content: Text('The logo must be under 3 MB.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final res = await _api.uploadLogo(file);
      if (!mounted) return;
      setState(() => _logoUrl = res['logoUrl']?.toString());
      messenger.showSnackBar(const SnackBar(content: Text('Logo updated.')));
    } on CrmException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not upload the logo.')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Business details'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              children: [
                const Text(
                  'Printed on your quotations, invoices and receipts.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                _card('Business', [
                  _logoRow(),
                  _field(
                    'Business name (as registered)',
                    _text('legalName', maxLength: 200),
                  ),
                  _field('Address', _text('address', maxLength: 500, lines: 2)),
                  _field('City', _text('city', maxLength: 100)),
                  _field(
                    'State',
                    _dropdown(_state, {
                      '': 'Select',
                      if (_state.isNotEmpty &&
                          !CrmOptions.states.contains(_state))
                        _state: _state,
                      for (final s in CrmOptions.states) s: s,
                    }, (v) => setState(() => _state = v)),
                  ),
                  _field(
                    'PIN code',
                    _text(
                      'pincode',
                      maxLength: 10,
                      keyboard: TextInputType.number,
                    ),
                  ),
                  _field(
                    'Phone',
                    _text(
                      'phone',
                      maxLength: 20,
                      keyboard: TextInputType.phone,
                    ),
                  ),
                  _field(
                    'Email',
                    _text(
                      'email',
                      maxLength: 150,
                      keyboard: TextInputType.emailAddress,
                    ),
                    hint: 'Client replies to your emails go here.',
                  ),
                ]),
                _card('Payment details', [
                  _field(
                    'Bank details',
                    _text(
                      'bankDetails',
                      maxLength: 1000,
                      lines: 3,
                      hint: 'Bank name\nAccount number\nIFSC',
                    ),
                  ),
                  _field(
                    'UPI ID',
                    _text('upiId', maxLength: 80, hint: 'name@bank'),
                  ),
                  _field(
                    'Default terms & conditions',
                    _text(
                      'terms',
                      maxLength: 4000,
                      lines: 4,
                      hint:
                          'e.g. 50% advance to confirm the booking. Balance before the event.',
                    ),
                  ),
                ]),
                _card('GST', [
                  _field(
                    'GSTIN',
                    _text(
                      'gstin',
                      maxLength: 15,
                      hint: 'Leave empty if not registered',
                      caps: true,
                    ),
                    hint:
                        'With a GSTIN, invoices are tax invoices with CGST + SGST '
                        '(client in your state) or IGST (other states). Without one, '
                        'no GST is charged.',
                  ),
                  _field('PAN', _text('pan', maxLength: 10, caps: true)),
                  _field(
                    'Default GST rate',
                    _dropdown(_defaultGstRate, {
                      for (final r in CrmOptions.gstRates) '$r': '$r%',
                    }, (v) => setState(() => _defaultGstRate = v)),
                  ),
                  _field(
                    'SAC code (optional)',
                    _text('defaultSac', maxLength: 8, hint: 'e.g. 998387'),
                  ),
                ]),
                _card('Reminders', [
                  _check(
                    'Email clients automatic payment reminders',
                    _autoReminders,
                    (v) => setState(() => _autoReminders = v),
                    'Sent at 9 am to clients with a pending balance and a due date: before '
                        'it, on the day, and 3 and 10 days after if still unpaid. They include '
                        'your bank and UPI details. You can turn them off for a single client.',
                  ),
                  if (_autoReminders)
                    _field(
                      'First reminder',
                      _dropdown(
                        _reminderDaysBefore,
                        const {
                          '0': 'Only on the due date',
                          '1': '1 day before',
                          '2': '2 days before',
                          '3': '3 days before',
                          '5': '5 days before',
                          '7': '7 days before',
                        },
                        (v) => setState(() => _reminderDaysBefore = v),
                      ),
                    ),
                  _check(
                    'Email me a daily summary',
                    _dailyDigest,
                    (v) => setState(() => _dailyDigest = v),
                    "Each morning when there's something to do: follow-ups due, payments "
                        'due or overdue, and events in the next 3 days.',
                  ),
                ]),
                _card('Numbering', [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Numbers run in order each financial year, e.g. '
                      '${_c['invoicePrefix']!.text.isEmpty ? 'INV' : _c['invoicePrefix']!.text}'
                      '/26-27/001. Up to 5 letters or numbers.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          'Invoice',
                          _text('invoicePrefix', maxLength: 5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          'Quotation',
                          _text('quotationPrefix', maxLength: 5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _field(
                          'Receipt',
                          _text('receiptPrefix', maxLength: 5),
                        ),
                      ),
                    ],
                  ),
                ]),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warningTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(_error!),
                  ),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(_saving ? 'Saving…' : 'Save'),
                ),
              ],
            ),
    );
  }

  Widget _logoRow() {
    final url = CrmApi.imageUrl(_logoUrl);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 64,
              height: 64,
              child: url == null
                  ? Container(
                      color: AppColors.inputFill,
                      child: const Icon(
                        Icons.image_outlined,
                        color: AppColors.textTertiary,
                      ),
                    )
                  : AppNetworkImage(url: url, width: 64, height: 64),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: _uploading ? null : _pickLogo,
                  child: Text(
                    _uploading
                        ? 'Uploading…'
                        : url == null
                        ? 'Upload logo'
                        : 'Change logo',
                  ),
                ),
                const Text(
                  'PNG or JPG, up to 3 MB. A square logo looks best.',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

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

  InputDecoration _decoration({String? hint}) => InputDecoration(
    hintText: hint,
    isDense: true,
    counterText: '',
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
    String key, {
    String? hint,
    int? maxLength,
    int lines = 1,
    TextInputType? keyboard,
    bool caps = false,
  }) {
    return TextField(
      controller: _c[key],
      maxLength: maxLength,
      minLines: lines,
      maxLines: lines == 1 ? 1 : lines + 3,
      keyboardType: lines > 1 ? TextInputType.multiline : keyboard,
      textCapitalization: caps
          ? TextCapitalization.characters
          : TextCapitalization.none,
      onChanged: key == 'invoicePrefix' ? (_) => setState(() {}) : null,
      decoration: _decoration(hint: hint),
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

  Widget _check(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    String hint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            title: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(
            hint,
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
