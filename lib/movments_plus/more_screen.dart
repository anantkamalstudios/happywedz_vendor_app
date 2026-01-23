// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:happy_weds_vendors/movments_plus/token_sharing.dart';
// import 'package:happy_weds_vendors/utils/common_app_bar.dart';
//
// import 'analytics_screen.dart';
// import 'event.dart';
//
// class MoreScreen extends StatelessWidget {
//   const MoreScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF8F9FA),
//      appBar: CommonAppBar(title: 'More Screens'),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _sectionTitle("Management"),
//           _menuTile(
//             icon: Icons.analytics,
//             title: "Analytics",
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const AnalyticsScreen(),
//                 ),
//               );
//             },
//           ),
//           _menuTile(
//             icon: Icons.storage,
//             title: "Packages & Storage",
//             onTap: () {
//               // Navigator.push(
//               //   context,
//               //   MaterialPageRoute(
//               //     builder: (_) => const PackagesScreen(),
//               //   ),
//               // );
//             },
//           ),
//           _menuTile(
//             icon: Icons.event,
//             title: "My Events",
//             onTap: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (_) => const EventsManagementPage(),
//                 ),
//               );
//             },
//           ),
//
//         ],
//       ),
//     );
//   }
//
//   // ======================= UI HELPERS =======================
//
//   Widget _sectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         title.toUpperCase(),
//         style: TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//           color: Colors.grey[600],
//           letterSpacing: 1,
//         ),
//       ),
//     );
//   }
//
//   Widget _menuTile({
//     required IconData icon,
//     required String title,
//     required VoidCallback onTap,
//     Color iconColor = const Color(0xFF00509D),
//   }) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ListTile(
//         leading: Icon(icon, color: iconColor),
//         title: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         trailing: const Icon(Icons.chevron_right),
//         onTap: onTap,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';

import 'analytics_screen.dart';
import 'event.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: 'More'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _headerCard(),
          const SizedBox(height: 24),

          _sectionTitle("Management"),
          _menuTile(
            icon: Icons.analytics,
            title: "Analytics",
            subtitle: "View performance & insights",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          _menuTile(
            icon: Icons.storage,
            title: "Packages & Storage",
            subtitle: "Manage plan & storage usage",
            onTap: () {
              // TODO: Navigate to Packages screen
            },
          ),

          const SizedBox(height: 24),

          _sectionTitle("Events"),
          _menuTile(
            icon: Icons.event,
            title: "My Events",
            subtitle: "Create & manage your events",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EventsManagementPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ======================= HEADER =======================

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00509D), Color(0xFF0066CC)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: const Icon(Icons.apps, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "More Options",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                "Manage analytics, events & storage",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ======================= SECTION TITLE =======================

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[600],
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ======================= MENU TILE =======================

  Widget _menuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF00509D),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.grey,
        ),
        onTap: onTap,
      ),
    );
  }
}
