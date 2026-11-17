import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

/// The real type of a KYC file, from its name or — for files shared from
/// another app, which can arrive without an extension — from its first bytes
/// (a PDF starts with `%PDF`). Null when it cannot be told.
Future<String?> kycMimeType(File file) async {
  List<int> head = const [];
  try {
    final raf = await file.open();
    head = await raf.read(16);
    await raf.close();
  } catch (_) {}
  final type = lookupMimeType(file.path, headerBytes: head);
  if (type != null) return type == 'image/jpg' ? 'image/jpeg' : type;
  if (head.length >= 4 && String.fromCharCodes(head.take(4)) == '%PDF') {
    return 'application/pdf';
  }
  return null;
}

const Map<String, String> _extensionFor = {
  'application/pdf': 'pdf',
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

class LabeledDocument {
  final String label;
  final File file;
  const LabeledDocument({required this.label, required this.file});
}

/// Mirrors `backen/src/services/api/vendorVerificationApi.js`.
class VendorVerificationApi {
  final String baseUrl = ApiConfig.baseUrl;
  static const String _base = '/vendor/verification';

  Future<Map<String, dynamic>> submit({
    required String token,
    required Map<String, String> fields,
    File? aadhaar,
    File? pan,
    List<LabeledDocument> businessDocs = const [],
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl$_base/submit'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    fields.forEach((key, value) {
      request.fields[key] = value;
    });

    if (aadhaar != null) request.files.add(await _part('aadhaar', aadhaar));
    if (pan != null) request.files.add(await _part('pan', pan));

    if (businessDocs.isNotEmpty) {
      for (final doc in businessDocs) {
        request.files.add(await _part('businessDocs', doc.file));
      }
      request.fields['businessDocLabels'] =
          jsonEncode(businessDocs.map((d) => d.label.trim()).toList());
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage(
      res,
      'We could not submit your documents. Please try again.',
    ));
  }

  Future<Map<String, dynamic>> getStatus(String token) async {
    final res = await http.get(
      Uri.parse('$baseUrl$_base/status'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    return const {};
  }

  Future<String?> getDocumentUrl(String token, dynamic documentId) async {
    final res = await http.get(
      Uri.parse('$baseUrl$_base/documents/$documentId/url'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['url'] as String?;
    }
    return null;
  }

  /// One file part with its real type. Without it `fromPath` sends
  /// `application/octet-stream`, and the server refuses it ("Aadhaar must be
  /// a PDF … you uploaded application/octet-stream") even for a real PDF.
  /// The browser sets the type itself, which is why the website never hit it.
  Future<http.MultipartFile> _part(String field, File file) async {
    final type = await kycMimeType(file) ?? 'application/octet-stream';
    final parts = type.split('/');
    var name = file.path.split(Platform.pathSeparator).last;
    final ext = _extensionFor[type];
    if (ext != null && !name.toLowerCase().contains('.')) name = '$name.$ext';
    return http.MultipartFile.fromPath(
      field,
      file.path,
      filename: name,
      contentType: MediaType(parts.first, parts.last),
    );
  }

  String _errorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] is String) return data['message'];
    } catch (_) {}
    return fallback;
  }
}
