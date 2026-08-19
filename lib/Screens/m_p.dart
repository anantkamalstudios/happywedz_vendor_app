// ============================================================================
// AUDIT NOTE — UNREFERENCED FILE, COMMENTED OUT (NOT DELETED)
// ============================================================================
//
// STATUS: dead code. Verified unreferenced across the whole project:
//   * no `import` of this file exists anywhere in lib/
//   * none of the classes it declares are constructed or navigated to
//   * it is not reachable from main.dart -> SplashScreen -> Login/HomeScreen
//
// REASON IT IS RETAINED:
// Not reachable and not imported. Superseded by lib/movments_plus/ (the
//   photographer 'Moments+' module reached from the dashboard FAB).
//
// The ENTIRE original source is preserved verbatim below, line for line, with
// a `// ` prefix. To restore this file, strip the leading `// ` from every
// line below the marker and remove this header.
//
// DO NOT DELETE WITHOUT PROJECT-OWNER APPROVAL.
//
// ------------------------- ORIGINAL SOURCE BELOW ----------------------------

// import 'package:flutter/material.dart';
//
// class MembershipPackagePage extends StatelessWidget {
//   const MembershipPackagePage({super.key});
//
//   Widget _planCard({
//     required String title,
//     required String price,
//     required String duration,
//     required List<String> features,
//     required Color color,
//   }) {
//     return Card(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title,
//                 style: TextStyle(
//                     fontSize: 18, fontWeight: FontWeight.bold, color: color)),
//             const SizedBox(height: 4),
//             Text("$price / $duration",
//                 style: const TextStyle(
//                     fontSize: 16, fontWeight: FontWeight.w600)),
//             const SizedBox(height: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: features
//                   .map((f) => Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.check,
//                         color: Colors.green, size: 20),
//                     const SizedBox(width: 8),
//                     Expanded(child: Text(f)),
//                   ],
//                 ),
//               ))
//                   .toList(),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: color,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 onPressed: () {
//                   // Buy now logic
//                 },
//                 child: const Text(
//                   "Buy Now",
//                   style: TextStyle(color: Colors.white),
//                 ),
//
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Membership Packages"),
//         backgroundColor: Color(0xFF00509D),
//         foregroundColor: Colors.white,
//
//
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _planCard(
//             title: "Basic Plan",
//             price: "₹999",
//             duration: "month",
//             features: [
//               "Get 50 Leads",
//               "Appear in Search Results",
//               "Basic Profile Listing",
//             ],
//             color: const Color(0xFF00509D),
//
//           ),
//           _planCard(
//             title: "Premium Plan",
//             price: "₹2999",
//             duration: "month",
//             features: [
//               "Get 200 Leads",
//               "Priority Search Listing",
//               "Featured Vendor Badge",
//               "Dedicated Support",
//             ],
//             color: const Color(0xFF00509D),
//
//           ),
//           _planCard(
//             title: "Annual Plan",
//             price: "₹19999",
//             duration: "year",
//             features: [
//               "Unlimited Leads",
//               "Top Search Priority",
//               "Premium Badge & Promotion",
//               "Dedicated Account Manager",
//             ],
//             color: const Color(0xFF00509D),
//
//           ),
//         ],
//       ),
//     );
//   }
// }
