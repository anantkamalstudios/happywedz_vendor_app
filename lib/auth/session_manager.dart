import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// SessionManager — the single source of truth for "is this vendor logged in?"
/// ============================================================================
///
/// AUDIT NOTE — WHAT WAS WRONG BEFORE
///
/// 1. THE SESSION CHECK WAS A BOOL ONLY.
///    `SplashScreen` and `Login._checkIfLoggedIn()` both did:
///        prefs.getBool('isLoggedIn') ?? false
///    and nothing else. If the bool survived but the token did not (a partly
///    completed logout, a `prefs.clear()` race, an app upgrade, a token the
///    server had already revoked), the app opened straight onto the Dashboard
///    with no credentials. Every screen then fired its request with
///    `Authorization: Bearer null`, every response came back 401, and each
///    screen swallowed it in a `catch` that only `debugPrint`ed — so the user
///    sat on a fully "logged in" dashboard where nothing ever loaded and no
///    error was ever shown. [isAuthenticated] now requires BOTH the flag and a
///    non-empty token.
///
/// 2. LOGOUT LOGIC LIVED INSIDE A DRAWER WIDGET.
///    `BusinessDrawer` was the only place that knew which keys make up a
///    session. Nothing else could clear a session correctly. That list is now
///    here, in [clearSession], with the SAME keys and the SAME "Remember me"
///    behaviour the drawer already implemented.
///
/// 3. LOGOUT USED `pushReplacement`.
///    That replaces only the top route. Any protected screen the vendor had
///    pushed (Storefront, Enquiry detail, the photographer module …) stayed
///    underneath, so pressing Back after logging out returned to authenticated
///    content. [logout] uses `pushAndRemoveUntil(… , (route) => false)`, which
///    tears the whole stack down.
///
/// THE STORAGE KEYS AND THEIR MEANINGS ARE UNCHANGED — this class reads and
/// writes exactly the keys the existing Login / SignUp screens already write.
/// ----------------------------------------------------------------------------
class SessionManager {
  SessionManager._();

  // ==========================================================================
  // KEYS — these are the EXISTING keys used by Login.dart / SignUp.dart.
  // Do not rename them; doing so would log every current user out on upgrade.
  // ==========================================================================
  static const String kIsLoggedIn = 'isLoggedIn';
  static const String kAuthToken = 'authToken';
  static const String kToken = 'token';
  static const String kVendorId = 'vendorId';
  static const String kVendorTypeId = 'vendorTypeId';
  static const String kVendorTypeName = 'vendorTypeName';
  static const String kVendorType = 'vendorType';
  static const String kBusinessName = 'businessName';
  static const String kEmail = 'email';
  static const String kSavedPassword = 'savedPassword';
  static const String kPhone = 'phone';
  static const String kProfileImage = 'profileImage';
  static const String kProfileCompleted = 'profileCompleted';
  static const String kCoverImage = 'coverImage';

  // Cached/derived values written by other screens; cleared on logout so the
  // next vendor never sees the previous vendor's numbers.
  static const String kLeadCount = 'lead_count';
  static const String kViewsCount = 'views_count';
  static const String kImpressionCount = 'impression_count';
  static const String kUnreadLeadsCount = 'unread_leads_count';
  static const String kReadLeads = 'read_leads';
  static const String kPendingFaqAnswers = 'pendingFaqAnswers';

  // ==========================================================================
  // READ
  // ==========================================================================

  /// The bearer token. Reads `token` first and falls back to `authToken`,
  /// which is the exact order every existing API call in this app already
  /// uses — both keys are written at login.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(kToken) ?? prefs.getString(kAuthToken);
    if (token == null || token.trim().isEmpty) return null;
    return token;
  }

  static Future<int?> getVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(kVendorId);
  }

  static Future<int?> getVendorTypeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(kVendorTypeId);
  }

  /// TRUE only when the session is actually usable: the logged-in flag is set
  /// AND a non-empty token exists. A flag without a token is treated as
  /// logged OUT (see note 1 above).
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool(kIsLoggedIn) ?? false;
    if (!flag) return false;

    final token = prefs.getString(kToken) ?? prefs.getString(kAuthToken);
    return token != null && token.trim().isNotEmpty;
  }

  /// A session that is flagged logged-in but has no token is corrupt. Callers
  /// use this to decide whether to show "Session expired" rather than a plain
  /// login screen.
  static Future<bool> isSessionCorrupt() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool(kIsLoggedIn) ?? false;
    final token = prefs.getString(kToken) ?? prefs.getString(kAuthToken);
    return flag && (token == null || token.trim().isEmpty);
  }

  // ==========================================================================
  // WRITE
  // ==========================================================================

  /// Persists a successful login. Null-safe: the previous implementation in
  /// Login.dart called `prefs.setInt('vendorId', vendorData['id'])` directly,
  /// which throws a `TypeError` and aborts the whole login when the API
  /// response omits `id`.
  static Future<void> saveSession({
    required String token,
    int? vendorId,
    int? vendorTypeId,
    String? businessName,
    String? email,
    String? phone,
    String? profileImage,
    bool? profileCompleted,
    String? vendorTypeName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(kIsLoggedIn, true);
    // Both keys are written because different screens read different ones.
    await prefs.setString(kAuthToken, token);
    await prefs.setString(kToken, token);

    if (vendorId != null) await prefs.setInt(kVendorId, vendorId);
    if (vendorTypeId != null) await prefs.setInt(kVendorTypeId, vendorTypeId);
    if (businessName != null) await prefs.setString(kBusinessName, businessName);
    if (email != null) await prefs.setString(kEmail, email);
    if (phone != null) await prefs.setString(kPhone, phone);
    if (profileImage != null) await prefs.setString(kProfileImage, profileImage);
    if (profileCompleted != null) {
      await prefs.setBool(kProfileCompleted, profileCompleted);
    }
    if (vendorTypeName != null) {
      await prefs.setString(kVendorTypeName, vendorTypeName);
    }
  }

  // ==========================================================================
  // CLEAR
  // ==========================================================================

  /// Removes every session key.
  ///
  /// "Remember me" semantics are preserved EXACTLY as the drawer already
  /// implemented them: the saved email + password are kept only when the
  /// vendor had previously ticked Remember me (i.e. both are present).
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberMe = prefs.getString(kSavedPassword) != null &&
        prefs.getString(kEmail) != null;

    for (final key in const [
      kIsLoggedIn,
      kAuthToken,
      kToken,
      kVendorId,
      kVendorTypeId,
      kVendorTypeName,
      kVendorType,
      kBusinessName,
      kPhone,
      kProfileImage,
      kProfileCompleted,
      kCoverImage,
      // Per-vendor cached figures — these leaked across accounts before,
      // because the drawer's logout never removed them. The next vendor to
      // log in on the same device saw the previous vendor's lead/views counts
      // in the drawer until their own Statistics screen happened to refresh.
      kLeadCount,
      kViewsCount,
      kImpressionCount,
      kUnreadLeadsCount,
      kReadLeads,
      kPendingFaqAnswers,
    ]) {
      await prefs.remove(key);
    }

    if (!rememberMe) {
      await prefs.remove(kEmail);
      await prefs.remove(kSavedPassword);
    }
  }

  // ==========================================================================
  // LOGOUT / REDIRECT
  // ==========================================================================

  /// Clears the session and returns to Login, destroying the entire navigation
  /// stack so Back cannot reach any authenticated screen.
  ///
  /// [loginPageBuilder] is injected by the caller to keep this file free of a
  /// dependency on the Screens layer.
  static Future<void> logout(
    BuildContext context, {
    required WidgetBuilder loginPageBuilder,
  }) async {
    await clearSession();

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: loginPageBuilder),
      (route) => false, // <-- destroys every route beneath
    );
  }

  /// True when an HTTP status means the session is no longer valid.
  static bool isUnauthorized(int statusCode) =>
      statusCode == 401 || statusCode == 403;
}