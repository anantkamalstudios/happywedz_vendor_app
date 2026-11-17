// Profile tab of the Google Profile dashboard (website dashboard/ProfileTab.jsx).
// One card per section of the Google profile with what Google shows now; edit
// one section at a time (description with AI help, hours, special hours,
// contact, services, categories, attributes, address, service area, open
// status, name, more hours) and save it on Google. Risky sections ask for a
// tick first. Google's suggested changes can be accepted or rejected above
// the cards.
import 'package:flutter/material.dart';

import '../../../api_services/google_profile_api.dart';
import '../../../theme/app_colors.dart';
import '../gp_format.dart';
import '../gp_parts.dart';
import 'profile_sections.dart';
import 'profile_shared.dart';
import 'profile_updates.dart';
import 'profile_utils.dart';

class _Section {
  final String id;
  final String title;
  final IconData icon;
  const _Section(this.id, this.title, this.icon);
}

// GrowthOS's section names (PROFILE_SECTIONS), with plain titles.
const List<_Section> _sections = [
  _Section('name', 'Business name', Icons.business_center_outlined),
  _Section('categories', 'Categories', Icons.sell_outlined),
  _Section('description', 'Description', Icons.notes_outlined),
  _Section('contact', 'Phone and website', Icons.phone_outlined),
  _Section('address', 'Address', Icons.location_on_outlined),
  _Section('service_area', 'Service area', Icons.map_outlined),
  _Section('hours', 'Opening hours', Icons.schedule),
  _Section('special_hours', 'Special hours', Icons.calendar_today_outlined),
  _Section('more_hours', 'More hours', Icons.watch_later_outlined),
  _Section('open_status', 'Open status', Icons.check_circle_outline),
  _Section('services', 'Services', Icons.list_alt_outlined),
  _Section('attributes', 'Attributes', Icons.tune),
];

// The cards in four groups, so the profile reads the way Google shows it.
const List<(String, List<String>)> _groups = [
  ('Basics', ['name', 'categories', 'description']),
  ('Contact and location', ['contact', 'address', 'service_area']),
  ('Hours', ['hours', 'special_hours', 'more_hours', 'open_status']),
  ('Services and extras', ['services', 'attributes']),
];

const int _maxTags = 10;

const Map<String, String> _openStatusLabels = {
  'OPEN': 'Open',
  'CLOSED_TEMPORARILY': 'Temporarily closed',
  'CLOSED_PERMANENTLY': 'Permanently closed',
};
const Map<String, String> _businessTypeLabels = {
  'CUSTOMER_AND_BUSINESS_LOCATION': "At your business and at customers' places",
  'CUSTOMER_LOCATION_ONLY': "Only at customers' places",
};

String _plural(int n, String one, String many) => '$n ${n == 1 ? one : many}';
String _range(Map<String, dynamic> r) {
  final close = str(r['close']);
  return '${str(r['open'])}–${close == '24:00' ? 'midnight' : close}';
}

/// Sections Google offers nothing to edit in for this category (or did not
/// send this time).
bool _noEditor(String section, Map<String, dynamic> data) {
  final unavailable = listOf(data['unavailable']);
  if (section == 'more_hours') {
    return listOf(data['more_hours_types']).isEmpty ||
        unavailable.contains('more_hours');
  }
  if (section == 'attributes') {
    return listOf(mapOf(data['attributes'])['meta']).isEmpty ||
        unavailable.contains('attributes');
  }
  return false;
}

class GpProfileTab extends StatefulWidget {
  final Map<String, dynamic> view;
  final void Function(String tabId) onOpenTab;
  final VoidCallback onChanged;

  const GpProfileTab({
    super.key,
    required this.view,
    required this.onOpenTab,
    required this.onChanged,
  });

  @override
  State<GpProfileTab> createState() => _GpProfileTabState();
}

class _GpProfileTabState extends State<GpProfileTab> {
  GpLoad<Map<String, dynamic>> _state = const GpLoad.loading();
  String _done = '';
  bool _editing = false;
  final GlobalKey<ProfileUpdatesState> _updates =
      GlobalKey<ProfileUpdatesState>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool quiet = false}) async {
    if (!quiet) setState(() => _state = const GpLoad.loading());
    try {
      final raw = await GoogleProfileApi.instance.profile();
      if (!mounted) return;
      setState(() => _state = GpLoad.ready(profileNormalise(raw)));
    } catch (e) {
      if (!mounted) return;
      if (gpHandleLocked(context, e)) return;
      if (quiet && _state.isReady) return;
      setState(() => _state = GpLoad.failed(e));
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _load(quiet: true),
      if (_updates.currentState != null)
        _updates.currentState!.load(quiet: true),
    ]);
  }

  Future<void> _edit(_Section section, Map<String, dynamic> data) async {
    if (_editing) return;
    setState(() {
      _done = '';
      _editing = true;
    });
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => profileSectionPage(section.id, data, section.title),
    ));
    if (!mounted) return;
    setState(() => _editing = false);
    if (saved == true) _onSaved(section);
  }

  void _onSaved(_Section section) {
    setState(() => _done =
        '${section.title} saved on Google.${profileRiskySections.contains(section.id) ? ' Google may review it before showing it.' : ' Google may take a few minutes to show it.'}');
    _load(quiet: true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = 16 + MediaQuery.of(context).padding.bottom;
    final padding = EdgeInsets.fromLTRB(16, 16, 16, bottom);

    if (_state.isLoading) {
      return ListView(padding: padding, children: const [
        GpLoadingLine('Loading your Google profile…'),
        SizedBox(height: 8),
        GpCardsShimmer(count: 5, height: 110),
      ]);
    }
    if (_state.isError) {
      return ListView(padding: padding, children: [
        ProfileErrorNote(
            error: _state.error,
            fallback: "We couldn't load this. Please try again."),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: GpButton(
              label: 'Try again', icon: Icons.refresh, onPressed: () => _load()),
        ),
      ]);
    }

    final data = _state.data!;
    final missing = listOf(data['unavailable'])
        .where((p) => p == 'more_hours' || p == 'attributes')
        .toList();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          const GpStack(gap: 4, children: [
            Text('Your Google profile', style: GpText.h3),
            Text(
                'Changes are saved on Google at once and read back from Google. Google may take a few minutes to show them.',
                style: GpText.note),
          ]),
          const SizedBox(height: 14),
          ProfileUpdates(key: _updates, onChanged: () => _load(quiet: true)),
          if (_done.isNotEmpty) ...[
            GpCallout(tone: GpTone.ok, text: _done),
            const SizedBox(height: 14),
          ],
          if (missing.isNotEmpty) ...[
            GpCallout(
              tone: GpTone.warn,
              text:
                  'Google did not send ${missing.map((m) => m == 'attributes' ? 'attributes' : 'more hours').join(' and ')} this time. Everything else can be edited; try again later for these.',
            ),
            const SizedBox(height: 14),
          ],
          for (final (title, ids) in _groups) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              child: Text(title.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
            for (final id in ids)
              _card(_sections.firstWhere((s) => s.id == id), data),
          ],
        ],
      ),
    );
  }

  Widget _card(_Section section, Map<String, dynamic> data) {
    final risky = profileRiskySections.contains(section.id);
    return GpCard(
      child: GpStack(gap: 10, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primaryTint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(section.icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GpStack(gap: 4, children: [
              Text(section.title, style: GpText.label),
              if (risky)
                const GpChip('Google reviews changes', tone: GpTone.alert),
            ]),
          ),
          if (!_noEditor(section.id, data))
            GpButton.ghost(
              label: 'Edit',
              icon: Icons.edit_outlined,
              small: true,
              onPressed: _editing ? null : () => _edit(section, data),
            ),
        ]),
        _summary(section.id, data),
      ]),
    );
  }

  Widget _text(String value, [String empty = 'Not set']) => value.isNotEmpty
      ? Text(value, style: GpText.lead)
      : Text(empty, style: GpText.muted);

  Widget _tags(List<(String, bool)> items, String empty) {
    if (items.isEmpty) return Text(empty, style: GpText.muted);
    return Wrap(spacing: 6, runSpacing: 6, children: [
      for (final (label, main) in items.take(_maxTags))
        ProfileTag(label, main: main),
      if (items.length > _maxTags)
        ProfileTag('+${items.length - _maxTags} more'),
    ]);
  }

  Widget _fact(IconData icon, String label, Widget value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 14, color: AppColors.textSecondary),
      const SizedBox(width: 6),
      SizedBox(width: 64, child: Text(label, style: GpText.note)),
      Expanded(child: value),
    ]);
  }

  /// What one section shows on Google now.
  Widget _summary(String section, Map<String, dynamic> data) {
    final p = mapOf(data['profile']);
    switch (section) {
      case 'name':
        return _text(str(p['title']));
      case 'categories':
        final primary = mapOf(p['primary_category']);
        return _tags([
          if (str(primary['display_name']).isNotEmpty)
            (str(primary['display_name']), true),
          for (final c in listOf(p['additional_categories']))
            (str(mapOf(c)['display_name']), false),
        ], 'Not set');
      case 'description':
        return _text(str(p['description']));
      case 'contact':
        final phones = [
          str(p['primary_phone']),
          ...listOf(p['additional_phones']).map(str),
        ].where((x) => x.isNotEmpty).toList();
        final website = str(p['website']);
        return GpStack(gap: 6, children: [
          _fact(
              Icons.phone_outlined,
              'Phone',
              phones.isEmpty
                  ? const Text('Not set', style: GpText.muted)
                  : Text(phones.join(', '), style: GpText.lead)),
          _fact(
              Icons.language,
              'Website',
              website.isEmpty
                  ? const Text('Not set', style: GpText.muted)
                  : Align(
                      alignment: Alignment.centerLeft,
                      child: GpLink(
                        website
                            .replaceFirst(RegExp(r'^https?://'), '')
                            .replaceFirst(RegExp(r'/$'), ''),
                        onTap: () => gpOpenUrl(context, website),
                      ),
                    )),
        ]);
      case 'address':
        final a = p['address'] is Map ? mapOf(p['address']) : null;
        final lines = a == null
            ? <String>[]
            : [
                ...listOf(a['address_lines']).map(str),
                [a['locality'], a['administrative_area'], a['postal_code']]
                    .map(str)
                    .where((x) => x.isNotEmpty)
                    .join(', '),
              ].where((x) => x.isNotEmpty).toList();
        return _text(lines.join('\n'));
      case 'service_area':
        if (p['service_area'] is! Map) return _text('');
        final area = mapOf(p['service_area']);
        final places = listOf(area['places']);
        return _text([
          _businessTypeLabels[str(area['business_type'])],
          places.isNotEmpty
              ? places.map((x) => str(mapOf(x)['name'])).join(', ')
              : 'No areas',
        ].whereType<String>().where((x) => x.isNotEmpty).join(' · '));
      case 'hours':
        final hours = listOf(p['regular_hours']).map(mapOf).toList();
        if (hours.isEmpty) return _text('');
        return GpStack(gap: 3, children: [
          for (final day in gpWeekdays)
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 44, child: Text(day.short, style: GpText.label)),
              Expanded(
                child: Builder(builder: (_) {
                  final ranges =
                      hours.where((h) => str(h['day']) == day.id).toList();
                  return Text(
                      ranges.isEmpty ? 'Closed' : ranges.map(_range).join(', '),
                      style: ranges.isEmpty ? GpText.muted : GpText.lead);
                }),
              ),
            ]),
        ]);
      case 'special_hours':
        final days = listOf(p['special_hours']).map(mapOf).toList();
        if (days.isEmpty) return _text('No special dates');
        return _text(
            '${_plural(days.length, 'special date', 'special dates')}: ${days.take(4).map((d) => '${formatDay(str(d['date']))} ${d['closed'] == true ? 'closed' : '${str(d['open'])}–${str(d['close'])}'}').join(', ')}${days.length > 4 ? ', …' : ''}');
      case 'more_hours':
        final types = listOf(data['more_hours_types']).map(mapOf).toList();
        if (types.isEmpty) {
          return _text('Google offers no extra hours for your category.');
        }
        final more = listOf(p['more_hours']).map(mapOf).toList();
        return _text(more.isNotEmpty
            ? more.map((h) {
                final t = types.firstWhere(
                    (t) => str(t['id']) == str(h['type_id']),
                    orElse: () => const <String, dynamic>{});
                return str(t['name']).isNotEmpty
                    ? str(t['name'])
                    : str(h['type_id']);
              }).join(', ')
            : 'None set');
      case 'open_status':
        final os = mapOf(p['open_status']);
        final status = str(os['status']);
        final opening = str(os['opening_date']);
        return _text([
          _openStatusLabels[status] ?? status,
          if (opening.isNotEmpty) 'Opening date ${formatDay(opening)}',
        ].where((x) => x.isNotEmpty).join(' · '));
      case 'services':
        return _tags([
          for (final s in listOf(p['services_on_google']))
            (str(mapOf(s)['label']), false),
        ], 'No services on Google yet');
      case 'attributes':
        final attrs = mapOf(data['attributes']);
        if (listOf(attrs['meta']).isEmpty) {
          return _text('Google offers no attributes for your category.');
        }
        final n = listOf(attrs['values']).length;
        return _text(n > 0 ? '$n set' : 'None set');
    }
    return const SizedBox.shrink();
  }
}
