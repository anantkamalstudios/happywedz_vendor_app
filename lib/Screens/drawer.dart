import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../Storefront/StoreFront.dart';
import '../auth/auth_guard.dart';
import '../auth/session_manager.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/app_network_image.dart';
import '../widgets/app_shimmer.dart';
import '../widgets/app_snackbar.dart';
import 'Login.dart';

/// ============================================================================
/// BusinessDrawer — the app's main navigation drawer
/// ============================================================================
///
/// API INTEGRATION IS UNCHANGED:
///   GET https://happywedz.com/api/vendor-services/vendor/{vendorId}
///       (used to derive the public review link)
///
/// AUDIT NOTE — THE LOGOUT BUG (critical, auth bypass)
///
/// The old logout did:
///     Navigator.pushReplacement(context, … Login());
///
/// `pushReplacement` swaps only the TOPMOST route. Reproduction of the bypass:
///
///     Login → Dashboard → open Storefront → open drawer → Logout
///       stack before: [Login(replaced), Dashboard, Storefront]
///       pushReplacement swaps Storefront  →  [Dashboard, Login]
///       press Back                        →  Dashboard, fully interactive,
///                                            with every "protected" screen
///                                            reachable again.
///
/// Session data was already cleared at that point, so the resurrected
/// Dashboard fired all of its requests with a null token, every one came back
/// 401, and every screen swallowed the 401 in a silent catch. The vendor saw a
/// working-looking but permanently empty app.
///
/// Logout now routes through [SessionManager.logout], which uses
/// `pushAndRemoveUntil(…, (route) => false)` to tear down the ENTIRE stack.
/// [AuthGuard] on the Dashboard is the second line of defence.
///
/// OTHER FIXES
///   • Logout had no confirmation — a mis-tap in a drawer signed the vendor
///     out instantly.
///   • The drawer was not closed before navigating, leaving it animating over
///     the Login screen.
///   • `coverImage` was read as a local file path written by the image picker
///     and rendered via `FileImage` inside a `DecorationImage` with no error
///     handling: once the OS cleared the picker's cache directory (routine on
///     Android) the file was gone and the drawer header threw an uncaught
///     image exception on every open.
///   • Every `ScaffoldMessenger.of(context)` call after an `await` was
///     unguarded (`use_build_context_synchronously`).
/// ----------------------------------------------------------------------------
class BusinessDrawer extends StatefulWidget {
  const BusinessDrawer({super.key});

  @override
  State<BusinessDrawer> createState() => _BusinessDrawerState();
}

class _BusinessDrawerState extends State<BusinessDrawer> {
  String userName = "";
  String userEmail = "";
  String coverImage = "";

  bool _isLoading = true;

  int leadCount = 0;
  int viewsCount = 0;
  int? vendorId;

  bool loadingLink = false;
  String? reviewLink;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// AUDIT FIX: `_loadUserData` and `_loadVendorId` were two separate async
  /// calls each with their own `setState`, which produced two rebuilds and a
  /// window where `vendorId` was still null while the menu was already
  /// tappable (tapping Storefront in that window showed "Vendor ID not found.
  /// Please login again." even though the vendor was perfectly logged in).
  /// They are merged into a single load.
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(SessionManager.kBusinessName) ?? "";
    final email = prefs.getString(SessionManager.kEmail) ?? "";
    final cover = prefs.getString(SessionManager.kCoverImage) ?? "";
    final id = prefs.getInt(SessionManager.kVendorId);
    final leads = prefs.getInt(SessionManager.kLeadCount) ?? 0;
    final views = prefs.getInt(SessionManager.kViewsCount) ?? 0;

    if (!mounted) return;

    setState(() {
      // AUDIT NOTE: the previous defaults were the literal strings
      // "Vendor Name" and "vendor@example.com" — placeholder business data
      // shown as if it were real. They are replaced with honest copy.
      userName = name.isNotEmpty ? name : "Your Business";
      userEmail = email;
      coverImage = cover;
      vendorId = id;
      leadCount = leads;
      viewsCount = views;
      _isLoading = false;
    });
  }

  Future<void> _contactSupport() async {
    final prefs = await SharedPreferences.getInstance();
    final fromEmail = prefs.getString(SessionManager.kEmail) ?? "";

    final Uri emailUri = Uri(
      scheme: "mailto",
      path: "pranjal.anantkamal@gmail.com",
      query: "subject=Support Request"
          "&body=Hello,\n\nMy registered email is: $fromEmail\n\nWrite your query here...",
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ Email launch error: $e");
      if (mounted) {
        AppSnackbar.error(context, "No email app is available on this device.");
      }
    }
  }

  /// ✅ Pick Image
  Future<void> _pickCoverImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        // AUDIT FIX: unbounded picks produced 8–12 MB bitmaps that were
        // decoded at full size into the 180px drawer header.
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (pickedFile == null) return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(SessionManager.kCoverImage, pickedFile.path);

      if (!mounted) return;
      setState(() => coverImage = pickedFile.path);
      AppSnackbar.success(context, "Cover image updated");
    } catch (e) {
      debugPrint("❌ Cover image pick failed: $e");
      if (mounted) {
        AppSnackbar.error(context, "Couldn't update the cover image.");
      }
    }
  }

  /// ✅ Remove Image
  Future<void> _removeCoverImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(SessionManager.kCoverImage);

    if (!mounted) return;
    setState(() => coverImage = "");
    AppSnackbar.success(context, "Cover image removed");
  }

  // ==========================================================================
  // LOGOUT
  // ==========================================================================

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text("Log out?", style: AppTextStyles.h3),
        content: Text(
          "You'll need to sign in again to manage your business.",
          style: AppTextStyles.bodySecondary,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Log out"),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Close the drawer first so it is not left animating over Login.
    Navigator.pop(context);

    if (!mounted) return;

    // AUDIT FIX (critical): clears the session AND destroys the whole
    // navigation stack, so Back cannot return to any protected screen.
    await SessionManager.logout(
      context,
      loginPageBuilder: (_) => const Login(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: _isLoading
          ? const SafeArea(child: ProfileShimmer())
          : SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  Expanded(child: _menu()),
                  const Divider(height: 1),
                  _logoutTile(),
                  // AUDIT FIX: the logout tile previously sat flush against
                  // the bottom edge, under the gesture-navigation bar on
                  // modern Android devices.
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header() {
    return SizedBox(
      height: 180,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background: brand gradient, or the chosen cover image over it.
          // AUDIT FIX: was `Colors.pink[100]` — a colour that appears nowhere
          // else in this app's palette and clashed with the blue brand.
          Container(decoration: const BoxDecoration(gradient: AppColors.headerGradient)),

          if (coverImage.isNotEmpty) _coverImageLayer(),

          // Scrim so the business name stays readable over any cover image.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  userName,
                  // AUDIT FIX (RenderFlex/text overflow): a long business name
                  // previously overflowed the header with no maxLines.
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h1.copyWith(color: Colors.white),
                ),
                if (userEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),

          // Cover image controls, restored from the previously commented-out
          // `_showEditOptions` bottom sheet (the picker methods were live but
          // completely unreachable — see the audit report).
          Positioned(
            top: 8,
            right: 8,
            child: Material(
              color: Colors.black26,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: "Change cover image",
                icon: const Icon(Icons.photo_camera_outlined,
                    color: Colors.white, size: 20),
                onPressed: _showEditOptions,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the cover image. Handles BOTH shapes the app stores in
  /// `coverImage`: a remote URL, or a local file path from the image picker.
  Widget _coverImageLayer() {
    if (coverImage.startsWith('http')) {
      return AppNetworkImage(url: coverImage, fit: BoxFit.cover);
    }

    final file = File(coverImage);
    // AUDIT FIX: the previous `FileImage(File(path))` inside a
    // `DecorationImage` threw an uncaught exception once Android cleared the
    // picker cache. Existence is now checked, and decode failures fall back to
    // the gradient instead of crashing the drawer.
    if (!file.existsSync()) return const SizedBox.shrink();

    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  /// Restored from the pre-existing (commented-out) implementation.
  void _showEditOptions() {
    showModalBottomSheet(
      backgroundColor: AppColors.surface,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: AppColors.primary),
              title: Text("Change photo", style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickCoverImage();
              },
            ),
            if (coverImage.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(
                  "Remove photo",
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _removeCoverImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------------- MENU ----------------
  Widget _menu() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _menuTile(
          icon: Icons.storefront_outlined,
          label: "Storefront",
          onTap: () {
            Navigator.pop(context);

            if (vendorId == null) {
              AppSnackbar.warning(
                context,
                "Vendor ID not found. Please log in again.",
              );
              return;
            }

            // AUDIT FIX: guarded push — a stale tap after the session has
            // expired can no longer open the Storefront.
            AuthGuard.push(
              context,
              (_) => Storefront(vendorId: vendorId!),
              debugLabel: 'Storefront',
            );
          },
        ),
        _menuTile(
          icon: Icons.reviews_outlined,
          label: "Get Client Review to You",
          trailing: loadingLink
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : null,
          // AUDIT FIX: the tile stayed tappable while the link request was in
          // flight, so a fast double tap fired the vendor-services GET twice.
          onTap: loadingLink ? null : _shareReviewLink,
        ),
        _menuTile(
          icon: Icons.support_agent_outlined,
          label: "Contact Support",
          onTap: () {
            Navigator.pop(context);
            _contactSupport();
          },
        ),
        _menuTile(
          icon: Icons.star_rate_outlined,
          label: "Rate on Play Store",
          onTap: _rateOnPlayStore,
        ),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(label, style: AppTextStyles.bodyMedium),
      trailing: trailing,
      onTap: onTap,
      // Consistent tap target height across every drawer row.
      minVerticalPadding: 14,
    );
  }

  Widget _logoutTile() {
    return ListTile(
      leading: const Icon(Icons.logout_rounded, color: AppColors.error),
      title: Text(
        'Logout',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
      ),
      minVerticalPadding: 14,
      onTap: _confirmLogout,
    );
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  Future<void> _shareReviewLink() async {
    await _generateReviewLinkOnce();

    if (!mounted) return;

    if (reviewLink == null || reviewLink!.isEmpty) {
      AppSnackbar.error(
        context,
        "Couldn't generate your review link. Please try again.",
      );
      return;
    }

    await Share.share(
      "Hey! 😊\n\n"
      "Please take a moment to share your review about my work:\n\n"
      "$reviewLink\n\n"
      "Thank you so much! 🙏",
    );
  }

  Future<void> _rateOnPlayStore() async {
    const playStoreUrl =
        "https://play.google.com/store/apps/details?id=com.happy.happy_weds_vendors";

    final uri = Uri.parse(playStoreUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        AppSnackbar.error(context, "Unable to open the Play Store");
      }
    } catch (e) {
      // AUDIT FIX: `canLaunchUrl` needs a <queries> entry on Android 11+ and
      // returns false for perfectly launchable URLs when it is missing, so the
      // old guard produced a false "Unable to open Play Store". Launch
      // directly and handle the failure instead.
      debugPrint("❌ Play Store launch failed: $e");
      if (mounted) AppSnackbar.error(context, "Unable to open the Play Store");
    }
  }

  // ================= GET VENDOR SERVICE ID (UNCHANGED ENDPOINT) =============
  Future<int?> _getVendorServiceId(int vendorId) async {
    // AUDIT FIX: read only `token` before. Every other call site in the app
    // falls back to `authToken`; this one silently returned null when only
    // `authToken` was present.
    final token = await SessionManager.getToken();
    if (token == null) return null;

    try {
      final res = await http.get(
        Uri.parse("https://happywedz.com/api/vendor-services/vendor/$vendorId"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 20));

      if (res.statusCode == 200) {
        final decoded = json.decode(res.body);
        // AUDIT FIX: `final List data = json.decode(...)` threw a raw
        // TypeError whenever the endpoint returned an object (its error shape)
        // instead of a list.
        if (decoded is List && decoded.isNotEmpty) {
          final first = decoded.first;
          if (first is Map) return _asInt(first['id']);
        }
      } else {
        debugPrint("❌ vendor-services returned ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ vendor-services lookup failed: $e");
    }
    return null;
  }

  Future<void> _generateReviewLinkOnce() async {
    if (reviewLink != null && reviewLink!.isNotEmpty) return; // generate once

    final id = vendorId ?? await SessionManager.getVendorId();
    if (id == null) return;

    if (!mounted) return;
    setState(() => loadingLink = true);

    final serviceId = await _getVendorServiceId(id);

    if (!mounted) return;
    setState(() {
      loadingLink = false;
      reviewLink = serviceId != null
          ? "https://happywedz.com/write-review/$serviceId"
          : null;
    });
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  // ==========================================================================
  // AUDIT NOTE — RETAINED, CURRENTLY UNUSED HELPERS
  //
  // `_statItem`, `_drawerItem` and `_showRateDialog` existed in this file but
  // were never called from anywhere (verified by grep across lib/). They are
  // kept, commented out, per the audit rules — `_drawerItem` in particular is
  // the generic row builder this drawer would use if more destinations are
  // added, and `_statItem` pairs with the `leadCount` / `viewsCount` fields
  // that are still loaded above.
  //
  // Do not delete without project-owner approval.
  // ==========================================================================
  //
  // /// Stat Item
  // static Widget _statItem(String title, String value) {
  //   return Column(
  //     children: [
  //       Text(
  //         value,
  //         style: const TextStyle(
  //           fontSize: 18,
  //           fontWeight: FontWeight.bold,
  //         ),
  //       ),
  //       Text(title, style: const TextStyle(fontSize: 13)),
  //     ],
  //   );
  // }
  //
  // /// Drawer Item
  // Widget _drawerItem(
  //     BuildContext context,
  //     IconData icon,
  //     String title,
  //     Widget page, {
  //       Color iconColor = Colors.blue,
  //     }) {
  //   return ListTile(
  //     leading: Icon(icon, color: iconColor),
  //     title: Text(title),
  //     onTap: () {
  //       Navigator.pop(context);
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(builder: (_) => page),
  //       ).then((_) => _loadUserData());
  //     },
  //   );
  // }
  //
  // /// Rate Sheet
  // void _showRateDialog(BuildContext context) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (_) => const SizedBox(
  //       height: 200,
  //       child: Center(child: Text("Rate bottom sheet")),
  //     ),
  //   );
  // }
}