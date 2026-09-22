/// Merging the Pricing & Packages form back into a vendor service's
/// `attributes`, the way the website's Storefront does it.
///
/// This lives apart from the screen because getting it wrong destroys data
/// that nobody typed in the app. Production carries free text in `PriceRange`
/// — "Rs. Price on Request", "Rs. 35,000" — left over from the old site, with
/// no min/max inside it. The screen used to rebuild that string on every save
/// as `"$min - $max"`, so a vendor who merely opened the page and pressed Save
/// turned their price into " - ".
///
/// Rules taken from `Storefront.jsx`:
/// * `starting_price` — `Number(x)` when filled, `undefined` (key dropped)
///   when blank. It must never be written as 0.
/// * `price_range` — always the `{min, max}` pair; this is what the website
///   reads back into its two inputs.
/// * `PriceRange` — `"$min - $max"` only when BOTH are filled, otherwise the
///   string already on the server is kept.
/// * `pricing_description` and the two package prices — dropped when blank.
class PricingAttributes {
  PricingAttributes._();

  /// Returns a copy of [attributes] with the pricing keys applied.
  ///
  /// [serverPriceRange] is the `PriceRange` that came back from the server.
  /// [photoPackage] and [photoVideoPackage] are null for vendor types that
  /// never see those fields, and their keys are then left untouched.
  static Map<String, dynamic> merge({
    required Map<String, dynamic> attributes,
    required String starting,
    required String min,
    required String max,
    required String description,
    required String serverPriceRange,
    String? photoPackage,
    String? photoVideoPackage,
    String? brochureBase64,
    String? brochureName,
  }) {
    final next = Map<String, dynamic>.from(attributes);

    if (starting.trim().isEmpty) {
      next.remove('starting_price');
    } else {
      final trimmed = starting.trim();
      // Migrated values look like "Rs. 40,000". Keep the text rather than
      // collapsing it to 0.
      next['starting_price'] = num.tryParse(trimmed) ?? trimmed;
    }

    final minText = min.trim();
    final maxText = max.trim();

    next['price_range'] = {'min': minText, 'max': maxText};
    next['PriceRange'] = (minText.isNotEmpty && maxText.isNotEmpty)
        ? '$minText - $maxText'
        : serverPriceRange;

    _putOrRemove(next, 'pricing_description', description);
    if (photoPackage != null) {
      _putOrRemove(next, 'photo_package_price', photoPackage);
    }
    if (photoVideoPackage != null) {
      _putOrRemove(next, 'photo_video_package_price', photoVideoPackage);
    }

    // A PDF carries a name but no base64 — it is too big for the column, so
    // the website stores the filename only and the app does the same.
    _putOrRemove(next, 'pricing_brochure_base64', brochureBase64 ?? '');
    _putOrRemove(next, 'pricing_brochure_name', brochureName ?? '');

    return next;
  }

  /// "image", "pdf", or null when there is no brochure.
  ///
  /// Reads the base64 prefix first and falls back to the file extension, the
  /// same order the website uses — a PDF has a name but never any base64.
  static String? brochureType({String? base64, String? name}) {
    if (base64 != null && base64.isNotEmpty) {
      return base64.startsWith('data:image') ? 'image' : 'pdf';
    }
    if (name != null && name.isNotEmpty) {
      return name.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image';
    }
    return null;
  }

  /// Splits the two price inputs out of a service's attributes.
  ///
  /// The `price_range` pair wins; the display string is only split apart when
  /// there is no pair to read, and a string with no dash yields nothing rather
  /// than a half-parsed value.
  static ({String min, String max}) readRange(Map<String, dynamic> attributes) {
    final pair = attributes['price_range'];
    if (pair is Map) {
      final min = pair['min']?.toString() ?? '';
      final max = pair['max']?.toString() ?? '';
      if (min.isNotEmpty || max.isNotEmpty) return (min: min, max: max);
    }

    final display = attributes['PriceRange']?.toString() ?? '';
    if (!display.contains('-')) return (min: '', max: '');

    final parts = display.split('-');
    return (
      min: parts.first.trim(),
      // Join the tail so "1-2-3" does not silently lose its end.
      max: parts.sublist(1).join('-').trim(),
    );
  }

  static void _putOrRemove(
    Map<String, dynamic> attributes,
    String key,
    String value,
  ) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      attributes.remove(key);
    } else {
      attributes[key] = trimmed;
    }
  }
}
