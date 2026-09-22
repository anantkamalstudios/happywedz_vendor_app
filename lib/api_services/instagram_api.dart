import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:happy_weds_vendors/utils/api_config.dart';

/// The vendor's Instagram connection, mirroring the website's `instagramApi`.
///
/// Every route is under `/instagram` and needs the bearer token:
///   GET    /instagram/           → {connected, connection}
///   GET    /instagram/auth-url   → {url}
///   DELETE /instagram/           → disconnect
class InstagramApi {
  final String baseUrl = ApiConfig.baseUrl;

  Map<String, String> _headers(String token) => {
        "Accept": "application/json",
        "Authorization": "Bearer $token",
      };

  /// The connected account, or null when there is none.
  ///
  /// The server answers `{connected: false}` with no `connection`, so an
  /// absent account is a normal result rather than an error.
  Future<Map<String, dynamic>?> getConnection({required String token}) async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/instagram/"),
        headers: _headers(token),
      );

      if (res.statusCode != 200) {
        debugPrint("GET /instagram/ → ${res.statusCode}");
        return null;
      }

      final data = jsonDecode(res.body);
      if (data is! Map) return null;
      if (data["connected"] != true) return null;

      final connection = data["connection"];
      return connection is Map
          ? Map<String, dynamic>.from(connection)
          : <String, dynamic>{};
    } catch (e) {
      debugPrint("❌ Instagram getConnection error: $e");
      return null;
    }
  }

  /// The signed Instagram login URL to send the vendor to.
  Future<String?> getAuthUrl({required String token}) async {
    final res = await http.get(
      Uri.parse("$baseUrl/instagram/auth-url"),
      headers: _headers(token),
    );

    if (res.statusCode != 200) {
      debugPrint("GET /instagram/auth-url → ${res.statusCode} ${res.body}");
      return null;
    }

    final data = jsonDecode(res.body);
    final url = (data is Map) ? data["url"]?.toString() : null;
    return (url == null || url.isEmpty) ? null : url;
  }

  Future<bool> disconnect({required String token}) async {
    try {
      final res = await http.delete(
        Uri.parse("$baseUrl/instagram/"),
        headers: _headers(token),
      );
      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (e) {
      debugPrint("❌ Instagram disconnect error: $e");
      return false;
    }
  }
}
