// Small helpers shared by the Google Profile screens (website gpFormat.js).
import 'package:intl/intl.dart';

const String growthosPrivacyUrl = 'https://gmb.aslai.cloud/legal/privacy';
const String growthosTermsUrl = 'https://gmb.aslai.cloud/legal/terms';
const String growthosLoginFallback = 'https://gmb.aslai.cloud/login';

const List<String> gpSteps = [
  'Send details',
  'Your account',
  'Connect Google',
  'Google verification',
  'Live on Google',
];

/// How many steps are finished on each screen. 5 = all done ("live").
const Map<String, int> gpStepForScreen = {
  'start': 0,
  'taken': 0,
  'approve': 1,
  'invited': 1,
  'expired': 1,
  'connect': 2,
  'pick': 2,
  'verify': 3,
  'live': 5,
};

class GpWeekday {
  final String id;
  final String short;
  final String long;
  const GpWeekday(this.id, this.short, this.long);
}

const List<GpWeekday> gpWeekdays = [
  GpWeekday('mon', 'Mon', 'Monday'),
  GpWeekday('tue', 'Tue', 'Tuesday'),
  GpWeekday('wed', 'Wed', 'Wednesday'),
  GpWeekday('thu', 'Thu', 'Thursday'),
  GpWeekday('fri', 'Fri', 'Friday'),
  GpWeekday('sat', 'Sat', 'Saturday'),
  GpWeekday('sun', 'Sun', 'Sunday'),
];

final List<String> gpWeekdayIds = gpWeekdays.map((d) => d.id).toList();

/// "HH:MM" from anything the storefront sends ("10:00 AM", "9:30"), or "".
String toTimeInput(Object? value) {
  if (value is! String) return '';
  final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*([aApP][mM])?$')
      .firstMatch(value.trim());
  if (match == null) return '';
  var hours = int.parse(match.group(1)!);
  final minutes = int.parse(match.group(2)!);
  final meridiem = match.group(3)?.toLowerCase();
  if (meridiem == 'pm' && hours < 12) hours += 12;
  if (meridiem == 'am' && hours == 12) hours = 0;
  if (hours > 23 || minutes > 59) return '';
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

DateTime? gpDate(Object? iso) {
  if (iso == null) return null;
  final s = iso.toString();
  if (s.isEmpty) return null;
  return DateTime.tryParse(s)?.toLocal();
}

/// "14:05", in the vendor's own time.
String formatClock(Object? iso) {
  final d = gpDate(iso);
  if (d == null) return '';
  return DateFormat('HH:mm').format(d);
}

/// "21 Oct, 14:05".
String formatWhen(Object? iso) {
  final d = gpDate(iso);
  if (d == null) return '';
  return '${DateFormat('d MMM').format(d)}, ${formatClock(iso)}';
}

/// "21 Oct 2026".
String formatDay(Object? iso) {
  final d = gpDate(iso);
  if (d == null) return '';
  return DateFormat('d MMM yyyy').format(d);
}

/// Milliseconds until [iso]; 0 when it is now or past.
int msUntil(Object? iso) {
  final d = gpDate(iso);
  if (d == null) return 0;
  final ms = d.difference(DateTime.now()).inMilliseconds;
  return ms > 0 ? ms : 0;
}

const int emailMax = 254;
bool isEmail(String value) =>
    value.length <= emailMax &&
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value);
bool sameEmail(String? a, String? b) =>
    a != null && b != null && a.trim().toLowerCase() == b.trim().toLowerCase();

String initials(Object? name) {
  final words = (name ?? '')
      .toString()
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'G';
  return words.take(2).map((w) => w[0].toUpperCase()).join();
}

const String googleBusinessUrl = 'https://business.google.com/';
const String googleHelpSuspended =
    'https://support.google.com/business/answer/4569145';
const String googleHelpOwnership =
    'https://support.google.com/business/answer/4566671';

/// The plain message for Google's connect error code.
String connectErrorText(String code) =>
    (code == 'denied' || code == 'cancelled' || code == 'access_denied')
        ? "You didn't allow access. Press Connect Google and choose Allow."
        : 'Google could not be connected. Please try again.';

class GpVerifyMethod {
  final String label;
  final String help;
  final String sent;
  const GpVerifyMethod(this.label, this.help, this.sent);
}

const Map<String, GpVerifyMethod> verifyMethods = {
  'ADDRESS': GpVerifyMethod(
    'Postcard',
    'Google posts a code to the business address.',
    'A postcard with your code is on its way to the business address. It usually takes a few days. Enter the code when it arrives.',
  ),
  'PHONE_CALL': GpVerifyMethod(
    'Phone call',
    'Google calls the business phone and reads out a code.',
    'Google is calling the business phone with your code. Enter it here.',
  ),
  'SMS': GpVerifyMethod(
    'Text message',
    'Google texts a code to the business phone.',
    'Google sent your code by text message. Enter it here.',
  ),
  'EMAIL': GpVerifyMethod(
    'Email',
    'Google emails a code.',
    'Google sent your code by email. Enter it here.',
  ),
  'AUTO': GpVerifyMethod(
    'Verify now',
    'Google can verify this business straight away.',
    'Google is checking your business.',
  ),
};

/// The verification code: 4 to 8 letters or numbers.
bool isVerifyCode(String value) =>
    RegExp(r'^[0-9A-Za-z]{4,8}$').hasMatch(value.trim());

// ── The new profile form ──────────────────────────────────────────────────

class ProfileLimits {
  static const int title = 100;
  static const int address = 80;
  static const int locality = 80;
  static const int administrativeArea = 80;
  static const int postalCode = 12;
  static const int phone = 20;
  static const int description = 750;
}

final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

bool isWebAddress(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty;
}

/// The create form's values (website profileFormFrom).
class GpProfileForm {
  String accountName;
  String locationId;
  String title;
  String category;
  String categoryName;
  String regionCode;
  String addressLine1;
  String addressLine2;
  String locality;
  String administrativeArea;
  String postalCode;
  String phone;
  String website;
  String description;
  bool withHours;
  List<String> days;
  String open;
  String close;

  GpProfileForm({
    this.accountName = '',
    this.locationId = '',
    this.title = '',
    this.category = '',
    this.categoryName = '',
    this.regionCode = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.locality = '',
    this.administrativeArea = '',
    this.postalCode = '',
    this.phone = '',
    this.website = '',
    this.description = '',
    this.withHours = false,
    List<String>? days,
    this.open = '',
    this.close = '',
  }) : days = days ?? [];

  factory GpProfileForm.from(Map prefill, String account) {
    final f = prefill['form'] is Map ? prefill['form'] as Map : const {};
    final lines = f['address_lines'] is List
        ? (f['address_lines'] as List).map((e) => '$e').toList()
        : <String>[];
    final hours = f['hours'] is Map ? f['hours'] as Map : null;
    final locs = prefill['locations'] is List ? prefill['locations'] as List : const [];
    final cat = f['category'] is Map ? f['category'] as Map : const {};
    return GpProfileForm(
      accountName: account,
      locationId: _s(f['location_id']).isNotEmpty
          ? _s(f['location_id'])
          : (locs.isNotEmpty && locs.first is Map ? _s((locs.first as Map)['id']) : ''),
      title: _s(f['title']),
      category: _s(cat['name']),
      categoryName: _s(cat['display_name']),
      regionCode: _s(f['region_code']),
      addressLine1: lines.isNotEmpty ? lines.first : '',
      addressLine2: lines.skip(1).join(', '),
      locality: _s(f['locality']),
      administrativeArea: _s(f['administrative_area']),
      postalCode: _s(f['postal_code']),
      phone: _s(f['phone']),
      website: _s(f['website']),
      description: _s(f['description']),
      withHours: hours != null,
      days: hours?['days'] is List
          ? (hours!['days'] as List)
              .map((e) => '$e')
              .where(gpWeekdayIds.contains)
              .toList()
          : <String>[],
      open: toTimeInput(hours?['open']),
      close: toTimeInput(hours?['close']),
    );
  }

  /// { field: message } for every value that is not right yet.
  Map<String, String> check() {
    final errors = <String, String>{};
    void need(String field, String value, String message, int max) {
      final v = value.trim();
      if (v.isEmpty) {
        errors[field] = message;
      } else if (v.length > max) {
        errors[field] = 'Use at most $max characters.';
      }
    }

    if (accountName.isEmpty) errors['account_name'] = 'Choose a Google business account.';
    if (locationId.isEmpty) errors['location_id'] = 'Choose a location.';
    need('title', title, 'Enter the business name.', ProfileLimits.title);
    if (category.isEmpty) {
      errors['category'] = "Search and choose a category from Google's list.";
    }
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(regionCode)) {
      errors['region_code'] = 'The country is missing. Contact HappyWedz support.';
    }
    need('address_line1', addressLine1, 'Enter the street address.', ProfileLimits.address);
    if (addressLine2.trim().length > ProfileLimits.address) {
      errors['address_line2'] = 'Use at most ${ProfileLimits.address} characters.';
    }
    need('locality', locality, 'Enter the city.', ProfileLimits.locality);
    need('administrative_area', administrativeArea, 'Enter the state.',
        ProfileLimits.administrativeArea);
    need('postal_code', postalCode, 'Enter the PIN code.', ProfileLimits.postalCode);
    if (phone.trim().length > ProfileLimits.phone) {
      errors['phone'] = 'Use at most ${ProfileLimits.phone} characters.';
    }
    final site = website.trim();
    if (site.isNotEmpty && !isWebAddress(site)) {
      errors['website'] = 'Enter a valid web address, starting with https://';
    }
    if (description.trim().length > ProfileLimits.description) {
      errors['description'] = 'Google allows up to ${ProfileLimits.description} characters.';
    }
    if (withHours) {
      if (days.isEmpty) errors['days'] = 'Choose the days you are open.';
      if (open.isEmpty) {
        errors['open'] = 'Enter the opening time.';
      } else if (!_time.hasMatch(open)) {
        errors['open'] = 'Enter a time like 09:30.';
      }
      if (close.isEmpty) {
        errors['close'] = 'Enter the closing time.';
      } else if (!_time.hasMatch(close)) {
        errors['close'] = 'Enter a time like 18:00.';
      }
      if (!errors.containsKey('open') &&
          !errors.containsKey('close') &&
          close.compareTo(open) <= 0) {
        errors['close'] = 'Closing time must be after opening time.';
      }
    }
    return errors;
  }

  /// The body GrowthOS takes for create/check and create.
  Map<String, dynamic> body() => {
        'account_name': accountName,
        'location_id': locationId,
        'title': title.trim(),
        'category': category,
        'category_name': categoryName,
        'region_code': regionCode,
        'address_lines': [addressLine1, addressLine2]
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList(),
        'locality': locality.trim(),
        'administrative_area': administrativeArea.trim(),
        'postal_code': postalCode.trim(),
        'phone': phone.trim().isEmpty ? null : phone.trim(),
        'website': website.trim().isEmpty ? null : website.trim(),
        'description': description.trim().isEmpty ? null : description.trim(),
        'hours': withHours
            ? {
                'days': gpWeekdayIds.where(days.contains).toList(),
                'open': open,
                'close': close,
              }
            : null,
      };
}

String _s(Object? v) => v == null ? '' : v.toString();

const Map<String, String> _fieldOfPath = {
  'address_lines': 'address_line1',
  'address_lines.0': 'address_line1',
  'address_lines.1': 'address_line2',
  'hours': 'days',
  'hours.days': 'days',
  'hours.open': 'open',
  'hours.close': 'close',
};

/// The server's field messages (validation_error → details.fields).
Map<String, String> serverFieldErrors(Map<String, dynamic> body) {
  final details = body['details'];
  final fields = (details is Map ? details['fields'] : null) ?? body['fields'];
  if (fields is! List) return {};
  final out = <String, String>{};
  for (final f in fields) {
    if (f is! Map || f['message'] is! String) continue;
    final p = f['path'];
    final path = p is List ? p.join('.') : (p ?? '').toString();
    final field = _fieldOfPath[path] ?? path.split('.').first;
    if (field.isNotEmpty && !out.containsKey(field)) out[field] = f['message'];
  }
  return out;
}

/// Safe readers for loosely-typed JSON.
String str(Object? v) => v == null ? '' : v.toString();
Map<String, dynamic> mapOf(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<dynamic> listOf(Object? v) => v is List ? v : const [];
num? numOf(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');
