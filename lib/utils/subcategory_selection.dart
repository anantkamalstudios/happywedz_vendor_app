import 'package:shared_preferences/shared_preferences.dart';

/// A vendor can sit under more than one subcategory, matching the website's
/// "Primary Subcategory" multi-select on the Basic Information screen.
///
/// Wire format (same as the website):
/// * Reading — the vendor-service payload carries the primary in
///   `vendor_subcategory_id` and the full set in a `subcategories` array.
/// * Writing — `vendor_subcategory_id` is sent as a comma separated list. The
///   backend keeps the first id as the primary and mirrors every id into its
///   join table, so a save that carries only one id drops the rest.
class SubcategorySelection {
  SubcategorySelection._();

  static const String _idsKey = 'vendor_subcategory_ids';
  static const String _primaryKey = 'vendor_subcategory_id';

  /// Reads the selected ids out of a vendor-service payload, primary first.
  static List<int> fromService(Map<String, dynamic>? service) {
    if (service == null) return const [];

    final joined = service['subcategories'];
    final ids = <int>[];
    if (joined is List) {
      for (final item in joined) {
        final id = _toInt(item is Map ? item['id'] : item);
        if (id != null) ids.add(id);
      }
    }

    return order(ids, _toInt(service['vendor_subcategory_id']));
  }

  /// Primary first, duplicates removed.
  static List<int> order(List<int> ids, int? primary) {
    final seen = <int>{};
    if (primary != null) seen.add(primary);
    seen.addAll(ids);
    return seen.toList();
  }

  /// The value to send as `vendor_subcategory_id`. A lone id stays an int so
  /// existing payloads look exactly as they did before.
  static Object? payload(List<int> ids) {
    if (ids.isEmpty) return null;
    if (ids.length == 1) return ids.first;
    return ids.join(',');
  }

  static Future<void> save(List<int> ids) async {
    final prefs = await SharedPreferences.getInstance();
    if (ids.isEmpty) {
      await prefs.remove(_idsKey);
      return;
    }
    await prefs.setInt(_primaryKey, ids.first);
    await prefs.setStringList(_idsKey, ids.map((id) => '$id').toList());
  }

  /// The stored selection, falling back to the primary id on its own.
  static Future<List<int>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final primary = prefs.getInt(_primaryKey);
    final stored = prefs.getStringList(_idsKey);

    if (stored == null || stored.isEmpty) {
      return primary == null ? const [] : [primary];
    }
    final ids = stored.map(int.tryParse).whereType<int>().toList();

    // The list is only trustworthy while it still covers the primary. Contact
    // Details and Facilities write the primary key on their own, so a primary
    // that is missing here means the list belongs to an older selection.
    if (primary != null && !ids.contains(primary)) return [primary];

    return order(ids, primary);
  }

  /// `vendor_subcategory_id` for the screens that only track the primary, so
  /// saving one of them keeps the other selections intact.
  ///
  /// The extras are only attached when the stored primary is the same one the
  /// caller is saving. A stored list left over from another vendor or another
  /// service would otherwise add subcategories nobody picked, so in that case
  /// this returns exactly what the caller would have sent on its own.
  static Future<Object?> payloadForPrimary(int? primary) async {
    if (primary == null) return null;

    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_primaryKey) != primary) return primary;

    final stored = await load();
    return stored.isEmpty ? primary : payload(stored);
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
