// // import 'dart:io';
// // import 'package:flutter/material.dart';
// // import 'package:connectivity_plus/connectivity_plus.dart';
// // import 'Screens/SignUp.dart';
// //
// // void main() {
// //   runApp(const MyApp());
// // }
// //
// // class MyApp extends StatelessWidget {
// //   const MyApp({super.key});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       theme: ThemeData(
// //         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
// //       ),
// //       home: const InternetCheckWrapper(child: SignUp()),
// //     );
// //   }
// // }
// //
// // class InternetCheckWrapper extends StatefulWidget {
// //   final Widget child;
// //   const InternetCheckWrapper({super.key, required this.child});
// //
// //   @override
// //   State<InternetCheckWrapper> createState() => _InternetCheckWrapperState();
// // }
// //
// // class _InternetCheckWrapperState extends State<InternetCheckWrapper> {
// //   @override
// //   void initState() {
// //     super.initState();
// //     WidgetsBinding.instance.addPostFrameCallback((_) {
// //       _checkInternet();
// //     });
// //   }
// //
// //   Future<void> _checkInternet() async {
// //     bool hasInternet = await _hasInternet();
// //     if (!hasInternet) {
// //       _showNoInternetDialog();
// //     }
// //   }
// //
// //   Future<bool> _hasInternet() async {
// //     try {
// //       final result = await InternetAddress.lookup('example.com');
// //       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
// //     } on SocketException catch (_) {
// //       return false;
// //     }
// //   }
// //
// //   void _showNoInternetDialog() {
// //     showDialog(
// //       context: context,
// //       barrierDismissible: false,
// //       builder: (context) => AlertDialog(
// //         title: const Text("No Internet"),
// //         content: const Text("Please check your internet connection."),
// //         actions: [
// //           TextButton(
// //             onPressed: () {
// //               Navigator.pop(context);
// //               _checkInternet(); // retry
// //             },
// //             child: const Text("Retry"),
// //           ),
// //           // TextButton(
// //           //   onPressed: () => Navigator.pop(context),
// //           //   child: const Text("Close"),
// //           // ),
// //         ],
// //       ),
// //     );
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return widget.child;
// //   }
// // }
//
//
//
//
//
// import 'dart:async';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'Screens/SignUp.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const InternetCheckWrapper(child: SignUp()),
//     );
//   }
// }
//
// class InternetCheckWrapper extends StatefulWidget {
//   final Widget child;
//   const InternetCheckWrapper({super.key, required this.child});
//
//   @override
//   State<InternetCheckWrapper> createState() => _InternetCheckWrapperState();
// }
//
// class _InternetCheckWrapperState extends State<InternetCheckWrapper> {
//   late final _subscription; // let Dart infer the type
//   bool _dialogIsOpen = false;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkInternet();
//     });
//
//     // Listen to connectivity changes
//     _subscription = Connectivity().onConnectivityChanged.listen((event) {
//       _checkInternet();
//     });
//   }
//
//   Future<void> _checkInternet() async {
//     bool hasInternet = await _hasInternet();
//     if (!hasInternet && !_dialogIsOpen) {
//       _showNoInternetDialog();
//     }
//   }
//
//   Future<bool> _hasInternet() async {
//     try {
//       final result = await InternetAddress.lookup('example.com');
//       return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
//     } on SocketException catch (_) {
//       return false;
//     }
//   }
//
//   void _showNoInternetDialog() {
//     _dialogIsOpen = true;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("No Internet"),
//         content: const Text("Please check your internet connection."),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _dialogIsOpen = false;
//               _checkInternet();
//             },
//             child: const Text("Retry"),
//           ),
//         ],
//       ),
//     ).then((_) {
//       _dialogIsOpen = false;
//     });
//   }
//
//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return widget.child;
//   }
// }
















import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'Screens/SignUp.dart';
import 'Screens/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  InternetCheckWrapper(child: SignUp()),
    );
  }
}

class InternetCheckWrapper extends StatefulWidget {
  final Widget child;
  const InternetCheckWrapper({super.key, required this.child});

  @override
  State<InternetCheckWrapper> createState() => _InternetCheckWrapperState();
}

class _InternetCheckWrapperState extends State<InternetCheckWrapper> {
  late final _subscription;
  bool _dialogIsOpen = false;
  BuildContext? _dialogContext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInternet();
    });

    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkInternet();
    });
  }

  Future<void> _checkInternet() async {
    bool hasInternet = await _hasInternet();

    if (!hasInternet && !_dialogIsOpen) {
      _showNoInternetDialog();
    } else if (hasInternet && _dialogIsOpen && _dialogContext != null) {
      Navigator.pop(_dialogContext!); // close dialog automatically
      _dialogIsOpen = false;
      _dialogContext = null;
    }
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  void _showNoInternetDialog() {
    _dialogIsOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return const AlertDialog(
          title: Text("No Internet"),
          content: Text("Please check your internet connection."),
        );
      },
    ).then((_) {
      _dialogIsOpen = false;
      _dialogContext = null;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
