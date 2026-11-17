/// Storefront completion %, ported line for line from the website's
/// `calculateCompletion` in `adminVendor/Storefront.jsx`.
///
/// Both clients PUT their result to the same
/// `/vendor-services/:id/storefront-completion` field, so they must agree —
/// the app used to use its own weighted sections and the stored number
/// flipped depending on which client saved last.
///
/// The website reads a `formData` object it builds from the service record
/// (see its `fetchServiceData`). Each section below notes which record field
/// that `formData` path comes from. JavaScript truthiness is kept on purpose
/// (an empty list or map counts as "filled"), because changing it here alone
/// would make the two clients disagree again.
class StorefrontCompletionCalculator {
  StorefrontCompletionCalculator._();

  /// [service] is the raw `GET /vendor-services/:id` record.
  /// [vendorTypeName] is the subcategory name, falling back to the vendor
  /// type name — the same `vendorTypeName` the website derives.
  /// [hasFaqAnswers] is whether `/faq-answers/:vendorId` has a non-empty
  /// answer (the website's `formData.faqs`).
  static int calculate(
    Map<String, dynamic> service, {
    required String vendorTypeName,
    required bool hasFaqAnswers,
  }) {
    final attrs = _map(service['attributes']);
    final type = vendorTypeName.trim().toLowerCase();
    final isVenue = isVenueType(type);
    final isCaterer = isCatererType(type);

    // formData.contact / formData.location only exist when the attribute does.
    final contact = attrs['contact'] is Map ? _map(attrs['contact']) : null;
    final location = attrs['location'] is Map ? _map(attrs['location']) : null;
    final priceRange =
        attrs['price_range'] is Map ? _map(attrs['price_range']) : null;

    final sections = <bool>[
      // business: attributes.Name, attributes.about_us
      _truthy(attrs['Name']) || _truthy(attrs['about_us']),

      // vendor-basic: attributes.vendor_name, attributes.tagline
      _truthy(attrs['vendor_name']) || _truthy(attrs['tagline']),

      // faq: at least one non-empty answer
      hasFaqAnswers,

      // vendor-contact: contact.{contactName, phone, email}
      contact != null &&
          (_truthy(contact['name']) ||
              _truthy(contact['phone']) ||
              _truthy(contact['email'])),

      // vendor-location: location.{city, state, addressLine1}. city is
      // attributes.city, state is attributes.location.state, addressLine1 is
      // never filled by the website.
      location != null &&
          (_truthy(attrs['city']) || _truthy(location['state'])),

      // photos: gallery drafts
      galleryCount(service) > 0,

      // videos: video drafts
      videoCount(service) > 0,

      // vendor-pricing: startingPrice, priceRange.{min,max}
      _truthy(attrs['starting_price']) ||
          (priceRange != null &&
              (_truthy(priceRange['min']) || _truthy(priceRange['max']))),

      // vendor-facilities
      _facilitiesFilled(attrs, type, isVenue, isCaterer),

      // promotions: `deals` defaults to [] on the website, and [] is truthy
      // in JS, so this section always counts as complete there.
      true,

      // vendor-policies: tnc (top level only), cancellation, refund
      _truthy(service['tnc']) ||
          _truthy(attrs['cancellation_policy']) ||
          _truthy(attrs['refund_policy']),

      // vendor-availability: attributes.available_slots (present = done,
      // even when empty, as in JS)
      _truthy(attrs['available_slots']),

      // vendor-marketing: primaryCTA — its tab is commented out on the
      // website, so this is only set on records that carry it at top level.
      _truthy(service['primaryCTA']),
    ];

    // vendor-menus, only for venues and caterers
    if (isVenue || isCaterer) {
      sections.add(_truthy(attrs['menus']) ||
          _truthy(attrs['veg_price']) ||
          _truthy(attrs['non_veg_price']) ||
          _truthy(attrs['menu_description']));
    }

    final completed = sections.where((done) => done).length;
    return (completed / sections.length * 100).round();
  }

  static bool isCatererType(String type) => const [
        'cater', 'food', 'tiffin', 'kitchen', 'meal', 'cake', 'bakery',
      ].any(type.contains);

  static bool isVenueType(String type) => const [
        'venue', 'marriage garden', 'banquet', 'resort', 'hotel', 'lawn',
        'palace', 'fort',
      ].any(type.contains);

  static bool _facilitiesFilled(
    Map<String, dynamic> attrs,
    String type,
    bool isVenue,
    bool isCaterer,
  ) {
    if (isVenue) return _masterHasData(attrs['venue_master']);
    if (isCaterer) return _masterHasData(attrs['caterer_master']);
    if (type.contains('photograph')) {
      return _masterHasData(attrs['photographer_master']);
    }
    if (type.contains('makeup') ||
        (type.contains('bridal') && type.contains('artist')) ||
        type.contains('mua')) {
      return _masterHasData(attrs['makeup_artist_master']);
    }
    if (type.contains('jewell') ||
        type.contains('jewelry') ||
        type.contains('accessor')) {
      // The website's `formData.jewellery_master || accessories_master || …`
      // always stops at jewellery_master, because it defaults to {} and {}
      // is truthy in JS.
      return _masterHasData(attrs['jewellery_master']);
    }
    return _truthy(attrs['happywedz_since'] ?? attrs['HappyWedz']) ||
        _truthy(attrs['offerings']) ||
        _truthy(attrs['travel_info']) ||
        _truthy(attrs['delivery_time']);
  }

  /// The website's `venueMasterHasData`: any non-blank string or any number
  /// anywhere inside the master profile.
  static bool _masterHasData(dynamic value) {
    if (value is String) return value.trim().isNotEmpty;
    if (value is num) return !value.isNaN;
    if (value is Map) return value.values.any(_masterHasData);
    if (value is List) return value.any(_masterHasData);
    return false;
  }

  /// Gallery photos, read the same way as the website's photo drafts.
  static int galleryCount(Map<String, dynamic> service) {
    final media = service['media'];
    final items = media is List
        ? media
        : media is Map && media['gallery'] is List
            ? media['gallery'] as List
            : const [];
    return items.where((item) {
      final url = item is Map ? (item['url'] ?? item['path']) : item;
      return _cleanUrl(url) != null;
    }).length;
  }

  /// Videos from the legacy `media.videos` plus `attributes.video` /
  /// `attributes.vedio`, as the website's video drafts.
  static int videoCount(Map<String, dynamic> service) {
    final media = service['media'];
    final attrs = _map(service['attributes']);
    final urls = <String>{};
    void addAll(dynamic list) {
      if (list is! List) return;
      for (final item in list) {
        final url = _cleanUrl(item is Map ? (item['url'] ?? item['path']) : item);
        if (url != null) urls.add(url);
      }
    }

    if (media is Map) addAll(media['videos']);
    addAll(attrs['video'] ?? attrs['vedio']);
    return urls.length;
  }

  static String? _cleanUrl(dynamic value) {
    if (value is! String) return null;
    final cleaned = value.replaceAll(RegExp(r'^\s*`|`\s*$'), '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  /// JavaScript truthiness: null, false, 0, NaN and "" are false; everything
  /// else — including empty lists and maps — is true.
  static bool _truthy(dynamic value) {
    if (value == null || value == false) return false;
    if (value is String) return value.isNotEmpty;
    if (value is num) return value != 0 && !value.isNaN;
    return true;
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}
