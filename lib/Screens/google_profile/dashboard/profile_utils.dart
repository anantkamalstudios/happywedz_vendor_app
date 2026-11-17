// Small helpers of the Profile tab (website dashboard/ProfileUtils.js).
// Limits and rules mirror GrowthOS's contracts (growthos-web/src/contracts/google.ts).
import 'package:intl/intl.dart';

import '../../../api_services/google_profile_api.dart';
import '../gp_format.dart';

/// Google's limits (PROFILE_LIMITS in GrowthOS).
class GpProfileLimits {
  GpProfileLimits._();
  static const int description = 750;
  static const int additionalCategories = 9;
  static const int additionalPhones = 2;
  static const int places = 20;
  static const int specialDays = 50;
}

final RegExp _timeRe = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');
bool profileIsTime(String? value) => _timeRe.hasMatch(value ?? '');

/// A web address starting with http:// or https://.
bool profileIsHttpUrl(Object? value) => isWebAddress('${value ?? ''}'.trim());

/// One opening–closing range of a day.
class ProfileRange {
  String open;
  String close;
  ProfileRange({this.open = '', this.close = ''});
  ProfileRange copy() => ProfileRange(open: open, close: close);
}

/// { mon: [ranges], … }; a day with no ranges is closed.
typedef ProfileWeek = Map<String, List<ProfileRange>>;

/// GrowthOS periods [{ day, open, close }] → the editor's week.
ProfileWeek profileToWeek([List<dynamic> periods = const []]) {
  final week = <String, List<ProfileRange>>{for (final d in gpWeekdayIds) d: []};
  for (final p in periods) {
    final m = mapOf(p);
    final day = str(m['day']);
    if (week.containsKey(day)) {
      week[day]!.add(ProfileRange(open: str(m['open']), close: str(m['close'])));
    }
  }
  return week;
}

List<Map<String, dynamic>> profileFromWeek(ProfileWeek week) => [
      for (final day in gpWeekdayIds)
        for (final r in week[day] ?? const <ProfileRange>[])
          {'day': day, 'open': r.open, 'close': r.close},
    ];

/// Problems of one week as { "mon.0": message } (GrowthOS weekSchema rules).
Map<String, String> profileWeekErrors(ProfileWeek week, [String prefix = '']) {
  final out = <String, String>{};
  for (final day in gpWeekdayIds) {
    final ranges = week[day] ?? const <ProfileRange>[];
    for (var i = 0; i < ranges.length; i++) {
      final r = ranges[i];
      final key = '$prefix$day.$i';
      if (r.open.isEmpty || r.close.isEmpty) {
        out[key] = 'Set an opening and a closing time.';
      } else if (!profileIsTime(r.open) ||
          !(profileIsTime(r.close) || r.close == '24:00')) {
        out[key] = 'Enter a time like 09:30.';
      } else if (r.close != '24:00' && r.close.compareTo(r.open) <= 0) {
        out[key] = 'The closing time must be after the opening time.';
      }
    }
  }
  return out;
}

/// "₹1,500.00" in the profile's currency; plain number when unknown.
String profileMoney(Object? value, [String? currency]) {
  if (value is! num) return '';
  final code = (currency == null || currency.isEmpty) ? 'INR' : currency;
  try {
    return NumberFormat.currency(
      locale: 'en_IN',
      name: code,
      symbol: NumberFormat.simpleCurrency(locale: 'en_IN', name: code)
          .currencySymbol,
      decimalDigits: 2,
    ).format(value);
  } catch (_) {
    return '$value';
  }
}

/// The server's field messages (validation_error → details.fields), distinct.
List<String> profileFieldMessages(Object? error) {
  if (error is! GpException) return const [];
  final details = error.body['details'];
  final fields = details is Map ? details['fields'] : null;
  if (fields is! List) return const [];
  final out = <String>[];
  for (final f in fields) {
    if (f is Map && f['message'] is String && !out.contains(f['message'])) {
      out.add(f['message'] as String);
    }
  }
  return out;
}

/// "2026-10-21" for a date.
String profileIsoDay(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The profile answer in the shape the forms expect (missing lists → empty).
Map<String, dynamic> profileNormalise(Object? raw) {
  final r = mapOf(raw);
  final p = mapOf(r['profile']);
  List<dynamic> list(Object? v) => v is List ? v : <dynamic>[];
  final attrs = mapOf(r['attributes']);
  return {
    ...r,
    'profile': {
      ...p,
      'title': str(p['title']),
      'description': str(p['description']),
      'additional_categories': list(p['additional_categories']),
      'additional_phones': list(p['additional_phones']),
      'regular_hours': list(p['regular_hours']),
      'special_hours': list(p['special_hours']),
      'more_hours': list(p['more_hours']),
      'services_on_google': list(p['services_on_google']),
      'open_status': p['open_status'] is Map
          ? mapOf(p['open_status'])
          : {'status': 'OPEN', 'opening_date': null},
    },
    'more_hours_types': list(r['more_hours_types']),
    'attributes': {
      'meta': list(attrs['meta']),
      'values': list(attrs['values']),
    },
    'growthos_services': list(r['growthos_services']),
    'currency': str(r['currency']).isEmpty ? 'INR' : str(r['currency']),
    'unavailable': list(r['unavailable']).map((e) => '$e').toList(),
  };
}

/// The region code of the profile's address, or "IN".
String profileRegion(Map<String, dynamic> profile) {
  final code = str(mapOf(profile['address'])['region_code']);
  return RegExp(r'^[A-Z]{2}$').hasMatch(code) ? code : 'IN';
}
