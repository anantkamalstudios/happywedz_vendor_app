import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api_services/crm_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/common_app_bar.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/whatsapp_icon.dart';
import '../crm/crm_widgets.dart';
import 'whatsapp_common.dart';

/// Connecting the vendor's WhatsApp provider — the website's
/// `WhatsAppConnect.jsx` (Settings → Integrations → WhatsApp).
///
/// Pressing Connect does not just save the two fields: the server calls the
/// provider with them first, so a wrong key fails here, while the vendor is
/// still looking at the box they pasted it into. The key is encrypted on the
/// server and never comes back; once connected only its last four characters
/// are shown.
///
/// Pops with `true` when the connection changed, so the workspace re-checks.
class WhatsAppConnectScreen extends ConsumerStatefulWidget {
  const WhatsAppConnectScreen({super.key});

  @override
  ConsumerState<WhatsAppConnectScreen> createState() =>
      _WhatsAppConnectScreenState();
}

class _WhatsAppConnectScreenState extends ConsumerState<WhatsAppConnectScreen> {
  final _api = CrmApi();
  final _baseUrl = TextEditingController();
  final _apiKey = TextEditingController();
  final _wabaId = TextEditingController();
  final _webhookSecret = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _savingWaba = false;
  bool _savingWebhook = false;
  bool _changed = false;
  bool _showLog = false;
  Map? _state;
  String _error = '';

  /// Templates the account cannot send yet: Meta has to approve each one.
  List _missing = const [];

  /// What the provider reports about the business account (`/whatsapp/waba`).
  Map? _waba;

  @override
  void initState() {
    super.initState();
    for (final c in [_baseUrl, _apiKey, _webhookSecret]) {
      c.addListener(() => setState(() {}));
    }
    _load();
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _apiKey.dispose();
    _wabaId.dispose();
    _webhookSecret.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _state == null;
      _error = '';
    });
    try {
      final data = await _api.whatsapp();
      if (!mounted) return;
      _apply(data['whatsapp'] as Map?);
      _loadWaba();
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not check your WhatsApp connection.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Optional: details of the connected business account, shown when the
  /// provider answers. A failure here changes nothing on the screen.
  Future<void> _loadWaba() async {
    if (_state?['connected'] != true || '${_state?['wabaId'] ?? ''}'.isEmpty) {
      return;
    }
    try {
      final res = await _api.whatsappWaba();
      if (!mounted) return;
      final w = res['waba'] ?? res['account'] ?? res;
      setState(() => _waba = w is Map ? w : null);
    } catch (_) {}
  }

  void _apply(Map? state) {
    setState(() {
      _state = state;
      if ('${state?['baseUrl'] ?? ''}'.isNotEmpty) {
        _baseUrl.text = '${state!['baseUrl']}';
      }
      _wabaId.text = '${state?['wabaId'] ?? ''}';
    });
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = '';
      _saving = true;
    });
    try {
      final data = await _api.connectWhatsapp({
        'baseUrl': _baseUrl.text.trim(),
        'apiKey': _apiKey.text.trim(),
        'wabaId': _wabaId.text.trim(),
      });
      if (!mounted) return;
      _changed = true;
      final state = data['whatsapp'] as Map?;
      _apply(state);
      setState(
        () => _missing = List.from(state?['missingTemplates'] ?? const []),
      );
      _apiKey.clear();
      waToast(context, '${data['message'] ?? 'WhatsApp is connected.'}');
      _loadWaba();
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(context, ref, e, 'Could not connect WhatsApp.');
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveWaba() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = '';
      _savingWaba = true;
    });
    try {
      final data = await _api.setWhatsappWaba(_wabaId.text.trim());
      if (!mounted) return;
      _changed = true;
      if (data['whatsapp'] is Map) _apply(data['whatsapp'] as Map);
      waToast(context, '${data['message'] ?? 'Saved.'}');
      _loadWaba();
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not save that account id.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _savingWaba = false);
    }
  }

  Future<void> _saveWebhook() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _error = '';
      _savingWebhook = true;
    });
    try {
      final data = await _api.setWhatsappWebhookSecret(
        _webhookSecret.text.trim(),
      );
      if (!mounted) return;
      _changed = true;
      if (data['whatsapp'] is Map) _apply(data['whatsapp'] as Map);
      _webhookSecret.clear();
      waToast(context, '${data['message'] ?? 'Saved.'}');
    } catch (e) {
      if (!mounted) return;
      final msg = waHandleError(
        context,
        ref,
        e,
        'Could not save that signing secret.',
      );
      if (msg != null) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _savingWebhook = false);
    }
  }

  Future<void> _copyWebhookUrl() async {
    final url = '${_state?['webhookUrl'] ?? ''}';
    if (url.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      waToast(context, 'Copied.');
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error =
            'Could not copy it — select the address and copy it yourself.',
      );
    }
  }

  void _disconnect() {
    showCrmConfirm(
      context,
      title: 'Disconnect WhatsApp?',
      text:
          'Your quotation and invoice buttons will go back to opening WhatsApp on your phone.',
      confirmLabel: 'Disconnect',
      danger: true,
      onConfirm: (_) async {
        setState(() => _saving = true);
        try {
          final data = await _api.disconnectWhatsapp();
          if (!mounted) return false;
          _changed = true;
          WaLastSeen.clear();
          _apply(data['whatsapp'] as Map?);
          setState(() {
            _waba = null;
            _missing = const [];
          });
          _apiKey.clear();
          waToast(context, 'WhatsApp is disconnected.');
          return true;
        } catch (e) {
          if (!mounted) return false;
          final msg = waHandleError(
            context,
            ref,
            e,
            'Could not disconnect WhatsApp.',
          );
          if (msg != null) setState(() => _error = msg);
          return false;
        } finally {
          if (mounted) setState(() => _saving = false);
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
          title: 'WhatsApp connection',
          onBack: () => Navigator.pop(context, _changed),
        ),
        body: _loading
            ? const FormShimmer(fields: 3)
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24 + MediaQuery.of(context).padding.bottom,
                  ),
                  children: [
                    const Text(
                      "Send quotations, invoices and receipts to your clients on WhatsApp, "
                      "straight from a client's page, and read their replies here. Paste the "
                      'base URL and API key from your WhatsApp provider below. Until you '
                      'connect, those buttons open WhatsApp on your phone as they do now.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_error.isNotEmpty) WaErrorBox(_error),
                    if (_state?['connected'] == true)
                      _connected()
                    else
                      _connectForm(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _warnLine(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 16,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.warning, fontSize: 13),
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, List<Widget> children) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(14),
    decoration: crmCardDecoration(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        const SizedBox(height: 10),
        ...children,
      ],
    ),
  );

  Widget _connected() {
    final s = _state!;
    final webhookReady = s['webhookReady'] == true;
    final log = List.from(s['webhookLog'] ?? const []);
    final webhookUrl = '${s['webhookUrl'] ?? ''}';
    final hasWaba = '${s['wabaId'] ?? ''}'.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.successTint,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WhatsApp is connected',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        if ('${s['phoneNumber'] ?? ''}'.isNotEmpty)
                          Text(
                            'Your clients will see messages from ${s['phoneNumber']}.',
                            style: AppTextStyles.caption,
                          ),
                        Text(
                          'Key ${s['apiKeyMasked'] ?? ''} · ${s['baseUrl'] ?? ''}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_missing.isNotEmpty || s['lastError'] != null)
                const SizedBox(height: 10),
              if (_missing.isNotEmpty)
                _warnLine(
                  'Still to create on Wapzio, as approved templates: ${_missing.join(', ')}. '
                  'Until Meta approves each one, that kind of message cannot be sent.',
                ),
              if ('${s['lastError'] ?? ''}'.isNotEmpty)
                _warnLine(
                  'The last message did not go through: ${s['lastError']}',
                ),
            ],
          ),
        ),

        _section('Account broadcasts are sent from', [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wabaId,
                  keyboardType: TextInputType.number,
                  autocorrect: false,
                  decoration: crmInputDecoration(hint: 'e.g. 1234567890123456'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _savingWaba ? null : _saveWaba,
                child: Text(_savingWaba ? 'Saving…' : 'Save'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${hasWaba ? 'Saved. Wapzio needs this to tell us what your templates say, so their previews work.' : 'Not set, so we cannot read what your templates say and their previews stay empty. Sending still works.'}'
            ' In Wapzio it is the number beside CONNECTED WABA ID on the Message Templates page.',
            style: AppTextStyles.caption.copyWith(
              color: hasWaba ? AppColors.textSecondary : AppColors.warning,
            ),
          ),
          if (_waba != null && _wabaRows().isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final r in _wabaRows())
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('${r.$1}: ${r.$2}', style: AppTextStyles.caption),
              ),
          ],
        ]),

        // Replies and delivery reports. Without this HappyWedz sees only its
        // own half of every conversation, and "sent" never becomes "delivered".
        _section('Replies and delivery reports', [
          if (webhookReady)
            Text(
              'On. ${waParse(s['webhookLastAt']) != null ? 'Last message from Wapzio ${waWhen(s['webhookLastAt'])}.' : 'Nothing has arrived yet — send yourself a WhatsApp message to test it.'}',
              style: const TextStyle(color: AppColors.success, fontSize: 13),
            )
          else
            const Text(
              "Off. Your clients' replies stay in Wapzio, and a message you send never shows "
              'as delivered or read. Two steps below turn it on.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          const SizedBox(height: 8),
          if (log.isNotEmpty) ...[
            InkWell(
              onTap: () => setState(() => _showLog = !_showLog),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      _showLog ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    Text(
                      'Last ${log.length} messages from Wapzio',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            if (_showLog)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final e in log.whereType<Map>())
                        Text(
                          [
                            '${waTimeOf(e['at'])} · ${e['event']} → ${e['kind']} → ${e['outcome']}',
                            if (e['why'] != null) ' (${e['why']})',
                            if (e['from'] != null) ' · from ${e['from']}',
                            if (e['to'] != null) ' · to ${e['to']}',
                            if (e['status'] != null) ' · ${e['status']}',
                          ].join(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
          if ('${s['webhookLastError'] ?? ''}'.isNotEmpty)
            _warnLine(
              'The last message from Wapzio could not be handled: ${s['webhookLastError']}',
            ),
          const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              children: [
                TextSpan(
                  text: '1. ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      'In Wapzio: Setup & Integration → Integrations → Connect a website. '
                      'Paste this address, and turn on ',
                ),
                TextSpan(
                  text: 'Incoming message',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Message status',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    webhookUrl.isEmpty ? '—' : webhookUrl,
                    maxLines: 2,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: webhookUrl.isEmpty ? null : _copyWebhookUrl,
                child: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              children: [
                TextSpan(
                  text: '2. ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text:
                      'Wapzio shows a signing secret once, on the next screen. Paste it '
                      'here — it is what proves a message really came from Wapzio.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _webhookSecret,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: crmInputDecoration(
                    hint: webhookReady
                        ? 'Saved — paste a new one to replace it'
                        : 'whsec_…',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _savingWebhook || _webhookSecret.text.trim().isEmpty
                    ? null
                    : _saveWebhook,
                child: Text(_savingWebhook ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ]),

        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton(
            onPressed: _saving ? null : _disconnect,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text('Disconnect'),
          ),
        ),
      ],
    );
  }

  /// Scalar fields of the account, labelled from their keys.
  List<(String, String)> _wabaRows() {
    final w = _waba;
    if (w == null) return const [];
    const labels = {
      'name': 'Account',
      'id': 'Account id',
      'wabaId': 'Account id',
      'phoneNumber': 'Number',
      'displayPhoneNumber': 'Number',
      'verifiedName': 'Verified name',
      'status': 'Status',
      'qualityRating': 'Quality',
      'messagingLimit': 'Messaging limit',
    };
    return [
      for (final e in labels.entries)
        if (w[e.key] != null &&
            w[e.key] is! Map &&
            w[e.key] is! List &&
            '${w[e.key]}'.isNotEmpty)
          (e.value, '${w[e.key]}'),
    ];
  }

  Widget _connectForm() {
    final s = _state;
    final broken =
        s != null &&
        s['connected'] == false &&
        '${s['baseUrl'] ?? ''}'.isNotEmpty;
    final canConnect =
        !_saving &&
        _baseUrl.text.trim().isNotEmpty &&
        _apiKey.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: crmCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (broken)
            CrmNotice(
              'Your WhatsApp connection stopped working'
              '${'${s['lastError'] ?? ''}'.isNotEmpty ? ': ${s['lastError']}' : '.'}'
              ' Paste your API key again to reconnect.',
            ),
          CrmField(
            label: 'Base URL',
            hint:
                "From your provider's API Credentials page — usually https://api.wapzio.com",
            child: TextField(
              controller: _baseUrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: crmInputDecoration(hint: 'https://api.wapzio.com'),
            ),
          ),
          CrmField(
            label: 'API key',
            hint:
                'Stored encrypted. It is never shown again after you connect.',
            child: TextField(
              controller: _apiKey,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: crmInputDecoration(hint: 'Paste your API key'),
            ),
          ),
          CrmField(
            label: 'WhatsApp Business Account id',
            hint:
                'Wapzio needs this to tell us what your templates say. Without it messages '
                'still send, but template previews stay empty. You can add it later.',
            child: TextField(
              controller: _wabaId,
              keyboardType: TextInputType.number,
              autocorrect: false,
              decoration: crmInputDecoration(hint: 'e.g. 1234567890123456'),
            ),
          ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: canConnect ? _connect : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const WhatsAppIcon(color: Colors.white),
            label: Text(
              _saving ? 'Checking your details…' : 'Connect WhatsApp',
            ),
          ),
        ],
      ),
    );
  }
}
