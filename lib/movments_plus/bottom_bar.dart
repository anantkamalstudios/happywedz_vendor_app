import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/movments_plus/token_sharing.dart';
import 'package:happy_weds_vendors/movments_plus/upload_screen.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'gallery_screen.dart';
import 'more_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),      // 0 - Dashboard
    TokensSharingScreen(),   // 1 - Token Sharing
    UploadMediaScreen(),         // 2 - Upload
    GalleryScreen(),        // 3 - Gallery
    MoreScreen(),      // 4 - Analytics
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF00509D),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,

          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.dashboard,
                color: _selectedIndex == 0
                    ? const Color(0xFF00509D)
                    : Colors.grey,
              ),
              label: "Dashboard",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.vpn_key,
                color: _selectedIndex == 1
                    ? const Color(0xFF00509D)
                    : Colors.grey,
              ),
              label: "Tokens",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.cloud_upload,
                color: _selectedIndex == 2
                    ? const Color(0xFF00509D)
                    : Colors.grey,
              ),
              label: "Upload",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.photo_library,
                color: _selectedIndex == 3
                    ? const Color(0xFF00509D)
                    : Colors.grey,
              ),
              label: "Gallery",
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.menu,
                color: _selectedIndex == 4
                    ? const Color(0xFF00509D)
                    : Colors.grey,
              ),
              label: "More",
            ),
          ],
        ),
      ),
    );
  }
}
