import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Screens/Login.dart';
import 'Screens/HomeScreen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // 👇 REQUIRED for Flutter Quill
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        quill.FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      home: const SplashScreen(),
    );

  }
}




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
