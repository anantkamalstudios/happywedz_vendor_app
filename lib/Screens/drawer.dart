import 'package:flutter/material.dart';
import 'package:happy_weds_vendors/Screens/setting.dart';

import 'm_p.dart';

class BusinessDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header with stats
          Container(
            color: Colors.pinkAccent,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                          'https://example.com/profile.jpg'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("ABC Weddings",
                              style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text("abc@example.com",
                              style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem("Leads", "120"),
                    _statItem("Reviews", "45"),
                    _statItem("Views", "2.3K"),
                  ],
                ),
              ],
            ),
          ),

          // Menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(context,Icons.info_outline, "Public Info",SettingsPage()),
                _drawerItem(context,Icons.card_membership, "Membership Package",MembershipPackagePage()),
                _drawerItem(context,Icons.rate_review, "Invite to Review",SettingsPage()),
                _drawerItem(context, Icons.settings, "Settings", SettingsPage()),
                _drawerItem(context,Icons.support_agent, "Contact Support",SettingsPage()),
                _drawerItem(context,Icons.update, "Updates",SettingsPage()),
                _drawerItem(context,Icons.star_rate, "Rate on Playstore",SettingsPage()),
                _drawerItem(context,Icons.headset_mic, "Support",SettingsPage()),
              ],
            ),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.pinkAccent),
            title: const Text('Logout'),
            onTap: () {
              // Handle logout
            },
          ),
        ],
      ),
    );
  }

  Widget _statItem(String title, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget page,
      ) {
    return ListTile(
      leading: Icon(icon, color: Colors.pinkAccent),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }

}
