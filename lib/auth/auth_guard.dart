import 'package:flutter/material.dart';

import '../Screens/Login.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'session_manager.dart';

/// ============================================================================
/// AuthGuard — nothing protected renders without a valid session
/// ============================================================================
///
/// AUDIT NOTE — THE BYPASSES THIS CLOSES
///
/// The app has NO named routes and NO deep links (verified: `routes:` /
/// `onGenerateRoute` / `pushNamed` appear nowhere, and AndroidManifest.xml
/// declares only the LAUNCHER intent-filter). Every authenticated screen is
/// therefore reached by an imperative `Navigator.push` that ultimately
/// originates from `HomeScreen`, or from `MainHomeScreen` in the photographer
/// module. Guarding those roots guards the whole authenticated surface.
///
/// Bypasses that existed before:
///
///  A. SPLASH → HOME ON A TOKENLESS SESSION.
///     `SplashScreen` routed on `prefs.getBool('isLoggedIn')` alone. See
///     [SessionManager.isAuthenticated] for why that is not sufficient.
///
///  B. THE SESSION COULD DIE WHILE THE APP WAS OPEN.
///     Once past the splash, nothing ever re-checked. If the token was cleared
///     (or expired server-side) while the app sat in the background, the vendor
///     came back to a live Dashboard. [AuthGuard] re-verifies on
///     `AppLifecycleState.resumed`.
///
///  C. BACK AFTER LOGOUT.
///     Handled in [SessionManager.logout] via `pushAndRemoveUntil`. The guard
///     is the second line of defence: even if some other code path pops back
///     to a protected screen, the guard's re-check bounces it to Login.
///
/// While the check runs the guard shows a neutral splash rather than the
/// protected UI, so authenticated content is never painted — not even for one
/// frame — before the session has been verified.
/// ----------------------------------------------------------------------------
class AuthGuard extends StatefulWidget {
  /// The protected screen. Built ONLY after the session verifies.
  final Widget child;

  /// Optional label used in debug logging to identify which screen was guarded.
  final String? debugLabel;

  const AuthGuard({super.key, required this.child, this.debugLabel});

  @override
  State<AuthGuard> createState() => _AuthGuardState();

  /// Guarded replacement for `Navigator.push` when opening a protected screen.
  ///
  /// Verifies the session BEFORE pushing, so a stale button tap on a screen
  /// that is already logged out cannot open protected content at all.
  static Future<T?> push<T>(
    BuildContext context,
    WidgetBuilder builder, {
    String? debugLabel,
  }) async {
    final ok = await SessionManager.isAuthenticated();

    if (!context.mounted) return null;

    if (!ok) {
      await _redirectToLogin(context);
      return null;
    }

    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (ctx) => AuthGuard(debugLabel: debugLabel, child: builder(ctx)),
      ),
    );
  }

  static Future<void> _redirectToLogin(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }
}

class _AuthGuardState extends State<AuthGuard> with WidgetsBindingObserver {
  /// null = still checking, true = allowed, false = redirecting.
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verify();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Bypass B: re-verify whenever the app comes back to the foreground.
    if (state == AppLifecycleState.resumed) {
      _verify();
    }
  }

  Future<void> _verify() async {
    final ok = await SessionManager.isAuthenticated();

    if (!mounted) return;

    if (ok) {
      if (_allowed != true) setState(() => _allowed = true);
      return;
    }

    debugPrint(
      '🔒 AuthGuard blocked ${widget.debugLabel ?? widget.child.runtimeType} '
      '— no valid session, redirecting to Login',
    );

    setState(() => _allowed = false);

    // Defer so we are not navigating during a build/lifecycle callback.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AuthGuard._redirectToLogin(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_allowed == true) return widget.child;
    return const _AuthCheckingScreen();
  }
}

/// Neutral screen shown while the session is being verified and while the
/// redirect to Login is in flight. Deliberately contains NO business data.
class _AuthCheckingScreen extends StatelessWidget {
  const _AuthCheckingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logoo.png',
              height: 64,
              // A missing asset must not take the screen down with it.
              errorBuilder: (_, __, ___) => const Icon(
                Icons.storefront_rounded,
                color: Colors.white,
                size: 56,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Checking your session…',
              style: AppTextStyles.bodySecondary.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}