import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_services/vendor_access_api.dart';

/// Vendor's onboarding/subscription state for the whole storefront.
///
/// Never cached in SharedPreferences: a stale copy must never be what decides
/// whether a tab looks editable or a plan-gated feature (CRM, Instagram) is
/// shown. HomeScreen keeps it loaded for the session and re-reads it on launch
/// and resume; the drawer re-reads it when opened, and plan purchase screens
/// invalidate it. The server enforces the real rule independently — this only
/// decides what the UI shows.
/// Mirrors `backen/src/context/VendorAccessContext.jsx`.
final vendorAccessProvider = FutureProvider.autoDispose<VendorAccess>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');
  if (token == null) return const VendorAccess();
  return VendorAccessApi().getAccess(token);
});

/// Plan-gated feature ids, as the server sends them in `access.modules`.
/// Only the ids the app has screens for — never a list of what exists.
class VendorModules {
  VendorModules._();
  static const String crm = 'crm';
  static const String instagram = 'instagram';
}

/// True only once access has loaded and the plan includes [module]. False
/// while loading, so nothing gated flashes into view and then disappears.
final vendorHasModuleProvider = Provider.autoDispose.family<bool, String>(
  (ref, module) =>
      ref.watch(vendorAccessProvider).value?.hasModule(module) ?? false,
);
