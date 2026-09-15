import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:happy_weds_vendors/utils/api_config.dart';

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

    if (aadhaar != null) {
      request.files.add(await http.MultipartFile.fromPath('aadhaar', aadhaar.path));
    }
    if (pan != null) {
      request.files.add(await http.MultipartFile.fromPath('pan', pan.path));
    }

    if (businessDocs.isNotEmpty) {
      for (final doc in businessDocs) {
        request.files.add(
          await http.MultipartFile.fromPath('businessDocs', doc.file.path),
        );
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

  String _errorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map && data['message'] is String) return data['message'];
    } catch (_) {}
    return fallback;
  }
}
