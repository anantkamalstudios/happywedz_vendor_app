import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_weds_vendors/utils/common_app_bar.dart';

class TokenGeneratorPage extends StatefulWidget {
  const TokenGeneratorPage({Key? key}) : super(key: key);

  @override
  State<TokenGeneratorPage> createState() => _TokenGeneratorPageState();
}

class _TokenGeneratorPageState extends State<TokenGeneratorPage> {
  int selectedType = 0;
  bool isLoading = false;

  // ======================= API CALL =======================

  Future<void> _generateToken() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken =
          prefs.getString('token') ?? prefs.getString('authToken');
      final vendorId = prefs.getInt('vendorId');

      if (authToken == null || vendorId == null) {
        throw Exception("Auth data missing");
      }

      final type = selectedType == 0 ? 'private' : 'public';

      final response = await http.post(
        Uri.parse('https://happywedz.com/api/token/generate'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "vendorId": vendorId,
          "type": type,
        }),
      );

      final data = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token generated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to generate token');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isLoading = false);
    }
  }

  // ======================= UI =======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: CommonAppBar(title: 'Generate Token'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Choose Token Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3436),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTokenCard(
                      isSelected: selectedType == 0,
                      icon: Icons.lock_outline,
                      iconColor: const Color(0xFF00509D),
                      title: 'Private Gallery',
                      description:
                      'Token-protected access. Perfect for exclusive client galleries.',
                      features: const [
                        'Protected access',
                        'Email sharing',
                        'Activity tracking',
                      ],
                      onTap: () => setState(() => selectedType = 0),
                    ),

                    const SizedBox(height: 16),

                    _buildTokenCard(
                      isSelected: selectedType == 1,
                      icon: Icons.public,
                      iconColor: const Color(0xFF10B981),
                      title: 'Public Gallery',
                      description:
                      'Open access with shareable link. Great for portfolio displays.',
                      features: const [
                        'Open access',
                        'Quick sharing',
                        'SEO optimized',
                      ],
                      onTap: () => setState(() => selectedType = 1),
                    ),

                    const SizedBox(height: 20),

                    // ================= INFO BANNER =================
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline,
                              color: Color(0xFF2196F3), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Token will be linked to your active event automatically',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF2196F3),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ================= BOTTOM BUTTONS =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFDFE6E9),
                          width: 1.5,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF636E72),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _generateToken,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF00509D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add_circle_outline, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Generate Token',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================= TOKEN CARD =======================

  Widget _buildTokenCard({
    required bool isSelected,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? iconColor : const Color(0xFFE1E8ED),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: iconColor.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const Spacer(),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Selected',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF636E72),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            ...features.map(
                  (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: iconColor, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2D3436),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

