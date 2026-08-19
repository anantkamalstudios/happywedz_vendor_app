import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/movments_plus/token_sharing.dart';
import 'package:happy_weds_vendors/movments_plus/upload_screen.dart';
import 'dashboard_screen.dart';
import 'gallery_screen.dart';
import 'more_screen.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  /// Lets any descendant (and screens pushed on top of this one, e.g.
  /// `EventsManagementPage`) drive the bottom navigation:
  ///
  ///   MainHomeScreen.of(context)?.openUpload();
  ///
  /// Returns `null` only when no `MainHomeScreen` is currently mounted.
  static MainHomeScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainHomeScreenState>() ??
        MainHomeScreenState._current;
  }

  @override
  State<MainHomeScreen> createState() => MainHomeScreenState();
}

class MainHomeScreenState extends State<MainHomeScreen> {
  /// The mounted instance, so pushed routes (which are siblings of this
  /// screen in the navigator, not descendants) can still reach it.
  static MainHomeScreenState? _current;

  static const int dashboardTab = 0;
  static const int tokensTab = 1;
  static const int uploadTab = 2;
  static const int galleryTab = 3;
  static const int moreTab = 4;

  int _selectedIndex = dashboardTab;

  // Arguments handed to the tab pages when they are opened programmatically.
  String? _uploadEventId;
  String? _uploadEventName;
  TokenFilterType _tokenFilter = TokenFilterType.all;

  @override
  void initState() {
    super.initState();
    _current = this;
  }

  @override
  void dispose() {
    if (_current == this) _current = null;
    super.dispose();
  }

  Widget _pageFor(int index) {
    switch (index) {
      case tokensTab:
        return TokensSharingScreen(initialFilter: _tokenFilter);
      case uploadTab:
        return UploadMediaScreen(
          preselectedEventId: _uploadEventId,
          preselectedEventName: _uploadEventName,
        );
      case galleryTab:
        return const GalleryScreen();
      case moreTab:
        return const MoreScreen();
      case dashboardTab:
      default:
        return const DashboardScreen();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      // A manual tap is a fresh visit, so drop any programmatic pre-selection.
      if (index != uploadTab) {
        _uploadEventId = null;
        _uploadEventName = null;
      }
      if (index != tokensTab) {
        _tokenFilter = TokenFilterType.all;
      }
      _selectedIndex = index;
    });
  }

  /// Switches to [index], first popping anything pushed on top of this screen
  /// so the tab actually becomes visible.
  void _goToTab(int index) {
    if (!mounted) return;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      Navigator.of(context).popUntil((r) => r == route);
    }

    setState(() => _selectedIndex = index);
  }

  /// Opens the Upload tab, optionally pre-selecting an event.
  void openUpload({String? eventId, String? eventName}) {
    _uploadEventId = eventId;
    _uploadEventName = eventName;
    _goToTab(uploadTab);
  }

  /// Opens the Tokens tab with [filter] applied.
  void openTokensWithFilter(TokenFilterType filter) {
    _tokenFilter = filter;
    _goToTab(tokensTab);
  }

  void openDashboard() => _goToTab(dashboardTab);

  void openGallery() => _goToTab(galleryTab);

  void openMore() => _goToTab(moreTab);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageFor(_selectedIndex),

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
