import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/services/internet_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:provider/provider.dart' show MultiProvider, ChangeNotifierProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'SplashScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Connectivity().onConnectivityChanged.listen((status) async {
    final hasNet = await InternetService.hasInternet();
    debugPrint(hasNet ? "✅ Internet Connected" : "❌ No Internet");
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
              return Stack(
                children: [
                  if (child != null) child,
                  const ConnectivityOverlay(), // shows/hides automatically
                ],
              );
            },

          home: const SplashScreen()

        );

  }}

class NoInternetScreen extends StatelessWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.wifi_off, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text("Please check your network"),
          ],
        ),
      ),
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
