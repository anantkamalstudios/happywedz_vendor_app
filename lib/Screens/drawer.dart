import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Login.dart';
import 'm_p.dart';
import 'setting.dart';

class BusinessDrawer extends StatefulWidget {
  const BusinessDrawer({Key? key}) : super(key: key);

  @override
  State<BusinessDrawer> createState() => _BusinessDrawerState();
}

class _BusinessDrawerState extends State<BusinessDrawer> {
  String userName = "";
  String userEmail = "";
  String coverImage = "";
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('businessName') ?? "Vendor Name";
      userEmail = prefs.getString('email') ?? "vendor@example.com";
      coverImage = prefs.getString('coverImage') ?? ""; // Only from drawer
      _isLoading = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Save only under drawer key
      await prefs.setString('coverImage', file.path);

      setState(() {
        coverImage = file.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cover image updated")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width cover image with name/email overlay
          GestureDetector(
            onTap: _pickCoverImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.pinkAccent,
                image: coverImage.isNotEmpty
                    ? DecorationImage(
                  image: coverImage.startsWith('http')
                      ? NetworkImage(coverImage)
                      : FileImage(File(coverImage)) as ImageProvider,
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: Container(
                // Optional semi-transparent overlay for readability
                color: Colors.pinkAccent.withOpacity(0.6),
                padding: const EdgeInsets.only(left: 16, bottom: 16, top: 40, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      userName.isNotEmpty ? userName : "Vendor Name",
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userEmail.isNotEmpty ? userEmail : "vendor@example.com",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Stats row below cover image
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem("Leads", "120"),
                _statItem("Reviews", "45"),
                _statItem("Views", "2.3K"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Drawer menu items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(context, Icons.info_outline, "Public Info", const SettingsPage()),
                _drawerItem(context, Icons.card_membership, "Membership Package", const MembershipPackagePage()),
                _drawerItem(context, Icons.rate_review, "Invite to Review", const SettingsPage()),
                _drawerItem(context, Icons.settings, "Settings", const SettingsPage()),
                _drawerItem(context, Icons.support_agent, "Contact Support", const SettingsPage()),
                _drawerItem(context, Icons.update, "Updates", const SettingsPage()),
                _drawerItem(context, Icons.star_rate, "Rate on Playstore", const SettingsPage()),
                _drawerItem(context, Icons.headset_mic, "Support", const SettingsPage()),
              ],
            ),
          ),

          const Divider(),

          // Logout button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.pinkAccent),
            title: const Text('Logout'),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('businessName');
              await prefs.remove('email');
              await prefs.remove('coverImage');

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  static Widget _statItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon, color: Colors.pinkAccent),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
