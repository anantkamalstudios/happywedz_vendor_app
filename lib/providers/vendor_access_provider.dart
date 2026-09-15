import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/vendor_access_api.dart';

/// Vendor's onboarding/subscription state for the whole storefront.
///
/// Fetched fresh on every read rather than cached in SharedPreferences: a stale
/// copy must never be what decides whether a tab looks editable. The server
/// enforces the real rule independently — this only decides what the UI shows.
/// Mirrors `backen/src/context/VendorAccessContext.jsx`.
final vendorAccessProvider = FutureProvider.autoDispose<VendorAccess>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return const VendorAccess();
  return VendorAccessApi().getAccess(token);
});
