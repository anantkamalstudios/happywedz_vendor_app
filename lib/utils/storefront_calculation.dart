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
    final pm = attributes["photographer_master"];
    final pmIdentity = pm is Map ? pm["identity"] : null;
    final pmStyle    = pm is Map ? pm["style_intelligence"] : null;
    final pmTeam     = pm is Map ? pm["team_coverage"] : null;

    final photographerFilled =
        (pmIdentity is Map && (pmIdentity["services_offered"] as List?)?.isNotEmpty == true) ||
        (pmStyle is Map && hasValue(pmStyle["editing_style"])) ||
        (pmTeam is Map && hasValue(pmTeam["team_size"]));

    final mm = attributes["mehndi_artist_master"];
    final mmIdentity = mm is Map ? mm["identity"] : null;
    final mmServices = mm is Map ? mm["services"] : null;

    final mehendiFilled =
        (mmIdentity is Map && hasValue(mmIdentity["artist_type"])) ||
        (mmServices is Map && (mmServices["services_offered"] as List?)?.isNotEmpty == true);

    final mam        = attributes["makeup_artist_master"];
    final mamIdentity = mam is Map ? mam["identity"] : null;
    final makeupFilled =
        mamIdentity is Map && hasValue(mamIdentity["artist_type"]);

    final fm        = attributes["florist_master"];
    final fmIdentity = fm is Map ? fm["identity"] : null;
    final floristFilled =
        fmIdentity is Map && hasValue(fmIdentity["brand_name"]);

    final gm         = attributes["gift_master"];
    final gmIdentity = gm is Map ? gm["identity"] : null;
    final giftsFilled =
        gmIdentity is Map && hasValue(gmIdentity["brand_name"]);

    final invm         = attributes["invitation_master"];
    final invmIdentity = invm is Map ? invm["identity"] : null;
    final invitationFilled =
        invmIdentity is Map && hasValue(invmIdentity["brand_name"]);

    final favm         = attributes["favor_master"];
    final favmIdentity = favm is Map ? favm["identity"] : null;
    final favorFilled =
        favmIdentity is Map && hasValue(favmIdentity["brand_name"]);

    final trm         = attributes["trousseau_master"];
    final trmIdentity = trm is Map ? trm["identity"] : null;
    final trousseauPackersFilled =
        trmIdentity is Map && hasValue(trmIdentity["brand_name"]);

    final pam         = attributes["pandit_master"];
    final pamIdentity = pam is Map ? pam["identity"] : null;
    final panditFilled =
        pamIdentity is Map && hasValue(pamIdentity["vendor_type"]);

    final catm         = attributes["caterer_master"];
    final catmIdentity = catm is Map ? catm["identity"] : null;
    final catererFilled =
        catmIdentity is Map && hasValue(catmIdentity["brand_name"]);

    final djm         = attributes["dj_master"];
    final djmIdentity = djm is Map ? djm["identity"] : null;
    final djFilled =
        djmIdentity is Map && hasValue(djmIdentity["vendor_type"]);

    final wem         = attributes["wedding_entertainer_master"];
    final wemIdentity = wem is Map ? wem["identity"] : null;
    final weddingEntFilled =
        wemIdentity is Map && hasValue(wemIdentity["vendor_type"]);

    final chm         = attributes["choreographer_master"];
    final chmIdentity = chm is Map ? chm["identity"] : null;
    final sangeetFilled =
        chmIdentity is Map && hasValue(chmIdentity["vendor_type"]);

    final pwl         = attributes["pre_wedding_location_master"];
    final pwlIdentity = pwl is Map ? pwl["identity"] : null;
    final preWedLocFilled =
        pwlIdentity is Map && hasValue(pwlIdentity["location_type"]);

    final pwp         = attributes["pre_wedding_photographer_master"];
    final pwpIdentity = pwp is Map ? pwp["identity"] : null;
    final preWedPhotoFilled =
        pwpIdentity is Map && hasValue(pwpIdentity["vendor_type"]);

    final jwm         = attributes["jewellery_master"];
    final jwmIdentity = jwm is Map ? jwm["identity"] : null;
    final jewelleryFilled =
        jwmIdentity is Map && hasValue(jwmIdentity["vendor_type"]);

    final fjm         = attributes["flower_jewellery_master"];
    final fjmIdentity = fjm is Map ? fjm["identity"] : null;
    final flowerJewelleryFilled =
        fjmIdentity is Map && hasValue(fjmIdentity["vendor_type"]);

    final acm         = attributes["accessories_master"];
    final acmIdentity = acm is Map ? acm["identity"] : null;
    final accessoriesFilled =
        acmIdentity is Map && hasValue(acmIdentity["vendor_type"]);

    final bom         = attributes["bridal_outfit_master"];
    final bomIdentity = bom is Map ? bom["identity"] : null;
    final bridalLehengaFilled =
        bomIdentity is Map && hasValue(bomIdentity["vendor_type"]);

    final cgm         = attributes["cocktail_gown_master"];
    final cgmIdentity = cgm is Map ? cgm["identity"] : null;
    final cocktailGownFilled =
        cgmIdentity is Map && hasValue(cgmIdentity["vendor_type"]);

    final rom         = attributes["rental_outfit_master"];
    final romIdentity = rom is Map ? rom["identity"] : null;
    final rentalOutfitFilled =
        romIdentity is Map && hasValue(romIdentity["vendor_type"]);

    final shm         = attributes["sherwani_master"];
    final shmIdentity = shm is Map ? shm["identity"] : null;
    final sherwaniFilled =
        shmIdentity is Map && hasValue(shmIdentity["brand_name"]);

    final wsm         = attributes["wedding_suit_master"];
    final wsmIdentity = wsm is Map ? wsm["identity"] : null;
    final weddingSuitFilled =
        wsmIdentity is Map && hasValue(wsmIdentity["brand_name"]);

    final wpm         = attributes["wedding_planner_master"];
    final wpmIdentity = wpm is Map ? wpm["identity"] : null;
    final weddingPlannerFilled =
        wpmIdentity is Map && hasValue(wpmIdentity["company_name"]);

    final dcm         = attributes["decorator_master"];
    final dcmIdentity = dcm is Map ? dcm["identity"] : null;
    final decoratorFilled =
        dcmIdentity is Map && hasValue(dcmIdentity["brand_company_name"]);

    if (
      hasValue(attributes["rooms"]) ||
      hasValue(attributes["parking"]) ||
      hasValue(attributes["offerings"]) ||
      hasValue(attributes["decor_policy"]) ||
      hasValue(attributes["catering_policy"]) ||
      photographerFilled ||
      mehendiFilled ||
      makeupFilled ||
      floristFilled ||
      giftsFilled ||
      invitationFilled ||
      favorFilled ||
      trousseauPackersFilled ||
      panditFilled ||
      catererFilled ||
      djFilled ||
      weddingEntFilled ||
      sangeetFilled ||
      preWedLocFilled ||
      preWedPhotoFilled ||
      weddingPlannerFilled ||
      decoratorFilled ||
      jewelleryFilled ||
      flowerJewelleryFilled ||
      accessoriesFilled ||
      bridalLehengaFilled ||
      cocktailGownFilled ||
      rentalOutfitFilled ||
      sherwaniFilled ||
      weddingSuitFilled
    ) {
      score += StorefrontSections.weights["facilities_and_features"]!;
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
