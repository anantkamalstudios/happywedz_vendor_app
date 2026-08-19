import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/movments_plus/package_page.dart';

import '../auth/auth_guard.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'analytics_screen.dart';
import 'event.dart';

/// AUDIT NOTE:
/// Analytics, Packages & Storage and My Events all read vendor-scoped data
/// from authenticated endpoints. They were opened with a bare
/// `Navigator.push`, so a tap that landed after the session had gone opened
/// the screen anyway and it simply rendered empty. They now go through
/// [AuthGuard], which verifies the session before pushing and re-verifies on
/// every app resume.

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        title: Text("More", style: AppTextStyles.appBarTitle),
        elevation: 1,
      ),
      //appBar: CommonAppBar(title: 'More'),
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
            onTap: () => AuthGuard.push(
              context,
              (_) => const AnalyticsScreen(),
              debugLabel: 'AnalyticsScreen',
            ),
          ),
          _menuTile(
            icon: Icons.storage,
            title: "Packages & Storage",
            subtitle: "Manage plan & storage usage",
            onTap: () => AuthGuard.push(
              context,
              (_) => PackageStoragePage(),
              debugLabel: 'PackageStoragePage',
            ),
          ),

          const SizedBox(height: 24),

          _sectionTitle("Events"),
          _menuTile(
            icon: Icons.event,
            title: "My Events",
            subtitle: "Create & manage your events",
            onTap: () => AuthGuard.push(
              context,
              (_) => const EventsManagementPage(),
              debugLabel: 'EventsManagementPage',
            ),
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
            backgroundColor: Colors.white.withValues(alpha: 0.2),
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
            color: Colors.black.withValues(alpha: 0.04),
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
            color: iconColor.withValues(alpha: 0.1),
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
