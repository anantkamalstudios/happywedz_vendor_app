import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';
import 'package:lottie/lottie.dart';

class ViewPlansScreen extends StatelessWidget {
  const ViewPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Membership Plans"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🎞️ Lottie animation
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_x62chJ.json',
              width: 220,
              repeat: true,
            ),
            const SizedBox(height: 30),

            // 🔵 Coming Soon - BLUE
            const Text(
              "Coming Soon!",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Exciting Membership Plans are on the way.\nStay tuned for amazing benefits!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 40),

            // 🔵 Stay Tuned Button (soft blue)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.2),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                "Stay Tuned 💙",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
