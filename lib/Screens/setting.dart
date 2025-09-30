import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionTitle("Account"),
          _buildSettingTile(
            icon: Icons.lock_outline,
            title: "Change Password",
            onTap: () {
              // Navigate to Change Password page
            },
          ),
          const Divider(height: 0),
          _buildSettingTile(
            icon: Icons.email_outlined,
            title: "Change Email",
            onTap: () {
              // Navigate to Change Email page
            },
          ),

          const SizedBox(height: 24),
          _buildSectionTitle("Preferences"),
          _buildSettingTile(
            icon: Icons.notifications_none,
            title: "Notification Settings",
            onTap: () {},
          ),
          const Divider(height: 0),
          _buildSettingTile(
            icon: Icons.language,
            title: "Language",
            onTap: () {},
          ),

          const SizedBox(height: 24),
          _buildSectionTitle("Support"),
          _buildSettingTile(
            icon: Icons.help_outline,
            title: "Help & FAQs",
            onTap: () {},
          ),
          const Divider(height: 0),
          _buildSettingTile(
            icon: Icons.phone_in_talk_outlined,
            title: "Contact Support",
            onTap: () {},
          ),

          const SizedBox(height: 24),
          _buildSignOutButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.pinkAccent),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text(
          "Sign Out",
          style: TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          // Handle sign-out confirmation
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Sign Out"),
              content: const Text("Are you sure you want to sign out?"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // Perform sign-out action
                  },
                  child:  Text(
                    "Sign Out",
                    style: TextStyle(color: Colors.pinkAccent[200]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
