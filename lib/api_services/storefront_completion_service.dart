import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/storefront_calculation.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';

class StorefrontCompletionService {
  /// Recalculates the storefront completion exactly as the website does and
  /// stores it on the service. Called after every storefront tab save.
  static Future<void> refreshCompletion({
    required int serviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      debugPrint("❌ Token missing, cannot refresh completion");
      return;
    }

    final headers = {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    };

    try {
      final getRes = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/vendor-services/$serviceId"),
        headers: headers,
      );

      if (getRes.statusCode != 200) {
        debugPrint("❌ Failed to fetch vendor-service: ${getRes.body}");
        return;
      }

      var decoded = jsonDecode(getRes.body);
      if (decoded is List) decoded = decoded.isNotEmpty ? decoded.first : null;
      if (decoded is! Map) return;
      final service = Map<String, dynamic>.from(decoded);

      final vendorId = prefs.getInt('vendorId');
      final vendorTypeId = prefs.getInt('vendorTypeId') ??
          _toInt(service['vendor']?['vendor_type_id']);

      // The two inputs the website takes from outside the service record.
      final results = await Future.wait([
        _vendorTypeName(
          vendorTypeId,
          _toInt(service['vendor_subcategory_id']),
          headers,
        ),
        _hasFaqAnswers(vendorId, headers),
      ]);

      final typeName = results[0] as String?;
      final hasFaq = results[1] as bool?;
      // A failed lookup would score a lower number than the website and
      // overwrite the stored one, so keep the stored value instead.
      if (typeName == null || hasFaq == null) {
        debugPrint("⚠️ Completion not updated: a lookup failed");
        return;
      }

      final completion = StorefrontCompletionCalculator.calculate(
        service,
        vendorTypeName: typeName,
        hasFaqAnswers: hasFaq,
      );

      debugPrint("📊 Storefront completion: $completion%");

      final putRes = await http.put(
        Uri.parse(
          "${ApiConfig.baseUrl}/vendor-services/$serviceId/storefront-completion",
        ),
        headers: {...headers, "Content-Type": "application/json"},
        body: jsonEncode({"completion": completion}),
      );

      if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
        debugPrint(
          "❌ Failed to update storefront completion: ${putRes.statusCode} ${putRes.body}",
        );
      }
    } catch (e) {
      debugPrint("❌ Exception in refreshCompletion: $e");
    }
  }

  /// The subcategory's name, falling back to the vendor type's name — the
  /// website's `vendorTypeName`, which picks the facilities and menus rules.
  /// Null when the lookup itself failed (as opposed to "no name").
  static Future<String?> _vendorTypeName(
    int? vendorTypeId,
    int? subcategoryId,
    Map<String, String> headers,
  ) async {
    if (vendorTypeId == null) return "";
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/vendor-types/$vendorTypeId"),
        headers: headers,
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      if (data is! Map) return null;

      final subcats = data['subcategories'];
      if (subcats is List && subcategoryId != null) {
        for (final s in subcats) {
          if (s is Map &&
              _toInt(s['id']) == subcategoryId &&
              (s['name'] ?? '').toString().isNotEmpty) {
            return s['name'].toString();
          }
        }
      }
      return (data['name'] ?? '').toString();
    } catch (e) {
      debugPrint("Vendor type lookup failed: $e");
      return null;
    }
  }

  /// True when at least one FAQ answer is non-empty, using the website's rule
  /// (JSON strings are parsed; empty lists and maps do not count).
  /// Null when the lookup itself failed.
  static Future<bool?> _hasFaqAnswers(
    int? vendorId,
    Map<String, String> headers,
  ) async {
    if (vendorId == null) return false;
    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/faq-answers/$vendorId"),
        headers: headers,
      );
      // 404 = no answers saved yet, which is a real "no".
      if (res.statusCode == 404) return false;
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final List answers = data is List
          ? data
          : data is Map && data['answers'] is List
              ? data['answers']
              : const [];

      return answers.any((a) {
        if (a is! Map) return false;
        dynamic value = a['answer'];
        if (value is String) {
          final s = value.trim();
          if ((s.startsWith('{') && s.endsWith('}')) ||
              (s.startsWith('[') && s.endsWith(']'))) {
            try {
              value = jsonDecode(s);
            } catch (_) {}
          }
        }
        if (value == null) return false;
        if (value is List) {
          return value.where((v) => v != null && v != false && v != '').isNotEmpty;
        }
        if (value is Map) return value.isNotEmpty;
        return value.toString().trim().isNotEmpty;
      });
    } catch (e) {
      debugPrint("FAQ answers lookup failed: $e");
      return null;
    }
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
