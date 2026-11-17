// Google verification, inside HappyWedz (website SetupVerify.jsx): the ways
// Google offers, "Send the code" for one of them, the code box → "Verify", and
// "Waiting for Google". Ways GrowthOS can't finish here are done on Google.
import 'package:flutter/material.dart';

import '../../api_services/google_profile_api.dart';
import 'gp_format.dart';
import 'gp_parts.dart';

const Map<String, IconData> _methodIcons = {
  'ADDRESS': Icons.mail_outline,
  'PHONE_CALL': Icons.phone_outlined,
  'SMS': Icons.sms_outlined,
  'EMAIL': Icons.mail_outline,
  'AUTO': Icons.shield_outlined,
};

class GpSetupVerify extends StatefulWidget {
  /// Reads the View again once Google says the profile is verified.
  final Future<bool> Function([String? message]) onVerified;

  /// The page's "Check again".
  final VoidCallback onRefresh;
  final bool refreshing;

  const GpSetupVerify(
      {super.key,
      required this.onVerified,
      required this.onRefresh,
      required this.refreshing});

  @override
  State<GpSetupVerify> createState() => _GpSetupVerifyState();
}

class _GpSetupVerifyState extends State<GpSetupVerify> {
  final _api = GoogleProfileApi.instance;
  final _pin = TextEditingController();
  final _pinFocus = FocusNode();

  String _status = 'loading'; // loading | ready | error
  Map<String, dynamic>? _data;
  Object? _error;
  String _method = '';
  bool _pinTouched = false;
  String? _busy; // send | verify | check
  String? _problem;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pin.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _load({bool quiet = false}) async {
    final mine = ++_request;
    if (!quiet) {
      setState(() {
        _status = 'loading';
        _data = null;
        _error = null;
      });
    }
    try {
      final data = await _api.verification();
      if (!mounted || mine != _request) return null;
      if (data is! Map) throw GpException.network();
      final map = Map<String, dynamic>.from(data);
      setState(() {
        _status = 'ready';
        _data = map;
        _error = null;
      });
      return map;
    } catch (e) {
      if (!mounted) return null;
      if (gpHandleLocked(context, e)) return null;
      if (mine == _request) {
        setState(() {
          _status = 'error';
          _data = null;
          _error = e;
        });
      }
      return null;
    }
  }

  Future<void> _checkAgain() async {
    setState(() {
      _busy = 'check';
      _problem = null;
    });
    final data = await _load(quiet: true);
    if (!mounted) return;
    setState(() => _busy = null);
    if (data?['state'] == 'verified') {
      widget.onVerified('Google verified your profile.');
    } else {
      widget.onRefresh();
    }
  }

  Future<void> _sendCode() async {
    if (_method.isEmpty || _busy != null) return;
    final method = _method;
    setState(() {
      _busy = 'send';
      _problem = null;
    });
    try {
      final started = await _api.startVerification(method);
      if (!mounted) return;
      if (started is Map && started['state'] == 'verified') {
        setState(() => _busy = null);
        widget.onVerified('Google verified your profile.');
        return;
      }
      gpToast(
          context,
          method == 'AUTO'
              ? 'Google is checking your business.'
              : 'Google is sending your code.');
      setState(() {
        _pin.clear();
        _pinTouched = false;
        _method = '';
      });
      await _load(quiet: true);
      if (mounted) _pinFocus.requestFocus();
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() => _problem =
          gpMessageOf(e, 'Could not ask Google for a code. Please try again.'));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _verify() async {
    setState(() => _pinTouched = true);
    if (!isVerifyCode(_pin.text) || _busy != null) {
      _pinFocus.requestFocus();
      return;
    }
    setState(() {
      _busy = 'verify';
      _problem = null;
    });
    try {
      await _api.completeVerification(_pin.text.trim());
      if (!mounted) return;
      setState(() => _busy = null);
      widget.onVerified('Your profile is verified.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = null);
      if (gpHandleLocked(context, e)) return;
      setState(() => _problem =
          gpMessageOf(e, "That code didn't work. Check it and try again."));
      _pinFocus.requestFocus();
    }
  }

  Widget _googleLink(String label,
          {String url = googleBusinessUrl, bool primary = false}) =>
      GpButton(
        label: label,
        icon: Icons.open_in_new,
        primary: primary,
        onPressed: () => gpOpenUrl(context, url),
      );

  Widget _checkAgainButton({bool primary = false}) {
    final anyBusy = _busy != null || widget.refreshing;
    return GpButton(
      label: 'Check again',
      icon: Icons.refresh,
      primary: primary,
      busy: _busy == 'check' || widget.refreshing,
      onPressed: anyBusy ? null : _checkAgain,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'loading') {
      return const GpLoadingLine('Asking Google how it can verify your profile…');
    }
    if (_status == 'error') {
      return GpStack(children: [
        GpCallout(
            tone: GpTone.bad,
            text: gpMessageOf(
                _error, "We couldn't load the verification. Please try again.")),
        GpButtons(children: [
          GpButton(label: 'Try again', icon: Icons.refresh, onPressed: () => _load()),
          _googleLink('Verify on Google instead'),
        ]),
      ]);
    }

    final v = _data!;
    final options = listOf(v['options'])
        .where((o) => o is Map && str(o['method']).isNotEmpty)
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
    final anyBusy = _busy != null || widget.refreshing;
    final state = str(v['state']);
    final awaitingCode = v['awaiting_code'] == true;

    if (state == 'verified') {
      return GpStack(children: [
        const GpCallout(
            title: 'Google verified your profile.',
            text: 'It can now appear on Google Search and Maps.'),
        GpButton(
          label: 'Show my profile',
          icon: Icons.check,
          busy: widget.refreshing,
          onPressed: widget.refreshing
              ? null
              : () => widget.onVerified('Google verified your profile.'),
        ),
      ]);
    }

    if (state == 'suspended' || state == 'conflict') {
      final suspended = state == 'suspended';
      return GpStack(children: [
        GpCallout(
          tone: GpTone.alert,
          title: suspended
              ? 'Google has suspended this profile'
              : 'This business is managed by another Google account',
          text: suspended
              ? "Verification can't help while it is suspended. Check the profile against Google's guidelines, fix it on Google and ask Google to restore it."
              : 'Ask the current owner on Google for ownership, or connect the Google account that already owns it.',
        ),
        GpButtons(children: [
          _googleLink("Open Google's help",
              primary: true,
              url: suspended ? googleHelpSuspended : googleHelpOwnership),
          _checkAgainButton(),
        ]),
      ]);
    }

    final waitingWords = verifyMethods[str(v['method'])]?.sent;
    final waitingForGoogle = !awaitingCode && state == 'pending';
    final showPinError = _pinTouched && !isVerifyCode(_pin.text);
    final chosen = verifyMethods[_method];

    return GpStack(gap: 14, children: [
      if (_problem != null) GpCallout(tone: GpTone.bad, text: _problem),
      if (awaitingCode)
        GpCard(
          margin: EdgeInsets.zero,
          child: GpStack(children: [
            const Text('Enter the code from Google', style: GpText.h3),
            Text(waitingWords ?? 'Google sent you a code. Enter it here.',
                style: GpText.lead),
            const Text('Verification code', style: GpText.label),
            Focus(
              onFocusChange: (has) {
                if (!has) setState(() => _pinTouched = _pin.text.isNotEmpty);
              },
              child: TextField(
                controller: _pin,
                focusNode: _pinFocus,
                enabled: !anyBusy,
                maxLength: 8,
                autofillHints: const [AutofillHints.oneTimeCode],
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _verify(),
                style: const TextStyle(fontSize: 18, letterSpacing: 4),
                decoration: gpInputDecoration(
                    counter: '',
                    error: showPinError
                        ? 'Enter the code from Google: 4 to 8 letters or numbers.'
                        : null),
              ),
            ),
            GpButton(
              label: 'Verify',
              icon: Icons.check,
              busy: _busy == 'verify',
              onPressed: anyBusy ? null : _verify,
            ),
          ]),
        ),
      if (waitingForGoogle)
        GpStack(children: [
          GpCallout(
            tone: GpTone.warn,
            title: 'Waiting for Google.',
            text:
                '${waitingWords ?? 'Google is checking your business.'} Press Check again later.',
          ),
          _checkAgainButton(primary: true),
        ]),
      if (options.isEmpty)
        (!awaitingCode
            ? GpStack(children: [
                const GpCallout(
                  tone: GpTone.alert,
                  title: "Google doesn't offer a way to verify here",
                  text:
                      'Google may ask for a video or another way. Finish verification on Google, then come back and press Check again.',
                ),
                GpButtons(children: [
                  _googleLink('Verify on Google', primary: true),
                  if (!waitingForGoogle) _checkAgainButton(),
                ]),
              ])
            : null)
      else
        GpStack(gap: 8, children: [
          Text(
              awaitingCode || waitingForGoogle
                  ? "Didn't get the code? Choose a way to send a new one."
                  : 'How should Google send your code?',
              style: GpText.h3),
          Column(children: [
            for (final option in options)
              Builder(builder: (context) {
                final m = str(option['method']);
                final words = verifyMethods[m];
                final icon = _methodIcons[m] ?? Icons.shield_outlined;
                final detail = [option['phone'], option['email'], option['address']]
                    .map(str)
                    .firstWhere((s) => s.isNotEmpty, orElse: () => '');
                if (words == null) {
                  // A way GrowthOS can't finish here: done on Google's own site.
                  return GpChoice(
                    selected: false,
                    icon: icon,
                    title: 'Another way',
                    subtitle: 'Finish this one on Google. Tap to open Google.',
                    onTap: () => gpOpenUrl(context, googleBusinessUrl),
                  );
                }
                return GpChoice(
                  selected: _method == m,
                  icon: icon,
                  title: words.label,
                  subtitle:
                      detail.isNotEmpty ? '${words.help} $detail' : words.help,
                  onTap: anyBusy ? null : () => setState(() => _method = m),
                );
              }),
          ]),
          GpButton(
            label: _method == 'AUTO' ? 'Verify now' : 'Send the code',
            icon: Icons.send_outlined,
            primary: !awaitingCode,
            busy: _busy == 'send',
            onPressed: (_method.isEmpty || anyBusy) ? null : _sendCode,
          ),
          if (_method.isEmpty && !anyBusy)
            const Text('Choose a way above.', style: GpText.note),
          if (chosen != null && _method != 'AUTO' && !anyBusy)
            Text('Google sends the code by ${chosen.label.toLowerCase()}.',
                style: GpText.note),
        ]),
      if (options.isNotEmpty || awaitingCode)
        GpButtons(children: [
          if (!waitingForGoogle) _checkAgainButton(),
          _googleLink('Verify on Google instead'),
        ]),
    ]);
  }
}
