import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class VendorServiceApi {
  final String baseUrl = "https://happywedz.com/api";

  Future<int?> getServiceIdByVendorId({
    required int vendorId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse("$baseUrl/vendor-services/vendor/$vendorId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      if (data.isNotEmpty) {
        return data[0]["id"];
      }
    }
    return null;
  }
  /// GET vendor service by vendorId
  Future<Map<String, dynamic>?> getByVendorId({
    required int vendorId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse("$baseUrl/vendor-services/vendor/$vendorId"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      final list = jsonDecode(res.body);
      return list.isNotEmpty ? list[0] : null;
    }
    return null;
  }

  /// GET vendor service by serviceId
  Future<Map<String, dynamic>?> getByServiceId({
    required int serviceId,
    required String token,
  }) async {
    final res = await http.get(
      Uri.parse("$baseUrl/vendor-services/$serviceId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      // Handle both single-object and array responses
      if (data is List) return data.isNotEmpty ? Map<String, dynamic>.from(data[0]) : null;
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// CREATE service
  Future<bool> createService({
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/vendor-services"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
    return res.statusCode == 200 || res.statusCode == 201;
  }

  /// UPDATE service (IMPORTANT)
  Future<bool> updateService({
    required int serviceId,
    required String token,
    required Map<String, dynamic> body,
  }) async {
    final res = await http.put(
      Uri.parse("$baseUrl/vendor-services/$serviceId"),
      headers: {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    // Accept any 2xx status (200 OK, 201 Created, 204 No Content, etc.)
    final success = res.statusCode >= 200 && res.statusCode < 300;
    debugPrint("PUT /vendor-services/$serviceId → ${res.statusCode} | success=$success");
    if (!success) debugPrint("Response body: ${res.body}");
    return success;
  }
}
