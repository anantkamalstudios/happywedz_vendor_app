
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/storefront_calculation.dart';
import 'package:happy_weds_vendors/utils/api_config.dart';


class StorefrontCompletionService {
  static Future<void> refreshCompletion({
    required int serviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('authToken');

    if (token == null || token.isEmpty) {
      debugPrint("❌ Token missing, cannot refresh completion");
      return;
    }

    debugPrint("══════════════════════════════════════");
    debugPrint("🚀 Storefront Completion Refresh START");
    debugPrint("🆔 serviceId: $serviceId");

    try {
      // 🔥 STEP 1: Fetch latest vendor-service
      final getUrl = Uri.parse(
        "${ApiConfig.baseUrl}/vendor-services/$serviceId",
      );

      final getRes = await http.get(
        getUrl,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (getRes.statusCode != 200) {
        debugPrint("❌ Failed to fetch vendor-service");
        debugPrint(getRes.body);
        return;
      }

      final data = jsonDecode(getRes.body);
      final Map<String, dynamic> attributes =
      Map<String, dynamic>.from(data["attributes"] ?? {});

      final List<dynamic> rootMedia =
      List<dynamic>.from(data["media"] ?? []);

      final completion =
      await StorefrontCompletionCalculator.calculate(attributes,  rootMedia: rootMedia, );

      debugPrint("📊 Calculated Completion: $completion%");

      // 🔥 STEP 3: PUT completion to server
      final putUrl = Uri.parse(
        "${ApiConfig.baseUrl}/vendor-services/$serviceId/storefront-completion",
      );

      final putRes = await http.put(
        putUrl,
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "completion": completion,
        }),
      );

      debugPrint("⬅️ PUT Status: ${putRes.statusCode}");
      debugPrint("⬅️ PUT Response: ${putRes.body}");

      if (putRes.statusCode == 200) {
        debugPrint("✅ Storefront completion updated successfully");
      } else {
        debugPrint("❌ Failed to update storefront completion");
      }
    } catch (e) {
      debugPrint("❌ Exception in refreshCompletion: $e");
    }
  }
}

