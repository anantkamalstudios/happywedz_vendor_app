/// Reading a vendor's 360° assets, and sanitising the link they paste.
///
/// Ported from the website's `src/utils/view360Helper.js`, whose docstring
/// lists the shapes these assets can arrive in — they depend on how and when
/// the record was last saved:
///
///   * top level string columns : `view360_image` / `view360_video`
///   * top level arrays         : `view360_images` / `view360_video`
///   * inside attributes        : `attributes.view360_images` / `..._video`
///   * a pasted link            : `attributes.view360_url`
///
/// Anything reading these has to accept all of them, so this is the one place
/// that knows the list.
class View360Assets {
  View360Assets._();

  /// The vendor's pasted link, but only when it is a plain http(s) URL.
  ///
  /// Vendors can type anything, and the value ends up in a link the app opens,
  /// so `javascript:`, `data:` and junk must never come back out. Stray
  /// backticks are stripped because pasted links often arrive wrapped in them.
  static String? safeUrl(dynamic value) {
    final cleaned = _clean(value);
    if (cleaned == null) return null;

    final parsed = Uri.tryParse(cleaned);
    if (parsed == null || !parsed.hasScheme || !parsed.hasAuthority) {
      return null;
    }
    final scheme = parsed.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;

    return parsed.toString();
  }

  /// Every 360° video on the record, in the order the shapes are checked,
  /// without duplicates.
  static List<String> videos(Map<String, dynamic>? service) {
    if (service == null) return const [];
    final attributes = _attributes(service);

    return _dedupe([
      ..._toList(service['view360_video']),
      ..._toList(service['view360_videos']),
      ..._toList(service['view360Videos']),
      ..._toList(attributes['view360_video']),
      ..._toList(attributes['view360_videos']),
    ]);
  }

  /// Every 360° pano image on the record.
  ///
  /// The website's own upload tab for these is commented out, but records
  /// saved earlier still carry them, so they are still read.
  static List<String> images(Map<String, dynamic>? service) {
    if (service == null) return const [];
    final attributes = _attributes(service);

    return _dedupe([
      ..._toList(service['view360_image']),
      ..._toList(service['view360_images']),
      ..._toList(service['view360Images']),
      ..._toList(attributes['view360_image']),
      ..._toList(attributes['view360_images']),
    ]);
  }

  /// True when the vendor has any 360° content at all.
  static bool has(Map<String, dynamic>? service) {
    if (service == null) return false;
    return videos(service).isNotEmpty ||
        images(service).isNotEmpty ||
        safeUrl(_attributes(service)['view360_url'] ??
                service['view360_url']) !=
            null;
  }

  static Map<String, dynamic> _attributes(Map<String, dynamic> service) {
    final attributes = service['attributes'];
    return attributes is Map
        ? Map<String, dynamic>.from(attributes)
        : <String, dynamic>{};
  }

  /// A usable string out of a plain value or an object carrying a url.
  static String? _entry(dynamic value) {
    if (value is Map) {
      return _clean(value['url'] ?? value['path'] ?? value['location']);
    }
    return _clean(value);
  }

  static List<String> _toList(dynamic value) {
    if (value == null) return const [];
    final items = value is List ? value : [value];
    return items.map(_entry).whereType<String>().toList();
  }

  /// Trims, strips wrapping backticks, and rejects the literal strings the API
  /// sometimes returns in place of a real absence.
  static String? _clean(dynamic value) {
    if (value is! String) return null;
    final cleaned = value.replaceAll(RegExp(r'^\s*`|`\s*$'), '').trim();
    if (cleaned.isEmpty) return null;
    final lower = cleaned.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;
    return cleaned;
  }

  static List<String> _dedupe(List<String> items) {
    final seen = <String>{};
    for (final item in items) {
      seen.add(item);
    }
    return seen.toList();
  }
}
