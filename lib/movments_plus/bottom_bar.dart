import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/movments_plus/token_sharing.dart';
import 'package:happy_weds_vendors/movments_plus/upload_screen.dart';

import 'dashboard_screen.dart';
import 'event.dart';
import 'more_screen.dart';

enum MainTab { dashboard, tokens, upload, events, more }
class MainHomeScreen extends StatefulWidget {
  final MainTab initialTab;
  final String? preselectedEventId;
  final String? preselectedEventName;

  const MainHomeScreen({
    super.key,
    this.initialTab = MainTab.dashboard,
    this.preselectedEventId,
    this.preselectedEventName,
  });

  static _MainHomeScreenState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainHomeScreenState>();

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}
class _MainHomeScreenState extends State<MainHomeScreen> {
  late MainTab selectedTab;
  String? selectedEventId;
  String? selectedEventName;
  TokenFilterType selectedTokenFilter = TokenFilterType.all;

  @override
  void initState() {
    super.initState();
    selectedTab = widget.initialTab;
  }
  void openTokensWithFilter(TokenFilterType filter) {
    setState(() {
      selectedTokenFilter = filter;
      selectedTab = MainTab.tokens;
    });
  }

  void openUpload({String? eventId, String? eventName}) {
    setState(() {
      selectedEventId = eventId;
      selectedEventName = eventName;
      selectedTab = MainTab.upload;
    });
  }


  @override
  Widget build(BuildContext context) {
    final pages = {
      MainTab.dashboard: const DashboardScreen(),
     // MainTab.tokens: const TokensSharingScreen(),
      MainTab.tokens: TokensSharingScreen(
        initialFilter: selectedTokenFilter,
      ),

      MainTab.upload: UploadMediaScreen(
        preselectedEventId: selectedEventId,
        preselectedEventName: selectedEventName,
      ),

      MainTab.events: const EventsManagementPage(),
      MainTab.more: const MoreScreen(),
    };

    return Scaffold(
      body: IndexedStack(
        index: MainTab.values.indexOf(selectedTab),
        children: pages.values.toList(),
      ),

      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: MainTab.values.indexOf(selectedTab),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF00509D),
          unselectedItemColor: Colors.grey,
          onTap: (i) => setState(() => selectedTab = MainTab.values[i]),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.vpn_key), label: "Tokens"),
            BottomNavigationBarItem(icon: Icon(Icons.cloud_upload), label: "Upload"),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: "More"),
          ],
        ),
      ),
    );
  }
}
