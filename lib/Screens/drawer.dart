import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../Storefront/StoreFront.dart';
import 'Login.dart';

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

  int leadCount = 0;
  int viewsCount = 0;
  int? vendorId;



  bool loadingLink = false;
  String? reviewLink;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVendorId();
  }

Future<void> _loadVendorId() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    vendorId = prefs.getInt("vendorId");
  });
}
  Future<void> _contactSupport() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String fromEmail = prefs.getString('email') ?? "";

    final Uri emailUri = Uri(
      scheme: "mailto",
      path: "pranjal.anantkamal@gmail.com",
      query: "subject=Support Request"
          "&body=Hello,\n\nMy registered email is: $fromEmail\n\nWrite your query here...",
    );

    try {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("❌ Email launch error: $e");
    }
  }

  /// ✅ Load user data
  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('businessName') ?? "Vendor Name";
      userEmail = prefs.getString('email') ?? "vendor@example.com";
      coverImage = prefs.getString('coverImage') ?? "";
      leadCount = prefs.getInt('lead_count') ?? 0;
      viewsCount = prefs.getInt('views_count') ?? 0;
      _isLoading = false;
    });
  }

  /// ✅ Pick Image
  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('coverImage', pickedFile.path);

    setState(() {
      coverImage = pickedFile.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cover image updated")),
    );
  }

  /// ✅ Remove Image
  Future<void> _removeCoverImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('coverImage');

    setState(() {
      coverImage = "";
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cover image removed")),
    );
  }

  /// ✅ Show Edit Options
  // void _showEditOptions() {
  //   showModalBottomSheet(
  //     backgroundColor: Colors.white,
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (_) {
  //       return Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           ListTile(
  //             leading: const Icon(Icons.photo, color: Colors.blue),
  //             title: const Text("Change Photo"),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _pickCoverImage();
  //             },
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.delete, color: Colors.red),
  //             title: const Text("Remove Photo"),
  //             onTap: () {
  //               Navigator.pop(context);
  //               _removeCoverImage();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {

    return Drawer(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // onTap: _showEditOptions,
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.pink[100],
                  image: coverImage.isNotEmpty
                      ? DecorationImage(
                    image: coverImage.startsWith('http')
                        ? NetworkImage(coverImage)
                        : FileImage(File(coverImage))
                    as ImageProvider,
                    fit: BoxFit.cover,
                  )
                      : null,
                ),

                child: Container(
                  color: coverImage.isEmpty
                      ? const Color(0xFFE0F7FA)
                      : Colors.transparent,
                  padding: const EdgeInsets.only(
                    left: 16,
                    bottom: 16,
                    top: 40,
                    right: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            userName,
                            softWrap: true,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 4),
                              // IconButton(
                              //   icon: const Icon(
                              //     Icons.add_a_photo,
                              //    // color: Color(0xFF4682B4),
                              //     color: Colors.black,
                              //     size: 20,
                              //   ),
                              //   onPressed: () {
                              //     _showEditOptions();
                              //   },
                              // ),

                            ],
                          ),
                        ],
                      ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          ),


          /// MENU ITEMS
          Expanded(

            child: Container(
              color: Colors.white,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [

                  ListTile(
                    leading: const Icon(Icons.storefront_outlined,
                        color: Color(0xFF4682B4)),
                    title: const Text("Storefront"),
                    onTap: () {
                      Navigator.pop(context);

                      if (vendorId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                              Text("Vendor ID not found. Please login again.")),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Storefront(vendorId: vendorId!),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.reviews,
                      color: Color(0xFF4682B4),
                    ),
                    title: const Text("Get Client Review to You"),
                    trailing: loadingLink
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : null,
                    onTap: () async {
                      await _generateReviewLinkOnce();

                      if (reviewLink == null || reviewLink!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Unable to generate review link")),
                        );
                        return;
                      }

                      await Share.share(
                        "Hey! 😊\n\n"
                            "Please take a moment to share your review about my work:\n\n"
                            "$reviewLink\n\n"
                            "Thank you so much! 🙏",
                      );
                    },
                  ),

                  // ListTile(
                  //   leading: const Icon(Icons.reviews,
                  //       color: Color(0xFF4682B4)),
                  //   title: const Text("Get Client Review to You"),
                  //   onTap: () async {
                  //     await Share.share(
                  //       "Hey! Please share your review about my work 😊",
                  //     );
                  //   },
                  // ),

                  // ListTile(
                  //   leading: const Icon(Icons.support_agent,
                  //       color: Color(0xFF4682B4)),
                  //   title: const Text("Contact Support"),
                  //   onTap: () async {
                  //     Navigator.pop(context);
                  //     _contactSupport();
                  //   },
                  // ),
                  ListTile(
                    leading: const Icon(
                      Icons.star_rate,
                      color: Color(0xFF4682B4),
                    ),
                    title: const Text("Rate on Playstore"),
                    onTap: _rateOnPlayStore,
                  ),

                  // ListTile(
                  //   leading: const Icon(Icons.star_rate,
                  //       color: Color(0xFF4682B4)),
                  //   title: const Text("Rate on Playstore"),
                  //   onTap: () => _showRateDialog(context),
                  // ),
                ],
              ),
            ),
          ),

          const Divider(
            color: Colors.grey,
          ),

          /// Logout
          // Container(
          //   color: Colors.white,
          //   child: ListTile(
          //     leading: const Icon(Icons.logout,  color: Color(0xFF4682B4)),
          //     title: const Text('Logout'),
          //     onTap: () async {
          //       SharedPreferences prefs =
          //       await SharedPreferences.getInstance();
          //       await prefs.clear();
          //
          //       Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(
          //           builder: (_) => Login(), // Login Page
          //         ),
          //       );
          //     },
          //   ),
          // ),
          Container(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF4682B4)),
              title: const Text('Logout'),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();

                // 🔐 Check if Remember Me was enabled
                final rememberMe =
                    prefs.getString('savedPassword') != null &&
                        prefs.getString('email') != null;

                // ❌ Clear session data only
                await prefs.remove('isLoggedIn');
                await prefs.remove('authToken');
                await prefs.remove('token');
                await prefs.remove('vendorId');
                await prefs.remove('vendorTypeId');
                await prefs.remove('businessName');
                await prefs.remove('phone');
                await prefs.remove('profileImage');
                await prefs.remove('profileCompleted');
                await prefs.remove('vendorTypeName');

                // ❌ Clear credentials ONLY if remember me was OFF
                if (!rememberMe) {
                  await prefs.remove('email');
                  await prefs.remove('savedPassword');
                }

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Login()),
                );
              },
            ),
          ),

        ],
      ),
    );
  }


  void _rateOnPlayStore() async {
    const playStoreUrl =
        "https://play.google.com/store/apps/details?id=com.happy.happy_weds_vendors";

    final uri = Uri.parse(playStoreUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication, // 🔥 opens Play Store app
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to open Play Store")),
      );
    }
  }


  // ================= GET VENDOR SERVICE ID =================
  Future<int?> _getVendorServiceId(int vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    final res = await http.get(
      Uri.parse(
          "https://happywedz.com/api/vendor-services/vendor/$vendorId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      if (data.isNotEmpty) {
        return data[0]['id'];
      }
    }
    return null;
  }

  Future<void> _generateReviewLinkOnce() async {
    if (reviewLink != null && reviewLink!.isNotEmpty) return; // 🔥 generate once

    final prefs = await SharedPreferences.getInstance();
    final vendorId = prefs.getInt("vendorId");
    if (vendorId == null) return;

    setState(() => loadingLink = true);

    final serviceId = await _getVendorServiceId(vendorId);

    setState(() {
      loadingLink = false;
      reviewLink = serviceId != null
          ? "https://happywedz.com/write-review/$serviceId"
          : null;
    });
  }

  /// Stat Item
  static Widget _statItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  /// Drawer Item
  Widget _drawerItem(
      BuildContext context,
      IconData icon,
      String title,
      Widget page, {
        Color iconColor = Colors.blue,
      }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ).then((_) => _loadUserData());
      },
    );
  }

  /// Rate Sheet
  void _showRateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => const SizedBox(
        height: 200,
        child: Center(child: Text("Rate bottom sheet")),
      ),
    );
  }
}

