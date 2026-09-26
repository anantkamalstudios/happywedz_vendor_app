import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';
import '../auth/session_manager.dart';
import '../utils/plan_module_lock.dart';

/// The vendor CRM, mirroring the website's `crmApi` (crmUi.js). Every route is
/// under `/vendor/crm` and is plan-gated: a plan without CRM gets 403
/// PLAN_MODULE_LOCKED, thrown here as [PlanModuleLockedException].
///
/// Money is always in paise (`…Paise`), exactly as the server sends it.
class CrmApi {
  static const String _base = '${ApiConfig.baseUrl}/vendor/crm';

  /// Page size used by the web Clients list.
  static const int pageSize = 25;

  Future<String> _token() async {
    final token = await SessionManager.getToken();
    if (token == null) {
      throw const CrmException(
        'Your session has expired. Please log in again.',
        401,
      );
    }
    return token;
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? params,
  ]) => _send('GET', path, params: params);

  /// JSON request; returns the decoded body or throws [CrmException] with the
  /// server's `message` (the web shows the same text).
  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? params,
    Object? body,
  }) async {
    final req =
        http.Request(
            method,
            Uri.parse('$_base$path').replace(queryParameters: params),
          )
          ..headers.addAll({
            'Accept': 'application/json',
            'Authorization': 'Bearer ${await _token()}',
            if (body != null) 'Content-Type': 'application/json',
          });
    if (body != null) req.body = jsonEncode(body);
    return _decode(await http.Response.fromStream(await req.send()));
  }

  Map<String, dynamic> _decode(http.Response res) {
    throwIfPlanModuleLocked(res);

    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = data is Map ? data['message']?.toString() : null;
      throw CrmException(
        message ?? 'Something went wrong. Please try again.',
        res.statusCode,
      );
    }
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// `{profile: {...}}` — business details printed on quotations/invoices.
  Future<Map<String, dynamic>> profile() => _get('/profile');

  /// Saves business details; the response carries a `message` to show.
  Future<Map<String, dynamic>> saveProfile(Map<String, dynamic> profile) =>
      _send('PUT', '/profile', body: profile);

  /// Uploads a PNG/JPG logo (≤ 3 MB, checked by the caller); returns `{logoUrl}`.
  Future<Map<String, dynamic>> uploadLogo(File file) async {
    final subtype = file.path.toLowerCase().endsWith('.png') ? 'png' : 'jpeg';
    final req = http.MultipartRequest('POST', Uri.parse('$_base/profile/logo'))
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer ${await _token()}',
      })
      ..files.add(
        await http.MultipartFile.fromPath(
          'logo',
          file.path,
          contentType: MediaType('image', subtype),
        ),
      );
    return _decode(await http.Response.fromStream(await req.send()));
  }

  /// Creates a client; returns `{client: {...}}`.
  Future<Map<String, dynamic>> createClient(Map<String, dynamic> client) =>
      _send('POST', '/clients', body: client);

  /// The client list as an Excel file, with the same filters as the list.
  Future<Uint8List> exportClients(Map<String, String> filters) async {
    final res = await http
        .get(
          Uri.parse('$_base/clients/export').replace(queryParameters: filters),
          headers: {'Authorization': 'Bearer ${await _token()}'},
        )
        .timeout(const Duration(seconds: 60));
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    _decode(res); // throws with the server's message
    throw const CrmException('Could not export your clients.', 0);
  }

  // ---------------------------------------------------------------- client
  /// `{client, events, quotations, invoices, payments, files, money, profile,
  /// due, lastReminder, activity, owner}` — everything the details page shows.
  Future<Map<String, dynamic>> client(dynamic id) => _get('/clients/$id');

  Future<Map<String, dynamic>> updateClient(
    dynamic id,
    Map<String, dynamic> body,
  ) => _send('PUT', '/clients/$id', body: body);

  Future<Map<String, dynamic>> deleteClient(dynamic id) =>
      _send('DELETE', '/clients/$id');

  Future<Map<String, dynamic>> owners() => _get('/owners');

  Future<Map<String, dynamic>> setClientOwner(dynamic id, int? ownerId) =>
      _send('POST', '/clients/$id/owner', body: {'ownerId': ownerId});

  Future<Map<String, dynamic>> sendReminder(dynamic id) =>
      _send('POST', '/clients/$id/reminders');

  Future<Map<String, dynamic>> addNote(dynamic id, String body) =>
      _send('POST', '/clients/$id/notes', body: {'body': body});

  Future<Map<String, dynamic>> deleteNote(dynamic noteId) =>
      _send('DELETE', '/notes/$noteId');

  /// Photos (image/*) or PDFs, ≤ 10 MB each, at most 10 per call.
  Future<Map<String, dynamic>> uploadFiles(dynamic id, List<File> files) async {
    final req =
        http.MultipartRequest('POST', Uri.parse('$_base/clients/$id/files'))
          ..headers.addAll({
            'Accept': 'application/json',
            'Authorization': 'Bearer ${await _token()}',
          });
    for (final f in files) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'files',
          f.path,
          contentType: _mediaTypeOf(f.path),
        ),
      );
    }
    final streamed = await req.send().timeout(const Duration(seconds: 120));
    return _decode(await http.Response.fromStream(streamed));
  }

  static MediaType _mediaTypeOf(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      case 'heic':
        return MediaType('image', 'heic');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  Future<Map<String, dynamic>> deleteFile(dynamic fileId) =>
      _send('DELETE', '/files/$fileId');

  // ------------------------------------------------------------ quotations
  Future<Map<String, dynamic>> createQuotation(
    dynamic clientId,
    Map<String, dynamic> body,
  ) => _send('POST', '/clients/$clientId/quotations', body: body);

  Future<Map<String, dynamic>> updateQuotation(
    dynamic id,
    Map<String, dynamic> body,
  ) => _send('PUT', '/quotations/$id', body: body);

  Future<Map<String, dynamic>> deleteQuotation(dynamic id) =>
      _send('DELETE', '/quotations/$id');

  /// `{sendEmail, email?}` → `{link, message}`.
  Future<Map<String, dynamic>> sendQuotation(
    dynamic id,
    Map<String, dynamic> body,
  ) => _send('POST', '/quotations/$id/send', body: body);

  Future<Map<String, dynamic>> setQuotationStatus(dynamic id, String status) =>
      _send('POST', '/quotations/$id/status', body: {'status': status});

  // -------------------------------------------------------------- invoices
  Future<Map<String, dynamic>> createInvoice(
    dynamic clientId,
    Map<String, dynamic> body,
  ) => _send('POST', '/clients/$clientId/invoices', body: body);

  Future<Map<String, dynamic>> sendInvoice(dynamic id) =>
      _send('POST', '/invoices/$id/send', body: <String, dynamic>{});

  Future<Map<String, dynamic>> cancelInvoice(dynamic id, String reason) =>
      _send('POST', '/invoices/$id/cancel', body: {'reason': reason});

  // -------------------------------------------------------------- payments
  Future<Map<String, dynamic>> createPayment(
    dynamic clientId,
    Map<String, dynamic> body,
  ) => _send('POST', '/clients/$clientId/payments', body: body);

  Future<Map<String, dynamic>> deletePayment(dynamic id) =>
      _send('DELETE', '/payments/$id');

  // -------------------------------------------------------------- pipeline
  /// `{columns: [{id, label, count, valuePaise, pendingPaise, more, clients}],
  /// lostReasons}` — same filters as the list (no status), plus `owner`.
  Future<Map<String, dynamic>> board(Map<String, String> params) =>
      _get('/board', params);

  /// Moves a client to another stage. Lost / cancelled carry `reason` and
  /// an optional `note`. Returns `{moved, message}`.
  Future<Map<String, dynamic>> setClientStatus(
    dynamic id,
    Map<String, dynamic> body,
  ) => _send('POST', '/clients/$id/status', body: body);

  // -------------------------------------------------------------- calendar
  /// `{items: [{type: event|follow_up|payment_due, date, clientId, clientName,
  /// title?, venue?, amountPaise?, note?}]}` for `YYYY-MM-DD` [from]..[to].
  Future<Map<String, dynamic>> calendar(String from, String to) =>
      _get('/calendar', {'from': from, 'to': to});

  // ------------------------------------------------------------- analytics
  Future<Map<String, dynamic>> analytics(String from, String to) =>
      _get('/analytics', {'from': from, 'to': to});

  // ------------------------------------------------------------------ team
  /// `{members, roles, seatsUsed, seatLimit, unassigned}`.
  Future<Map<String, dynamic>> team() => _get('/team');

  /// `{name, email, role}` → `{member, link, message}`. Also used to resend.
  Future<Map<String, dynamic>> inviteTeamMember(Map<String, dynamic> body) =>
      _send('POST', '/team', body: body);

  Future<Map<String, dynamic>> updateTeamMember(
    dynamic id,
    Map<String, dynamic> body,
  ) => _send('PUT', '/team/$id', body: body);

  Future<Map<String, dynamic>> removeTeamMember(dynamic id) =>
      _send('DELETE', '/team/$id');

  // -------------------------------------------------------------- WhatsApp
  /// `{whatsapp: {connected, ...}}` — whether the vendor has connected a
  /// WhatsApp Business number. When connected, documents are sent by the
  /// server as WhatsApp templates instead of opening a `wa.me` chat.
  Future<Map<String, dynamic>> whatsapp() => _get('/whatsapp');

  /// Sends a quotation / invoice / payment receipt to the client as a WhatsApp
  /// template from the connected number. Returns `{message}`.
  Future<Map<String, dynamic>> sendOnWhatsapp(CrmDocType type, dynamic id) =>
      _send('POST', '/${type.path}/$id/whatsapp');

  // ------------------------------------------------------------------ PDFs
  static String quotationPdf(dynamic id) => '/quotations/$id/pdf';
  static String invoicePdf(dynamic id) => '/invoices/$id/pdf';
  static String receiptPdf(dynamic id) => '/payments/$id/receipt';

  /// Downloads a quotation / invoice / receipt PDF (paths above).
  Future<Uint8List> downloadPdf(String path) async {
    final res = await http
        .get(
          Uri.parse('$_base$path'),
          headers: {'Authorization': 'Bearer ${await _token()}'},
        )
        .timeout(const Duration(seconds: 60));
    if (res.statusCode >= 200 && res.statusCode < 300) return res.bodyBytes;
    _decode(res);
    throw const CrmException('Could not open the file.', 0);
  }

  /// `{summary: {...}, viewer: {...}}` — the four stat cards, upcoming events,
  /// follow-ups due and overdue payments.
  Future<Map<String, dynamic>> summary() => _get('/summary');

  /// `{clients: [...], total}`. Filters use the web's ids: status
  /// (`all`, `lead`, `quoted`, …), source, payment (`pending`, `overdue`,
  /// `cleared`), sort (`newest`, `event`, `balance`, `name`), followup (`due`).
  Future<Map<String, dynamic>> clients({
    String? q,
    String status = 'all',
    String source = 'all',
    String payment = 'all',
    String sort = 'newest',
    String? followup,
    int page = 1,
  }) {
    return _get('/clients', {
      ...filters(
        q: q,
        status: status,
        source: source,
        payment: payment,
        sort: sort,
        followup: followup,
      ),
      'page': '$page',
      'limit': '$pageSize',
    });
  }

  /// List filters as query parameters — shared by the list and the export.
  static Map<String, String> filters({
    String? q,
    String status = 'all',
    String source = 'all',
    String payment = 'all',
    String sort = 'newest',
    String? followup,
  }) => {
    if (q != null && q.isNotEmpty) 'q': q,
    'status': status,
    'source': source,
    'payment': payment,
    'sort': sort,
    if (followup != null) 'followup': followup,
  };

  /// A logo/upload path as the server returns it → a loadable URL (same rule
  /// as the web: relative paths live under `/uploads/`).
  static String? imageUrl(String? path) {
    final p = path?.replaceAll('`', '').trim() ?? '';
    if (p.isEmpty) return null;
    if (p.startsWith('http://') ||
        p.startsWith('https://') ||
        p.startsWith('data:')) {
      return p;
    }
    return '${ApiConfig.baseUrl}${p.startsWith('/') ? p : '/uploads/$p'}';
  }
}

/// A document the CRM can send to a client, with its route segment.
enum CrmDocType {
  quotation('quotations'),
  invoice('invoices'),
  receipt('payments');

  final String path;
  const CrmDocType(this.path);
}

class CrmException implements Exception {
  final String message;
  final int statusCode;
  const CrmException(this.message, this.statusCode);

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Option lists, verbatim from the web CRM so ids and labels match.
class CrmOptions {
  CrmOptions._();

  static const leadSources = {
    'happywedz': 'HappyWedz',
    'instagram': 'Instagram',
    'facebook': 'Facebook',
    'google': 'Google',
    'referral': 'Referral',
    'website': 'Website',
    'walk_in': 'Walk-in',
    'whatsapp': 'WhatsApp',
    'other': 'Other',
  };

  static const statuses = {
    'lead': 'Lead',
    'quoted': 'Quoted',
    'booked': 'Booked',
    'completed': 'Completed',
    'lost': 'Lost',
    'cancelled': 'Cancelled',
  };

  static const lostReasons = {
    'budget': 'Budget too high',
    'no_response': 'No response',
    'date_unavailable': 'Date not available',
    'other_vendor': 'Chose another vendor',
    'postponed': 'Event postponed',
    'other': 'Other',
  };

  static const eventSuggestions = [
    'Roka',
    'Engagement',
    'Mehendi',
    'Haldi',
    'Sangeet',
    'Cocktail',
    'Wedding',
    'Reception',
    'Pre-wedding shoot',
  ];

  static const gstRates = [0, 5, 12, 18, 28];

  static const states = [
    'Andaman and Nicobar Islands',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chandigarh',
    'Chhattisgarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu and Kashmir',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Ladakh',
    'Lakshadweep',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Puducherry',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
  ];

  /// GSTIN state codes, for the "a Maharashtra GSTIN starts with 27" check.
  static const gstStateCodes = {
    'Jammu and Kashmir': '01',
    'Himachal Pradesh': '02',
    'Punjab': '03',
    'Chandigarh': '04',
    'Uttarakhand': '05',
    'Haryana': '06',
    'Delhi': '07',
    'Rajasthan': '08',
    'Uttar Pradesh': '09',
    'Bihar': '10',
    'Sikkim': '11',
    'Arunachal Pradesh': '12',
    'Nagaland': '13',
    'Manipur': '14',
    'Mizoram': '15',
    'Tripura': '16',
    'Meghalaya': '17',
    'Assam': '18',
    'West Bengal': '19',
    'Jharkhand': '20',
    'Odisha': '21',
    'Chhattisgarh': '22',
    'Madhya Pradesh': '23',
    'Gujarat': '24',
    'Dadra and Nagar Haveli and Daman and Diu': '26',
    'Maharashtra': '27',
    'Karnataka': '29',
    'Goa': '30',
    'Lakshadweep': '31',
    'Kerala': '32',
    'Tamil Nadu': '33',
    'Puducherry': '34',
    'Andaman and Nicobar Islands': '35',
    'Telangana': '36',
    'Andhra Pradesh': '37',
    'Ladakh': '38',
  };

  static final gstinPattern = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
  );

  static const paymentMethods = {
    'cash': 'Cash',
    'upi': 'UPI',
    'bank_transfer': 'Bank transfer',
    'card': 'Card',
    'cheque': 'Cheque',
    'other': 'Other',
  };

  static const quotationStatuses = {
    'draft': 'Draft',
    'sent': 'Sent',
    'accepted': 'Accepted',
    'rejected': 'Declined',
    'expired': 'Expired',
  };

  static const invoicePaymentStates = {
    'unpaid': 'Unpaid',
    'part_paid': 'Part paid',
    'paid': 'Paid',
    'cancelled': 'Cancelled',
  };

  static const taxModeHints = {
    'none': 'No GST — add your GSTIN in Business details to charge GST.',
    'intra': 'CGST + SGST — the client is in your state (or no state is set).',
    'inter': 'IGST — the client is in another state.',
  };

  static const payments = {
    'pending': 'Payment pending',
    'overdue': 'Payment overdue',
    'cleared': 'Fully paid',
  };

  static const sorts = {
    'newest': 'Newest first',
    'event': 'Event date',
    'balance': 'Highest balance',
    'name': 'Name A–Z',
  };
}

/// Formatting helpers matching the web (`₹28,32,000`, `15 Oct 2026`).
class CrmFormat {
  CrmFormat._();

  static final NumberFormat _whole = NumberFormat('#,##,##0', 'en_IN');
  static final NumberFormat _decimal = NumberFormat('#,##,##0.00', 'en_IN');

  /// `decimals: true` always shows paise (`₹4,000.00`), as the web does on
  /// quotation/invoice totals.
  static String rupees(dynamic paise, {bool decimals = false}) {
    final rupees = ((num.tryParse('$paise') ?? 0).round()) / 100;
    final whole = !decimals && rupees % 1 == 0;
    return '₹${whole ? _whole.format(rupees) : _decimal.format(rupees)}';
  }

  /// Paise → the plain rupee string an input box starts with ("400000").
  static String paiseToInput(dynamic paise) {
    if (paise == null || '$paise'.isEmpty) return '';
    final r = ((num.tryParse('$paise') ?? 0).round()) / 100;
    return r % 1 == 0 ? r.toInt().toString() : r.toStringAsFixed(2);
  }

  /// "24 Sept 2026, 3:05 pm" — activity timestamps.
  static String dateTime(dynamic value) {
    final d = value == null ? null : DateTime.tryParse('$value')?.toLocal();
    return d == null ? '' : DateFormat('d MMM yyyy, h:mm a').format(d);
  }

  /// `YYYY-MM-DD` [days] from today.
  static String inDays(int days) =>
      DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: days)));

  /// `YYYY-MM-DD` dates are calendar days, not instants — parsed as local.
  static DateTime? parseDate(dynamic value) {
    if (value == null || '$value'.isEmpty) return null;
    final s = '$value';
    final d = DateTime.tryParse(s.length == 10 ? '${s}T00:00:00' : s);
    return d?.toLocal();
  }

  /// A rupee amount typed by the vendor ("1,00,000" or "2500.50") → paise.
  /// Empty → 0; not a valid non-negative number → null.
  static int? toPaise(String input) {
    final t = input.replaceAll(',', '').trim();
    if (t.isEmpty) return 0;
    final n = double.tryParse(t);
    return n == null || n < 0 || !n.isFinite ? null : (n * 100).round();
  }

  static String date(dynamic value) {
    final d = parseDate(value);
    return d == null ? '' : DateFormat('d MMM yyyy').format(d);
  }

  /// Today as `YYYY-MM-DD`, for comparing against due dates like the web does.
  static String today() => DateFormat('yyyy-MM-dd').format(DateTime.now());
}

/// GST maths, identical to the web's so totals match to the paisa.
class CrmTax {
  CrmTax._();

  /// `none` (no GSTIN), `intra` (same state or no client state), `inter`.
  static String mode(Map? profile, String? clientState) {
    final gstin = '${profile?['gstin'] ?? ''}'.trim();
    if (gstin.isEmpty) return 'none';
    final client = (clientState ?? '').trim();
    if (client.isEmpty) return 'intra';
    final own = '${profile?['state'] ?? ''}'.trim().toLowerCase();
    return own == client.toLowerCase() ? 'intra' : 'inter';
  }

  /// Lines are `{quantity, rate (rupee text), gstRate}`; the discount is
  /// spread across lines in proportion before tax, as on the web.
  static CrmTotals totals(List<CrmLine> lines, int discountPaise, String mode) {
    final amounts = lines.map((l) {
      final qty = double.tryParse(l.quantity) ?? 0;
      final rate = CrmFormat.toPaise(l.rate) ?? 0;
      return (qty * rate).round();
    }).toList();
    final rates = lines
        .map((l) => mode == 'none' ? 0 : (int.tryParse(l.gstRate) ?? 0))
        .toList();
    final subtotal = amounts.fold<int>(0, (a, b) => a + b);
    final discount = discountPaise.clamp(0, subtotal);
    var spread = 0, half = 0, igst = 0;
    for (var i = 0; i < amounts.length; i++) {
      final share = i == amounts.length - 1
          ? discount - spread
          : (subtotal == 0 ? 0 : (discount * amounts[i] / subtotal).round());
      spread += share;
      final taxable = amounts[i] - share;
      if (mode == 'intra') half += (taxable * rates[i] / 200).round();
      if (mode == 'inter') igst += (taxable * rates[i] / 100).round();
    }
    final tax = half * 2 + igst;
    return CrmTotals(
      subtotal: subtotal,
      discount: discount,
      cgst: half,
      sgst: half,
      igst: igst,
      tax: tax,
      total: subtotal - discount + tax,
      lineAmounts: amounts,
    );
  }
}

/// One editable quotation/invoice line, as the web's item editor holds it.
class CrmLine {
  String description;
  String quantity;
  String rate; // rupees, as typed
  String gstRate;
  String sac;

  CrmLine({
    this.description = '',
    this.quantity = '1',
    this.rate = '',
    this.gstRate = '18',
    this.sac = '',
  });

  /// From the client's events (new quotation / invoice starts here).
  static List<CrmLine> fromEvents(List events, int gstRate, String sac) =>
      events
          .map(
            (e) => CrmLine(
              description: [
                e['name'],
                e['eventDate'] == null ? null : CrmFormat.date(e['eventDate']),
                e['venue'],
              ].where((x) => x != null && '$x'.isNotEmpty).join(' – '),
              rate: CrmFormat.paiseToInput(e['pricePaise']),
              gstRate: '$gstRate',
              sac: sac,
            ),
          )
          .toList();

  /// From a saved quotation's items (editing it).
  static List<CrmLine> fromItems(List items) => items
      .map(
        (i) => CrmLine(
          description: [
            i['eventName'],
            i['description'],
          ].where((x) => x != null && '$x'.isNotEmpty).join(' – '),
          quantity: '${i['quantity'] ?? 1}',
          rate: CrmFormat.paiseToInput(i['ratePaise']),
          gstRate: '${i['gstRate'] ?? 0}',
          sac: '${i['sac'] ?? ''}',
        ),
      )
      .toList();

  Map<String, dynamic> toJson() => {
    'description': description.trim(),
    'quantity': double.tryParse(quantity) ?? 0,
    'ratePaise': CrmFormat.toPaise(rate),
    'gstRate': int.tryParse(gstRate) ?? 0,
    if (sac.isNotEmpty) 'sac': sac,
  };

  /// Same checks and wording as the web; null when every line is fine.
  static String? validate(List<CrmLine> lines) {
    if (lines.isEmpty) return 'Add at least one item.';
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i];
      if (l.description.trim().isEmpty) {
        return 'Item ${i + 1} needs a description.';
      }
      if (!((double.tryParse(l.quantity) ?? 0) > 0)) {
        return 'Item ${i + 1}: quantity must be more than 0.';
      }
      if (l.rate.trim().isEmpty || CrmFormat.toPaise(l.rate) == null) {
        return 'Item ${i + 1}: enter a rate.';
      }
    }
    return null;
  }
}

class CrmTotals {
  final int subtotal, discount, cgst, sgst, igst, tax, total;
  final List<int> lineAmounts;
  const CrmTotals({
    required this.subtotal,
    required this.discount,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.tax,
    required this.total,
    required this.lineAmounts,
  });
}

/// WhatsApp links and the web's ready-made messages, word for word.
class CrmShare {
  CrmShare._();

  static const _site = 'https://happywedz.com';

  static String quotationLink(dynamic token) => '$_site/crm/quote/$token';
  static String invoiceLink(dynamic token) => '$_site/crm/doc/invoice/$token';
  static String receiptLink(dynamic token) => '$_site/crm/doc/receipt/$token';

  /// Indian numbers get the 91 prefix; returns '' when unusable.
  static String _phone(String? phone) {
    var d = (phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (d.length == 11 && d.startsWith('0')) d = d.substring(1);
    if (d.length == 10) d = '91$d';
    return d.length >= 11 ? d : '';
  }

  static Uri whatsapp(String? phone, [String text = '']) => Uri.parse(
    'https://wa.me/${_phone(phone)}${text.isEmpty ? '' : '?text=${Uri.encodeComponent(text)}'}',
  );

  static String _first(dynamic name) {
    final f = '${name ?? ''}'.split(RegExp(r'[\s&,]+')).first;
    return f.isEmpty ? 'there' : f;
  }

  static String _join(List<String> parts) =>
      parts.where((p) => p.isNotEmpty).join('\n\n');

  static String quotation(Map client, String seller, Map q) => _join([
    'Hi ${_first(client['name'])}, here is your quotation ${q['number']} from $seller for ${CrmFormat.rupees(q['totalPaise'])}.',
    'View and accept it here: ${quotationLink(q['publicToken'])}',
  ]);

  static String invoice(Map client, String seller, Map inv) {
    final paid = (inv['paidPaise'] as num?) ?? 0;
    final total = (inv['totalPaise'] as num?) ?? 0;
    return _join([
      'Hi ${_first(client['name'])}, please find invoice ${inv['number']} from $seller for ${CrmFormat.rupees(total)}.'
          '${paid > 0 ? ' Received so far: ${CrmFormat.rupees(paid)}. Balance: ${CrmFormat.rupees(total - paid < 0 ? 0 : total - paid)}.' : ''}',
      invoiceLink(inv['publicToken']),
    ]);
  }

  static String receipt(Map client, String seller, Map p) => _join([
    'Hi ${_first(client['name'])}, we have received ${CrmFormat.rupees(p['amountPaise'])} on ${CrmFormat.date(p['paidOn'])}. Thank you!',
    'Receipt ${p['receiptNumber']}: ${receiptLink(p['publicToken'])}',
    '– $seller',
  ]);

  static String reminder(
    Map client,
    String seller,
    Map? due,
    dynamic amountPaise,
    String? upiId,
  ) => _join([
    'Hi ${_first(client['name'])}, a gentle reminder that ${CrmFormat.rupees(amountPaise)} is pending'
        '${due?['date'] != null ? ', due on ${CrmFormat.date(due!['date'])}' : ''}.',
    due?['invoiceToken'] != null
        ? 'Invoice ${due!['invoiceNumber']}: ${invoiceLink(due['invoiceToken'])}'
        : '',
    (upiId ?? '').isNotEmpty ? 'UPI: $upiId' : '',
    "If you've already paid, please ignore this. Thank you!\n– $seller",
  ]);
}
