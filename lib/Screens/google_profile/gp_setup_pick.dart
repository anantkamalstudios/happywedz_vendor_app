// Screen "pick" (website SetupPick.jsx): Google is connected. The vendor
// chooses the Google business account and the profile in it ("Use this
// profile"), or creates a new profile here (GpSetupCreate).
import 'package:flutter/material.dart';

import '../../api_services/google_profile_api.dart';
import '../../theme/app_colors.dart';
import 'gp_format.dart';
import 'gp_parts.dart';
import 'gp_setup_create.dart';

/// A Google error with "Try again", and "Connect Google again" when Google's
/// access has run out.
class _GoogleProblem extends StatelessWidget {
  final Object? error;
  final String fallback;
  final VoidCallback? onRetry;
  final VoidCallback onReconnect;
  final bool connecting;
  const _GoogleProblem(
      {required this.error,
      required this.fallback,
      this.onRetry,
      required this.onReconnect,
      required this.connecting});

  @override
  Widget build(BuildContext context) {
    final reconnect = gpErrorCode(error) == 'google_reconnect';
    return GpStack(children: [
      GpCallout(tone: GpTone.bad, text: gpMessageOf(error, fallback)),
      if (reconnect)
        GpButton(
            label: 'Connect Google again',
            icon: Icons.person_add_alt,
            busy: connecting,
            onPressed: connecting ? null : onReconnect)
      else if (onRetry != null)
        GpButton(label: 'Try again', icon: Icons.refresh, onPressed: onRetry),
    ]);
  }
}

class GpSetupPick extends StatefulWidget {
  final bool connecting;
  final String? connectProblem;
  final VoidCallback onConnect;

  /// Reads the View again after the profile was chosen or created
  /// (resolves true when it moved on).
  final Future<bool> Function([String? message]) onDone;

  const GpSetupPick(
      {super.key,
      required this.connecting,
      required this.connectProblem,
      required this.onConnect,
      required this.onDone});

  @override
  State<GpSetupPick> createState() => _GpSetupPickState();
}

class _GpSetupPickState extends State<GpSetupPick> {
  final _api = GoogleProfileApi.instance;

  String _mode = 'pick'; // pick | create
  String _accStatus = 'loading';
  List<Map<String, dynamic>> _accounts = [];
  Object? _accError;
  String _account = '';

  String _locAccount = '';
  String _locStatus = 'idle';
  List<Map<String, dynamic>> _locations = [];
  Object? _locError;
  String _location = '';

  bool _picking = false;
  Object? _pickError;

  bool _unlinkConfirm = false;
  bool _unlinkBusy = false;
  Object? _unlinkError;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  List<Map<String, dynamic>> _named(Object? data) => listOf(data)
      .where((a) => a is Map && str(a['name']).isNotEmpty)
      .map((a) => Map<String, dynamic>.from(a as Map))
      .toList();

  Future<void> _loadAccounts() async {
    setState(() {
      _accStatus = 'loading';
      _accounts = [];
      _accError = null;
    });
    try {
      final items = _named(await _api.accounts());
      if (!mounted) return;
      setState(() {
        _accStatus = 'ready';
        _accounts = items;
        _account = items.any((a) => a['name'] == _account)
            ? _account
            : items.length == 1
                ? str(items.first['name'])
                : '';
      });
      if (_account.isNotEmpty) _loadLocations(_account);
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _accStatus = 'error';
        _accError = e;
      });
    }
  }

  Future<void> _loadLocations(String accountName) async {
    if (accountName.isEmpty) return;
    final mine = ++_request;
    setState(() {
      _locAccount = accountName;
      _locStatus = 'loading';
      _locations = [];
      _locError = null;
    });
    try {
      final items = _named(await _api.locations(accountName));
      if (!mounted || mine != _request) return;
      setState(() {
        _locStatus = 'ready';
        _locations = items;
        _location = items.length == 1 ? str(items.first['name']) : '';
      });
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      if (mine == _request) {
        setState(() {
          _locStatus = 'error';
          _locError = e;
        });
      }
    }
  }

  void _chooseAccount(String name) {
    setState(() {
      _account = name;
      _location = '';
      _pickError = null;
    });
    if (name.isNotEmpty) _loadLocations(name);
  }

  void _switchMode(String next) => setState(() {
        _mode = next;
        _pickError = null;
      });

  Future<void> _pickProfile() async {
    if (_account.isEmpty || _location.isEmpty || _picking) return;
    setState(() {
      _picking = true;
      _pickError = null;
    });
    try {
      await _api.pickLocation(
          {'account_name': _account, 'location_name': _location});
      if (!mounted) return;
      await widget.onDone('Your Google profile is connected.');
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() => _pickError = e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _unlinkConfirm = true;
      _unlinkBusy = true;
      _unlinkError = null;
    });
    try {
      await _api.disconnectGoogle();
      if (!mounted) return;
      setState(() {
        _unlinkConfirm = false;
        _unlinkBusy = false;
      });
      widget.onDone('Google disconnected. Press Connect Google to connect again.');
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _unlinkBusy = false;
        _unlinkError = e;
      });
    }
  }

  Widget _otherAccount() {
    return GpStack(gap: 10, children: [
      GpButton.ghost(
        label: 'Use a different Google account',
        icon: Icons.person_add_alt,
        busy: widget.connecting,
        onPressed: widget.connecting ? null : widget.onConnect,
      ),
      if (!_unlinkConfirm)
        GpButton.ghost(
          label: 'Disconnect Google',
          icon: Icons.logout,
          onPressed: () => setState(() {
            _unlinkConfirm = true;
            _unlinkError = null;
          }),
        )
      else
        GpStack(gap: 8, children: [
          if (_unlinkError != null)
            GpCallout(
                tone: GpTone.bad,
                text: gpErrorMessage(_unlinkError,
                    'Google could not be disconnected. Please try again.')),
          GpConfirmBox(
            text:
                'Disconnect this Google account from HappyWedz? Nothing on Google changes. You can connect again straight away.',
            confirmLabel: 'Yes, disconnect',
            busy: _unlinkBusy,
            onConfirm: _disconnect,
            onCancel: () => setState(() {
              _unlinkConfirm = false;
              _unlinkError = null;
            }),
          ),
        ]),
    ]);
  }

  Widget _emptyBlock(String title, String text, List<Widget> buttons) {
    return GpStack(cross: CrossAxisAlignment.stretch, children: [
      const Icon(Icons.location_on_outlined, size: 30, color: AppColors.primary),
      Text(title, textAlign: TextAlign.center, style: GpText.h3),
      Text(text, textAlign: TextAlign.center, style: GpText.lead),
      ...buttons,
    ]);
  }

  Widget? _renderLocations() {
    if (_account.isEmpty) return null;
    if (_locAccount != _account || _locStatus == 'loading' || _locStatus == 'idle') {
      return const GpLoadingLine('Loading your profiles…');
    }
    if (_locStatus == 'error') {
      return _GoogleProblem(
        error: _locError,
        fallback: "We couldn't load your profiles. Please try again.",
        onRetry: () => _loadLocations(_account),
        onReconnect: widget.onConnect,
        connecting: widget.connecting,
      );
    }
    if (_locations.isEmpty) {
      return _emptyBlock(
        'This Google account has no Business Profile yet',
        "Create one from your HappyWedz details${_accounts.length > 1 ? ', or choose another business account above.' : '.'} It's created in your own Google account.",
        [
          GpButton(
              label: 'Create a new profile',
              icon: Icons.add,
              onPressed: () => _switchMode('create')),
          _otherAccount(),
        ],
      );
    }
    return GpStack(children: [
      const Text('Choose your profile', style: GpText.h3),
      Column(children: [
        for (final item in _locations)
          GpChoice(
            selected: _location == item['name'],
            title: str(item['title']).isNotEmpty
                ? str(item['title'])
                : 'Untitled profile',
            subtitle: [item['address'], item['category']]
                .map(str)
                .where((s) => s.isNotEmpty)
                .join(' · '),
            onTap: () => setState(() {
              _location = str(item['name']);
              _pickError = null;
            }),
          ),
      ]),
      if (_pickError != null)
        _GoogleProblem(
          error: _pickError,
          fallback: "We couldn't use this profile. Please try again.",
          onReconnect: widget.onConnect,
          connecting: widget.connecting,
        ),
      GpButton(
        label: 'Use this profile',
        icon: Icons.check,
        expand: true,
        busy: _picking,
        onPressed: (_location.isEmpty || _picking) ? null : _pickProfile,
      ),
      GpButton.ghost(
        label: 'Create a new profile instead',
        icon: Icons.add,
        expand: true,
        onPressed: _picking ? null : () => _switchMode('create'),
      ),
      if (_location.isEmpty && !_picking)
        const Text('Choose your profile above.', style: GpText.note),
    ]);
  }

  Widget _renderAccounts() {
    if (_accStatus == 'loading') {
      return const GpLoadingLine('Loading your Google business accounts…');
    }
    if (_accStatus == 'error') {
      return _GoogleProblem(
        error: _accError,
        fallback: "We couldn't load your Google business accounts. Please try again.",
        onRetry: _loadAccounts,
        onReconnect: widget.onConnect,
        connecting: widget.connecting,
      );
    }
    if (_accounts.isEmpty) {
      return _emptyBlock(
        'No Google business account found',
        'Open Google Business Profile once with this Google account to set up its business account, then come back here and press Check again.',
        [
          GpButton(
              label: 'Open Google Business Profile',
              icon: Icons.open_in_new,
              onPressed: () => gpOpenUrl(context, googleBusinessUrl)),
          GpButton.ghost(
              label: 'Check again', icon: Icons.refresh, onPressed: _loadAccounts),
          _otherAccount(),
        ],
      );
    }
    final chosen = _accounts.firstWhere((a) => a['name'] == _account,
        orElse: () => const <String, dynamic>{});
    return GpStack(children: [
      if (_accounts.length > 1)
        GpDropdown<String>(
          label: 'Google business account',
          value: _account.isEmpty ? null : _account,
          hint: 'Choose a business account',
          items: [
            for (final a in _accounts)
              DropdownMenuItem(
                value: str(a['name']),
                child: Text(
                    str(a['accountName']).isNotEmpty
                        ? str(a['accountName'])
                        : str(a['name']),
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: _picking ? null : (v) => _chooseAccount(v ?? ''),
        )
      else
        Text.rich(TextSpan(style: GpText.note, children: [
          const TextSpan(text: 'Google business account: '),
          TextSpan(
              text: str(chosen['accountName']).isNotEmpty
                  ? str(chosen['accountName'])
                  : str(chosen['name']),
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ])),
      _renderLocations(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == 'create') {
      return GpSetupCreate(
        accounts: _accounts,
        account: _account,
        onBack: () => _switchMode('pick'),
        onCreated: () => widget.onDone('Your Google profile was created.'),
      );
    }
    return Column(children: [
      GpCard(
        tint: true,
        child: GpStack(children: [
          const GpCallout(text: 'Google is connected.'),
          if (widget.connectProblem != null)
            GpCallout(tone: GpTone.bad, text: widget.connectProblem),
          const Text('Pick your Google Business Profile', style: GpText.h2),
          const Text(
              'Choose the profile of this business. Nothing new is created. No profile yet? Create one here from your HappyWedz details.',
              style: GpText.lead),
          _renderAccounts(),
        ]),
      ),
      GpAsideCard(title: "Don't see your profile?", children: [
        const Text(
            'It may be in another Google account. Connect the Google account that manages your profile on Google.',
            style: GpText.lead),
        _otherAccount(),
      ]),
    ]);
  }
}
