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
  String profileImage = "";
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
      profileImage = prefs.getString('profileImage') ?? "";
      _isLoading = false;
    });
  }

// Add this to reload drawer when it opens
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData(); // Ensures latest info is loaded each time
  }



  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', file.path);
      setState(() {
        profileImage = file.path;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile picture updated")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer header
          Container(
            color: Colors.pinkAccent,
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
                : Column(
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: profileImage.isNotEmpty
                              ? (profileImage.startsWith('http')
                              ? NetworkImage(profileImage)
                              : FileImage(File(profileImage))) as ImageProvider
                              : const AssetImage("assets/images/default_profile.png"),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.pinkAccent,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty ? userName : "Vendor Name",
                            style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail.isNotEmpty ? userEmail : "vendor@example.com",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
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

          // Drawer menu
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

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.pinkAccent),
            title: const Text('Logout'),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);
              await prefs.remove('businessName');
              await prefs.remove('email');
              await prefs.remove('profileImage');

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
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
