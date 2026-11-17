// The vendor's Google Business Profile, set up through GrowthOS AI (a HappyWedz
// partner). Port of the website's GoogleProfilePage.jsx: the HappyWedz server
// tells this page which screen to show (the "view"), and each button moves it on.
//
// Google is connected from here. The website sends the browser to Google and
// Google sends it back with ?google=connected; a phone has no such return, so
// (like InstagramConnectScreen) the link opens in the browser and the status is
// read again — from GrowthOS — when the vendor comes back to the app.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api_services/google_profile_api.dart';
import '../../theme/app_colors.dart';
import '../../utils/common_app_bar.dart';
import '../../widgets/app_shimmer.dart';
import 'dashboard/gp_dashboard.dart';
import 'gp_format.dart';
import 'gp_parts.dart';
import 'gp_setup_pick.dart';
import 'gp_start_screen.dart';
import 'gp_status_screens.dart';

/// GrowthOS sends the approval email again at most once every 5 minutes (RD-23).
const Duration _linkResendEvery = Duration(minutes: 5);

class GoogleProfileScreen extends StatefulWidget {
  const GoogleProfileScreen({super.key});

  @override
  State<GoogleProfileScreen> createState() => _GoogleProfileScreenState();
}

class _GoogleProfileScreenState extends State<GoogleProfileScreen>
    with WidgetsBindingObserver {
  final GoogleProfileApi _api = GoogleProfileApi.instance;
  final ScrollController _scroll = ScrollController();

  String _status = 'loading'; // loading | failed | ready
  bool _loadNetwork = false;
  String _loadMessage = '';
  Map<String, dynamic>? _view;

  /// null | refresh | resend | setup | link | connect
  String? _busy;
  Map<String, dynamic>? _problem; // why the last "Set up" failed: {message, fields}
  bool _otherEmail = false;
  String? _triedEmail;
  String? _linkProblem;
  String? _linkResendAt;
  String? _connectProblem;
  Timer? _tick;

  /// True only between opening Google in the browser and coming back.
  bool _awaitingGoogle = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingGoogle) {
      _awaitingGoogle = false;
      _backFromGoogle();
    }
  }

  // ── Loading ─────────────────────────────────────────────────────────────

  /// [force]: read GrowthOS now (after Google), falling back to the stored View.
  Future<Map<String, dynamic>?> _load(
      {bool silent = false, bool force = false}) async {
    if (!silent && mounted) setState(() => _status = 'loading');
    try {
      dynamic data;
      if (force) {
        try {
          data = await _api.refresh();
        } catch (e) {
          if (gpErrorCode(e) == 'PLAN_MODULE_LOCKED') rethrow;
          data = await _api.get();
        }
      } else {
        data = await _api.get();
      }
      if (!mounted) return null;
      final view = data is Map ? Map<String, dynamic>.from(data) : null;
      setState(() {
        _view = view;
        _status = view != null ? 'ready' : 'failed';
        if (view == null) {
          _loadNetwork = false;
          _loadMessage = '';
        }
      });
      _armTimer();
      return view;
    } catch (e) {
      if (!mounted) return null;
      if (gpHandleLocked(context, e)) return null;
      if (silent) return null;
      setState(() {
        _loadNetwork = gpErrorCode(e) == 'network';
        _loadMessage = _loadNetwork
            ? gpNetworkMessage
            : gpErrorMessage(e, 'Something went wrong. Please try again.');
        _status = 'failed';
      });
      return null;
    }
  }

  Future<void> _backFromGoogle() async {
    final before = _view?['screen'];
    setState(() => _busy = null);
    final data = await _load(force: true);
    if (!mounted || data == null) return;
    if (data['screen'] != before && before == 'connect') {
      gpToast(context, 'Google connected');
    }
  }

  void _setView(Map<String, dynamic>? next) {
    setState(() => _view = next);
    _armTimer();
  }

  /// Redraws when a resend wait ends, so the button turns back on by itself.
  void _armTimer() {
    _tick?.cancel();
    final wait = msUntil(_resendAt);
    if (wait <= 0) return;
    _tick = Timer(Duration(milliseconds: wait + 500), () {
      if (mounted) setState(() {});
    });
  }

  String? get _resendAt {
    final at = _view?['resend_available_at']?.toString();
    if (at != null && at.isNotEmpty) return at;
    return _view?['screen'] == 'approve' ? _linkResendAt : null;
  }

  String? get _resendWait => msUntil(_resendAt) > 0 ? _resendAt : null;

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Map<String, dynamic>? _asView(Object? d) =>
      d is Map ? Map<String, dynamic>.from(d) : null;

  /// A failed action: the plan lost the module, the network dropped, or the server said why.
  void _actionFailed(Object e, String fallback) {
    if (gpHandleLocked(context, e)) return;
    gpToast(
        context,
        gpErrorCode(e) == 'network'
            ? gpNetworkMessage
            : gpErrorMessage(e, fallback),
        error: true);
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    setState(() => _busy = 'refresh');
    try {
      final next = _asView(await _api.refresh());
      if (!mounted) return;
      final changed = next?['screen'] != _view?['screen'];
      _setView(next);
      setState(() => _linkProblem = null);
      if (changed) {
        gpToast(context, 'Status updated from GrowthOS.');
        _toTop();
      } else {
        gpToast(context,
            'Nothing has changed yet. Finish the step, then check again.');
      }
    } catch (e) {
      if (mounted) {
        _actionFailed(e, 'Could not check your status. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// "Connect Google": a one-time link from HappyWedz, opened in the browser.
  Future<void> _connect() async {
    setState(() {
      _busy = 'connect';
      _connectProblem = null;
    });
    try {
      final url = await _api.connectUrl();
      if (url == null) throw GpException.network();
      final opened =
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!opened) {
        setState(() {
          _busy = null;
          _connectProblem = 'Could not open Google. Please try again.';
        });
        return;
      }
      // The button stays busy until the vendor comes back.
      _awaitingGoogle = true;
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = null);
      if (gpHandleLocked(context, e)) return;
      setState(() => _connectProblem = gpErrorCode(e) == 'network'
          ? gpNetworkMessage
          : gpErrorMessage(e, 'Google could not be connected. Please try again.'));
    }
  }

  /// A profile was picked, created or verified: read the status again;
  /// resolves true when the screen moved on.
  Future<bool> _afterGoogleStep([String? message]) async {
    setState(() => _busy = 'refresh');
    try {
      final next = _asView(await _api.refresh());
      if (!mounted) return false;
      final changed = next?['screen'] != _view?['screen'];
      _setView(next);
      setState(() => _connectProblem = null);
      if (message != null) gpToast(context, message);
      if (changed) _toTop();
      return changed;
    } catch (e) {
      if (mounted) {
        _actionFailed(e, 'Could not check your status. Please try again.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  String _ownerEmailOf(Map<String, dynamic>? v, String fallback) {
    final g = mapOf(v?['growthos']);
    final s = mapOf(v?['storefront']);
    final a = str(g['owner_email']);
    if (a.isNotEmpty) return a;
    final b = str(s['email']);
    return b.isNotEmpty ? b : fallback;
  }

  String _linkEmailOf(Map<String, dynamic>? v) {
    final r = str(mapOf(v?['link_request'])['email']);
    if (r.isNotEmpty) return r;
    final s = str(mapOf(v?['storefront'])['email']);
    return s.isNotEmpty ? s : 'you';
  }

  Future<void> _resend() async {
    setState(() => _busy = 'resend');
    try {
      final next = _asView(await _api.resend());
      if (!mounted) return;
      final moved = next?['screen'] != _view?['screen'];
      _setView(next);
      gpToast(context, 'A new link was emailed to ${_ownerEmailOf(next, 'you')}.');
      if (moved) _toTop();
    } catch (e) {
      if (!mounted) return;
      final code = gpErrorCode(e);
      final body = e is GpException ? e.body : const <String, dynamic>{};
      final data = mapOf(body['data']);
      if (code == 'too_soon') {
        final at = str(body['resend_available_at']).isNotEmpty
            ? str(body['resend_available_at'])
            : str(data['resend_available_at']);
        if (data['screen'] != null) {
          _setView(data);
        } else if (at.isNotEmpty && _view != null) {
          _setView({..._view!, 'resend_available_at': at});
        }
        gpToast(context,
            gpErrorMessage(e, 'Please wait a few minutes before sending it again.'),
            error: true);
      } else if (code == 'invalid_state') {
        gpToast(context,
            gpErrorMessage(e, 'Your status has moved on. Showing the latest.'),
            error: true);
        _load(silent: true);
      } else {
        _actionFailed(e, 'Could not send the email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// "Wait until …" from a too-soon answer.
  String? _waitFrom(Map<String, dynamic> body) {
    final data = mapOf(body['data']);
    final at = str(body['resend_available_at']).isNotEmpty
        ? str(body['resend_available_at'])
        : str(data['resend_available_at']);
    if (at.isNotEmpty) return at;
    final seconds =
        numOf(body['retry_after_seconds']) ?? numOf(data['retry_after_seconds']);
    if (seconds != null && seconds > 0) {
      return DateTime.now()
          .add(Duration(milliseconds: (seconds * 1000).round()))
          .toUtc()
          .toIso8601String();
    }
    return null;
  }

  void _holdLinkResend() => _linkResendAt =
      DateTime.now().add(_linkResendEvery).toUtc().toIso8601String();

  Future<void> _linkExisting() async {
    setState(() {
      _busy = 'link';
      _linkProblem = null;
    });
    try {
      final next = _asView(await _api.linkExisting());
      if (!mounted) return;
      setState(() {
        _otherEmail = false;
        _triedEmail = null;
      });
      if (next?['screen'] == 'approve') {
        _holdLinkResend();
        _setView(next);
        gpToast(context, 'GrowthOS emailed ${_linkEmailOf(next)} to approve.');
      } else {
        _setView(next);
        gpToast(context, 'Status updated from GrowthOS.');
      }
      _toTop();
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      final data = e is GpException ? e.data : null;
      if (data?['screen'] != null) _setView(data);
      setState(() => _linkProblem = gpErrorCode(e) == 'network'
          ? gpNetworkMessage
          : gpErrorMessage(e, 'Could not ask GrowthOS. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _resendLink() async {
    setState(() => _busy = 'resend');
    try {
      final next = _asView(await _api.resendLink());
      if (!mounted) return;
      final moved = next?['screen'] != _view?['screen'];
      _holdLinkResend();
      _setView(next);
      gpToast(context, 'A new email was sent to ${_linkEmailOf(next)}.');
      if (moved) _toTop();
    } catch (e) {
      if (!mounted) return;
      final code = gpErrorCode(e);
      final body = e is GpException ? e.body : const <String, dynamic>{};
      if (code == 'too_soon' || code == 'rate_limited') {
        final data = mapOf(body['data']);
        if (data['screen'] != null) _setView(data);
        final at = _waitFrom(body);
        if (at != null) {
          _linkResendAt = at;
          _armTimer();
        }
        gpToast(context,
            gpErrorMessage(e, 'Please wait a few minutes before sending it again.'),
            error: true);
      } else if (code == 'invalid_state') {
        gpToast(context,
            gpErrorMessage(e, 'Your status has moved on. Showing the latest.'),
            error: true);
        _load(silent: true);
      } else {
        _actionFailed(e, 'Could not send the email. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _setup(Map<String, dynamic> body) async {
    setState(() {
      _busy = 'setup';
      _problem = null;
    });
    try {
      final next = _asView(await _api.setup(body));
      if (!mounted) return;
      _setView(next);
      setState(() {
        _otherEmail = false;
        _triedEmail = null;
      });
      gpToast(context,
          'Sent to GrowthOS. Check ${_ownerEmailOf(next, 'your email')}.');
      _toTop();
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      final code = gpErrorCode(e);
      final answer = e is GpException ? e.body : const <String, dynamic>{};
      final data = e is GpException ? e.data : null;
      if (code == 'email_taken' && data?['screen'] != null) {
        _setView(data);
        setState(() {
          _otherEmail = false;
          _triedEmail = str(body['owner_email']).isEmpty
              ? null
              : str(body['owner_email']);
          _linkProblem = null;
        });
        _toTop();
      } else if (code == 'network') {
        setState(() => _problem = {'message': gpNetworkMessage});
      } else {
        setState(() => _problem = {
              'message':
                  gpErrorMessage(e, 'Could not send your details. Please try again.'),
              'fields': code == 'validation_error' ? answer['fields'] : null,
            });
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _useOtherEmail() {
    setState(() {
      _problem = null;
      _linkProblem = null;
      _otherEmail = true;
    });
    _toTop();
  }

  void _backToChoices() {
    setState(() {
      _problem = null;
      _otherEmail = false;
    });
    _toTop();
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  Widget _loading() => const Padding(
        padding: EdgeInsets.all(16),
        child: AppShimmer(
          child: Column(children: [
            ShimmerBox(height: 8, radius: 4, margin: EdgeInsets.only(bottom: 16)),
            ShimmerBox(height: 220, radius: 14, margin: EdgeInsets.only(bottom: 14)),
            ShimmerBox(height: 140, radius: 14),
          ]),
        ),
      );

  Widget _failed() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GpCard(
          child: GpStack(cross: CrossAxisAlignment.center, children: [
            Icon(_loadNetwork ? Icons.wifi_off_rounded : Icons.location_on_outlined,
                size: 34, color: AppColors.primary),
            const Text("Couldn't load your Google Profile",
                textAlign: TextAlign.center, style: GpText.h3),
            Text(
                _loadMessage.isEmpty
                    ? 'Something went wrong. Please try again.'
                    : _loadMessage,
                textAlign: TextAlign.center,
                style: GpText.lead),
            GpButton(
                label: 'Try again', icon: Icons.refresh, onPressed: () => _load()),
          ]),
        ),
      ],
    );
  }

  Widget _screenBody(String screen, bool askOwnerEmail) {
    final view = _view!;
    final loginUrl = str(view['growthos_login_url']).isNotEmpty
        ? str(view['growthos_login_url'])
        : growthosLoginFallback;
    switch (screen) {
      case 'start':
        return GpStartScreen(
          key: ValueKey(askOwnerEmail ? 'other-email' : 'first'),
          view: view,
          busy: _busy == 'setup',
          problem: _problem,
          onSubmit: _setup,
          askOwnerEmail: askOwnerEmail,
          blockedEmails: [
            str(mapOf(view['storefront'])['email']),
            _triedEmail ?? '',
          ].where((e) => e.isNotEmpty).toList(),
          onBack: askOwnerEmail ? _backToChoices : null,
        );
      case 'invited':
        return GpInvitedScreen(
            view: view,
            busy: _busy,
            resendWait: _resendWait,
            onRefresh: _refresh,
            onResend: _resend);
      case 'expired':
        return GpExpiredScreen(
            view: view, busy: _busy, resendWait: _resendWait, onResend: _resend);
      case 'connect':
        return GpConnectScreen(
            view: view,
            busy: _busy,
            connectProblem: _connectProblem,
            onConnect: _connect,
            onRefresh: _refresh);
      case 'pick':
        return GpSetupPick(
          connecting: _busy == 'connect',
          connectProblem: _connectProblem,
          onConnect: _connect,
          onDone: _afterGoogleStep,
        );
      case 'verify':
        return GpVerifyScreen(
            view: view,
            busy: _busy,
            onRefresh: _refresh,
            onVerified: _afterGoogleStep);
      case 'approve':
        return GpApproveScreen(
            view: view,
            busy: _busy,
            resendWait: _resendWait,
            onRefresh: _refresh,
            onResend: _resendLink);
      case 'taken':
        return GpTakenScreen(
          view: view,
          loginUrl: loginUrl,
          busy: _busy,
          takenEmail: _triedEmail,
          problem: _linkProblem,
          onLinkExisting: _linkExisting,
          onUseOtherEmail: _useOtherEmail,
        );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final askOwnerEmail = _otherEmail && _view?['screen'] == 'taken';
    final screen = askOwnerEmail ? 'start' : str(_view?['screen']);
    final known = gpStepForScreen.containsKey(screen);

    Widget body;
    if (_status == 'loading') {
      body = _loading();
    } else if (_status == 'failed' || !known) {
      body = _failed();
    } else if (screen == 'live') {
      // Once live, the steps are all done: a slim profile line, then the tabs.
      body = Column(children: [
        GpLiveBar(view: _view!),
        Expanded(child: GpDashboard(view: _view!)),
      ]);
    } else {
      final checkedAt =
          screen != 'start' ? formatWhen(_view?['checked_at']) : '';
      body = RefreshIndicator(
        onRefresh: () async {
          await _load(silent: true);
        },
        child: ListView(
          controller: _scroll,
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, 24 + MediaQuery.of(context).padding.bottom),
          children: [
            GpStepStrip(done: gpStepForScreen[screen] ?? 0),
            if (checkedAt.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text('Status last checked $checkedAt', style: GpText.note),
              ),
            _screenBody(screen, askOwnerEmail),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: 'Google Business Profile'),
      body: body,
    );
  }
}
