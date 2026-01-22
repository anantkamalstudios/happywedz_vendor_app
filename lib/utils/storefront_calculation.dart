import 'package:shared_preferences/shared_preferences.dart';

import 'storefront_completion_config.dart';

class StorefrontCompletionCalculator {
  // static Future<int> calculate(Map<String, dynamic> attributes) async {
  static Future<int> calculate(
      Map<String, dynamic> attributes, {
        List? rootMedia,
      }) async {
    int score = 0;

    bool hasValue(dynamic v) =>
        v != null && v.toString().trim().isNotEmpty;

    bool hasAll(Map? map, List<String> keys) {
      if (map == null) return false;
      return keys.every((k) => hasValue(map[k]));
    }

    // ================= BASIC INFO (10)
    if (hasValue(attributes["name"]) &&
        hasValue(attributes["about_us"])) {
      score += StorefrontSections.weights["basic_info"]!;
    }

    final prefs = await SharedPreferences.getInstance();
    final faqDone = prefs.getBool("faqCompleted") ?? false;

    if (faqDone) {
      score += StorefrontSections.weights["faq"]!;
    }

    // ================= CONTACT DETAILS (5)
    final contact = attributes["contact"];
    if (hasAll(contact, ["name", "phone"])) {
      score += StorefrontSections.weights["contact_details"]!;
    }

    // ================= LOCATION (10)
    final location = attributes["location"];
    if (hasAll(location, ["state", "pincode"]) &&
        hasValue(attributes["city"]) &&
        hasValue(attributes["address"])) {
      score += StorefrontSections.weights["location"]!;
    }


    // ================= PHOTOS (5)
    if ((rootMedia ?? []).isNotEmpty) {
      score += StorefrontSections.weights["photos"]!;
    }

    // ================= VIDEOS (10)
    final videos = attributes["video"];
    if ((videos as List?)?.isNotEmpty == true) {
      score += StorefrontSections.weights["videos"]!;
    }


    // ================= FACILITIES & FEATURES (10)
    if (
    hasValue(attributes["rooms"]) ||
        hasValue(attributes["parking"]) ||
        hasValue(attributes["offerings"]) ||
        hasValue(attributes["decor_policy"]) ||
        hasValue(attributes["catering_policy"])
    ) {
      score +=
      StorefrontSections.weights["facilities_and_features"]!;
    }

    // ================= PROMOTION (10)
    final deals = attributes["deals"];
    if (deals is List && deals.isNotEmpty) {
      score += StorefrontSections.weights["promotion"]!;
    }

    // ================= POLICIES & TERMS (10)
    if (hasValue(attributes["cancellation_policy"]) &&
        hasValue(attributes["refund_policy"]) &&
        hasValue(attributes["payment_terms"]) &&
        hasValue(attributes["tnc"])) {
      score += StorefrontSections.weights["policies_and_terms"]!;
    }

    // ================= AVAILABILITY / SLOTS (10)
    if ((attributes["available_slots"] as List?)?.isNotEmpty == true) {
      score += StorefrontSections.weights["availability"]!;
    }

    // ================= PRICING & PACKAGES (5)
    if (hasValue(attributes["starting_price"]) &&
        hasValue(attributes["PriceRange"])) {
      score +=
      StorefrontSections.weights["pricing_and_packages"]!;
    }

    return score.clamp(0, 100);
  }
}
