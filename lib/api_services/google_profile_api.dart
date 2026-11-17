import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/api_config.dart';
import '../utils/plan_module_lock.dart';

/// The vendor's Google Business Profile, set up through GrowthOS AI (a
/// HappyWedz partner). Mirrors the website's `googleProfileApi.js`
/// (`googleProfileApi`, `gpManageApi`, `assistantApi`): same paths, same
/// methods, same bodies. Every route is under `/vendor/google-profile` and is
/// plan-gated (`google_profile`): a plan without it gets 403
/// PLAN_MODULE_LOCKED, thrown here as [PlanModuleLockedException].
///
/// Like the website's `view()`, each call resolves to the answer's `data`
/// (or null); list calls that also carry `meta` resolve to a [GpPage].
/// Any other failure is thrown as [GpException], whose [GpException.code] is
/// the server's `code` (validation_error, email_taken, too_soon …), or
/// `http_<status>` when it sent none, or `network` when no answer came back.
class GoogleProfileApi {
  GoogleProfileApi._();
  static final GoogleProfileApi instance = GoogleProfileApi._();
  factory GoogleProfileApi() => instance;

  /// The path prefix, as the website's BASE. Server-served images are under
  /// `$basePath/images/<id>` and need the bearer token to load.
  static const String basePath = '/vendor/google-profile';
  static const String _base = '${ApiConfig.baseUrl}$basePath';
  static const String _assistant = '$_base/assistant';

  /// The website's default axios timeout.
  static const Duration _normal = Duration(seconds: 30);

  /// AI writing and "sync now" can take up to a minute on GrowthOS (website SLOW).
  static const Duration _slow = Duration(seconds: 100);

  static Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static String _enc(String value) => Uri.encodeComponent(value);

  Future<Map<String, String>> _headers({bool json = false}) async {
    final t = await token();
    return {
      'Accept': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
      if (json) 'Content-Type': 'application/json',
    };
  }

  /// Sends one JSON request and returns the decoded body (a Map), or throws.
  Future<Map<String, dynamic>> _send(
    String method,
    String url, {
    Map<String, String>? params,
    Object? body,
    Duration timeout = _normal,
  }) async {
    final uri = Uri.parse(url).replace(
      queryParameters: (params == null || params.isEmpty) ? null : params,
    );
    final http.Response res;
    try {
      final req = http.Request(method, uri)
        ..headers.addAll(await _headers(json: body != null));
      if (body != null) req.body = jsonEncode(body);
      res = await http.Response.fromStream(await req.send().timeout(timeout))
          .timeout(timeout);
    } on TimeoutException {
      throw GpException.network();
    } on SocketException {
      throw GpException.network();
    } on http.ClientException {
      throw GpException.network();
    } on HandshakeException {
      throw GpException.network();
    }
    return _decode(res, '$method $url');
  }

  Map<String, dynamic> _decode(http.Response res, String label) {
    throwIfPlanModuleLocked(res);
    dynamic data;
    try {
      data = res.body.isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      data = null;
    }
    final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debugPrint('Google profile $label -> ${res.statusCode} ${res.body}');
      throw GpException(
        status: res.statusCode,
        code: map['code']?.toString() ?? 'http_${res.statusCode}',
        serverMessage: map['message']?.toString(),
        body: map,
      );
    }
    return map;
  }

  Future<dynamic> _view(
    String method,
    String url, {
    Map<String, String>? params,
    Object? body,
    Duration timeout = _normal,
  }) async {
    final map = await _send(method, url,
        params: params, body: body, timeout: timeout);
    return map['data'];
  }

  Future<GpPage> _page(
    String method,
    String url, {
    Map<String, String>? params,
    Object? body,
    Duration timeout = _normal,
  }) async {
    final map = await _send(method, url,
        params: params, body: body, timeout: timeout);
    final meta = map['meta'];
    return GpPage(
      map['data'],
      meta is Map ? Map<String, dynamic>.from(meta) : null,
    );
  }

  /// Multipart POST with the file in `file` (and any extra text fields).
  Future<dynamic> _upload(
    String url,
    File file, {
    Map<String, String> fields = const {},
    Duration timeout = _normal,
  }) async {
    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final parts = mimeType.split('/');
    final http.Response res;
    try {
      final req = http.MultipartRequest('POST', Uri.parse(url))
        ..headers.addAll(await _headers())
        ..fields.addAll(fields)
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType(parts.first, parts.length > 1 ? parts[1] : 'jpeg'),
        ));
      res = await http.Response.fromStream(await req.send().timeout(timeout))
          .timeout(timeout);
    } on TimeoutException {
      throw GpException.network();
    } on SocketException {
      throw GpException.network();
    } on http.ClientException {
      throw GpException.network();
    }
    return _decode(res, 'POST $url')['data'];
  }

  // ── Setup state (RD-23 / RD-24) ──────────────────────────────────────────

  /// The "view": which screen to show and everything it needs.
  Future<dynamic> get() => _view('GET', _base);
  Future<dynamic> refresh() => _view('POST', '$_base/refresh');

  /// body { has_google_profile, opening_time, closing_time, weekly_off, consent: true, owner_email? }.
  Future<dynamic> setup(Map<String, dynamic> body) =>
      _view('POST', '$_base/setup', body: body);
  Future<dynamic> resend() => _view('POST', '$_base/resend');
  Future<dynamic> linkExisting() => _view('POST', '$_base/link-existing');
  Future<dynamic> resendLink() => _view('POST', '$_base/link-existing/resend');

  /// The one-time GrowthOS link that starts Google's sign-in.
  Future<String?> connectUrl() async {
    final data = await _view('GET', '$_base/google/connect-url');
    final url = data is Map ? data['url']?.toString() : null;
    return (url == null || url.isEmpty) ? null : url;
  }

  Future<dynamic> connection() => _view('GET', '$_base/google/connection');
  Future<void> disconnectGoogle() =>
      _send('DELETE', '$_base/google/connection');

  /// [{ name: "accounts/…", accountName, type }]
  Future<dynamic> accounts() => _view('GET', '$_base/google/accounts');

  /// [{ name: "locations/…", title, address, phone, website, category }]
  Future<dynamic> locations(String account) =>
      _view('GET', '$_base/google/locations', params: {'account': account});

  /// Use an existing profile: { account_name, location_name }.
  Future<dynamic> pickLocation(Map<String, dynamic> body) =>
      _view('POST', '$_base/google/location', body: body);

  /// { locations, map_pin, storefront_pin, form: {...} }
  Future<dynamic> prefill([String? locationId]) => _view(
        'GET',
        '$_base/google/create/prefill',
        params: (locationId != null && locationId.isNotEmpty)
            ? {'location_id': locationId}
            : null,
      );

  /// [{ name: "categories/…", display_name }]
  Future<dynamic> createCategories(String q, [String? region]) => _view(
        'GET',
        '$_base/google/create/categories',
        params: {'q': q, if (region != null && region.isNotEmpty) 'region': region},
      );

  /// { data: [{ title, address, request_access_uri }], meta: { checked, reason } }
  Future<GpPage> checkProfile(Map<String, dynamic> body) =>
      _page('POST', '$_base/google/create/check', body: body, timeout: _slow);
  Future<dynamic> createProfile(Map<String, dynamic> body) =>
      _view('POST', '$_base/google/create', body: body, timeout: _slow);

  /// { maps_url } or {} (the storefront's own pin) -> { latitude, longitude }.
  Future<dynamic> savePin([Map<String, dynamic> body = const {}]) =>
      _view('PUT', '$_base/google/create/pin', body: body, timeout: _slow);

  /// { state, method, awaiting_code, options: [{ method, phone, address, email }] }
  Future<dynamic> verification() => _view('GET', '$_base/google/verification');
  Future<dynamic> startVerification(String method) => _view(
      'POST', '$_base/google/verification',
      body: {'method': method}, timeout: _slow);
  Future<dynamic> completeVerification(String pin) => _view(
      'POST', '$_base/google/verification/complete',
      body: {'pin': pin}, timeout: _slow);

  // ── Managing the live profile (RD-21) ────────────────────────────────────

  Future<dynamic> overview() => _view('GET', '$_base/overview');
  Future<dynamic> performance([int days = 30]) =>
      _view('GET', '$_base/performance', params: {'days': '$days'});

  // Reviews
  Future<dynamic> reviewsStatus() => _view('GET', '$_base/reviews/status');
  Future<GpPage> reviews(
          {String filter = 'all', int page = 1, int pageSize = 20}) =>
      _page('GET', '$_base/reviews', params: {
        'filter': filter,
        'page': '$page',
        'page_size': '$pageSize',
      });
  Future<dynamic> syncReviews() =>
      _view('POST', '$_base/reviews/sync', body: {}, timeout: _slow);
  Future<dynamic> draftReply(String reviewId) => _view(
      'POST', '$_base/reviews/${_enc(reviewId)}/draft',
      body: {}, timeout: _slow);
  Future<dynamic> saveReply(String reviewId, String reply) => _view(
      'PUT', '$_base/reviews/${_enc(reviewId)}/reply',
      body: {'reply': reply});
  Future<dynamic> publishReply(String reviewId, String reply) => _view(
      'POST', '$_base/reviews/${_enc(reviewId)}/publish',
      body: {'reply': reply});
  Future<dynamic> editPublishedReply(String reviewId, String reply) => _view(
      'PUT', '$_base/reviews/${_enc(reviewId)}/published-reply',
      body: {'reply': reply});
  Future<dynamic> deleteReply(String reviewId) =>
      _view('DELETE', '$_base/reviews/${_enc(reviewId)}/reply');

  /// Read the profile, photos and posts from Google now (once every 5 minutes).
  Future<dynamic> syncGoogle() =>
      _view('POST', '$_base/sync', body: {}, timeout: _slow);

  // Posts
  Future<GpPage> posts([String? status]) => _page('GET', '$_base/posts',
      params: (status != null && status.isNotEmpty) ? {'status': status} : null);
  Future<dynamic> generatePost(Map<String, dynamic> body) =>
      _view('POST', '$_base/posts/generate', body: body, timeout: _slow);
  Future<dynamic> createPost(Map<String, dynamic> body) =>
      _view('POST', '$_base/posts', body: body);
  Future<dynamic> updatePost(String postId, Map<String, dynamic> body) =>
      _view('PUT', '$_base/posts/${_enc(postId)}', body: body);
  Future<dynamic> deletePost(String postId) =>
      _view('DELETE', '$_base/posts/${_enc(postId)}');
  Future<dynamic> publishPost(String postId) =>
      _view('POST', '$_base/posts/${_enc(postId)}/publish');
  Future<dynamic> schedulePost(String postId) =>
      _view('POST', '$_base/posts/${_enc(postId)}/schedule');
  Future<dynamic> unschedulePost(String postId) =>
      _view('POST', '$_base/posts/${_enc(postId)}/unschedule');
  Future<dynamic> uploadImage(File file) => _upload('$_base/images', file);

  // Profile
  Future<dynamic> profile() => _view('GET', '$_base/profile');
  Future<dynamic> saveProfileSection(
          String section, Map<String, dynamic> body) =>
      _view('PUT', '$_base/profile/${_enc(section)}', body: body);
  Future<dynamic> generateDescription(
          [Map<String, dynamic> body = const {}]) =>
      _view('POST', '$_base/profile/description/generate',
          body: body, timeout: _slow);
  Future<dynamic> categories(String q, [String? region]) => _view(
        'GET',
        '$_base/profile/categories',
        params: {'q': q, if (region != null && region.isNotEmpty) 'region': region},
      );
  Future<dynamic> places(String q) =>
      _view('GET', '$_base/profile/places', params: {'q': q});
  Future<dynamic> googleUpdates() =>
      _view('GET', '$_base/profile/google-updates');
  Future<dynamic> answerGoogleUpdates(Map<String, dynamic> body) =>
      _view('POST', '$_base/profile/google-updates', body: body);

  // Photos
  Future<dynamic> photos() => _view('GET', '$_base/photos');
  Future<dynamic> addPhoto(File file, String category) =>
      _upload('$_base/photos', file, fields: {'category': category});
  Future<dynamic> deletePhoto(String name) =>
      _view('DELETE', '$_base/photos', params: {'name': name});

  // "Improve with AI" (RD-22)
  Future<dynamic> agent() => _view('GET', '$_base/agent');
  Future<dynamic> setAgent(bool on) =>
      _view('PUT', '$_base/agent', body: {'on': on});
  Future<GpPage> keywords() => _page('GET', '$_base/keywords');
  Future<dynamic> suggestKeywords([Map<String, dynamic> body = const {}]) =>
      _view('POST', '$_base/keywords/suggest', body: body, timeout: _slow);
  Future<dynamic> addKeyword(Map<String, dynamic> body) =>
      _view('POST', '$_base/keywords', body: body);
  Future<dynamic> setKeywordStatus(String keywordId, String status) => _view(
      'PATCH', '$_base/keywords/${_enc(keywordId)}',
      body: {'status': status});
  Future<dynamic> deleteKeyword(String keywordId) =>
      _view('DELETE', '$_base/keywords/${_enc(keywordId)}');
  Future<dynamic> storefront() => _view('GET', '$_base/storefront');
  Future<dynamic> facts() => _view('GET', '$_base/facts');
  Future<dynamic> useStorefront() => _view('POST', '$_base/storefront/use');
  Future<GpPage> services() => _page('GET', '$_base/services');
  Future<dynamic> suggestServices() =>
      _view('POST', '$_base/services/suggest', body: {}, timeout: _slow);
  Future<dynamic> addService(Map<String, dynamic> body) =>
      _view('POST', '$_base/services', body: body);
  Future<dynamic> deleteService(String serviceId) =>
      _view('DELETE', '$_base/services/${_enc(serviceId)}');
  Future<dynamic> sendStorefrontPhotos(List<dynamic> items) =>
      _view('POST', '$_base/storefront/photos', body: {'items': items});

  // Fixes
  Future<dynamic> fixes() => _view('GET', '$_base/fixes');
  Future<dynamic> prepareFixes() =>
      _view('POST', '$_base/fixes/prepare', body: {}, timeout: _slow);
  Future<dynamic> approveFix(String actionId) =>
      _view('POST', '$_base/fixes/${_enc(actionId)}/approve');
  Future<dynamic> rejectFix(String actionId) =>
      _view('POST', '$_base/fixes/${_enc(actionId)}/reject');

  // ── RD-25: the AI assistant chat ─────────────────────────────────────────

  /// { score, generated_for, items: [{ key, priority, title, message, points, action }] }
  Future<dynamic> assistantCoach() => _view('GET', '$_assistant/coach');

  /// Command[] of the last 30 days, oldest first.
  Future<dynamic> assistantHistory() => _view('GET', _assistant);
  Future<void> assistantClear() => _send('DELETE', _assistant);

  /// string[] — starter commands.
  Future<dynamic> assistantSuggestions() =>
      _view('GET', '$_assistant/suggestions');

  /// { kind: "question", answer } | { kind: "command", command }
  Future<dynamic> assistantSend(String text, [String? attachmentId]) => _view(
        'POST',
        _assistant,
        body: {
          'text': text,
          if (attachmentId != null && attachmentId.isNotEmpty)
            'attachment_id': attachmentId,
        },
        timeout: _slow,
      );

  /// A photo for the next message: { id, kind, name, url }.
  Future<dynamic> assistantAttach(File file) =>
      _upload('$_assistant/attachments', file, timeout: _slow);
  Future<dynamic> assistantChoose(String commandId, Object? option) => _view(
      'POST', '$_assistant/${_enc(commandId)}/choose',
      body: {'option': option}, timeout: _slow);

  /// body { text?, parts?, edits?, photo_id?, attributes? }
  Future<dynamic> assistantApply(String commandId,
          [Map<String, dynamic> body = const {}]) =>
      _view('POST', '$_assistant/${_enc(commandId)}/apply',
          body: body, timeout: _slow);
  Future<dynamic> assistantCancel(String commandId) => _view(
      'POST', '$_assistant/${_enc(commandId)}/cancel',
      body: {}, timeout: _slow);
  Future<dynamic> assistantUndo(String commandId) => _view(
      'POST', '$_assistant/${_enc(commandId)}/undo',
      body: {}, timeout: _slow);
  Future<dynamic> assistantUpload(String commandId, String uploadId) => _view(
      'POST', '$_assistant/${_enc(commandId)}/upload',
      body: {'upload_id': uploadId}, timeout: _slow);

  /// A server-served image (`/vendor/google-profile/images/<id>`) needs the
  /// token; returns the absolute URL to load it from, and whether it does.
  static bool needsAuth(String? url) =>
      url != null && url.startsWith('$basePath/images/');
  static String absoluteUrl(String url) =>
      needsAuth(url) ? '${ApiConfig.baseUrl}$url' : url;
}

/// A list answer: `data` plus `meta` (pages, counts, checked …).
class GpPage {
  final dynamic data;
  final Map<String, dynamic>? meta;
  const GpPage(this.data, this.meta);

  List<dynamic> get list => data is List ? data as List : const [];
}

/// A refused or failed call.
class GpException implements Exception {
  /// 0 when no answer came back.
  final int status;

  /// The server's code, `http_<status>`, or `network`.
  final String code;

  /// The server's own `message`, when it sent one.
  final String? serverMessage;

  /// The whole decoded error body (`data`, `fields`, `details` …).
  final Map<String, dynamic> body;

  const GpException({
    required this.status,
    required this.code,
    this.serverMessage,
    this.body = const {},
  });

  factory GpException.network() =>
      const GpException(status: 0, code: 'network');

  bool get isNetwork => code == 'network';

  /// `body.data` when it is a Map (e.g. the View sent with email_taken).
  Map<String, dynamic>? get data {
    final d = body['data'];
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }

  @override
  String toString() => 'GpException($code, $status): $serverMessage';
}

const String gpNetworkMessage =
    'Could not reach HappyWedz. Check your internet connection and try again.';

/// The server's error code, as the website's `errorCode()`.
String gpErrorCode(Object? error) {
  if (error is GpException) return error.code;
  if (error is PlanModuleLockedException) return 'PLAN_MODULE_LOCKED';
  return 'network';
}

/// The server's message when it sent one, otherwise [fallback] (website `errorMessage`).
String gpErrorMessage(Object? error,
    [String fallback = 'Something went wrong. Please try again.']) {
  if (error is GpException) {
    final m = error.serverMessage;
    return (m != null && m.trim().isNotEmpty) ? m : fallback;
  }
  if (error is PlanModuleLockedException) {
    final m = error.message;
    return (m != null && m.isNotEmpty) ? m : fallback;
  }
  return fallback;
}

/// The network line when no answer came back, else the server's message (website `messageOf`).
String gpMessageOf(Object? error, String fallback) =>
    gpErrorCode(error) == 'network' ? gpNetworkMessage : gpErrorMessage(error, fallback);
