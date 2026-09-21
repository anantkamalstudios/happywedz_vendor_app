import 'package:flutter/material.dart';

import 'Screens/HomeScreen.dart';
import 'Screens/Login.dart';
import 'auth/auth_guard.dart';
import 'auth/session_manager.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';

/// ============================================================================
/// SplashScreen — app entry point and the FIRST authentication gate
/// ============================================================================
///
/// AUDIT NOTE — WHAT WAS FIXED HERE
///
/// 1. THE SPLASH BLOCKED THE APP FOR 10 SECONDS.
///    The AnimationController was `Duration(seconds: 10)` and navigation was
///    driven by its `completed` status listener, so EVERY cold start — even
///    with the session already resolved in ~30ms — sat on the progress bar for
///    a full ten seconds. Now the controller runs for 2.2s and navigation
///    happens as soon as BOTH the minimum brand moment and the session check
///    are done, whichever finishes last.
///
/// 2. THE SESSION CHECK COULD LOSE ITS RACE SILENTLY.
///    `_checkLoginStatus()` was fired without `await` and its result was read
///    later by the animation listener. It happened to work only because the
///    animation was 10s long. With a short splash that is a real race, so the
///    check is now awaited explicitly.
///
/// 3. IT ROUTED ON A BOOL ALONE.
///    `prefs.getBool('isLoggedIn')` was the entire gate. A session whose token
///    had been cleared still counted as logged in and dropped the vendor onto
///    a Dashboard where every API call returned 401. It now uses
///    [SessionManager.isAuthenticated], which requires a non-empty token too,
///    and a token-less "logged in" flag is cleaned up before showing Login.
///
/// 4. IT PUSHED HomeScreen UNGUARDED.
///    HomeScreen is now wrapped in [AuthGuard], which re-verifies the session
///    on every app resume.
/// ----------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  /// Minimum time the brand moment stays on screen. Long enough to read,
  /// short enough not to feel broken.
  static const Duration _minimumSplash = Duration(milliseconds: 2200);

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: _minimumSplash,
    )..forward();

    _bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================= BOOTSTRAP =================

  /// Runs the session check and the minimum splash duration CONCURRENTLY and
  /// navigates when the slower of the two finishes.
  Future<void> _bootstrap() async {
    bool isAuthenticated = false;

    try {
      final results = await Future.wait<Object>([
        SessionManager.isAuthenticated(),
        Future<Object>.delayed(_minimumSplash, () => true),
      ]);
      isAuthenticated = results.first == true;

      // A "logged in" flag with no token is a corrupt session (a partially
      // completed logout, or storage cleared by the OS). Tidy it up so the
      // vendor gets a clean Login instead of a half-authenticated state.
      if (!isAuthenticated && await SessionManager.isSessionCorrupt()) {
        debugPrint('🔒 Splash: corrupt session detected — clearing');
        await SessionManager.clearSession();
      }
    } catch (e) {
      // Storage failure must never leave the user stranded on the splash.
      // Failing closed (to Login) is the safe direction.
      debugPrint('❌ Splash session check failed: $e');
      isAuthenticated = false;
    }

    _navigateNext(isAuthenticated);
  }

  // ================= NAVIGATION =================

  void _navigateNext(bool isAuthenticated) {
    if (!mounted || _navigated) return;
    _navigated = true;

    debugPrint(
      isAuthenticated
          ? '🔓 Splash: valid session → Dashboard'
          : '🔒 Splash: no valid session → Login',
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isAuthenticated
            // AUDIT FIX: the Dashboard is never reached unguarded.
            ? const AuthGuard(debugLabel: 'HomeScreen', child: HomeScreen())
            : const Login(),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ===== LOGO =====
              // AUDIT FIX: `width: double.infinity` with `height: 250` forced
              // the image to fill the full screen width, which on small
              // devices squashed the logo against the edges. Constrained to a
              // fraction of the width instead, and given an errorBuilder so a
              // missing asset cannot take the launch screen down.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Image.asset(
                  "assets/images/splashlogo.png",
                  height: 200,
                  fit: BoxFit.contain,
                  color: Colors.white,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.storefront_rounded,
                    size: 96,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ===== PROGRESS BAR =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 70),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        minHeight: 6,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ===== SUBTEXT =====
              Text(
                "Loading your workspace…",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}