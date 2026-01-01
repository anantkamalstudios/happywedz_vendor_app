import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/common_app_bar.dart';

class SocialNetworkPage extends StatefulWidget {
  const SocialNetworkPage({super.key});

  @override
  State<SocialNetworkPage> createState() => _SocialNetworkPageState();
}

class _SocialNetworkPageState extends State<SocialNetworkPage> {
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final TextEditingController pinterestController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  bool loading = false;
  bool saving = false;

  int? vendorId;
  String? token;

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ================= INIT =================
  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    vendorId = prefs.getInt('vendorId');
    token = prefs.getString('token');

    print("🔑 vendorId: $vendorId | token: $token");

    if (vendorId != null && token != null) {
      await _fetchLinksFromAPI(); // 🔥 ALWAYS FETCH FRESH
    }
  }

  // ================= FETCH FROM API =================
  Future<void> _fetchLinksFromAPI() async {
    setState(() => loading = true);

    try {
      final response = await http.get(
        Uri.parse("https://happywedz.com/api/vendor/$vendorId"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      print("📩 GET response: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          facebookController.text = data['facebook_link'] ?? '';
          instagramController.text = data['instagram_link'] ?? '';
          pinterestController.text = data['pinterest_link'] ?? '';
          twitterController.text = data['twitter_link'] ?? '';
          websiteController.text = data['website'] ?? '';
        });

        // Optional: cache locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('facebook_link', facebookController.text);
        await prefs.setString('instagram_link', instagramController.text);
        await prefs.setString('pinterest_link', pinterestController.text);
        await prefs.setString('twitter_link', twitterController.text);
        await prefs.setString('website', websiteController.text);

        print("✅ Fresh links loaded from API");
      } else {
        print("❌ Failed to fetch vendor data");
      }
    } catch (e) {
      print("❌ API Error: $e");
    }

    setState(() => loading = false);
  }

  // ================= SAVE LINKS =================
  Future<void> saveLinks() async {
    if (vendorId == null || token == null) return;

    setState(() => saving = true);

    final body = {
      "facebook_link": facebookController.text.trim(),
      "instagram_link": instagramController.text.trim(),
      "pinterest_link": pinterestController.text.trim(),
      "twitter_link": twitterController.text.trim(),
      "website": websiteController.text.trim(),
    };

    try {
      final response = await http.put(
        Uri.parse("https://happywedz.com/api/vendor/$vendorId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      );

      print("📩 PUT response: ${response.statusCode}");
      print("📦 Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('facebook_link', body['facebook_link']!);
        await prefs.setString('instagram_link', body['instagram_link']!);
        await prefs.setString('pinterest_link', body['pinterest_link']!);
        await prefs.setString('twitter_link', body['twitter_link']!);
        await prefs.setString('website', body['website']!);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Links saved successfully")),
        );

        print("✅ Links updated on server + local cache");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save links")),
        );
      }
    } catch (e) {
      print("❌ Save error: $e");
    }

    setState(() => saving = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonAppBar(title: "Professional Links"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add Your Professional Links",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            _socialField(
              label: "Facebook",
              hint: "https://www.facebook.com/username",
              icon: Icons.facebook,
              color: const Color(0xFF1877F2),
              controller: facebookController,
            ),

            _socialField(
              label: "Instagram",
              hint: "https://www.instagram.com/username",
              icon: Icons.camera_alt,
              color: const Color(0xFF00509D),
              controller: instagramController,
            ),

            _socialField(
              label: "Pinterest",
              hint: "https://www.pinterest.com/username",
              icon: Icons.push_pin,
              color: const Color(0xFFE60023),
              controller: pinterestController,
            ),

            _socialField(
              label: "Twitter",
              hint: "https://www.twitter.com/username",
              icon: Icons.alternate_email,
              color: const Color(0xFF1DA1F2),
              controller: twitterController,
            ),

            _socialField(
              label: "Website",
              hint: "https://www.yourwebsite.com",
              icon: Icons.web,
              color: const Color(0xFF4CAF50),
              controller: websiteController,
            ),

            const SizedBox(height: 40),

            Center(
              child: ElevatedButton(
                onPressed: saving ? null : saveLinks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00509D),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Save Links",
                  style:
                  TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SOCIAL FIELD WIDGET =================
  Widget _socialField({
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
