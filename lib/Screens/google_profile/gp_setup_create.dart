// "Create a new profile" (website SetupCreate.jsx, SetupCategory.jsx,
// SetupHours.jsx, SetupPin.jsx). The form is filled in from the vendor's
// details (prefill). The vendor checks every value, chooses Google's category,
// and presses Check: GrowthOS shows profiles already on Google that look the
// same. "Create my Google profile" creates it in the vendor's own Google
// account. When Google needs the map location first, the "Map location" box
// comes before Create.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../api_services/google_profile_api.dart';
import '../../theme/app_colors.dart';
import 'gp_format.dart';
import 'gp_parts.dart';

/// Google refused the create because it could not place the address on the map.
bool _isPinDropRequired(Object e) =>
    gpErrorCode(e) == 'google_rejected' &&
    e is GpException &&
    mapOf(e.body['details'])['reason'] == 'pin_drop_required';

const List<String> _fieldOrder = [
  'account_name',
  'location_id',
  'title',
  'category',
  'address_line1',
  'address_line2',
  'locality',
  'administrative_area',
  'postal_code',
  'phone',
  'website',
  'description',
  'days',
  'open',
  'close',
  'region_code',
];

class _CheckResult {
  final String key;
  final List<Map<String, dynamic>> matches;
  final bool checked;
  final String? reason;
  const _CheckResult(this.key, this.matches, this.checked, this.reason);
}

class GpSetupCreate extends StatefulWidget {
  final List<Map<String, dynamic>> accounts;
  final String account;
  final VoidCallback onBack;

  /// Reads the View again; resolves true when the page moved on to verification.
  final Future<bool> Function() onCreated;

  const GpSetupCreate(
      {super.key,
      required this.accounts,
      required this.account,
      required this.onBack,
      required this.onCreated});

  @override
  State<GpSetupCreate> createState() => _GpSetupCreateState();
}

class _GpSetupCreateState extends State<GpSetupCreate> {
  final _api = GoogleProfileApi.instance;

  String? _locationId;
  String _prefillStatus = 'loading';
  Map<String, dynamic>? _prefill;
  Object? _prefillError;
  GpProfileForm? _v;
  final Map<String, bool> _touched = {};
  bool _tried = false;
  Map<String, String> _serverErrors = {};
  String? _problem;
  _CheckResult? _check;
  bool _confirm = false;
  String? _busy; // check | create | continue
  bool _created = false;
  bool _pinRejected = false;
  bool _pinSaved = false;
  int _request = 0;

  final Map<String, TextEditingController> _c = {
    for (final f in [
      'title',
      'address_line1',
      'address_line2',
      'locality',
      'administrative_area',
      'postal_code',
      'phone',
      'website',
      'description',
    ])
      f: TextEditingController(),
  };
  final Map<String, GlobalKey> _keys = {for (final f in _fieldOrder) f: GlobalKey()};
  final GlobalKey _pinKey = GlobalKey();
  final GlobalKey _confirmKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadPrefill(null);
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fillControllers(GpProfileForm v) {
    _c['title']!.text = v.title;
    _c['address_line1']!.text = v.addressLine1;
    _c['address_line2']!.text = v.addressLine2;
    _c['locality']!.text = v.locality;
    _c['administrative_area']!.text = v.administrativeArea;
    _c['postal_code']!.text = v.postalCode;
    _c['phone']!.text = v.phone;
    _c['website']!.text = v.website;
    _c['description']!.text = v.description;
  }

  Future<void> _loadPrefill(String? forLocation) async {
    final mine = ++_request;
    setState(() {
      _prefillStatus = 'loading';
      _prefill = null;
      _prefillError = null;
    });
    try {
      final data = await _api.prefill(forLocation);
      if (!mounted || mine != _request) return;
      if (data is! Map || data['form'] == null) throw GpException.network();
      final map = Map<String, dynamic>.from(data);
      final account = widget.account.isNotEmpty
          ? widget.account
          : (widget.accounts.length == 1 ? str(widget.accounts.first['name']) : '');
      final v = GpProfileForm.from(map, account);
      _fillControllers(v);
      setState(() {
        _prefillStatus = 'ready';
        _prefill = map;
        _v = v;
        _touched.clear();
        _tried = false;
        _serverErrors = {};
        _check = null;
        _confirm = false;
        _pinRejected = false;
        _pinSaved = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      if (mine == _request) {
        setState(() {
          _prefillStatus = 'error';
          _prefillError = e;
        });
      }
    }
  }

  /// The map location was saved: read the prefill again for map_pin, keeping
  /// what the vendor typed.
  Future<void> _pinDone() async {
    setState(() {
      _pinSaved = true;
      _pinRejected = false;
      _problem = null;
    });
    final mine = _request;
    try {
      final fresh = await _api.prefill(_locationId);
      if (!mounted || mine != _request || fresh is! Map || fresh['form'] == null) {
        return;
      }
      setState(() => _prefill = {
            ...?_prefill,
            ...Map<String, dynamic>.from(fresh),
            'map_pin': true,
          });
    } catch (_) {
      // GrowthOS already said the location is saved; the form keeps its details.
    }
  }

  void _set(void Function(GpProfileForm v) patch, List<String> fields) {
    setState(() {
      patch(_v!);
      for (final f in fields) {
        _serverErrors.remove(f);
      }
      _problem = null;
      _confirm = false;
    });
  }

  String _errorOf(String field, Map<String, String> clientErrors) =>
      _serverErrors[field] ??
      ((_tried || _touched[field] == true) ? (clientErrors[field] ?? '') : '');

  String? _firstError(Map<String, String> errors) {
    for (final f in _fieldOrder) {
      if (errors.containsKey(f)) return f;
    }
    return null;
  }

  void _focusField(String field) {
    final ctx = _keys[field]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          alignment: 0.3, duration: const Duration(milliseconds: 250));
    }
  }

  void _show(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.3, duration: const Duration(milliseconds: 250));
      }
    });
  }

  /// Every value right? Shows the messages and moves to the first wrong one otherwise.
  bool _ready() {
    final errors = _v!.check();
    setState(() => _tried = true);
    final field = _firstError(errors);
    if (field == null) return true;
    if (field == 'region_code' || field == 'account_name' || field == 'location_id') {
      setState(() => _problem = errors[field]);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusField(field));
    return false;
  }

  void _failed(Object e, String fallback) {
    if (_isPinDropRequired(e)) {
      setState(() {
        _serverErrors = {};
        _problem = null;
        _pinSaved = false;
        _pinRejected = true;
      });
      _show(_pinKey);
      return;
    }
    final fields = e is GpException ? serverFieldErrors(e.body) : <String, String>{};
    setState(() {
      _serverErrors = fields;
      _problem = gpMessageOf(e, fallback);
    });
    final field = _firstError(fields);
    if (field != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusField(field));
    }
  }

  Future<_CheckResult?> _runCheck() async {
    final body = _v!.body();
    final key = jsonEncode(body);
    setState(() {
      _busy = 'check';
      _problem = null;
      _confirm = false;
    });
    try {
      final answer = await _api.checkProfile(body);
      if (!mounted) return null;
      final matches = answer.list
          .where((m) => m is Map && str(m['title']).isNotEmpty)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
      final meta = answer.meta ?? const {};
      final result = _CheckResult(key, matches, meta['checked'] != false,
          meta['reason'] is String ? meta['reason'] as String : null);
      setState(() => _check = result);
      return result;
    } catch (e) {
      if (!mounted) return null;
      if (gpHandleLocked(context, e)) return null;
      _failed(e, 'Could not check Google. Please try again.');
      return null;
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _pressCheck() {
    if (!_ready() || _busy != null) return;
    _runCheck();
  }

  bool get _pinNeeded =>
      _pinRejected || (_prefill?['map_pin'] == false && !_pinSaved);

  Future<void> _pressCreate() async {
    if (_pinNeeded) {
      _show(_pinKey);
      return;
    }
    if (!_ready() || _busy != null) return;
    final key = jsonEncode(_v!.body());
    if (_check == null || _check!.key != key) {
      final result = await _runCheck();
      if (result == null || !result.checked || result.matches.isNotEmpty) return;
    }
    if (!mounted) return;
    setState(() => _confirm = true);
    _show(_confirmKey);
  }

  Future<void> _doCreate() async {
    setState(() {
      _busy = 'create';
      _problem = null;
    });
    try {
      await _api.createProfile(_v!.body());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = null;
        _confirm = false;
      });
      if (gpHandleLocked(context, e)) return;
      _failed(e, 'Could not create the profile. Please try again.');
      return;
    }
    final moved = await widget.onCreated();
    if (!mounted) return;
    setState(() {
      _busy = null;
      if (!moved) _created = true;
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  Widget _heading() => GpStack(gap: 8, children: [
        const Text('Create your Google profile', style: GpText.h2),
        GpButton.ghost(
          label: 'Back to your profiles',
          icon: Icons.arrow_back,
          small: true,
          onPressed: _busy != null ? null : widget.onBack,
        ),
      ]);

  Widget _aside() => const GpAsideCard(title: 'Before you create it', children: [
        GpNumbered([
          'Use your real business name, as couples see it on your signboard.',
          'Check the address: Google shows it on Maps.',
          'The profile is created in your own Google account.',
          'Google then asks you to verify the business, usually with a code.',
        ], bullets: true),
      ]);

  Widget _text(
    String field,
    String label,
    Map<String, String> clientErrors,
    void Function(GpProfileForm v, String s) apply, {
    String? hint,
    String? helper,
    bool optional = false,
    int? maxLength,
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return KeyedSubtree(
      key: _keys[field],
      child: GpTextField(
        label: label,
        controller: _c[field]!,
        hint: hint,
        helper: helper,
        optional: optional,
        maxLength: maxLength,
        minLines: maxLines > 1 ? 4 : 1,
        maxLines: maxLines,
        keyboardType: keyboard,
        enabled: _busy == null,
        error: _errorOf(field, clientErrors),
        onChanged: (s) => _set((v) => apply(v, s), [field]),
        onBlur: () => setState(() => _touched[field] = true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_created) {
      return Column(children: [
        GpCard(
          child: GpStack(children: [
            const GpCallout(title: 'Your Google profile was created.'),
            const Text('Next: Google verification', style: GpText.h2),
            const Text("We couldn't show the next step yet. Press Continue to try again.",
                style: GpText.lead),
            GpButton(
              label: 'Continue',
              icon: Icons.refresh,
              busy: _busy == 'continue',
              onPressed: _busy == 'continue'
                  ? null
                  : () async {
                      setState(() => _busy = 'continue');
                      await widget.onCreated();
                      if (mounted) setState(() => _busy = null);
                    },
            ),
          ]),
        ),
        _aside(),
      ]);
    }

    if (_prefillStatus != 'ready' || _v == null) {
      return Column(children: [
        GpCard(
          child: GpStack(children: [
            _heading(),
            if (_prefillStatus == 'error') ...[
              GpCallout(
                  tone: GpTone.bad,
                  text: gpMessageOf(
                      _prefillError, "We couldn't load your details. Please try again.")),
              GpButton(
                  label: 'Try again',
                  icon: Icons.refresh,
                  onPressed: () => _loadPrefill(_locationId)),
            ] else
              const GpLoadingLine('Filling in your details…'),
          ]),
        ),
        _aside(),
      ]);
    }

    final v = _v!;
    final data = _prefill!;
    final locations = listOf(data['locations'])
        .whereType<Map>()
        .map((l) => Map<String, dynamic>.from(l))
        .toList();
    final clientErrors = v.check();
    final bodyKey = jsonEncode(v.body());
    final currentCheck = (_check != null && _check!.key == bodyKey) ? _check : null;
    final working = _busy != null;
    final pinNeeded = _pinNeeded;

    return Column(children: [
      GpCard(
        child: GpStack(gap: 14, children: [
          _heading(),
          const Text(
              'We filled this in from your HappyWedz details. Check every value: it appears on Google Search and Maps.',
              style: GpText.lead),
          if (widget.accounts.length > 1)
            KeyedSubtree(
              key: _keys['account_name'],
              child: GpDropdown<String>(
                label: 'Google business account',
                value: v.accountName.isEmpty ? null : v.accountName,
                hint: 'Choose a business account',
                error: _errorOf('account_name', clientErrors),
                items: [
                  for (final a in widget.accounts)
                    DropdownMenuItem(
                      value: str(a['name']),
                      child: Text(
                          str(a['accountName']).isNotEmpty
                              ? str(a['accountName'])
                              : str(a['name']),
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: working
                    ? null
                    : (s) => _set((v) => v.accountName = s ?? '', ['account_name']),
              ),
            ),
          if (locations.length > 1)
            KeyedSubtree(
              key: _keys['location_id'],
              child: GpDropdown<String>(
                label: 'Business location',
                value: locations.any((l) => str(l['id']) == v.locationId)
                    ? v.locationId
                    : null,
                helper:
                    'The profile is linked to this location. Changing it fills the form in again.',
                items: [
                  for (final l in locations)
                    DropdownMenuItem(
                        value: str(l['id']),
                        child: Text(str(l['name']), overflow: TextOverflow.ellipsis)),
                ],
                onChanged: working
                    ? null
                    : (s) {
                        _locationId = (s == null || s.isEmpty) ? null : s;
                        _loadPrefill(_locationId);
                      },
              ),
            ),
          _text('title', 'Business name', clientErrors, (v, s) => v.title = s,
              helper: 'Your real business name, as couples see it on your signboard.',
              maxLength: ProfileLimits.title),
          KeyedSubtree(
            key: _keys['category'],
            child: _SetupCategory(
              key: ValueKey('cat-${v.locationId}'),
              region: v.regionCode,
              initialQuery: str(mapOf(data['form'])['category_query']).isNotEmpty
                  ? str(mapOf(data['form'])['category_query'])
                  : v.categoryName,
              name: v.category,
              displayName: v.categoryName,
              error: _errorOf('category', clientErrors),
              disabled: working,
              onChange: (name, display) => _set((v) {
                v.category = name;
                v.categoryName = display;
              }, ['category', 'category_name']),
            ),
          ),
          _text('address_line1', 'Street address', clientErrors,
              (v, s) => v.addressLine1 = s,
              maxLength: ProfileLimits.address),
          _text('address_line2', 'Area / landmark', clientErrors,
              (v, s) => v.addressLine2 = s,
              optional: true, maxLength: ProfileLimits.address),
          _text('locality', 'City', clientErrors, (v, s) => v.locality = s,
              maxLength: ProfileLimits.locality),
          _text('administrative_area', 'State', clientErrors,
              (v, s) => v.administrativeArea = s,
              maxLength: ProfileLimits.administrativeArea),
          _text('postal_code', 'PIN code', clientErrors, (v, s) => v.postalCode = s,
              maxLength: ProfileLimits.postalCode, keyboard: TextInputType.number),
          _text('phone', 'Phone', clientErrors, (v, s) => v.phone = s,
              optional: true,
              helper: 'Google may call or text this number with the verification code.',
              maxLength: ProfileLimits.phone,
              keyboard: TextInputType.phone),
          _text('website', 'Website', clientErrors, (v, s) => v.website = s,
              optional: true, hint: 'https://', keyboard: TextInputType.url),
          _text('description', 'Description', clientErrors,
              (v, s) => v.description = s,
              optional: true,
              maxLines: 8,
              maxLength: ProfileLimits.description,
              helper:
                  '${v.description.length} / ${ProfileLimits.description} characters'),
          KeyedSubtree(
            key: _keys['days'],
            child: _SetupHours(
              form: v,
              disabled: working,
              errors: {
                'days': _errorOf('days', clientErrors),
                'open': _errorOf('open', clientErrors),
                'close': _errorOf('close', clientErrors),
              },
              onChange: (patch, fields) {
                _set(patch, fields);
                setState(() => _touched['days'] = true);
              },
            ),
          ),
          if (pinNeeded)
            KeyedSubtree(
              key: _pinKey,
              child: _SetupPin(
                storefrontPin: data['storefront_pin'] == true,
                rejected: _pinRejected,
                disabled: working,
                onSaved: _pinDone,
              ),
            )
          else if (_pinSaved)
            const GpCallout(text: 'Map location saved. You can create your profile now.'),
          if (_problem != null) GpCallout(tone: GpTone.bad, text: _problem),
          if (currentCheck != null && !_confirm)
            _checkResult(currentCheck, working),
          if (_confirm)
            KeyedSubtree(
              key: _confirmKey,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: GpStack(children: [
                  const Text('Create this profile on Google?', style: GpText.h3),
                  Text.rich(TextSpan(style: GpText.lead, children: [
                    const TextSpan(text: "It's created in your own Google account as "),
                    TextSpan(
                        text: v.title.trim(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const TextSpan(
                        text:
                            '. Google then asks you to verify the business, usually with a code by postcard, phone call, text message or email.'),
                  ])),
                  GpButtons(children: [
                    GpButton(
                        label: 'Yes, create it',
                        icon: Icons.check,
                        busy: _busy == 'create',
                        onPressed: working ? null : _doCreate),
                    GpButton.ghost(
                        label: 'Not yet',
                        onPressed: working ? null : () => setState(() => _confirm = false)),
                  ]),
                ]),
              ),
            )
          else
            GpStack(gap: 8, children: [
              GpButtons(children: [
                GpButton.ghost(
                    label: 'Check',
                    icon: Icons.search,
                    busy: _busy == 'check',
                    onPressed: working ? null : _pressCheck),
                GpButton(
                    label: 'Create my Google profile',
                    icon: Icons.add,
                    onPressed: (working || pinNeeded) ? null : _pressCreate),
              ]),
              if (pinNeeded)
                const _InlineWarn('Save the map location first.'),
              if (_tried && clientErrors.isNotEmpty && !working)
                const _InlineWarn('Fix the fields marked in red.'),
            ]),
          const Text(
              'Check looks for this business on Google first. Nothing is created until you confirm.',
              style: GpText.note),
        ]),
      ),
      _aside(),
    ]);
  }

  /// What GrowthOS found on Google for these details.
  Widget _checkResult(_CheckResult r, bool busy) {
    if (!r.checked) {
      return GpStack(children: [
        const GpCallout(
            tone: GpTone.alert, title: 'Google could not check for an existing profile'),
        const Text(
            'If you are sure this business is not on Google yet, you can create the profile now. If it may already exist, search for it on Google Maps first and ask for access instead.',
            style: GpText.lead),
        if (r.reason != null) Text('Google said: ${r.reason}', style: GpText.note),
        GpButtons(children: [
          GpButton.ghost(
              label: 'Create the profile',
              onPressed: busy ? null : () => setState(() => _confirm = true)),
          GpButton.ghost(
              label: 'Cancel', onPressed: busy ? null : () => setState(() => _check = null)),
        ]),
      ]);
    }
    if (r.matches.isEmpty) {
      return const GpCallout(
          text: 'No matching profile found on Google. You can create yours.');
    }
    return GpStack(children: [
      const GpCallout(tone: GpTone.alert, title: 'This business may already be on Google'),
      const Text(
          'Google found profiles that look like yours. If one is yours, request access on Google instead of creating a second one.',
          style: GpText.lead),
      for (final m in r.matches)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: GpStack(gap: 4, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: str(m['title']), style: GpText.label),
              if (str(m['address']).isNotEmpty)
                TextSpan(text: ' · ${str(m['address'])}', style: GpText.note),
            ])),
            str(m['request_access_uri']).isNotEmpty
                ? GpLink('Request access on Google',
                    icon: Icons.open_in_new,
                    onTap: () => gpOpenUrl(context, str(m['request_access_uri'])))
                : const Text('Search for it on Google Maps to ask for access.',
                    style: GpText.note),
          ]),
        ),
      GpButtons(children: [
        GpButton.ghost(
            label: "It's a different business — create mine",
            onPressed: busy ? null : () => setState(() => _confirm = true)),
        GpButton.ghost(
            label: 'Cancel', onPressed: busy ? null : () => setState(() => _check = null)),
      ]),
    ]);
  }
}

class _InlineWarn extends StatelessWidget {
  final String text;
  const _InlineWarn(this.text);

  @override
  Widget build(BuildContext context) => Row(children: [
        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: GpText.note)),
      ]);
}

// ── Category (website SetupCategory.jsx) ───────────────────────────────────

/// Search Google's own list and choose one: searches after 2 letters and a
/// short pause, starting with the business's own category words; older
/// answers are ignored.
class _SetupCategory extends StatefulWidget {
  final String region;
  final String initialQuery;
  final String name;
  final String displayName;
  final String error;
  final bool disabled;
  final void Function(String name, String displayName) onChange;

  const _SetupCategory({
    super.key,
    required this.region,
    required this.initialQuery,
    required this.name,
    required this.displayName,
    required this.error,
    required this.disabled,
    required this.onChange,
  });

  @override
  State<_SetupCategory> createState() => _SetupCategoryState();
}

class _SetupCategoryState extends State<_SetupCategory> {
  late final TextEditingController _text =
      TextEditingController(text: widget.initialQuery);
  String _query = '';
  String _resultQuery = '';
  String _status = 'idle';
  List<Map<String, dynamic>> _items = [];
  Object? _error;
  Timer? _debounce;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _setQuery(widget.initialQuery.trim());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _onText(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) _setQuery(value.trim());
    });
  }

  Future<void> _setQuery(String q) async {
    setState(() => _query = q);
    if (q.length < 2) return;
    final mine = ++_request;
    setState(() {
      _resultQuery = q;
      _status = 'loading';
      _items = [];
      _error = null;
    });
    try {
      final items = await GoogleProfileApi.instance.createCategories(q, widget.region);
      if (!mounted || mine != _request) return;
      setState(() {
        _status = 'ready';
        _items = listOf(items)
            .where((c) => c is Map && str(c['name']).isNotEmpty)
            .map((c) => Map<String, dynamic>.from(c as Map))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      if (mine == _request) {
        setState(() {
          _status = 'error';
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _query.length >= 2 && _resultQuery == _query;
    return GpStack(gap: 6, children: [
      const Text('Category', style: GpText.label),
      widget.name.isNotEmpty
          ? Text.rich(TextSpan(style: GpText.note, children: [
              const TextSpan(text: 'Chosen: '),
              TextSpan(
                  text: widget.displayName.isNotEmpty ? widget.displayName : widget.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const TextSpan(text: '. Search to change it.'),
            ]))
          : const Text(
              "Search Google's list and choose the one that fits best. Type at least 2 letters.",
              style: GpText.note),
      TextField(
        controller: _text,
        enabled: !widget.disabled,
        onChanged: _onText,
        style: const TextStyle(fontSize: 14),
        decoration: gpInputDecoration(
          hint: 'Search categories, e.g. wedding photographer',
          error: widget.error,
          prefixIcon: const Icon(Icons.search, size: 18),
        ),
      ),
      if (active && _status == 'loading')
        const GpLoadingLine("Searching Google's categories…"),
      if (active && _status == 'error')
        Text(gpErrorMessage(_error, "The search didn't work. Please try again."),
            style: GpText.error),
      if (active && _status == 'ready' && _items.isEmpty)
        const Text('No category matches. Try another word.', style: GpText.note),
      if (active && _status == 'ready' && _items.isNotEmpty)
        Column(children: [
          for (final item in _items)
            GpChoice(
              selected: widget.name == item['name'],
              title: str(item['display_name']).isNotEmpty
                  ? str(item['display_name'])
                  : str(item['name']),
              onTap: widget.disabled
                  ? null
                  : () => widget.onChange(
                      str(item['name']),
                      str(item['display_name']).isNotEmpty
                          ? str(item['display_name'])
                          : str(item['name'])),
            ),
        ]),
    ]);
  }
}

// ── Hours (website SetupHours.jsx) ─────────────────────────────────────────

/// The open days and one opening and closing time for them, or no hours.
class _SetupHours extends StatelessWidget {
  final GpProfileForm form;
  final bool disabled;
  final Map<String, String> errors;
  final void Function(void Function(GpProfileForm v) patch, List<String> fields)
      onChange;

  const _SetupHours(
      {required this.form,
      required this.disabled,
      required this.errors,
      required this.onChange});

  @override
  Widget build(BuildContext context) {
    final daysError = errors['days'] ?? '';
    return GpStack(gap: 10, children: [
      const Text.rich(TextSpan(text: 'Opening hours', style: GpText.h3, children: [
        TextSpan(
            text: ' (optional)',
            style: TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: AppColors.textTertiary)),
      ])),
      GpCheck(
        value: form.withHours,
        onChanged: disabled
            ? null
            : (on) => onChange((v) => v.withHours = on, ['with_hours']),
        label: const Text('Add opening hours', style: GpText.lead),
      ),
      if (form.withHours) ...[
        const Text('Open days', style: GpText.label),
        GpDayPicker(
          selected: form.days,
          onToggle: disabled
              ? null
              : (day) => onChange(
                  (v) => v.days = v.days.contains(day)
                      ? v.days.where((d) => d != day).toList()
                      : [...v.days, day],
                  ['days']),
        ),
        daysError.isNotEmpty
            ? Text(daysError, style: GpText.error)
            : const Text('Tap the days you are open.', style: GpText.note),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: GpTimeField(
              label: 'Opens',
              value: form.open,
              error: errors['open'],
              onChanged: disabled ? null : (s) => onChange((v) => v.open = s, ['open']),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GpTimeField(
              label: 'Closes',
              value: form.close,
              error: errors['close'],
              onChanged:
                  disabled ? null : (s) => onChange((v) => v.close = s, ['close']),
            ),
          ),
        ]),
        const Text(
            'Different hours on some days? Add them later in the Profile tab, after Google verifies the profile.',
            style: GpText.note),
      ],
    ]);
  }
}

// ── Map location (website SetupPin.jsx) ────────────────────────────────────

const int _mapsUrlMax = 2000;

/// The pasted link's problem, or "" when it can be sent.
String _linkProblem(String link) {
  if (link.isEmpty) return 'Paste a Google Maps link to your business.';
  if (link.length > _mapsUrlMax) return 'The link is too long.';
  const bad = 'Paste a Google Maps link that starts with https://.';
  if (RegExp(r'\s').hasMatch(link)) return bad;
  final u = Uri.tryParse(link);
  return (u != null && (u.scheme == 'https' || u.scheme == 'http') && u.host.isNotEmpty)
      ? ''
      : bad;
}

class _SetupPin extends StatefulWidget {
  final bool storefrontPin;
  final bool rejected;
  final bool disabled;
  final Future<void> Function() onSaved;

  const _SetupPin(
      {required this.storefrontPin,
      required this.rejected,
      required this.disabled,
      required this.onSaved});

  @override
  State<_SetupPin> createState() => _SetupPinState();
}

class _SetupPinState extends State<_SetupPin> {
  final _link = TextEditingController();
  String? _busy; // storefront | link
  String _linkError = '';
  String _problem = '';

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  bool get _locked => _busy != null || widget.disabled;

  Future<void> _save(String kind, Map<String, dynamic> body) async {
    setState(() {
      _busy = kind;
      _problem = '';
      _linkError = '';
    });
    try {
      await GoogleProfileApi.instance.savePin(body);
      if (!mounted) return;
      setState(() => _busy = null);
      _link.clear();
      await widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = null);
      if (gpHandleLocked(context, e)) return;
      final message =
          gpMessageOf(e, "We couldn't save the map location. Please try again.");
      setState(() {
        if (kind == 'link') {
          _linkError = message;
        } else {
          _problem = message;
        }
      });
    }
  }

  void _saveLink() {
    if (_locked) return;
    final value = _link.text.trim();
    final wrong = _linkProblem(value);
    if (wrong.isNotEmpty) {
      setState(() => _linkError = wrong);
      return;
    }
    _save('link', {'maps_url': value});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: GpStack(children: [
        const Row(children: [
          Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
          SizedBox(width: 6),
          Text('Map location', style: GpText.h3),
        ]),
        const Text("Google needs your business's place on the map.", style: GpText.lead),
        if (widget.rejected)
          const GpCallout(
              tone: GpTone.bad,
              text:
                  "Google couldn't place your address on the map. Check the address above, save your map location, then create your profile again."),
        if (widget.storefrontPin) ...[
          GpButton(
            label: 'Use my storefront map pin',
            icon: Icons.location_on_outlined,
            busy: _busy == 'storefront',
            onPressed: _locked ? null : () => _save('storefront', {}),
          ),
          if (_problem.isNotEmpty) GpCallout(tone: GpTone.bad, text: _problem),
          const Text('Or paste a link instead:', style: GpText.note),
        ],
        GpTextField(
          label: 'Paste a Google Maps link to your business',
          controller: _link,
          hint: 'https://maps.app.goo.gl/…',
          keyboardType: TextInputType.url,
          maxLength: _mapsUrlMax,
          enabled: !_locked,
          helper:
              'To copy it: open Google Maps, find your business, press Share, then Copy link. Not on Maps yet? Drop a pin on your place, then Share and Copy link.',
          error: _linkError.isEmpty ? null : _linkError,
          onChanged: (_) {
            if (_linkError.isNotEmpty) setState(() => _linkError = '');
          },
          onSubmitted: (_) => _saveLink(),
        ),
        GpButton(
          label: 'Save location',
          icon: Icons.check,
          primary: !widget.storefrontPin,
          busy: _busy == 'link',
          onPressed: _locked ? null : _saveLink,
        ),
      ]),
    );
  }
}
