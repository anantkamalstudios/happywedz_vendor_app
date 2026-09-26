import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/common_app_bar.dart';
import '../../utils/plan_module_lock.dart';
import '../../widgets/app_network_image.dart';
import '../../widgets/plan_feature_guard.dart';
import '../../widgets/whatsapp_icon.dart';
import 'crm_business_details_screen.dart';
import 'crm_client_form_screen.dart';
import 'crm_document_editor_screen.dart';
import 'crm_payment_form_screen.dart';
import 'crm_pdf_screen.dart';
import 'crm_widgets.dart';

/// CRM → client details, mirroring the web (CrmPage.jsx `Aa`): header with
/// contact, owner and actions; money summary with reminders; follow-up;
/// Overview / Quotations / Invoices / Payments tabs. Every action calls the
/// same `/vendor/crm/*` endpoint as the website.
///
/// Pops with `true` when something changed, so the client list refreshes.
class CrmClientDetailScreen extends ConsumerStatefulWidget {
  final dynamic clientId;

  const CrmClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<CrmClientDetailScreen> createState() =>
      _CrmClientDetailScreenState();
}

class _CrmClientDetailScreenState extends ConsumerState<CrmClientDetailScreen>
    with SingleTickerProviderStateMixin {
  final _api = CrmApi();
  late final TabController _tabs = TabController(length: 4, vsync: this)
    ..addListener(() {
      if (!_tabs.indexIsChanging) setState(() {});
    });

  Map<String, dynamic>? _data;
  String? _error;
  List _owners = [];
  bool _changingOwner = false;
  bool _uploading = false;
  bool _changed = false;

  // WhatsApp: with a connected number the server sends templates; otherwise
  // the buttons open a wa.me chat. [_waSending] is `type:id` while sending.
  bool _waConnected = false;
  String? _waSending;

  // Follow-up editor.
  bool _editingFollowUp = false;
  bool _savingFollowUp = false;
  String _followUpDate = '';
  final _followUpNote = TextEditingController();

  // Notes.
  final _note = TextEditingController();
  bool _savingNote = false;
  bool _showAllActivity = false;

  @override
  void initState() {
    super.initState();
    _load();
    _api
        .owners()
        .then((r) {
          if (mounted) {
            setState(() => _owners = List.from(r['owners'] ?? const []));
          }
        })
        .catchError((_) {});
    _api
        .whatsapp()
        .then((r) {
          if (mounted) {
            setState(
              () =>
                  _waConnected = (r['whatsapp'] as Map?)?['connected'] == true,
            );
          }
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    _followUpNote.dispose();
    _note.dispose();
    super.dispose();
  }

  // ==========================================================================
  // Data
  // ==========================================================================

  Map get _client => (_data?['client'] as Map?) ?? const {};
  List get _events => List.from(_data?['events'] ?? const []);
  List get _quotations => List.from(_data?['quotations'] ?? const []);
  List get _invoices => List.from(_data?['invoices'] ?? const []);
  List get _payments => List.from(_data?['payments'] ?? const []);
  List get _files => List.from(_data?['files'] ?? const []);
  List get _activity => List.from(_data?['activity'] ?? const []);
  Map get _money => (_data?['money'] as Map?) ?? const {};
  Map? get _profile => _data?['profile'] as Map?;
  Map? get _due => _data?['due'] as Map?;
  String get _seller {
    final n = '${_profile?['legalName'] ?? ''}';
    return n.isEmpty ? 'us' : n;
  }

  int _n(Map m, String k) => ((m[k] as num?) ?? 0).toInt();

  Future<void> _load() async {
    try {
      final data = await _api.client(widget.clientId);
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
      });
    } catch (e) {
      _handleError(
        e,
        'Could not load this client.',
        asPageError: _data == null,
      );
    }
  }

  void _handleError(Object e, String fallback, {bool asPageError = false}) {
    if (!mounted) return;
    if (e is PlanModuleLockedException) {
      showPlanModuleLocked(
        context,
        ref,
        module: e.module.isEmpty ? 'crm' : e.module,
        message: e.message,
      );
      return;
    }
    final message = e is CrmException ? e.message : fallback;
    if (asPageError) {
      setState(() => _error = message);
    } else {
      _toast(message);
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  /// Runs an action, shows the server's message, reloads. True on success.
  Future<bool> _run(
    Future<Map<String, dynamic>> Function() action,
    String fallback,
  ) async {
    try {
      final res = await action();
      _changed = true;
      if (res['message'] != null) _toast('${res['message']}');
      await _load();
      return true;
    } catch (e) {
      _handleError(e, fallback);
      return false;
    }
  }

  /// After a pushed form returns a message: show it and reload.
  Future<void> _afterForm(Object? result, {int? tab}) async {
    if (result == null || !mounted) return;
    _changed = true;
    if (result is String && result.isNotEmpty) _toast(result);
    if (tab != null) _tabs.animateTo(tab);
    await _load();
  }

  // ==========================================================================
  // Actions
  // ==========================================================================

  Future<void> _open(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _toast(
        'Could not open ${uri.scheme == 'https' ? 'WhatsApp' : 'the app'}.',
      );
    }
  }

  Future<void> _whatsapp(String text, {Future<void> Function()? before}) async {
    try {
      if (before != null) await before();
      await _open(CrmShare.whatsapp(_client['phone']?.toString(), text));
    } catch (e) {
      _handleError(e, 'Could not prepare the message.');
    }
  }

  bool _isWaSending(CrmDocType type, Map doc) =>
      _waSending == '${type.name}:${doc['id']}';

  /// Sends [doc] on WhatsApp like the web: as a template from the connected
  /// number, or — when none is connected — by opening a chat with [text].
  /// [before] only runs for the chat fallback.
  Future<void> _sendOnWhatsapp(
    CrmDocType type,
    Map doc,
    String text, {
    Future<void> Function()? before,
  }) async {
    if (!_waConnected) return _whatsapp(text, before: before);
    setState(() => _waSending = '${type.name}:${doc['id']}');
    try {
      final res = await _api.sendOnWhatsapp(type, doc['id']);
      _changed = true;
      _toast('${res['message'] ?? 'Sent on WhatsApp.'}');
      await _load();
    } catch (e) {
      _handleError(e, 'Could not send it on WhatsApp.');
    } finally {
      if (mounted) setState(() => _waSending = null);
    }
  }

  Future<void> _push(Widget screen, {int? tab}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    await _afterForm(result, tab: tab);
  }

  Future<void> _editAndToast() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrmClientFormScreen(client: _client, events: _events),
      ),
    );
    if (result != null) await _afterForm('Client saved.');
  }

  void _newQuotation([Map? quotation]) => _push(
    CrmDocumentEditorScreen.quotation(
      client: _client,
      events: _events,
      profile: _profile,
      quotation: quotation,
    ),
    tab: 1,
  );

  void _newInvoice([dynamic quotationId]) => _push(
    CrmDocumentEditorScreen.invoice(
      client: _client,
      events: _events,
      profile: _profile,
      quotations: _quotations,
      defaultQuotationId: quotationId,
    ),
    tab: 2,
  );

  void _recordPayment([dynamic invoiceId]) => _push(
    CrmPaymentFormScreen(
      client: _client,
      money: _money,
      invoices: _invoices.where((i) => i['status'] != 'cancelled').toList(),
      defaultInvoiceId: invoiceId,
    ),
    tab: 3,
  );

  void _pdf(String title, String path) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CrmPdfScreen(title: title, path: path),
    ),
  );

  Future<void> _setOwner(String? ownerId) async {
    setState(() => _changingOwner = true);
    await _run(
      () => _api.setClientOwner(
        _client['id'],
        ownerId == null ? null : int.tryParse(ownerId),
      ),
      'Could not change who this client belongs to.',
    );
    if (mounted) setState(() => _changingOwner = false);
  }

  Future<void> _uploadFiles() async {
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'pdf'],
    );
    final paths =
        picked?.files.map((f) => f.path).whereType<String>().toList() ?? [];
    if (paths.isEmpty) return;
    for (final f in picked!.files) {
      if (f.size > 10 * 1024 * 1024) {
        return _toast('${f.name} is larger than 10 MB.');
      }
    }
    setState(() => _uploading = true);
    try {
      await _api.uploadFiles(
        _client['id'],
        paths.take(10).map(File.new).toList(),
      );
      _changed = true;
      _toast(paths.length > 10 ? 'Uploaded the first 10 files.' : 'Uploaded.');
      await _load();
    } catch (e) {
      _handleError(e, 'Upload failed.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveFollowUp(Map<String, dynamic> body, String message) async {
    setState(() => _savingFollowUp = true);
    try {
      await _api.updateClient(_client['id'], body);
      _changed = true;
      _toast(message);
      setState(() => _editingFollowUp = false);
      await _load();
    } catch (e) {
      _handleError(e, 'Could not save the follow-up.');
    } finally {
      if (mounted) setState(() => _savingFollowUp = false);
    }
  }

  Future<void> _addNote() async {
    if (_note.text.trim().isEmpty) return;
    setState(() => _savingNote = true);
    try {
      await _api.addNote(_client['id'], _note.text);
      _note.clear();
      await _load();
    } catch (e) {
      _handleError(e, 'Could not save the note.');
    } finally {
      if (mounted) setState(() => _savingNote = false);
    }
  }

  Future<void> _sendQuotation(Map q) async {
    final email = TextEditingController(text: '${_client['email'] ?? ''}');
    var sendEmail = email.text.isNotEmpty;
    var busy = false;
    String? link;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) => AlertDialog(
          title: Text('Send quotation ${q['number']}'),
          content: SingleChildScrollView(
            child: link != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share this link with your client, for example on WhatsApp:',
                      ),
                      const SizedBox(height: 10),
                      SelectableText(
                        link!,
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: link!),
                              );
                              _toast('Link copied.');
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('Copy'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _whatsapp(
                              CrmShare.quotation(_client, _seller, q),
                            ),
                            icon: const WhatsAppIcon(),
                            label: const Text('Share on WhatsApp'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your client gets a link where they can view the quotation, download "
                        "the PDF and accept it. You'll get an email when they answer.",
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: sendEmail,
                        onChanged: (v) =>
                            setDialog(() => sendEmail = v ?? false),
                        title: const Text(
                          'Email it with the PDF attached',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      if (sendEmail)
                        CrmField(
                          label: 'Client email',
                          child: CrmTextInput(
                            controller: email,
                            keyboard: TextInputType.emailAddress,
                            onChanged: (_) => setDialog(() {}),
                          ),
                        ),
                    ],
                  ),
          ),
          actions: link != null
              ? [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Done'),
                  ),
                ]
              : [
                  TextButton(
                    onPressed: busy ? null : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: busy || (sendEmail && email.text.trim().isEmpty)
                        ? null
                        : () async {
                            setDialog(() => busy = true);
                            try {
                              final res = await _api.sendQuotation(q['id'], {
                                if (email.text.trim().isNotEmpty)
                                  'email': email.text.trim(),
                                'sendEmail':
                                    sendEmail && email.text.trim().isNotEmpty,
                              });
                              _changed = true;
                              if (res['message'] != null) {
                                _toast('${res['message']}');
                              }
                              setDialog(() {
                                link =
                                    '${res['link'] ?? CrmShare.quotationLink(q['publicToken'])}';
                                busy = false;
                              });
                              _load();
                            } catch (e) {
                              setDialog(() => busy = false);
                              _handleError(e, 'Could not send the quotation.');
                            }
                          },
                    child: Text(
                      busy
                          ? 'Sending…'
                          : sendEmail
                          ? 'Send'
                          : 'Get link',
                    ),
                  ),
                ],
        ),
      ),
    );
    email.dispose();
  }

  void _confirmDeleteClient() {
    final hasRecords = _invoices.isNotEmpty || _payments.isNotEmpty;
    showCrmConfirm(
      context,
      title: 'Delete ${_client['name']}?',
      text: hasRecords
          ? 'This client has invoices or payments, which must be kept for your accounts. '
                'Set the status to Cancelled or Lost instead.'
          : "The client, their events, quotations and files will be deleted. This can't be undone.",
      confirmLabel: 'Delete client',
      danger: true,
      onConfirm: (_) async {
        try {
          await _api.deleteClient(_client['id']);
          if (!mounted) return true;
          _toast('Client deleted.');
          Navigator.pop(context, true);
          return true;
        } catch (e) {
          _handleError(e, 'Could not delete the client.');
          return false;
        }
      },
    );
  }

  // ==========================================================================
  // UI
  // ==========================================================================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: CommonAppBar(
          title: _data == null ? 'Client' : '${_client['name'] ?? 'Client'}',
          onBack: () => Navigator.pop(context, _changed),
        ),
        body: _data == null
            ? (_error != null
                  ? _errorView()
                  : const Center(child: CircularProgressIndicator()))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    14,
                    14,
                    14,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    _header(),
                    const SizedBox(height: 12),
                    _actions(),
                    const SizedBox(height: 14),
                    _moneyCard(),
                    const SizedBox(height: 12),
                    _followUp(),
                    const SizedBox(height: 4),
                    _tabBar(),
                    const SizedBox(height: 12),
                    ...switch (_tabs.index) {
                      0 => _overview(),
                      1 => _quotationsTab(),
                      2 => _invoicesTab(),
                      _ => _paymentsTab(),
                    },
                  ],
                ),
              ),
      ),
    );
  }

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              setState(() => _error = null);
              _load();
            },
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  // ---------------------------------------------------------------- header

  Widget _header() {
    final c = _client;
    final place = [
      c['location'],
      c['state'],
    ].where((x) => x != null && '$x'.isNotEmpty).join(', ');
    final owner = _data?['owner'] as Map?;

    Widget meta(IconData icon, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Expanded(child: child),
        ],
      ),
    );

    Widget link(String text, Uri uri) => GestureDetector(
      onTap: () => _open(uri),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${c['name'] ?? ''}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            CrmBadge(
              status: '${c['status']}',
              label: CrmOptions.statuses[c['status']] ?? '${c['status']}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        if ('${c['phone'] ?? ''}'.isNotEmpty)
          meta(
            Icons.phone_outlined,
            link('${c['phone']}', Uri(scheme: 'tel', path: '${c['phone']}')),
          ),
        if ('${c['email'] ?? ''}'.isNotEmpty)
          meta(
            Icons.mail_outline,
            link('${c['email']}', Uri(scheme: 'mailto', path: '${c['email']}')),
          ),
        if (place.isNotEmpty) meta(Icons.place_outlined, Text(place)),
        meta(
          Icons.campaign_outlined,
          Text(
            'Source: ${CrmOptions.leadSources[c['leadSource']] ?? c['leadSource'] ?? '—'}',
          ),
        ),
        if (_owners.isNotEmpty)
          meta(
            Icons.person_outline,
            DropdownButton<String>(
              value: c['ownerId'] == null ? '' : '${c['ownerId']}',
              isDense: true,
              isExpanded: true,
              underline: const SizedBox(),
              onChanged: _changingOwner
                  ? null
                  : (v) => _setOwner(v == null || v.isEmpty ? null : v),
              items: [
                const DropdownMenuItem(value: '', child: Text('Unassigned')),
                for (final o in _owners)
                  DropdownMenuItem(
                    value: '${o['id']}',
                    child: Text(
                      o['isMe'] == true ? '${o['name']} (me)' : '${o['name']}',
                    ),
                  ),
              ],
            ),
          )
        else if (owner != null)
          meta(Icons.person_outline, Text('${owner['name'] ?? ''}')),
      ],
    );
  }

  Widget _actions() {
    final hasPhone = '${_client['phone'] ?? ''}'.isNotEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasPhone)
          OutlinedButton.icon(
            onPressed: () => _open(CrmShare.whatsapp('${_client['phone']}')),
            icon: const WhatsAppIcon(),
            label: const Text(
              'WhatsApp',
              style: TextStyle(color: WhatsAppIcon.green),
            ),
          ),
        OutlinedButton.icon(
          onPressed: _editAndToast,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Edit'),
        ),
        OutlinedButton.icon(
          onPressed: () => _newQuotation(),
          icon: const Icon(Icons.description_outlined, size: 16),
          label: const Text('New quotation'),
        ),
        ElevatedButton.icon(
          onPressed: () => _recordPayment(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Record payment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- money

  Widget _moneyCard() {
    final m = _money;
    final finalSource = const {
      'invoice': 'from invoices',
      'quotation': 'accepted quotation',
      'events': 'sum of event prices',
    }[m['finalSource']];
    final balance = _n(m, 'balancePaise');
    final pending = m['isPending'] == true;
    final due = _due;

    String balanceNote;
    if (pending) {
      balanceNote = due != null
          ? '${'${due['date']}'.compareTo(CrmFormat.today()) < 0 ? 'Overdue since' : 'Due'} ${CrmFormat.date(due['date'])}'
          : 'Payment pending';
    } else {
      balanceNote = _n(m, 'finalPaise') > 0 ? 'Fully paid' : 'No amount yet';
    }

    Widget cell(String label, String value, String? note, {Color? color}) =>
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (note != null && note.isNotEmpty)
                Text(
                  note,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        );

    final client = _client;
    final lastReminder = _data?['lastReminder'] as Map?;
    final reminderText = lastReminder != null
        ? 'Last reminder emailed ${CrmFormat.date(lastReminder['createdAt'])}.'
        : _profile?['autoReminders'] == true &&
              client['remindersEnabled'] != false &&
              '${client['email'] ?? ''}'.isNotEmpty &&
              due != null
        ? 'Automatic email reminders are on for this client.'
        : 'Remind the client about the pending balance.';

    return Container(
      decoration: crmCardDecoration(),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: cell(
                    'Final amount',
                    CrmFormat.rupees(m['finalPaise']),
                    finalSource,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: cell(
                    'Advance received',
                    CrmFormat.rupees(m['advancePaise']),
                    null,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: cell(
                    'Total received',
                    CrmFormat.rupees(m['receivedPaise']),
                    '${_payments.length} payment${_payments.length == 1 ? '' : 's'}',
                    color: AppColors.success,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: cell(
                    'Net balance',
                    balance < 0
                        ? '${CrmFormat.rupees(-balance)} extra'
                        : CrmFormat.rupees(balance),
                    balanceNote,
                    color: pending
                        ? AppColors.warning
                        : _n(m, 'finalPaise') > 0
                        ? AppColors.success
                        : null,
                  ),
                ),
              ],
            ),
          ),
          if (pending) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminderText,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: '${client['email'] ?? ''}'.isEmpty
                            ? () => _toast(
                                "Add the client's email to send email reminders",
                              )
                            : () => showCrmConfirm(
                                context,
                                title: 'Email a payment reminder?',
                                text:
                                    '${client['email']} will get a reminder for ${CrmFormat.rupees(balance)}'
                                    '${due != null ? ' (due ${CrmFormat.date(due['date'])})' : ''}, with your bank and UPI details'
                                    '${due?['invoiceToken'] != null ? ' and a link to the invoice' : ''}.',
                                confirmLabel: 'Send reminder',
                                onConfirm: (_) => _run(
                                  () => _api.sendReminder(client['id']),
                                  'Could not send the reminder.',
                                ),
                              ),
                        icon: const Icon(Icons.mail_outline, size: 16),
                        label: const Text('Email reminder'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _whatsapp(
                          CrmShare.reminder(
                            client,
                            _seller,
                            due,
                            balance,
                            _profile?['upiId']?.toString(),
                          ),
                        ),
                        icon: const WhatsAppIcon(),
                        label: const Text(
                          'WhatsApp reminder',
                          style: TextStyle(color: WhatsAppIcon.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------- follow-up

  Widget _followUp() {
    final c = _client;
    final date = '${c['followUpDate'] ?? ''}';
    final note = '${c['followUpNote'] ?? ''}';

    void startEditing() => setState(() {
      _followUpDate = date.isNotEmpty ? date : CrmFormat.inDays(1);
      _followUpNote.text = note;
      _editingFollowUp = true;
    });

    if (_editingFollowUp) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: crmCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Next follow-up',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            CrmField(
              label: 'Date',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CrmDateInput(
                    value: _followUpDate,
                    clearable: false,
                    firstDate: DateTime.now(),
                    onChanged: (d) => setState(() => _followUpDate = d),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final q in const [
                        ('Tomorrow', 1),
                        ('In 3 days', 3),
                        ('Next week', 7),
                        ('In 2 weeks', 14),
                      ])
                        ActionChip(
                          label: Text(
                            q.$1,
                            style: const TextStyle(fontSize: 12),
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => setState(
                            () => _followUpDate = CrmFormat.inDays(q.$2),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            CrmField(
              label: 'What about?',
              child: CrmTextInput(
                controller: _followUpNote,
                hint: 'e.g. Confirm the Sangeet venue',
                maxLength: 300,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _savingFollowUp
                      ? null
                      : () => setState(() => _editingFollowUp = false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _savingFollowUp || _followUpDate.isEmpty
                      ? null
                      : () => _saveFollowUp(
                          {
                            'followUpDate': _followUpDate,
                            'followUpNote': _followUpNote.text.trim().isEmpty
                                ? null
                                : _followUpNote.text.trim(),
                          },
                          'Follow-up set for ${CrmFormat.date(_followUpDate)}.',
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_savingFollowUp ? 'Saving…' : 'Save'),
                ),
              ],
            ),
          ],
        ),
      );
    }

    if (date.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: startEditing,
          icon: const Icon(Icons.notifications_active_outlined, size: 16),
          label: const Text('Set a follow-up reminder'),
        ),
      );
    }

    final today = CrmFormat.today();
    final isDue = date.compareTo(today) <= 0;
    final headline = date == today
        ? 'Follow up today'
        : isDue
        ? 'Follow-up overdue since ${CrmFormat.date(date)}'
        : 'Follow up on ${CrmFormat.date(date)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: isDue ? AppColors.warningTint : AppColors.infoTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: isDue ? AppColors.warning : AppColors.info,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: headline,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (note.isNotEmpty) TextSpan(text: ' — $note'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _savingFollowUp ? null : startEditing,
                child: const Text('Change'),
              ),
              TextButton.icon(
                onPressed: _savingFollowUp
                    ? null
                    : () => _saveFollowUp({
                        'followUpDate': null,
                        'followUpNote': null,
                      }, 'Follow-up done.'),
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Done'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ tabs

  Widget _tabBar() {
    final counts = [0, _quotations.length, _invoices.length, _payments.length];
    const labels = ['Overview', 'Quotations', 'Invoices', 'Payments'];
    return TabBar(
      controller: _tabs,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primary,
      tabs: [
        for (var i = 0; i < 4; i++)
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(labels[i]),
                if (counts[i] > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${counts[i]}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _card({
    required String title,
    Widget? action,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  // -------------------------------------------------------------- overview

  List<Widget> _overview() {
    final c = _client;
    String orDash(dynamic v) => v == null || '$v'.isEmpty ? '—' : '$v';

    return [
      _card(
        title: 'Events',
        action: OutlinedButton(
          onPressed: _editAndToast,
          child: const Text('Edit events'),
        ),
        children: _events.isEmpty
            ? [
                const Text(
                  'No events yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ]
            : [
                for (final e in _events)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${e['name'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${e['eventDate'] == null ? '—' : CrmFormat.date(e['eventDate'])}'
                                ' · ${orDash(e['venue'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CrmFormat.rupees(e['pricePaise']),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      CrmFormat.rupees(_money['eventsTotalPaise']),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
      ),
      _card(
        title: 'Details',
        children: [
          for (final row in [
            ('Description', orDash(c['description'])),
            ('Additional note', orDash(c['additionalNote'])),
            ('Additional information', orDash(c['additionalInfo'])),
            (
              'Balance due by',
              c['paymentDueDate'] == null
                  ? '—'
                  : CrmFormat.date(c['paymentDueDate']),
            ),
            ('Pending payment note', orDash(c['pendingNote'])),
            if (c['enquiryId'] != null)
              ('From enquiry', 'HappyWedz enquiry #${c['enquiryId']}'),
            ('Added', CrmFormat.date(c['createdAt'])),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.$1,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(row.$2),
                ],
              ),
            ),
        ],
      ),
      _card(
        title: 'Photos & documents',
        action: OutlinedButton.icon(
          onPressed: _uploading ? null : _uploadFiles,
          icon: const Icon(Icons.attach_file, size: 16),
          label: Text(_uploading ? 'Uploading…' : 'Upload'),
        ),
        children: [
          if (_files.isEmpty)
            const Text(
              'Keep photos, signed contracts and other documents for this client here. '
              'Images or PDF, up to 10 MB each.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final f in _files) _fileTile(f)],
            ),
        ],
      ),
      _notesCard(),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: _confirmDeleteClient,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          icon: const Icon(Icons.delete_outline, size: 16),
          label: const Text('Delete client'),
        ),
      ),
    ];
  }

  Widget _fileTile(Map f) {
    final url = CrmApi.imageUrl(f['url']?.toString());
    final isPhoto = f['kind'] == 'photo';
    final name = '${f['name'] ?? 'Document'}';
    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              onTap: url == null ? null : () => _open(Uri.parse(url)),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: isPhoto && url != null
                    ? AppNetworkImage(url: url, width: 104, height: 104)
                    : Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.description_outlined,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: () => showCrmConfirm(
                context,
                title: 'Remove this file?',
                text: f['name'] != null
                    ? name
                    : 'This file will be removed from the client.',
                confirmLabel: 'Remove',
                danger: true,
                onConfirm: (_) => _run(
                  () => _api.deleteFile(f['id']),
                  'Could not remove the file.',
                ),
              ),
              child: const CircleAvatar(
                radius: 11,
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _activityIcons = {
    'client': Icons.person_add_alt,
    'quotation': Icons.description_outlined,
    'accepted': Icons.check_circle_outline,
    'rejected': Icons.cancel_outlined,
    'invoice': Icons.receipt_long_outlined,
    'cancelled': Icons.cancel_outlined,
    'payment': Icons.currency_rupee,
    'reminder': Icons.notifications_outlined,
    'file': Icons.attach_file,
    'note': Icons.sticky_note_2_outlined,
  };

  Widget _notesCard() {
    const preview = 8;
    final all = _activity;
    final shown = _showAllActivity ? all : all.take(preview).toList();
    return _card(
      title: 'Notes & activity',
      children: [
        CrmTextInput(
          controller: _note,
          lines: 2,
          maxLength: 4000,
          hint: 'Add a note — a call, a meeting, what the client asked for…',
          onChanged: (_) => setState(() {}),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: ElevatedButton(
              onPressed: _savingNote || _note.text.trim().isEmpty
                  ? null
                  : _addNote,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(_savingNote ? 'Saving…' : 'Add note'),
            ),
          ),
        ),
        for (final a in shown)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.inputFill,
                  child: Icon(
                    _activityIcons[a['type']] ?? Icons.description_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${a['text'] ?? ''}'),
                      Text(
                        '${CrmFormat.dateTime(a['at'])}${a['by'] != null ? ' · ${a['by']}' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (a['type'] == 'note')
                  IconButton(
                    tooltip: 'Delete note',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error,
                    ),
                    onPressed: () => _run(
                      () => _api.deleteNote(a['noteId']),
                      'Could not delete the note.',
                    ),
                  ),
              ],
            ),
          ),
        if (all.length > preview)
          TextButton(
            onPressed: () =>
                setState(() => _showAllActivity = !_showAllActivity),
            child: Text(
              _showAllActivity ? 'Show less' : 'Show all ${all.length}',
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------ documents

  Widget _docRow({
    required String number,
    required Widget badge,
    Widget? chip,
    required String subtitle,
    required dynamic totalPaise,
    required List<Widget> actions,
    bool faded = false,
  }) {
    return Opacity(
      opacity: faded ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: crmCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        number,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      badge,
                      if (chip != null) chip,
                    ],
                  ),
                ),
                Text(
                  CrmFormat.rupees(totalPaise),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: actions),
          ],
        ),
      ),
    );
  }

  /// The quotation / invoice row's WhatsApp button (see [_sendOnWhatsapp]).
  Widget _whatsappButton(
    CrmDocType type,
    Map doc,
    String text, {
    Future<void> Function()? before,
  }) {
    final sending = _isWaSending(type, doc);
    return Tooltip(
      message: _waConnected ? 'Send on WhatsApp' : 'Share on WhatsApp',
      child: _smallButton(
        sending ? 'Sending…' : 'WhatsApp',
        sending ? null : () => _sendOnWhatsapp(type, doc, text, before: before),
        icon: const WhatsAppIcon(size: 15),
      ),
    );
  }

  Widget _smallButton(
    String label,
    VoidCallback? onPressed, {
    bool primary = false,
    bool danger = false,
    Widget? icon,
  }) {
    final color = danger
        ? AppColors.error
        : label == 'WhatsApp'
        ? WhatsAppIcon.green
        : null;
    final style =
        (primary
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  )
                : OutlinedButton.styleFrom(foregroundColor: color))
            .copyWith(
              visualDensity: VisualDensity.compact,
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            );
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 4),
              Text(label),
            ],
          );
    return primary
        ? ElevatedButton(onPressed: onPressed, style: style, child: child)
        : OutlinedButton(onPressed: onPressed, style: style, child: child);
  }

  Widget _tabIntro(
    String text,
    String buttonLabel,
    VoidCallback onPressed, {
    Widget? extra,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(color: AppColors.textSecondary)),
          if (extra != null) extra,
          const SizedBox(height: 8),
          _smallButton(buttonLabel, onPressed, primary: true, icon: const Icon(Icons.add, size: 15)),
        ],
      ),
    );
  }

  Widget _emptyTab(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Center(
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    ),
  );

  List<Widget> _quotationsTab() {
    return [
      _tabIntro(
        'Custom quotations for this client. Send them by email or link; the client can accept online.',
        'New quotation',
        () => _newQuotation(),
      ),
      if (_quotations.isEmpty) _emptyTab('No quotations yet.'),
      for (final q in _quotations) _quotationRow(q),
    ];
  }

  Widget _quotationRow(Map q) {
    final status = q['isExpired'] == true ? 'expired' : '${q['status']}';
    final items = List.from(q['items'] ?? const []).length;
    final accepted = q['status'] == 'accepted';
    return _docRow(
      number: '${q['number']}',
      badge: CrmBadge(
        status: status,
        label: CrmOptions.quotationStatuses[status] ?? status,
      ),
      subtitle:
          '${CrmFormat.date(q['issueDate'])}'
          '${q['validUntil'] != null ? ' · valid until ${CrmFormat.date(q['validUntil'])}' : ''}'
          ' · $items item${items == 1 ? '' : 's'}',
      totalPaise: q['totalPaise'],
      actions: [
        _smallButton(
          'PDF',
          () => _pdf('Quotation ${q['number']}', CrmApi.quotationPdf(q['id'])),
        ),
        _whatsappButton(
          CrmDocType.quotation,
          q,
          CrmShare.quotation(_client, _seller, q),
          // A draft or declined quotation is marked sent first, so its link works.
          before: q['status'] == 'draft' || q['status'] == 'rejected'
              ? () async {
                  await _api.sendQuotation(q['id'], {'sendEmail': false});
                  _changed = true;
                  _load();
                }
              : null,
        ),
        if (!accepted) _smallButton('Edit', () => _newQuotation(q)),
        if (!accepted)
          _smallButton(
            q['status'] == 'draft' ? 'Send' : 'Send again',
            () => _sendQuotation(q),
          ),
        if (q['status'] == 'sent')
          _smallButton(
            'Mark accepted',
            () => showCrmConfirm(
              context,
              title: 'Mark ${q['number']} as accepted?',
              text:
                  'Use this when the client agreed outside HappyWedz, for example on a call. '
                  'The client will be marked as booked.',
              confirmLabel: 'Mark accepted',
              onConfirm: (_) => _run(
                () => _api.setQuotationStatus(q['id'], 'accepted'),
                'Could not update the quotation.',
              ),
            ),
          ),
        if (accepted)
          _smallButton(
            'Create invoice',
            () => _newInvoice(q['id']),
            primary: true,
          ),
        if (!accepted)
          _smallButton(
            'Delete',
            () => showCrmConfirm(
              context,
              title: 'Delete ${q['number']}?',
              text: q['status'] == 'sent'
                  ? "The client's link will stop working."
                  : "This can't be undone.",
              confirmLabel: 'Delete',
              danger: true,
              onConfirm: (_) => _run(
                () => _api.deleteQuotation(q['id']),
                'Could not delete the quotation.',
              ),
            ),
            danger: true,
          ),
      ],
    );
  }

  List<Widget> _invoicesTab() {
    final gstin = '${_profile?['gstin'] ?? ''}';
    return [
      _tabIntro(
        gstin.isNotEmpty
            ? 'GST invoices from $gstin.'
            : 'Invoices without GST.',
        'New invoice',
        () => _newInvoice(),
        extra: TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CrmBusinessDetailsScreen()),
          ).then((_) => _load()),
          child: const Text('Business details'),
        ),
      ),
      if (_invoices.isEmpty) _emptyTab('No invoices yet.'),
      for (final inv in _invoices) _invoiceRow(inv),
    ];
  }

  Widget _invoiceRow(Map inv) {
    final cancelled = inv['status'] == 'cancelled';
    final state = '${inv['paymentState']}';
    final taxMode = '${inv['taxMode'] ?? 'none'}';
    final paid = ((inv['paidPaise'] as num?) ?? 0) > 0;
    return _docRow(
      faded: cancelled,
      number: '${inv['number']}',
      badge: CrmBadge(
        status: state,
        label: CrmOptions.invoicePaymentStates[state] ?? state,
      ),
      chip: taxMode == 'none'
          ? null
          : Text(
              taxMode == 'intra' ? 'CGST + SGST' : 'IGST',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
      subtitle:
          '${CrmFormat.date(inv['invoiceDate'])}'
          '${inv['dueDate'] != null ? ' · due ${CrmFormat.date(inv['dueDate'])}' : ''}'
          '${paid ? ' · received ${CrmFormat.rupees(inv['paidPaise'])}' : ''}'
          '${cancelled && inv['cancelReason'] != null ? ' · cancelled: ${inv['cancelReason']}' : ''}',
      totalPaise: inv['totalPaise'],
      actions: [
        _smallButton(
          'PDF',
          () => _pdf('Invoice ${inv['number']}', CrmApi.invoicePdf(inv['id'])),
        ),
        if (!cancelled) ...[
          _whatsappButton(
            CrmDocType.invoice,
            inv,
            CrmShare.invoice(_client, _seller, inv),
          ),
          _smallButton(
            'Email',
            () => '${_client['email'] ?? ''}'.isEmpty
                ? _toast("Add the client's email first (Edit).")
                : showCrmConfirm(
                    context,
                    title: 'Email ${inv['number']}?',
                    text:
                        'The invoice PDF will be sent to ${_client['email']}.',
                    confirmLabel: 'Send email',
                    onConfirm: (_) => _run(
                      () => _api.sendInvoice(inv['id']),
                      'Could not email the invoice.',
                    ),
                  ),
          ),
          if (state != 'paid')
            _smallButton('Record payment', () => _recordPayment(inv['id'])),
          _smallButton(
            'Cancel',
            () => showCrmConfirm(
              context,
              title: 'Cancel ${inv['number']}?',
              text:
                  "Invoices can't be edited or deleted once issued. Cancelling keeps it on "
                  'record, marked CANCELLED, and its number stays used. Issue a new invoice if '
                  'something was wrong.',
              confirmLabel: 'Cancel invoice',
              danger: true,
              inputLabel: 'Reason (printed on the invoice)',
              onConfirm: (reason) => _run(
                () => _api.cancelInvoice(inv['id'], reason),
                'Could not cancel the invoice.',
              ),
            ),
            danger: true,
          ),
        ],
      ],
    );
  }

  List<Widget> _paymentsTab() {
    return [
      _tabIntro(
        'Every payment gets a receipt you can download or share.',
        'Record payment',
        () => _recordPayment(),
      ),
      if (_payments.isEmpty) _emptyTab('No payments yet.'),
      for (final p in _payments)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: crmCardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CrmFormat.date(p['paidOn']),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  Text(
                    CrmFormat.rupees(p['amountPaise']),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _pdf(
                      'Receipt ${p['receiptNumber']}',
                      CrmApi.receiptPdf(p['id']),
                    ),
                    child: Text(
                      '${p['receiptNumber']}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (p['isAdvance'] == true)
                    const CrmBadge(status: 'booked', label: 'Advance'),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                [
                  CrmOptions.paymentMethods[p['method']] ??
                      '${p['method'] ?? ''}',
                  if ('${p['reference'] ?? ''}'.isNotEmpty) '${p['reference']}',
                  'Against: ${p['invoiceNumber'] ?? '—'}',
                ].join(' · '),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if ('${p['note'] ?? ''}'.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${p['note']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Send receipt on WhatsApp',
                    icon: const WhatsAppIcon(size: 20),
                    onPressed: _isWaSending(CrmDocType.receipt, p)
                        ? null
                        : () => _sendOnWhatsapp(
                            CrmDocType.receipt,
                            p,
                            CrmShare.receipt(_client, _seller, p),
                          ),
                  ),
                  IconButton(
                    tooltip: 'Remove payment',
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    onPressed: () => showCrmConfirm(
                      context,
                      title: 'Remove payment ${p['receiptNumber']}?',
                      text:
                          '${CrmFormat.rupees(p['amountPaise'])} on ${CrmFormat.date(p['paidOn'])} '
                          'will be removed and the balance recalculated. Use this only for a '
                          'payment entered by mistake.',
                      confirmLabel: 'Remove',
                      danger: true,
                      onConfirm: (_) => _run(
                        () => _api.deletePayment(p['id']),
                        'Could not remove the payment.',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    ];
  }
}
