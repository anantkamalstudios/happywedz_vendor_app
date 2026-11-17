// "Google suggested changes" on the Profile tab (website dashboard/ProfileUpdates.jsx):
// the fields where Google's version differs from the vendor's, with both
// versions; accept Google's or keep your own (only fields Google already
// changed; others are still under review). Shown only when Google suggests
// something. API: googleUpdates / answerGoogleUpdates.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'profile_shared.dart';

// Google field paths → plain names (GrowthOS's labels).
const Map<String, String> _fieldLabels = {
  'title': 'Business name',
  'phoneNumbers': 'Phone numbers',
  'phoneNumbers.primaryPhone': 'Main phone',
  'phoneNumbers.additionalPhones': 'Other phones',
  'websiteUri': 'Website',
  'regularHours': 'Opening hours',
  'specialHours': 'Special hours',
  'moreHours': 'More hours',
  'categories': 'Categories',
  'categories.primaryCategory': 'Main category',
  'categories.additionalCategories': 'Other categories',
  'storefrontAddress': 'Address',
  'serviceArea': 'Service area',
  'profile': 'Description',
  'profile.description': 'Description',
  'openInfo': 'Open status',
  'openInfo.status': 'Open status',
  'openInfo.openingDate': 'Opening date',
  'serviceItems': 'Services',
};

String _labelOf(String path) =>
    _fieldLabels[path] ?? _fieldLabels[path.split('.').first] ?? path;

const Map<String, String> _days = {
  'MONDAY': 'Mon',
  'TUESDAY': 'Tue',
  'WEDNESDAY': 'Wed',
  'THURSDAY': 'Thu',
  'FRIDAY': 'Fri',
  'SATURDAY': 'Sat',
  'SUNDAY': 'Sun',
};
const Map<String, String> _openStatus = {
  'OPEN': 'Open',
  'CLOSED_TEMPORARILY': 'Temporarily closed',
  'CLOSED_PERMANENTLY': 'Permanently closed',
};

String _clock(Object? t) {
  if (t is! Map) return '';
  String two(Object? v) => '${v is num ? v.toInt() : 0}'.padLeft(2, '0');
  return '${two(t['hours'])}:${two(t['minutes'])}';
}

String? _joined(Iterable<Object?> parts, [String sep = ', ']) {
  final list = parts
      .where((e) => e != null && '$e'.isNotEmpty)
      .map((e) => '$e')
      .toList();
  return list.isEmpty ? null : list.join(sep);
}

/// A raw Google value as short readable text, or null when there is nothing.
/// Never shows code: an unknown shape is read field by field.
String? _readable(Object? value) {
  if (value == null) return null;
  if (value is String) return value.trim().isEmpty ? null : value.trim();
  if (value is num) return '$value';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) return _joined(value.map(_readable));
  if (value is! Map || value.isEmpty) return null;
  final v = value;
  if (v['displayName'] is String) return v['displayName'] as String;
  if (v.containsKey('primaryPhone') || v.containsKey('additionalPhones')) {
    return _joined([v['primaryPhone'], ...listOf(v['additionalPhones'])]);
  }
  if (v['addressLines'] != null ||
      (v['locality'] != null && '${v['locality']}'.isNotEmpty) ||
      (v['postalCode'] != null && '${v['postalCode']}'.isNotEmpty)) {
    return _joined([
      ...listOf(v['addressLines']),
      v['locality'],
      v['administrativeArea'],
      v['postalCode'],
    ]);
  }
  if (v.containsKey('primaryCategory') ||
      v.containsKey('additionalCategories')) {
    return _joined([
      mapOf(v['primaryCategory'])['displayName'],
      ...listOf(v['additionalCategories']).map((c) => mapOf(c)['displayName']),
    ]);
  }
  if (v['periods'] is List) {
    return _joined((v['periods'] as List).map((p) {
      final m = mapOf(p);
      final day = _days[str(m['openDay'])] ?? str(m['openDay']);
      return '$day ${_clock(m['openTime'])}–${_clock(m['closeTime'])}';
    }));
  }
  if (v['status'] is String) {
    return _openStatus[v['status']] ?? v['status'] as String;
  }
  return _joined(v.values.map(_readable), ' · ');
}

class ProfileUpdates extends StatefulWidget {
  /// Reloads the profile after an answer.
  final VoidCallback onChanged;
  const ProfileUpdates({super.key, required this.onChanged});

  @override
  State<ProfileUpdates> createState() => ProfileUpdatesState();
}

class ProfileUpdatesState extends State<ProfileUpdates> {
  String _status = 'loading'; // loading | ready | error
  List<Map<String, dynamic>> _fields = const [];
  Object? _loadError;
  String? _busy; // accept | reject
  Object? _error;
  String _done = '';

  @override
  void initState() {
    super.initState();
    load();
  }

  /// Checks Google's suggestions again (also used by pull-to-refresh).
  Future<void> load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _status = 'loading';
        _loadError = null;
      });
    }
    try {
      final data = await GoogleProfileApi.instance.googleUpdates();
      if (!mounted) return;
      final fields = mapOf(data)['fields'];
      setState(() {
        _status = 'ready';
        _fields = fields is List
            ? fields
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : const [];
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() {
        _status = 'error';
        _fields = const [];
        _loadError = e;
      });
    }
  }

  Future<void> _decide(String action) async {
    setState(() {
      _busy = action;
      _error = null;
      _done = '';
    });
    try {
      await GoogleProfileApi.instance.answerGoogleUpdates({'action': action});
      if (!mounted) return;
      setState(() => _done = action == 'accept'
          ? "Google's version accepted."
          : 'Your version kept on Google.');
      await load(quiet: true);
      widget.onChanged();
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Widget _doneLine() => _done.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GpCallout(tone: GpTone.ok, text: _done),
        );

  @override
  Widget build(BuildContext context) {
    if (_status == 'loading') return _doneLine();
    if (_status == 'error') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GpStack(gap: 10, children: [
          ProfileErrorNote(
              error: _loadError,
              fallback: "We couldn't check Google's suggested changes."),
          GpButton.ghost(
              label: "Check Google's suggestions again",
              icon: Icons.refresh,
              onPressed: () => load()),
        ]),
      );
    }
    if (_fields.isEmpty) return _doneLine();

    final decidable = _fields.where((f) => f['pending'] != true).toList();

    return GpCard(
      tint: true,
      child: GpStack(gap: 14, children: [
        const GpStack(gap: 4, children: [
          Text('Google suggested changes', style: GpText.h3),
          Text(
              'Google sometimes changes profile details, for example from customer suggestions. Compare both versions and choose which to keep.',
              style: GpText.note),
        ]),
        for (final f in _fields) _field(f),
        if (_error != null) ProfileErrorNote(error: _error),
        if (decidable.isNotEmpty)
          GpButtons(children: [
            GpButton(
              label: "Accept Google's version",
              busy: _busy == 'accept',
              onPressed: _busy != null ? null : () => _decide('accept'),
            ),
            GpButton.ghost(
              label: 'Keep mine',
              busy: _busy == 'reject',
              onPressed: _busy != null ? null : () => _decide('reject'),
            ),
          ])
        else
          Text(
              "Google is checking ${_fields.length > 1 ? 'these changes' : 'this change'}. You don't need to do anything: this box goes away when Google has finished.",
              style: GpText.note),
        if (_done.isNotEmpty) GpCallout(tone: GpTone.ok, text: _done),
      ]),
    );
  }

  Widget _field(Map<String, dynamic> f) {
    final pending = f['pending'] == true;
    Widget version(String title, String? text, String empty) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: GpStack(gap: 4, children: [
              Text(title, style: GpText.note),
              Text(text ?? empty,
                  style: text == null
                      ? GpText.muted
                      : const TextStyle(
                          fontSize: 13.5, color: AppColors.textPrimary)),
            ]),
          ),
        );
    return GpStack(gap: 8, children: [
      Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(_labelOf(str(f['field'])), style: GpText.label),
          if (pending) const GpChip('Google is reviewing it', tone: GpTone.warn),
        ],
      ),
      IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          version('Your version', _readable(f['yours']), 'Not set'),
          const SizedBox(width: 8),
          version("Google's version", _readable(f['google']),
              pending ? 'Not shown yet' : 'Not set'),
        ]),
      ),
    ]);
  }
}
