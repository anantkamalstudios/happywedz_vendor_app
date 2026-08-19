import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_weds_vendors/auth/session_manager.dart';

/// ============================================================================
/// SessionManager tests — the authentication rules this audit added
/// ============================================================================
///
/// AUDIT NOTE:
/// The project shipped with exactly one test — the stock `flutter create`
/// counter smoke test, which asserted on a counter this app has never had and
/// therefore FAILED on every run (see test/widget_test.dart, now commented out
/// with an explanation).
///
/// These tests lock in the authentication behaviour that the audit changed,
/// because it is the part most likely to silently regress:
///
///   • a logged-in FLAG without a TOKEN must count as logged OUT — this was
///     the bypass that let the app open the Dashboard with no credentials;
///   • logging out must clear the session AND the per-vendor cached counters,
///     so one vendor's figures cannot leak to the next vendor on the device;
///   • "Remember me" must survive logout, and must not survive it when the box
///     was unticked.
/// ----------------------------------------------------------------------------
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('isAuthenticated', () {
    test('is false on a fresh install', () async {
      expect(await SessionManager.isAuthenticated(), isFalse);
    });

    test('is false when the flag is set but there is NO token '
        '(the bypass this audit closed)', () async {
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
      });

      expect(await SessionManager.isAuthenticated(), isFalse);
      expect(await SessionManager.isSessionCorrupt(), isTrue);
    });

    test('is false when the token is present but empty/whitespace', () async {
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
        SessionManager.kToken: '   ',
      });

      expect(await SessionManager.isAuthenticated(), isFalse);
    });

    test('is false when a token exists but the flag was never set', () async {
      SharedPreferences.setMockInitialValues({
        SessionManager.kToken: 'abc.def.ghi',
      });

      expect(await SessionManager.isAuthenticated(), isFalse);
    });

    test('is true only with both the flag and a non-empty token', () async {
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
        SessionManager.kToken: 'abc.def.ghi',
      });

      expect(await SessionManager.isAuthenticated(), isTrue);
      expect(await SessionManager.isSessionCorrupt(), isFalse);
    });

    test('accepts a session stored only under the legacy authToken key',
        () async {
      // Different screens historically read `token` or `authToken`; both must
      // resolve, or a valid session looks empty on half the app.
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
        SessionManager.kAuthToken: 'legacy-token',
      });

      expect(await SessionManager.isAuthenticated(), isTrue);
      expect(await SessionManager.getToken(), 'legacy-token');
    });
  });

  group('saveSession', () {
    test('writes both token keys and survives null vendor fields', () async {
      // The register/login endpoints have both been observed omitting `id`.
      // Previously this threw a TypeError half-way through the write and left
      // a corrupt, half-persisted session behind.
      await SessionManager.saveSession(
        token: 'tok',
        vendorId: null,
        vendorTypeId: null,
        businessName: null,
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SessionManager.kIsLoggedIn), isTrue);
      expect(prefs.getString(SessionManager.kToken), 'tok');
      expect(prefs.getString(SessionManager.kAuthToken), 'tok');
      expect(prefs.getInt(SessionManager.kVendorId), isNull);
      expect(await SessionManager.isAuthenticated(), isTrue);
    });

    test('persists the vendor fields it is given', () async {
      await SessionManager.saveSession(
        token: 'tok',
        vendorId: 42,
        vendorTypeId: 1,
        businessName: 'Blue Lotus Studio',
        email: 'vendor@example.com',
      );

      expect(await SessionManager.getVendorId(), 42);
      expect(await SessionManager.getVendorTypeId(), 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SessionManager.kBusinessName), 'Blue Lotus Studio');
    });
  });

  group('clearSession', () {
    test('removes the session and the per-vendor cached counters', () async {
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
        SessionManager.kToken: 'tok',
        SessionManager.kAuthToken: 'tok',
        SessionManager.kVendorId: 42,
        SessionManager.kVendorTypeId: 1,
        SessionManager.kBusinessName: 'Blue Lotus Studio',
        // These leaked across accounts before the audit: the old drawer logout
        // never removed them, so the NEXT vendor to log in on this device saw
        // the previous vendor's lead and view counts in the drawer.
        SessionManager.kLeadCount: 17,
        SessionManager.kViewsCount: 230,
        SessionManager.kUnreadLeadsCount: 4,
      });

      await SessionManager.clearSession();

      final prefs = await SharedPreferences.getInstance();
      expect(await SessionManager.isAuthenticated(), isFalse);
      expect(prefs.getString(SessionManager.kToken), isNull);
      expect(prefs.getString(SessionManager.kAuthToken), isNull);
      expect(prefs.getInt(SessionManager.kVendorId), isNull);
      expect(prefs.getString(SessionManager.kBusinessName), isNull);
      expect(prefs.getInt(SessionManager.kLeadCount), isNull);
      expect(prefs.getInt(SessionManager.kViewsCount), isNull);
      expect(prefs.getInt(SessionManager.kUnreadLeadsCount), isNull);
    });

    test('KEEPS saved credentials when "Remember me" was on', () async {
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
        SessionManager.kToken: 'tok',
        SessionManager.kEmail: 'vendor@example.com',
        SessionManager.kSavedPassword: 'hunter2',
      });

      await SessionManager.clearSession();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SessionManager.kEmail), 'vendor@example.com');
      expect(prefs.getString(SessionManager.kSavedPassword), 'hunter2');
      // …but the session itself is gone.
      expect(await SessionManager.isAuthenticated(), isFalse);
    });

    test('CLEARS the saved email when "Remember me" was off', () async {
      // Remember-me off means no saved password, which is how the existing
      // drawer logout detected it. The email must not linger.
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
        SessionManager.kToken: 'tok',
        SessionManager.kEmail: 'vendor@example.com',
      });

      await SessionManager.clearSession();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SessionManager.kEmail), isNull);
    });

    test('a cleared session cannot be revived by the logged-in flag alone',
        () async {
      SharedPreferences.setMockInitialValues({
        SessionManager.kIsLoggedIn: true,
        SessionManager.kToken: 'tok',
      });

      await SessionManager.clearSession();

      // Simulate something re-setting only the flag (a partial write, a stale
      // code path). The app must still treat this as logged out.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SessionManager.kIsLoggedIn, true);

      expect(await SessionManager.isAuthenticated(), isFalse);
      expect(await SessionManager.isSessionCorrupt(), isTrue);
    });
  });

  group('isUnauthorized', () {
    test('treats 401 and 403 as session loss, and nothing else', () {
      expect(SessionManager.isUnauthorized(401), isTrue);
      expect(SessionManager.isUnauthorized(403), isTrue);
      expect(SessionManager.isUnauthorized(200), isFalse);
      expect(SessionManager.isUnauthorized(404), isFalse);
      expect(SessionManager.isUnauthorized(500), isFalse);
    });
  });
}
