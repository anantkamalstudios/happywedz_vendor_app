

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/services/internet_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart' show MultiProvider, ChangeNotifierProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'SplashScreen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

/// AUDIT NOTE — REMOVED IMPORTS


void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  Connectivity().onConnectivityChanged.listen((status) async {
    try {
      final hasNet = await InternetService.hasInternet();
      debugPrint(hasNet ? "✅ Internet Connected" : "❌ No Internet");
    } catch (e) {
      debugPrint("⚠️ Connectivity check failed: $e");
    }
  });

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HappyWedz Business',

      // ======================================================================

      // ======================================================================
      theme: AppTheme.light,

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],

      builder: (context, child) {

        final media = MediaQuery.of(context);
        final clamped = media.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.30,
        );

        return MediaQuery(
          data: media.copyWith(textScaler: clamped),
          child: Stack(
            children: [
              if (child != null) child,
              const ConnectivityOverlay(), // shows/hides automatically
            ],
          ),
        );
      },

      home: const SplashScreen(),
    );
  }
}


class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.wifi_off_rounded, size: 72, color: AppColors.textTertiary),
              SizedBox(height: 20),
              Text(
                "No Internet Connection",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Please check your network",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// AUDIT NOTE — PRE-EXISTING COMMENTED-OUT CODE, RETAINED VERBATIM.
//
// This is the original inline SplashScreen. It was already commented out
// before this audit; the live implementation now lives in lib/SplashScreen.dart
// (which additionally fixes the 10-second splash delay and the token-less
// session check documented there).
//
// Kept intentionally. Do not delete without project-owner approval.
// ============================================================================
///
// /// Splash screen to check login status
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> {
//   bool _dialogIsOpen = false;
//   BuildContext? _dialogContext;
//
//   @override
//   void initState() {
//     super.initState();
//     _initializeApp();
//   }
//
//   Future<void> _initializeApp() async {
//     await _checkLoginStatus();
//    // await _checkInternet();
//   }
//
//   // ---------------- Login Status ----------------
//   Future<void> _checkLoginStatus() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
//
//     // Small delay for smooth splash transition
//     await Future.delayed(const Duration(milliseconds: 500));
//
//     if (isLoggedIn) {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const HomeScreen()),
//       );
//     } else {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (_) => const Login()), // or SignUp()
//       );
//     }
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return const Scaffold(
//       body: Center(child: CircularProgressIndicator()),
//     );
//   }
// }