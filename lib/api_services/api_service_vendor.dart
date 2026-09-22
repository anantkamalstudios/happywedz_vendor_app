import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:happy_weds_vendors/utils/api_config.dart';

class VendorServiceApi {
  final String baseUrl = ApiConfig.baseUrl;

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

  /// UPDATE service with 360° video files attached.
  ///
  /// Videos cannot ride along in the JSON body, so this mirrors the shape the
  /// website's `buildFormData` sends: `attributes` as a JSON string, the new
  /// files under `view360_video`, and the URLs of the ones already stored
  /// under `view360_video_urls`. That last field is what stops the server
  /// dropping the videos the vendor is keeping.
  Future<bool> updateServiceWith360Videos({
    required int serviceId,
    required String token,
    required int vendorId,
    required Object? vendorSubcategoryId,
    required Map<String, dynamic> attributes,
    required List<String> keptVideoUrls,
    required List<String> newVideoPaths,
  }) async {
    final request = http.MultipartRequest(
      "PUT",
      Uri.parse("$baseUrl/vendor-services/$serviceId"),
    );

    request.headers["Authorization"] = "Bearer $token";
    request.headers["Accept"] = "application/json";

    request.fields["vendor_id"] = "$vendorId";
    if (vendorSubcategoryId != null) {
      request.fields["vendor_subcategory_id"] = "$vendorSubcategoryId";
    }
    request.fields["attributes"] = jsonEncode(attributes);
    request.fields["view360_video_urls"] = jsonEncode(keptVideoUrls);

    for (final path in newVideoPaths) {
      request.files.add(
        await http.MultipartFile.fromPath("view360_video", path),
      );
    }

    try {
      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      final success = res.statusCode >= 200 && res.statusCode < 300;
      debugPrint(
        "PUT (multipart) /vendor-services/$serviceId → ${res.statusCode} | success=$success",
      );
      if (!success) debugPrint("Response body: ${res.body}");
      return success;
    } catch (e) {
      debugPrint("❌ 360 video upload error: $e");
      return false;
    }
  }
}
